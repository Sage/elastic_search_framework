class ExampleIndexAlias2
  extend ElasticSearchFramework::IndexAlias

  index ExampleIndex, active: false
  index ExampleIndex2, active: true

  name :example
end
