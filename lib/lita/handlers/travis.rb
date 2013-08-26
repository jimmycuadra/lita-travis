require "digest"

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
        data = parse_payload(request.params["payload"]) or return
        repo = get_repo(data)
        validate_repo(repo, request.env["HTTP_AUTHORIZATION"]) or return
        notify_rooms(repo, data)
      end

      private

      def parse_payload(json)
        begin
          MultiJson.load(json)
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

      def notify_rooms(repo, data)
        rooms = rooms_for_repo(repo) or return
        message = <<-MSG.chomp
[Travis CI] #{repo}: #{data["status_message"]} at #{data["commit"]} \
- #{data["compare_url"]}
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

        unless Digest::SHA2.hexdigest("#{repo}#{token}") == auth_hash
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
