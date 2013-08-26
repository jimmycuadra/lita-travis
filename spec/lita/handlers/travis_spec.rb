require "spec_helper"

describe Lita::Handlers::Travis, lita_handler: true do
  it { routes_http(:post, "/travis").to(:receive) }

  describe ".default_config" do
    it "sets token to nil" do
      expect(Lita.config.handlers.travis.token).to be_nil
    end

    it "sets repos to an empty hash" do
      expect(Lita.config.handlers.travis.repos).to eq({})
    end
  end
end
