module ElasticSearchFramework
  class Query

    class InvalidQueryError < StandardError
      def initialize(message)
        super(message)
      end
    end

    def initialize(index:)
      @index = index
      @parts = []
    end

    def method_missing(name)
      @parts << { type: :field, value: name }
      self
    end

    def eq(value)
      condition(expression: ':', value: value)
      self
    end

    def contains?(value)
      condition(expression: ':', value: value)
      self
    end

    def not_eq(value)
      field = @parts.last
      unless field[:type] == :field
        raise ::InvalidQueryError.new('The not_eq query part can only be chained to a field.')
      end
      @parts.pop
      @parts << { type: :not_eq, field: field[:value], value: value }
      self
    end

    def gt(value)
      condition(expression: ':>', value: value)
      self
    end

    def gt_eq(value)
      condition(expression: ':>=', value: value)
      self
    end

    def lt(value)
      condition(expression: ':<', value: value)
      self
    end

    def lt_eq(value)
      condition(expression: ':<=', value: value)
      self
    end

    def exists?
      field = @parts.last
      unless field[:type] == :field
        raise ::InvalidQueryError.new('The exists? query part can only be chained to a field.')
      end
      @parts.pop
      @parts << { type: :exists?, field: field[:value] }
      self
    end

    def and
      @parts << { type: :and }
      self
    end

    def or
      @parts << { type: :or }
      self
    end

    def execute(limit: 10, count: false)
      query = build
      repository = ElasticSearchFramework::Repository.new
      repository.query(index: @index, expression: query, limit: limit, count: count)
    end

    def build
      @expression_string = ''

      @parts.each do |p|
        case p[:type]
          when :field
            @expression_string += ' ' + p[:value].to_s
          when :condition
            @expression_string += p[:expression].to_s + format_value(p[:value])
          when :exists
            @expression_string += ' _exists_:' + p[:field].to_s
          when :not_eq
            @expression_string += ' NOT (' + p[:field].to_s + ':' + format_value(p[:value]) + ')'
          when :and
            @expression_string += ' AND'
          when :or
            @expression_string += ' OR'
          else
            raise 'Invalid query part'
        end
      end

      return @expression_string.strip
    end

    def condition(expression:, value:)
      @parts << { type: :condition, expression: expression, value: value }
    end

    def format_value(value)
      result = value.to_s
      if value.is_a?(String)
        result = '"' + value + '"'
      end
      result
    end

  end
end
