require "spec_helper"

describe Lita::Handlers::Travis, lita_handler: true do
  it { routes_http(:post, "/travis").to(:receive) }
end
