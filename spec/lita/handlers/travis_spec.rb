require "spec_helper"

describe Lita::Handlers::Travis, lita_handler: true do
  it { is_expected.to route_http(:post, "/travis").to(:receive) }

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
        Digest::SHA2.hexdigest("foo/barabc123")
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
  "branch": "master",
  "commit": "abcdefg",
  "committer_name": "Bongo",
  "compare_url": "https://example.com/",
  "repository": {
    "name": "bar",
    "owner_name": "foo"
  }
}
      JSON
    end

    let(:different_branch_payload) do
      <<-JSON.chomp
{
  "status_message": "Passed",
  "branch": "staging",
  "commit": "abcdefg",
  "committer_name": "Bongo",
  "compare_url": "https://example.com/",
  "repository": {
    "name": "bar",
    "owner_name": "foo"
  }
}
      JSON
    end

    before do
      registry.config.handlers.travis.repos = {}
    end

    context "happy path" do
      before do
        registry.config.handlers.travis.token = "abc123"
        registry.config.handlers.travis.repos["foo/bar"] = "#baz"
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

    context "with an invalid authorization header" do
      before do
        registry.config.handlers.travis.token = "abc123"
        registry.config.handlers.travis.repos["foo/bar"] = "#baz"
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

    context "with only config.default_rooms set" do
      before do
        registry.config.handlers.travis.token = "abc123"
        registry.config.handlers.travis.default_rooms = "#default"
        allow(request).to receive(:env).and_return(valid_env)
        allow(params).to receive(:[]).with("payload").and_return(valid_payload)
      end

      it "sends a notification message to the applicable rooms" do
        expect(robot).to receive(:send_message) do |target, message|
          expect(target.room).to eq("#default")
          expect(message).to include("[Travis CI]")
        end
        subject.receive(request, response)
      end
    end
    context "branch config set" do
      before do
        registry.config.handlers.travis.branch = "master"
        allow(request).to receive(:env).and_return(valid_env)
      end

      it "doesn't send notifications for branches that don't match the config" do
        allow(params).to receive(:[]).with("payload")
                          .and_return(different_branch_payload)
        expect(robot).not_to receive(:send_message)
        expect(Lita.logger).to receive(:info)
        subject.receive(request, response)
      end

      it "only sends notifications for branches that match the config" do
        allow(params).to receive(:[]).with("payload")
                          .and_return(valid_payload)
        expect(robot).to receive(:send_message) do |target, message|
          expect(message).to include("[Travis CI]")
        end
        subject.receive(request, response)
      end
    end

    context "without setting a value for the repo in config.repos and no default" do
      before do
        registry.config.handlers.travis.token = "abc123"
        allow(registry.config.handlers.travis).to receive(:default_rooms).and_return(nil)
        allow(request).to receive(:env).and_return(valid_env)
        allow(params).to receive(:[]).with("payload").and_return(valid_payload)
      end

      it "logs a warning that the request was ignored" do
        expect(Lita.logger).to receive(:warn) do |warning|
          expect(warning).to include("ignored because no rooms were specified")
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
