module PayoutPal
  module Configuration
    Config = Struct.new(:mode, :client_id, :client_secret)

    def configure
      yield config
    end

    private

    def config
      @config ||= Config.new
    end
  end
end
