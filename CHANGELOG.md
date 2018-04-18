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
