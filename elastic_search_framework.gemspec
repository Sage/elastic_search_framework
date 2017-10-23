# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'elastic_search_framework/version'

Gem::Specification.new do |spec|
  spec.name          = "elastic_search_framework"
  spec.version       = ElasticSearchFramework::VERSION
  spec.authors       = ["vaughanbrittonsage"]
  spec.email         = ["vaughanbritton@gmail.com"]

  spec.summary       = 'A lightweight framework to for working with elastic search.'
  spec.description   = 'A lightweight framework to for working with elastic search.'
  spec.homepage      = "https://github.com/sage/elastic_search_framework"
  spec.license       = "MIT"

  spec.files         = Dir.glob("{bin,lib,spec}/**/**/**")
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_dependency 'hash_kit', '~> 0.5'
  spec.add_dependency 'json'
  spec.add_dependency 'connection_pool'
end
