require "lita"

module Lita
  module Handlers
    class Travis < Handler
      def self.default_config(config)
        config.token = nil
        config.repos = {}
      end

      http.post "/travis", :receive
    end

    Lita.register_handler(Travis)
  end
end
