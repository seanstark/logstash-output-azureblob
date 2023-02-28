
# Logstash Azure Blob Storage Output Plugin

This is an output plugin for [Logstash](https://github.com/elastic/logstash). This plugin was forked from https://github.com/tuffk/Logstash-output-to-Azure-Blob and updated to use the latest Azure Storage SDK

## Disclaimers

I am not a Ruby developer and may not be able to respond efficently to issues or bugs. Please take this into consideration when using this plugin

## Example Configuration
```
output {
    azure {
        storage_account_name => "my-azure-account"    # required
        storage_access_key => "my-super-secret-key"   # required
        container_name => "my-container"              # required
        size_file => 1024*1024*5                      # optional
        time_file => 10                               # optional
        restore => true                               # optional
        temporary_directory => "path/to/directory"    # optional
        prefix => "a_prefix"                          # optional
        upload_queue_size => 2                        # optional
        upload_workers_count => 1                     # optional
        rotation_strategy_val => "size_and_time"      # optional
        tags => []                                    # optional
        encoding => "none"                            # optional
    }
}
```
