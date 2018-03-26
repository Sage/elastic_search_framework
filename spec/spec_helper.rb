require "rubygems"
require "bundler"
require 'elastic_search_framework'
require_relative '../spec/test_item.rb'
require_relative '../spec/example_index'
require 'pry'

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.order = :defined
end

ElasticSearchFramework.logger.level = Logger::ERROR
ElasticSearchFramework.host = ENV.fetch('ELASTIC_SEARCH_HOST', 'http://elasticsearch')
ElasticSearchFramework.port = ENV.fetch('ELASTIC_SEARCH_PORT', '9200')
