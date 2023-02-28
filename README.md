
# Logstash Azure Blob Storage Output Plugin

This is an output plugin for [Logstash](https://github.com/elastic/logstash). This plugin was forked from https://github.com/tuffk/Logstash-output-to-Azure-Blob and updated to use the latest Azure Storage SDK

## Disclaimers

I am not a Ruby developer and may not be able to respond efficently to issues or bugs. Please take this into consideration when using this plugin

## Example Configuration
```
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

```
input {
    syslog {
        port => "5514"
        type => "syslog"
		codec => cef
    }
}

output {
    azure_blob {
        storage_account_name => "cs7100320020b9463f8"
        storage_access_key => "Z5Y2T/v63LCTmGqcOdXvSOv/iov3Dib10hgXtSWKwL8Deg+zWLyC9P/P4A8Bz0QjXT/FaoZShqf1+AStajdeBg=="
        container_name => "fwlogstest"
    }
}
```

# Libraries
This plugin uses the https://github.com/Azure/azure-storage-ruby library. The class documentation is here: https://www.rubydoc.info/gems/azure-storage-blob/1.0.1