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

  describe "#receive" do
    let(:request) do
      request = double("Rack::Request")
      allow(request).to receive(:params).and_return(params)
      request
    end

    let(:response) { Rack::Response.new }

    let(:params) { double("Hash") }

    let(:valid_env) do
      env = double("Hash")
      allow(env).to receive(:[]).with("HTTP_AUTHORIZATION").and_return(
        Digest::SHA256.new.digest("foo/barabc123")
      )
      env
    end

    let(:invalid_env) do
      env = double("Hash")
      allow(env).to receive(:[]).with("HTTP_AUTHORIZATION").and_return("foo")
      env
    end

    let(:valid_payload) do
      <<-JSON.chomp
{
  "status_message": "Passed",
  "commit": "abcdefg",
  "compare_url": "https://example.com/",
  "repository": {
    "name": "bar",
    "owner_name": "foo"
  }
}
      JSON
    end

    context "happy path" do
      before do
        Lita.config.handlers.travis.token = "abc123"
        Lita.config.handlers.travis.repos["foo/bar"] = "#baz"
        allow(request).to receive(:env).and_return(valid_env)
        allow(params).to receive(:[]).with("payload").and_return(valid_payload)
      end

      it "sends a notification message to the applicable rooms" do
        expect(robot).to receive(:send_message) do |target, message|
          expect(target.room).to eq("#baz")
          expect(message).to include("[Travis CI]")
        end
        subject.receive(request, response)
      end
    end

    context "with a missing token" do
      before do
        Lita.config.handlers.travis.repos["foo/bar"] = "#baz"
        allow(request).to receive(:env).and_return(valid_env)
        allow(params).to receive(:[]).with("payload").and_return(valid_payload)
      end

      it "logs a warning that the token is not set" do
        expect(Lita.logger).to receive(:warn) do |warning|
          expect(warning).to include("token is not set")
        end
        subject.receive(request, response)
      end
    end

    context "with an invalid authorization header" do
      before do
        Lita.config.handlers.travis.token = "abc123"
        Lita.config.handlers.travis.repos["foo/bar"] = "#baz"
        allow(request).to receive(:env).and_return(invalid_env)
        allow(params).to receive(:[]).with("payload").and_return(valid_payload)
      end

      it "logs a warning that the request was invalid" do
        expect(Lita.logger).to receive(:warn) do |warning|
          expect(warning).to include("did not pass authentication")
        end
        subject.receive(request, response)
      end
    end

    context "without setting a value for the repo in config.repos" do
      before do
        Lita.config.handlers.travis.token = "abc123"
        allow(request).to receive(:env).and_return(valid_env)
        allow(params).to receive(:[]).with("payload").and_return(valid_payload)
      end

      it "logs a warning that the request was invalid" do
        expect(Lita.logger).to receive(:warn) do |warning|
          expect(warning).to include("unconfigured project")
        end
        subject.receive(request, response)
      end
    end

    it "logs an error if the payload cannot be parsed" do
      allow(params).to receive(:[]).with("payload").and_return("not json")
      expect(Lita.logger).to receive(:error)
      subject.receive(request, response)
    end
  end
end
