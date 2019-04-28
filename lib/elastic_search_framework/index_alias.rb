module ElasticSearchFramework
  module IndexAlias
    attr_accessor :index_settings

    def index(klass)
      unless instance_variable_defined?(:@elastic_search_indexes)
        instance_variable_set(:@elastic_search_indexes, [])
      end
      indexes = self.instance_variable_get(:@elastic_search_indexes)
      indexes << klass
    end

    def indexes
      self.instance_variable_get(:@elastic_search_indexes)
    end

    def name(name)
      unless instance_variable_defined?(:@elastic_search_index_alias_name)
        instance_variable_set(:@elastic_search_index_alias_name, name: "#{name}")
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self.class}] - Duplicate index alias name: #{name}.")
      end
    end

    def create
      uri = URI("#{host}/_aliases")

      payload = {
          actions: []
      }

      indexes.foreach do |index|
        action = index == indexes.last ? "add" : "remove"
        payload[:actions] << { action => { index: index.full_name, alias: self.full_name } }
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = JSON.dump(payload)
      request.content_type = 'application/json'

      response = repository.with_client do |client|
        client.request(request)
      end

      is_valid_response?(response.code) || Integer(response.code) == 404
    end

    def get
      uri = URI("#{host}/_alias/#{full_name}")

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
      uri = URI("#{host}/_aliases")

      payload = {
          actions: []
      }

      indexes.foreach do |index|
        payload[:actions] << { remove: { index: index.full_name, alias: self.full_name } }
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = JSON.dump(payload)
      request.content_type = 'application/json'

      response = repository.with_client do |client|
        client.request(request)
      end

      is_valid_response?(response.code) || Integer(response.code) == 404
    end

    def is_valid_response?(code)
      [200,201,202].include?(Integer(code))
    end

    def full_name
      name = instance_variable_get(:@elastic_search_index_alias_name)
      if ElasticSearchFramework.namespace != nil
        "#{ElasticSearchFramework.namespace}#{ElasticSearchFramework.namespace_delimiter}#{name.downcase}"
      else
        name.downcase
      end
    end

    def description
      index = indexes.last
      hash = index.instance_variable_get(:@elastic_search_index_def)
      if index.instance_variable_defined?(:@elastic_search_index_id)
        hash[:id] = index.instance_variable_get(:@elastic_search_index_id)
      else
        hash[:id] = :id
      end
      hash
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
