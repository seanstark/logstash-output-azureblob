require 'logstash/outputs/base'
require 'logstash/namespace'
require 'azure/storage/blob'
require 'azure/storage/common'
require 'tmpdir'

class LogStash::Outputs::LogstashAzureBlobOutput < LogStash::Outputs::Base
  # name for the namespace under output for logstash configuration
  config_name 'azure_blob'
  default :codec, "line"

  require 'logstash/outputs/blob/writable_directory_validator'
  require 'logstash/outputs/blob/path_validator'
  require 'logstash/outputs/blob/size_rotation_policy'
  require 'logstash/outputs/blob/time_rotation_policy'
  require 'logstash/outputs/blob/size_and_time_rotation_policy'
  require 'logstash/outputs/blob/temporary_file'
  require 'logstash/outputs/blob/temporary_file_factory'
  require 'logstash/outputs/blob/uploader'
  require 'logstash/outputs/blob/file_repository'

  PREFIX_KEY_NORMALIZE_CHARACTER = '_'.freeze
  PERIODIC_CHECK_INTERVAL_IN_SECONDS = 15
  CRASH_RECOVERY_THREADPOOL = Concurrent::ThreadPoolExecutor.new(min_threads: 1,
                                                                 max_threads: 2,
                                                                 fallback_policy: :caller_runs)

  # azure container
  config :storage_account_name, validate: :string, required: false

  # azure key
  config :storage_access_key, validate: :string, required: false

  # conatainer name
  config :container_name, validate: :string, required: false

  # mamadas
  config :size_file, validate: :number, default: 1024 * 1024 * 5
  config :time_file, validate: :number, default: 15
  config :restore, validate: :boolean, default: true
  config :temporary_directory, validate: :string, default: File.join(Dir.tmpdir, 'logstash')
  config :prefix, validate: :string, default: ''
  config :upload_queue_size, validate: :number, default: 2 * (Concurrent.processor_count * 0.25).ceil
  config :upload_workers_count, validate: :number, default: (Concurrent.processor_count * 0.5).ceil
  config :rotation_strategy_val, validate: %w[size_and_time size time], default: 'size_and_time'
  config :tags, validate: :array, default: []
  config :encoding, validate: %w[none gzip], default: 'none'

  attr_accessor :storage_account_name, :storage_access_key, :container_name,
                :size_file, :time_file, :restore, :temporary_directory, :prefix, :upload_queue_size,
                :upload_workers_count, :rotation_strategy_val, :tags, :encoding

  # initializes the +LogstashAzureBlobOutput+ instances
  # validates all config parameters
  # initializes the uploader
  def register
    unless @prefix.empty?
      unless PathValidator.valid?(prefix)
        raise LogStash::ConfigurationError.new("Prefix must not contains: #{PathValidator::INVALID_CHARACTERS}")
      end
    end

    unless WritableDirectoryValidator.valid?(@temporary_directory)
      raise LogStash::ConfigurationError.new("Logstash must have the permissions to write to the temporary directory: #{@temporary_directory}")
    end

    if @time_file.nil? && @size_file.nil? || @size_file.zero? && @time_file.zero?
      raise LogStash::ConfigurationError.new('at least one of time_file or size_file set to a value greater than 0')
    end

    @file_repository = FileRepository.new(@tags, @encoding, @temporary_directory)

    @rotation = rotation_strategy

    executor = Concurrent::ThreadPoolExecutor.new(min_threads: 1,
                                                  max_threads: @upload_workers_count,
                                                  max_queue: @upload_queue_size,
                                                  fallback_policy: :caller_runs)

    @uploader = Uploader.new(blob_container_resource, container_name, @logger, executor)

    restore_from_crash if @restore
    start_periodic_check if @rotation.needs_periodic?
  end

  # Receives multiple events and check if there is space in temporary directory
  # @param events_and_encoded [Object]
  def multi_receive_encoded(events_and_encoded)
    prefix_written_to = Set.new

    events_and_encoded.each do |event, encoded|
      prefix_key = normalize_key(event.sprintf(@prefix))
      prefix_written_to << prefix_key

      begin
        @file_repository.get_file(prefix_key) { |file| file.write(encoded) }
        # The output should stop accepting new events coming in, since it cannot do anything with them anymore.
        # Log the error and rethrow it.
      rescue Errno::ENOSPC => e
        @logger.error('Azure: No space left in temporary directory', temporary_directory: @temporary_directory)
        raise e
      end
    end

    # Groups IO calls to optimize fstat checks
    rotate_if_needed(prefix_written_to)
  end

  # close the temporary file and uploads the content to Azure
  def close
    stop_periodic_check if @rotation.needs_periodic?

    @logger.debug('Uploading current workspace')

    # The plugin has stopped receiving new events, but we still have
    # data on disk, lets make sure it get to Azure blob.
    # If Logstash get interrupted, the `restore_from_crash` (when set to true) method will pickup
    # the content in the temporary directly and upload it.
    # This will block the shutdown until all upload are done or the use force quit.
    @file_repository.each_files do |file|
      upload_file(file)
    end

    @file_repository.shutdown

    @uploader.stop # wait until all the current upload are complete
    @crash_uploader.stop if @restore # we might have still work to do for recovery so wait until we are done
  end

  # Validates and normalize prefix key
  # @param prefix_key [String]
  def normalize_key(prefix_key)
    prefix_key.gsub(PathValidator.matches_re, PREFIX_KEY_NORMALIZE_CHARACTER)
  end

  # checks periodically the tmeporary file if it needs to be rotated
  def start_periodic_check
    @logger.debug('Start periodic rotation check')

    @periodic_check = Concurrent::TimerTask.new(execution_interval: PERIODIC_CHECK_INTERVAL_IN_SECONDS) do
      @logger.debug('Periodic check for stale files')

      rotate_if_needed(@file_repository.keys)
    end

    @periodic_check.execute
  end

  def stop_periodic_check
    @periodic_check.shutdown
  end

  # login to azure cloud using azure storage blob client and create the container if it doesn't exist
  # @return [Object] the azure_blob_service object, which is the endpoint to azure gem
  def blob_container_resource
    blob_client = Azure::Storage::Blob::BlobService.create(
        storage_account_name: storage_account_name, 
        storage_access_key: storage_access_key
    )
    list = blob_client.list_containers()
    list.each do |item|
      @container = item if item.name == container_name
    end

    blob_client.create_container(container_name) unless @container
    blob_client
  end

  # check if it needs to rotate according to rotation policy and rotates it if it needs
  # @param prefixes [String]
  def rotate_if_needed(prefixes)
    prefixes.each do |prefix|
      # Each file access is thread safe,
      # until the rotation is done then only
      # one thread has access to the resource.
      @file_repository.get_factory(prefix) do |factory|
        temp_file = factory.current

        if @rotation.rotate?(temp_file)
          @logger.debug('Rotate file',
                        strategy: @rotation.class.name,
                        key: temp_file.key,
                        path: temp_file.path)

          upload_file(temp_file)
          factory.rotate!
        end
      end
    end
  end

  # uploads the file using the +Uploader+
  def upload_file(temp_file)
    @logger.debug('Queue for upload', path: temp_file.path)

    # if the queue is full the calling thread will be used to upload
    temp_file.close # make sure the content is on disk
    unless temp_file.empty? # rubocop:disable GuardClause
      @uploader.upload_async(temp_file,
                             on_complete: method(:clean_temporary_file))
    end
  end

  # creates an instance for the rotation strategy
  def rotation_strategy
    case @rotation_strategy_val
    when 'size'
      SizeRotationPolicy.new(size_file)
    when 'time'
      TimeRotationPolicy.new(time_file)
    when 'size_and_time'
      SizeAndTimeRotationPolicy.new(size_file, time_file)
    end
  end

  # Cleans the temporary files after it is uploaded to azure blob
  def clean_temporary_file(file)
    @logger.debug('Removing temporary file', file: file.path)
    file.delete!
  end

  # uploads files if there was a crash before
  def restore_from_crash
    @crash_uploader = Uploader.new(blob_container_resource, container_name, @logger, CRASH_RECOVERY_THREADPOOL)

    temp_folder_path = Pathname.new(@temporary_directory)
    Dir.glob(::File.join(@temporary_directory, '**/*'))
       .select { |file| ::File.file?(file) }
       .each do |file|
      temp_file = TemporaryFile.create_from_existing_file(file, temp_folder_path)
      @logger.debug('Recovering from crash and uploading', file: temp_file.path)
      @crash_uploader.upload_async(temp_file, on_complete: method(:clean_temporary_file))
    end
  end
end
