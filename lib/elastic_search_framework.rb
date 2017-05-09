require 'hash_kit'
require 'json'
require 'curb'
require_relative 'elastic_search_framework/version'
require_relative 'elastic_search_framework/logger'
require_relative 'elastic_search_framework/exceptions'
require_relative 'elastic_search_framework/repository'
require_relative 'elastic_search_framework/index'
require_relative 'elastic_search_framework/query'

require 'date'

module ElasticSearchFramework
  def self.namespace=(value)
    @namespace = value
  end
  def self.namespace
    @namespace
  end
  def self.namespace_delimiter=(value)
    @namespace_delimiter = value
  end
  def self.namespace_delimiter
    @namespace_delimiter ||= '.'
  end
  def self.default_host=(value)
    @default_store = value
  end
  def self.default_host
    @default_store
  end
  def self.default_port=(value)
    @default_port = value
  end
  def self.default_port
    @default_port ||= 9200
  end
end
