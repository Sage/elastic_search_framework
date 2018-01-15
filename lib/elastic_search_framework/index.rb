module ElasticSearchFramework
  module Index
    def index(name:, shards: nil)
      unless instance_variable_defined?(:@elastic_search_index_def)
        instance_variable_set(:@elastic_search_index_def, {
            name: "#{name}", shards: shards
        })
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self.class}] - Duplicate index description. Name: #{name} | Shards: #{shards}.")
      end
    end

    def id(field)
      unless instance_variable_defined?(:@elastic_search_index_id)
        instance_variable_set(:@elastic_search_index_id, field)
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self.class}] - Duplicate index id. Field: #{field}.")
      end
    end

    def mapping(name:, field:, type:, analyser:)

      unless instance_variable_defined?(:@elastic_search_index_mappings)
        instance_variable_set(:@elastic_search_index_mappings, {})
      end

      mappings = instance_variable_get(:@elastic_search_index_mappings)

      if mappings[name] == nil
        mappings[name] = {}
      end

      mappings[name][field] = { type: type, analyser: analyser}

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

      payload = create_payload(description: description, mappings: mappings)

      put(payload: payload)

    end

    def put(payload:)
      uri = URI("#{host}/#{full_name}")

      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = JSON.dump(payload)

      response = repository.with_client do |client|
        client.request(request)
      end

      unless is_valid_response?(response.code)
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self}] - Failed to put index. Payload: #{payload} | Response: #{response.body}")
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

    def create_payload(description:, mappings:)
      payload = {}

      if description[:shards] != nil
        payload[:settings] = {
            number_of_shards: Integer(description[:shards])
        }
      end

      if mappings.keys.length > 0

        payload[:mappings] = {}

        mappings.keys.each do |name|
          payload[:mappings][name] = {
              properties: {}
          }
          mappings[name].keys.each do |field|
            payload[:mappings][name][:properties][field] = {
                type: mappings[name][field][:type],
                index: mappings[name][field][:analyser]
            }
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
      ElasticSearchFramework::Repository.new
    end

    def get_item(id:, type: 'default')
      repository.get(index: self, id: id, type: type)
    end

    def put_item(type: 'default', item:)
      repository.set(entity: item, index: self, type: type)
    end

    def delete_item(id:, type: 'default')
      repository.drop(index: self, id: id, type: type)
    end

    def query
      ElasticSearchFramework::Query.new(index: self)
    end
  end
end
