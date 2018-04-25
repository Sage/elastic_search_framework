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
