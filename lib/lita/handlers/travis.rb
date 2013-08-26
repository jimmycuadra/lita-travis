require "lita"

module Lita
  module Handlers
    class Travis < Handler
      http.post "/travis", :receive
    end

    Lita.register_handler(Travis)
  end
end
