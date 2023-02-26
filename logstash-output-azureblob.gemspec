Gem::Specification.new do |s|
  s.name          = 'logstash-output-azureblob'
  s.version       = '0.1.0'
  s.licenses      = ['Apache-2.0']
  s.summary       = 'A Logstash output plugin to send data to Azure Blob Storage'
  s.description   = 'This output plugin will send data to Azure Blob Storage'
  s.homepage      = 'https://github.com/seanstark/logstash-output-azure-blob'
  s.authors       = ['Sean Stark']
  s.email         = 'sean.stark@microsoft.com'
  s.require_paths = ['lib']

  # Files
  s.files = Dir['lib/**/*','spec/**/*','vendor/**/*','*.gemspec','*.md','CONTRIBUTORS','Gemfile','LICENSE','NOTICE.TXT']
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core-plugin-api", "~> 2.0"
  s.add_runtime_dependency "logstash-codec-plain"
  s.add_development_dependency "logstash-devutils"
end
