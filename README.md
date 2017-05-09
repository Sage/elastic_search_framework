# Elastic Search Framework

Welcome to Elastic Search Framework, this is a light weight framework that provides managers to help with interacting with Elastic Search.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'elastic_search_framework'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install elasticsearch_framework

## Usage

##Global Config

### #namespace
The namespace is used to set the prefix applied to all table and index names.

    elasticsearchFramework.namespace = 'uat'
    
> With a namespace of 'uat' and a table name of 'people', the resulting table name would be 'uat.people'
    
### #namespace_delimiter
This is the delimiter used to join the namespace prefix to table/index names.

> DEFAULT = '.'

    elasticsearchFramework.namespace_delimiter = '-'
    
### #default_host
This is used to set the default host that should be used for all connection actions that don't specify an override.

    ElasticSearchFramework.default_host = 'http://elasticsearch'

# Index
To define an index within elasticsearch, create an index definition class that extends from the `ElasticSearchFramework::Index` module.

    class ExampleIndex
      extend ElasticSearchFramework::Index
    
      index name: 'example_index', shards: 1
      
      mapping name: 'default', field: :name, type: :string, analyser: :not_analyzed    
    end
    
**attributes**

 - **index** [Hash] [Required] This is used to specify the name of the index, and the number of shards the index should use.
 - **mapping** [Hash] [Optional] This is used to specify field mappings to control the analyzer used for a given field.


## #create
This method is called create the index definition within an elastic search instance.

    ExampleIndex.create
 
 
## #drop
This method is called to drop the index from an elastic search instance.

    ExampleIndex.drop
  
## #exists?
This method is called to determine if an index exists in a elastic search instance.

    ExampleIndex.exists?


## #query
This method is called to query the index for a collection of items.

The query is then built up using method chaining e.g:

    query = ExampleIndex.query.gender.eq('male').and.age.gt(18)
    
The above query chain translates into:

    FROM ExampleIndex WHERE gender == 'male' AND age > 18
     
To execute the query you can then call `#execute` on the query:

    query.execute
    
### #execute
This method is called to execute a query.

**Params**

 - **limit** [Integer] [Optional] This is used to specify a limit to the number of items returned by the query.
 - **count** [Boolean] [Optional] This is used to specify if the query should just return a count of results.

## Query expressions

### #eq(value)
This method is used to specify the `==` operator within a query.

### #not_eq(value)
This method is called to specify the `!=` operator within a query.

### #gt(value)
This method is called to specify the `>` operator within a query.

### #gt_eq(vaue)
This method is called to specify the `>=` operator within a query.

### #lt(value)
This method is called to specify the `<` operator within a query.

### #lt_eq(value)
This method is called to specify the `<=` operator within a query.

### #contains(value)
This method is called to check if a field contains a value within a query.

### #exists?
This method is called to check if a field exists within a query.

### #and
This method is called to combine conditions together in a traditional `&&` method within a query.

### #or 
This method is called to combine conditions together in a traditional `||` method within a query.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/vaughanbrittonsage/elasticsearch_framework. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
