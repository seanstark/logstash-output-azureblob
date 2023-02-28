
# Logstash Output Plugin for Azure Blob Storage
[![Gem Version](https://badge.fury.io/rb/logstash-output-azureblob.svg)](https://badge.fury.io/rb/logstash-output-azureblob)

This is an output plugin for [Logstash](https://github.com/elastic/logstash). It is fully free and open source. The license is Apache 2.0. This plugin was forked from https://github.com/tuffk/Logstash-output-to-Azure-Blob and updated to use the latest Azure Storage Ruby SDK

- This plugin uses the https://github.com/Azure/azure-storage-ruby library
- The class documentation is here: https://www.rubydoc.info/gems/azure-storage-blob

## Disclaimers

I am not a Ruby developer and may not be able to respond efficently to issues or bugs. Please take this into consideration when using this plugin

- Azure Data Lake Storage Gen2 accounts are not currently supported. 
- Managed Identities and Service Principles are currently not supported for auth. 

## Requirements
- Logstash version 8.6+ [Installation instructions](https://www.elastic.co/guide/en/logstash/current/installing-logstash.html). 
    - Tested on 8.6.2
- Azure Storage Account
    - Azure Storage Account Access Key(s)

## Installation
```sh
bin/logstash-plugin install logstash-output-azureblob
```
> On Ubuntu the default path is /usr/share/logstash/bin/

## Configuration

Information about configuring Logstash can be found in the [Logstash configuration guide](https://www.elastic.co/guide/en/logstash/current/configuration.html).

You will need to configure this plugin before sending events from Logstash to an Azure Storage Account. The following example shows the minimum you need to provide:

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

### Example with syslog

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

## Development

- Docker Image - [cameronkerrnz/logstash-plugin-dev:7.17](https://hub.docker.com/r/cameronkerrnz/logstash-plugin-dev)
    - https://github.com/cameronkerrnz/logstash-plugin-dev
- jruby 9.2.20.1 (2.5.8)
- Logstash Version 8.6.2+

1. Install Dependencies

    ```shell
    rake vendor
    bundle install
    ```
2. Build the plugin
    ```shell
    gem build logstash-output-azureblob.gemspec
    ```
3. Install Locally
    ```shell
    /usr/share/logstash/bin/logstash-plugin install /usr/share/logstash/logstash-output-azureblob-0.9.0.gem
    ```
4. Test with configuration file
    ```shell
    /usr/share/logstash/bin/logstash -f blob.conf
    ```
    
## Contributing

All contributions are welcome: ideas, patches, documentation, bug reports, and complaints. For more information about contributing, see the [CONTRIBUTING](https://github.com/elastic/logstash/blob/master/CONTRIBUTING.md) file.
