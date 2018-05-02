module ElasticSearchFramework
  class Repository

    def set(index:, entity:, type: 'default')
      uri = URI("#{host}/#{index.full_name}/#{type.downcase}/#{get_id_value(index: index, entity: entity)}")
      hash = hash_helper.to_hash(entity)

      request = Net::HTTP::Put.new(uri.request_uri)
      request.body = JSON.dump(hash)
      request.content_type = 'application/json'

      response = with_client do |client|
        client.request(request)
      end

      unless is_valid_response?(response.code)
        raise ElasticSearchFramework::Exceptions::IndexError.new(
            "An error occurred setting an index document. Response: #{response.body} | Code: #{response.code}"
        )
      end
      return true
    end

    def get(index:, id:, type: 'default')
      uri = URI("#{host}/#{index.full_name}/#{type.downcase}/#{id}/_source")

      request = Net::HTTP::Get.new(uri.request_uri)

      response = with_client do |client|
        client.request(request)
      end

      if is_valid_response?(response.code)
        result = JSON.load(response.body)
        hash_helper.indifferent!(result)
        return result
      elsif Integer(response.code) == 404
        return nil
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new(
            "An error occurred getting an index document. Response: #{response.body}"
        )
      end
    end

    def drop(index:, id:, type: 'default')
      uri = URI("#{host}/#{index.full_name}/#{type.downcase}/#{id}")

      request = Net::HTTP::Delete.new(uri.request_uri)

      response = with_client do |client|
        client.request(request)
      end

      if is_valid_response?(response.code) || Integer(response.code) == 404
        return true
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new(
            "An error occurred dropping an index document. Response: #{response.body}"
        )
      end
    end

    def query(index:, expression:, type: 'default', limit: 10, count: false)
      uri = URI("#{host}/#{index.full_name}/#{type}/_search?q=#{URI.encode(expression)}&size=#{limit}")

      request = Net::HTTP::Get.new(uri.request_uri)

      response = with_client do |client|
        client.request(request)
      end

      if is_valid_response?(response.code)
        result = JSON.parse(response.body)
        hash_helper.indifferent!(result)
        if count
          return result[:hits][:total]
        else
          return result[:hits][:total] > 0 ? result[:hits][:hits] : []
        end
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred executing an index query. Response: #{response.body}")
      end
    end

    def json_query(index_name:, json_query:, type: 'default')
      uri = URI("#{host}/#{index_name}/#{type}/_search")

      request = Net::HTTP::Get.new(uri.request_uri)
      request.body = json_query

      response = with_client do |client|
        client.request(request)
      end

      if is_valid_response?(response.code)
        result = JSON.parse(response.body)
        return result['hits']
      else
        raise ElasticSearchFramework::Exceptions::IndexError.new("An error occurred executing an index query. Response: #{response.body}")
      end
    end

    def client
      @client ||= Net::HTTP.new(host_uri.host, host_uri.port).tap do |c|
        c.use_ssl = host_uri.scheme == 'https'
        c.open_timeout = open_timeout
        c.read_timeout = read_timeout
      end
    end

    def idle_timeout
      @idle_timeout ||= Integer(ENV['CONNECTION_IDLE_TIMEOUT'] ||  5)
    end

    def read_timeout
      @read_timeout ||= Integer(ENV['CONNECTION_READ_TIMEOUT'] ||  5)
    end

    def open_timeout
      @read_timeout ||= Integer(ENV['CONNECTION_OPEN_TIMEOUT'] ||  1)
    end

    def is_valid_response?(status)
      [200,201,202].include?(Integer(status))
    end

    def host
      "#{ElasticSearchFramework.host}:#{ElasticSearchFramework.port}"
    end

    def host_uri
      URI("#{ElasticSearchFramework.host}:#{ElasticSearchFramework.port}")
    end

    def hash_helper
      @hash_helper ||= HashKit::Helper.new
    end

    def get_id_value(index:, entity:)
      if entity.is_a?(Hash)
        entity[index.description[:id].to_sym] || entity[index.description[:id].to_s]
      else
        entity.instance_variable_get("@#{index.description[:id]}")
      end
    end

    def with_client
      response = nil

      self.class.pool.with do |base|
        base.client.read_timeout = read_timeout
        begin
          response = yield base.client
        ensure
          base.client.read_timeout = idle_timeout
        end
      end

      response
    end

    def self.pool
      @pool ||= ConnectionPool.new(size: pool_size, timeout: pool_timeout) { ElasticSearchFramework::Repository.new }
    end

    def self.pool_size
      @pool_size ||= Integer(ENV['CONNECTION_POOL_SIZE'] || 25)
    end

    def self.pool_timeout
      @pool_timeout ||= Integer(ENV['CONNECTION_IDLE_TIMEOUT'] || 5)
    end

  end
end
