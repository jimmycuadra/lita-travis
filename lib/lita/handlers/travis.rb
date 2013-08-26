require "digest"
require "uri"

require "lita"

module Lita
  module Handlers
    # Provides Travis CI webhooks for Lita.
    class Travis < Handler
      def self.default_config(config)
        config.token = nil
        config.repos = {}
      end

      http.post "/travis", :receive

      def receive(request, response)
        payload = extract_payload(request.body) or return
        repo = get_repo(payload)
        validate_repo(repo, request.env["Authorization"]) or return
        notify_rooms(repo, payload)
      end

      private

      def extract_payload(body)
        begin
          payload = MultiJson.load(URI.unescape(body.sub(/^payload=/, "")))
          payload["payload"] if payload.key?("payload")
        rescue MultiJson::LoadError => e
          Lita.logger.error(
            "Could not parse JSON payload from Travis CI: #{e.message}"
          )
          return
        end
      end

      def get_repo(pl)
        "#{pl["repository"]["owner_name"]}/#{pl["repository"]["name"]}"
      end

      def notify_rooms(repo, payload)
        rooms = rooms_for_repo(repo) or return
        message = <<-MSG.chomp
[Travis CI] #{repo}: #{payload["status_message"]} at #{payload["commit"]} \
- #{payload["compare_url"]}
        MSG

        rooms.each do |room|
          target = Source.new(nil, room)
          robot.send_message(target, message)
        end
      end

      def rooms_for_repo(repo)
        rooms = Lita.config.handlers.travis.repos[repo]

        if rooms
          Array(rooms)
        else
          Lita.logger.warn <<-WARNING.chomp
Notification from Travis CI for unconfigured project: #{repo}
WARNING
          return
        end
      end

      def validate_repo(repo, auth_hash)
        token = Lita.config.handlers.travis.token

        unless token
          Lita.logger.warn <<-WARNING.chomp
Notification from Travis CI could not be validated because \
Lita.config.handlers.token is not set.
          WARNING
          return
        end

        unless auth_hash == Digest::SHA256.new.digest("#{repo}#{token}")
          Lita.logger.warn <<-WARNING.chomp
Notification from Travis CI did not pass authentication.
          WARNING
          return
        end

        true
      end
    end

    Lita.register_handler(Travis)
  end
end
