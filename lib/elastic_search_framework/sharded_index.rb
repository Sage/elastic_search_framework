module ElasticSearchFramework
  module ShardedIndex
    attr_accessor :index_settings

    def index(name:, version: nil, routing: false)
      unless instance_variable_defined?(:@elastic_search_index_def)
        instance_variable_set(:@elastic_search_index_def, name: "#{name}#{version}")
        instance_variable_set(:@elastic_search_index_version, version: version) unless version.nil?
        # instance_variable_set(:@elastic_search_index_routing, routing)
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self.class}] - Duplicate index description. Name: #{name}.")
      end
    end

    def version
      instance_variable_defined?(:@elastic_search_index_version) ? instance_variable_get(:@elastic_search_index_version) : 0
    end

    # def enable_routing
    #   @@routing = true
    # end

    def routing_enabled?
      true
    end

    def id(field)
      unless instance_variable_defined?(:@elastic_search_index_id)
        instance_variable_set(:@elastic_search_index_id, field)
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self.class}] - Duplicate index id. Field: #{field}.")
      end
    end

    def mapping(name:, field:, **options)
      unless instance_variable_defined?(:@elastic_search_index_mappings)
        instance_variable_set(:@elastic_search_index_mappings, {})
      end

      mappings = instance_variable_get(:@elastic_search_index_mappings)

      mappings[name] = {} if mappings[name].nil?

      mappings[name][field] = options

      instance_variable_set(:@elastic_search_index_mappings, mappings)
    end

    def create
      if !valid?
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self.class}] - Invalid Index description specified.")
      end

      if exists?
        ElasticSearchFramework.logger.debug { "[#{self.class}] - Index already exists."}
        return
      end
      payload = create_payload

      put(payload: payload)
    end

    def put(payload:)
      uri = URI("#{host}/#{full_name}")

      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = JSON.dump(payload)
      request.content_type = 'application/json'

      response = repository.with_client do |client|
        client.request(request)
      end

      unless is_valid_response?(response.code)
        if JSON.parse(response.body, symbolize_names: true).dig(:error, :root_cause, 0, :type) == 'index_already_exists_exception'
          # We get here because the `exists?` check in #create is non-atomic
          ElasticSearchFramework.logger.warn "[#{self.class}] - Failed to create preexisting index. | Response: #{response.body}"
        else
          raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self}] - Failed to put index. Payload: #{payload} | Response: #{response.body}")
        end
      end
      true
    end

    def get
      uri = URI("#{host}/#{full_name}")

      request = Net::HTTP::Get.new(uri.request_uri)

      response = repository.with_client do |client|
        client.request(request)
      end

      result = nil
      if is_valid_response?(response.code)
        result = JSON.parse(response.body)
      end
      result
    end

    def exists?
      get != nil
    end

    def delete
      uri = URI("#{host}/#{full_name}")

      request = Net::HTTP::Delete.new(uri.request_uri)

      response = repository.with_client do |client|
        client.request(request)
      end

      is_valid_response?(response.code) || Integer(response.code) == 404
    end

    def settings(name:, type: nil, value:)
      self.index_settings = {} if index_settings.nil?
      index_settings[name] = {} if index_settings[name].nil?
      return index_settings[name][type] = value if type
      index_settings[name] = value
    end

    def create_payload
      payload = { }
      payload[:settings] = index_settings unless index_settings.nil?

      unless mappings.keys.empty?
        payload[:mappings] = {}

        mappings.keys.each do |name|
          payload[:mappings][name] = { properties: {} }
          mappings[name].keys.each do |field|
            payload[:mappings][name][:properties][field] = mappings[name][field]
          end
        end
      end

      payload
    end

    def valid?
      self.instance_variable_get(:@elastic_search_index_def) ? true : false
    end

    def description
      hash = self.instance_variable_get(:@elastic_search_index_def)
      if instance_variable_defined?(:@elastic_search_index_id)
        hash[:id] = self.instance_variable_get(:@elastic_search_index_id)
      else
        hash[:id] = :id
      end
      hash
    end

    def mappings
      self.instance_variable_defined?(:@elastic_search_index_mappings) ? self.instance_variable_get(:@elastic_search_index_mappings) : {}
    end

    def is_valid_response?(code)
      [200,201,202].include?(Integer(code))
    end

    def full_name
      if ElasticSearchFramework.namespace != nil
        "#{ElasticSearchFramework.namespace}#{ElasticSearchFramework.namespace_delimiter}#{description[:name].downcase}"
      else
        description[:name].downcase
      end
    end

    def host
      "#{ElasticSearchFramework.host}:#{ElasticSearchFramework.port}"
    end

    def repository
      @repository ||= ElasticSearchFramework::Repository.new
    end

    def get_item(id:, type: 'default', routing_key: nil)
      options = { index: self, id: id, type: type }
      options[:routing_key] = routing_key if routing_enabled? && routing_key

      repository.get(options)
    end

    def put_item(type: 'default', item:, op_type: 'index', routing_key: nil)
      options = { entity: item, index: self, type: type, op_type: op_type }
      options[:routing_key] = routing_key if routing_enabled? && routing_key

      repository.set(options)
    end

    def delete_item(id:, type: 'default', routing_key: nil)
      options = { index: self, id: id, type: type }
      options[:routing_key] = routing_key if routing_enabled? && routing_key

      repository.drop(options)
    end

    def query
      ElasticSearchFramework::Query.new(index: self)
    end
  end
end
