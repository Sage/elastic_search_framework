require 'connection_pool'
require 'date'
require 'hash_kit'
require 'json'
require 'net/http'
require_relative 'elastic_search_framework/version'
require_relative 'elastic_search_framework/logger'
require_relative 'elastic_search_framework/exceptions'
require_relative 'elastic_search_framework/repository'
require_relative 'elastic_search_framework/index'
require_relative 'elastic_search_framework/index_alias'
require_relative 'elastic_search_framework/query'

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
  def self.host=(value)
    @host = value
  end
  def self.host
    @host
  end
  def self.port=(value)
    @port = value
  end
  def self.port
    @port ||= 9200
  end
end
