
# Logstash Azure Blob Storage Output Plugin

This is an output plugin for [Logstash](https://github.com/elastic/logstash).

It is fully free and fully open source. The license is Apache 2.0, meaning you are pretty much free to use it however you want in whatever way.

## Documentation

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
