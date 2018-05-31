## v2.0.0
### Breaking change

The index method no longer accepts shards as a parameter.
This change follows the implementation of a new settings method allowing you to pass any number of settings objects to build out the index.

Where the index method is currently being used as follows
```
index name: 'index_name', shards: 1
```

This should now look as follows.
```
index name 'index_name'
settings name: :number_of_shards, value: 1
```

## v1.4.0
* Resolve JSON query to work with ES6 by adding the request content type.
* Make the mapping method more flexible to allow more than just type and index to be passed for the mapping parameters/options.

## v1.3.0
* 1.3.0 was pushed and yanked from gem server.
* Code did contain: Resolve JSON query to work with ES6 by adding the request content type.

## v1.2.0
* Added a json_query method to provide the ability to query ElasticSearch with a json object.

## v1.1.0

* Fix the eq and contains? queries.
The contains? method. This was doing the same thing as the eq method. Added the wildcard symbols to match the queries we were running using kibana.
The condition type. I've updated this to always do `value.to_s` as ES accepts a String value in the query for searches.

## v1.0.0

* Support Elasticsearch v6.2.x. See https://www.elastic.co/guide/en/elasticsearch/reference/current/breaking-changes-6.0.html for more info.

Note: Contains breaking changes to the mapping API:

```ruby
mapping name: 'default', field: :name, type: :string, analyser: :not_analyzed
```

must be changed to use the new format:

```ruby
mapping name: 'default', field: :name, type: :keyword, index: true
```

## v0.2.4

* Bugfix to catch and surpress index already exists error.
