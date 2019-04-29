class ExampleIndex2
  extend ElasticSearchFramework::Index

  index name: 'example_index', version: 2

  mapping name: 'default', field: :name, type: :keyword, index: true
end

class ExampleIndexWithId2
  extend ElasticSearchFramework::Index

  index name: 'example_index', version: 2

  id :number

  mapping name: 'default', field: :name, type: :keyword, index: true
end

class ExampleIndexWithSettings2
  extend ElasticSearchFramework::Index

  index name: 'example_index', version: 2

  normalizer_value = { custom_normalizer: { type: 'custom', char_filter: [], filter: ['lowercase'] } }
  analyzer_value = { custom_analyzer: { type: 'custom', tokenizer: 'standard', filter: %w(lowercase) } }

  settings name: :number_of_shards, value: 1
  settings name: :analysis, type: :normalizer, value: normalizer_value
  settings name: :analysis, type: :analyzer, value: analyzer_value
  mapping name: 'default', field: :name, type: :keyword, index: true
end
