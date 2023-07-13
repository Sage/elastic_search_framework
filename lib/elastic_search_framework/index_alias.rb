module ElasticSearchFramework
  module IndexAlias
    def index(klass, active:)
      unless instance_variable_defined?(:@elastic_search_indexes)
        instance_variable_set(:@elastic_search_indexes, [])
      end
      indexes = self.instance_variable_get(:@elastic_search_indexes)
      indexes << {klass: klass, active: active}
      instance_variable_set(:@elastic_search_indexes, indexes)
    end

    def indexes
      self.instance_variable_get(:@elastic_search_indexes)
    end

    def name(name)
      unless instance_variable_defined?(:@elastic_search_index_alias_name)
        instance_variable_set(:@elastic_search_index_alias_name, "#{name}")
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self.class}] - Duplicate index alias name: #{name}.")
      end
    end

    def valid?
      indexes.select { |i| i[:active] == true }.length == 1
    end

    def create
      if !valid?
        raise ElasticSearchFramework::Exceptions::IndexError.new("[#{self.class}] - Invalid Index alias.")
      end

      uri = URI("#{host}/_aliases")

      payload = {
        actions: [],
      }

      indexes.each do |index|
        action = nil
        if exists?(index: index[:klass])
          action = "remove" if !index[:active]
        else
          action = "add" if index[:active]
        end
        next if action.nil?

        payload[:actions] << {action => {index: index[:klass].full_name, alias: self.full_name}}
      end

      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = JSON.dump(payload)
      request.content_type = "application/json"

      response = repository.with_client do |client|
        client.request(request)
      end

      is_valid_response?(response.code) || Integer(response.code) == 404
    end

    def delete
      uri = URI("#{host}/_all/_aliases/#{full_name}")

      request = Net::HTTP::Delete.new(uri.request_uri)

      response = repository.with_client do |client|
        client.request(request)
      end

      is_valid_response?(response.code) || Integer(response.code) == 404
    end

    def exists?(index:)
      uri = URI("#{host}/#{index.full_name}/_alias/#{full_name}")

      request = Net::HTTP::Get.new(uri.request_uri)

      response = repository.with_client do |client|
        client.request(request)
      end

      return false if response.code == "404"

      result = nil
      if is_valid_response?(response.code)
        result = JSON.parse(response.body)
      end

      return true if !result.nil? && result[index.full_name]["aliases"] != nil
      return false
    end

    def is_valid_response?(code)
      [200, 201, 202].include?(Integer(code))
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
      index = indexes.last[:klass]
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
      @repository ||= ElasticSearchFramework::Repository.new
    end

    def get_item(id:, type: "_doc", routing_key: nil)
      active_index = indexes.detect { |i| i[:active] == true }[:klass]

      options = { index: self, id: id, type: type }
      options[:routing_key] = routing_key if active_index.routing_enabled? && routing_key

      repository.get(options)
    end

    def put_item(type: "_doc", item:, op_type: 'index', routing_key: nil)
      indexes.each do |index|
        options = { entity: item, index: index[:klass], type: type, op_type: op_type }
        options[:routing_key] = routing_key if index[:klass].routing_enabled? && routing_key

        repository.set(options)
      end
    end

    def delete_item(id:, type: "_doc", routing_key: nil)
      indexes.each do |index|
        options = { index: index[:klass], id: id, type: type }
        options[:routing_key] = routing_key if index[:klass].routing_enabled? && routing_key

        repository.drop(options)
      end
    end

    def query
      ElasticSearchFramework::Query.new(index: self)
    end

    def routing_enabled?
      indexes.find(active: true).first[:klass].routing_enabled?
    end
  end
end
