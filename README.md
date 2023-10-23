# Elastic Search Framework [![Maintainability](https://api.codeclimate.com/v1/badges/a8de5f956f6e248a30a0/maintainability)](https://codeclimate.com/github/Sage/elastic_search_framework/maintainability) [![Test Coverage](https://api.codeclimate.com/v1/badges/a8de5f956f6e248a30a0/test_coverage)](https://codeclimate.com/github/Sage/elastic_search_framework/test_coverage) [![Gem Version](https://badge.fury.io/rb/elastic_search_framework.svg)](https://badge.fury.io/rb/elastic_search_framework)

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


## Global Config

### #namespace
The namespace is used to set the prefix applied to all table and index names.

> Optional.

    elasticsearchFramework.namespace = 'uat'

> With a namespace of 'uat' and a table name of 'people', the resulting table name would be 'uat.people'

### #namespace_delimiter
This is the delimiter used to join the namespace prefix to table/index names.

> DEFAULT = '.'

    elasticsearchFramework.namespace_delimiter = '-'

### #host
This is used to set the host that should be used for all connection actions.

    ElasticSearchFramework.host = 'http://elasticsearch'

### #port
This is used to set the port that should be used for all connection actions.

    ElasticSearchFramework.port = 9200

> DEFAULT = 9200

# IndexAlias
To define an index alias within elasticsearch, create an index alias class that extends from the `ElasticSearchFramework::IndexAlias` module.

Example:


```ruby
class ExampleIndexAlias
  extend ElasticSearchFramework::IndexAlias

  index ExampleIndex, active: true
  index ExampleIndex2, active: false

  name :example
end
```

**attributes**

 - **index** [Hash] [Required] [Multi] This is used to specify the indexes associated with this alias and which index is the current active index for the alias to point to.
 - **name** [Hash] [Required] [Single] This is used to specify the unique name of the index alias.

---

Index Aliases are required to decouple your application from a specific index and allow you to handle index updates without downtime.

To change the mapping of an existing index Create a new version of the index, then associate the new index with the index alias as an inactive index `active: false`. This will allow index writes and deletes to be performed on both indexes so no new data is lost while you perform a `_reindex` operation to move existing data from the old index into the new index.

Once you have `_reindexed` into your new index you can then de-activate the old index `active: false` and activate the new index `active: true` in your index alias. This will swap all requests to the new index.

Doing the above steps should enable you to seamlessly transition between 1 index and another when mapping/analyzer changes are required.

## #create
This method is called to create the index alias within an elastic search instance.
> This method is idempotent and will modify the index alias if it already exists.

> All associated indexes must exist before this method is called.

    ExampleIndexAlias.create

## Index operation methods
The following index operation methods are available for an index alias:

- `#get_item`
- `#put_item`
- `#delete_item`
- `#query`

> `#put_item` calls will be performed against all indexes associated with the alias.

> `#delete_item` calls will be performed against all indexes associated with the alias.

> Details for how to use the above index operation methods can be found below.

# Index
To define an index within elasticsearch, create an index definition class that extends from the `ElasticSearchFramework::Index` module.

```ruby
class ExampleIndex
  extend ElasticSearchFramework::Index

  index name: 'example_index', shards: 1

  id :example_id

  mapping name: 'default', field: :name, type: :keyword, index: true
end
```

**attributes**

 - **index** [Hash] [Required] This is used to specify the name of the index, and the number of shards the index should use.
 - **mapping** [Hash] [Optional] This is used to specify field mappings to control the analyzer used for a given field.
 - **id** [Hash] [Optional] [Default=id] This is used to specify the id field of the index document. (By default this is :id)

## #create
This method is called to create the index definition within an elastic search instance.

    ExampleIndex.create


## #drop
This method is called to drop the index from an elastic search instance.

    ExampleIndex.drop

## #exists?
This method is called to determine if an index exists in a elastic search instance.

    ExampleIndex.exists?


## #put_item
This method is called to store a document/entity within the index.

    ExampleIndex.put_item(item: document)

**Params**

 - **item** [Object] [Required] This is the document/entity you want to store in the index.
 - **type** [String] [Optional] [Default='default'] This is used to specify the type of the document within the index.

## #get_item
This method is called to fetch a document from within the index.

    ExampleIndex.get_item(id: document_id)

**Params**

 - **id** [String/Integer] [Required] This is the unique identifier of the document/entity you want to fetch from the index.
 - **type** [String] [Optional] [Default='default'] This is used to specify the type of the document within the index.

## #delete_item
This method is called to delete a document from within the index.

    ExampleIndex.delete_item(id: document_id)

**Params**

 - **id** [String/Integer] [Required] This is the unique identifier of the document/entity you want to delete from the index.
 - **type** [String] [Optional] [Default='default'] This is used to specify the type of the document within the index.



## #query
This method is called to query the index for a collection of items.

The query is then built up using method chaining e.g:

    query = ExampleIndex.query.gender.eq('male').and.age.gt(18)

The above query chain translates into:

    FROM ExampleIndex WHERE gender == 'male' AND age > 18

To execute the query you can then call `#execute` on the query:

    query.execute

> Due to method chaining, the #execute method can also be chained to the end of a query directly.

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

## Testing

To run the tests locally, we use Docker to provide both a Ruby and JRuby environment along with a reliable Redis container.

### Setup Images:

> This builds the Ruby docker image.

```bash
./script/setup.sh
```

### Run Tests:

> This executes the test suite.

```bash
./script/test.sh
```

### Cleanup

> This is used to clean down docker image created in the setup script.

```bash
./script/cleanup.sh
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sage/elasticsearch_framework. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

This gem is available as open source under the terms of the [MIT licence](LICENSE).

Copyright (c) 2018 Sage Group Plc. All rights reserved.
