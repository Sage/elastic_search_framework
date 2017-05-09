module ElasticSearchFramework
  class Repository

    def set(index:, id:, entity:, type: 'default')
      client = curl
      client.url = "#{host}/#{index.full_name}/#{type.downcase}/#{id}"
      hash = hash_helper.to_hash(entity)
      client.http_put(JSON.dump(hash))
      unless is_valid_response?(client)
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred setting an index document. Response: #{client.body_str}")
      end
      return true
    end

    def get(index:, id:, type: 'default')
      client = curl
      client.url = "#{host}/#{index.full_name}/#{type.downcase}/#{id}/_source"
      client.get
      if is_valid_response?(client)
        result = JSON.load(client.body_str)
        hash_helper.indifferent!(result)
        return result
      elsif client.response_code == 404
        return nil
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred getting an index document. Response: #{client.body_str}")
      end
    end

    def drop(index:, id:, type: 'default')
      client = curl
      client.url = "#{host}/#{index.full_name}/#{type.downcase}/#{id}"
      client.delete
      if is_valid_response?(client) || client.response_code == 404
        return true
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred dropping an index document. Response: #{client.body_str}")
      end
    end

    def query(index:, expression:, type: 'default', limit: 10, count: false)
      client = curl
      client.url = "#{host}/#{index.full_name}/#{type}/_search?q=#{URI.encode(expression)}&size=#{limit}"
      client.get
      if is_valid_response?(client)
        result = JSON.parse(client.body_str)
        hash_helper.indifferent!(result)
        if count
          return result[:hits][:total]
        else
          return result[:hits][:total] > 0 ? result[:hits][:hits] : []
        end
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred executing an index query. Response: #{client.body_str}")
      end
    end

    def curl
      Curl::Easy.new
    end

    def is_valid_response?(client)
      [200,201,202].include?(client.response_code)
    end

    def host
      "#{ElasticSearchFramework.default_host}:#{ElasticSearchFramework.default_port}"
    end

    def hash_helper
      @hash_helper ||= HashKit::Helper.new
    end

  end
end