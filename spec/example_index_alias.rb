class ExampleIndexAlias
  extend ElasticSearchFramework::IndexAlias

  index ExampleIndex, active: true
  index ExampleIndex2, active: false

  name :example
end

class InvalidIndexAlias
  extend ElasticSearchFramework::IndexAlias

  index ExampleIndex, active: false
  index ExampleIndex2, active: false

  name :example
end
