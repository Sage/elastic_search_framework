module ElasticSearchFramework
  class Repository

    def set(index:, id:, entity:, type: 'default')
      client.url = "#{host}/#{index.full_name}/#{type.downcase}/#{id}"
      client.http_put(class_helper.to_json(entity))
      unless is_valid_response?(client)
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred setting an index document. Response: #{client.body_str}")
      end
      return true
    end

    def get(index:, id:, type: 'default')
      client.url = "#{host}/#{index.full_name}/#{type.downcase}/#{id}/_source"
      client.get
      if is_valid_response?(client)
        result = JSON.load(client.body_str)
        hash_helper.hash_kit.indifferent!(result)
        return result
      elsif client.response_code == 404
        return nil
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred getting an index document. Response: #{client.body_str}")
      end
    end

    def drop(index:, id:, type: 'default')
      client.url = "#{host}/#{index.full_name}/#{type.downcase}/#{id}"
      client.delete
      if is_valid_response?(client) || client.response_code == 404
        return true
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred dropping an index document. Response: #{client.body_str}")
      end
    end

    def client
      @curl ||= Curl::Easy.new
    end

    def is_valid_response?(client)
      [200,201,202].include?(client.response_code)
    end

    def host
      "#{ElasticSearchFramework.default_host}:#{ElasticSearchFramework.default_port}"
    end

    def hash_helper
      @hash_helper ||= HashHelper.new
    end

  end
end