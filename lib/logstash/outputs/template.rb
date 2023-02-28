# encoding: utf-8
require "logstash/outputs/base"

# An azureblob output that does nothing.
class LogStash::Outputs::Azureblob < LogStash::Outputs::Base
  config_name "azureblob"

  public
  def register
  end # def register

  public
  def receive(event)
    return "Event received"
  end # def event
end # class LogStash::Outputs::Azureblob
