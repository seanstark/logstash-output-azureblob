
# Logstash Output Plugin for Azure Blob Storage

This is an output plugin for [Logstash](https://github.com/elastic/logstash). It is fully free and open source. The license is Apache 2.0. This plugin was forked from https://github.com/tuffk/Logstash-output-to-Azure-Blob and updated to use the latest Azure Storage Ruby SDK

## Disclaimers

I am not a Ruby developer and may not be able to respond efficently to issues or bugs. Please take this into consideration when using this plugin

## Requirements
- Logstash version 8.6+. [Installation instructions](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html). Tested on 8.6.2
- Azure Storage Account
    - ADLS2 is not supported
    - Azure Storage Account Access Key(s)

## Installation
```sh
bin/logstash-plugin install logstash-output-azureblob
```
> On Ubuntu the default path is /usr/share/logstash/bin/

## Configuration
```yaml
output {
    azure_blob {
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

### Example with SYSLOG

```yaml
input {
    syslog {
        port => "5514"
        type => "syslog"
        codec => cef
    }
}

output {
    azure_blob {
        storage_account_name => "<account-name>"
        storage_access_key => "<access-key>"
        container_name => "<container-name>"
    }
}
```

# Libraries
- This plugin uses the https://github.com/Azure/azure-storage-ruby library. 
- The class documentation is here: https://www.rubydoc.info/gems/azure-storage-blob/1.0.1
