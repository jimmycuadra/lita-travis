require "lita"

module Lita
  module Handlers
    class Travis < Handler
    end

    Lita.register_handler(Travis)
  end
end
