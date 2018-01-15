class ExampleIndex
  extend ElasticSearchFramework::Index

  index name: 'example_index'

  mapping name: 'default', field: :name, type: :string, analyser: :not_analyzed

end

class ExampleIndexWithId
  extend ElasticSearchFramework::Index

  index name: 'example_index'

  id :number

  mapping name: 'default', field: :name, type: :string, analyser: :not_analyzed

end

class ExampleIndexWithShard
  extend ElasticSearchFramework::Index

  index name: 'example_index', shards: 1

  mapping name: 'default', field: :name, type: :string, analyser: :not_analyzed

end

class InvalidExampleIndex
  extend ElasticSearchFramework::Index
end
