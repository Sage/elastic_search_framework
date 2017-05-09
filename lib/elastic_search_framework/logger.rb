require 'logger'

module ElasticSearchFramework

  def self.logger
    return @@logger
  end

  def self.set_logger(logger)
    @@logger = logger
  end

  ElasticSearchFramework.set_logger(Logger.new(STDOUT))

end
