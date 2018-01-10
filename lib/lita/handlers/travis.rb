require "digest"

require "lita"

module Lita
  module Handlers
    # Provides Travis CI webhooks for Lita.
    class Travis < Handler
      config :token, type: String, required: true
      config :repos, type: Hash, default: {}
      config :default_rooms, type: [Array, String]
      config :branch, type: String

      http.post "/travis", :receive

      def receive(request, response)
        data = parse_payload(request.params["payload"]) or return
        repo = get_repo(data)
        validate_repo(repo, request.env["HTTP_AUTHORIZATION"]) or return
        case config.branch
        when nil
          notify_rooms(repo, data)
        when -> (branch) { branch == data['branch'] }
          notify_rooms(repo, data)
        else
          Lita.logger.info("Skipping notification for branch #{data['branch']}")
        end
      end

      private

      def parse_payload(json)
        begin
          MultiJson.load(json)
        rescue MultiJson::LoadError => e
          Lita.logger.error(t("parse_error", message: e.message))
          return
        end
      end

      def get_repo(pl)
        "#{pl["repository"]["owner_name"]}/#{pl["repository"]["name"]}"
      end

      def notify_rooms(repo, data)
        rooms = rooms_for_repo(repo) or return

        message = t(
          "message",
          repo: repo,
          status_message: data["status_message"],
          commit: data["commit"][0...7],
          branch: data["branch"],
          committer_name: data["committer_name"],
          compare_url: data["compare_url"]
        )

        rooms.each do |room|
          target = Source.new(room: room)
          robot.send_message(target, message)
        end
      end

      def rooms_for_repo(repo)
        rooms = config.repos[repo]
        default_rooms = config.default_rooms

        if rooms
          Array(rooms)
        elsif default_rooms
          Array(default_rooms)
        else
          Lita.logger.warn(t("no_room_configured"), repo: repo)
          return
        end
      end

      def validate_repo(repo, auth_hash)
        unless Digest::SHA2.hexdigest("#{repo}#{config.token}") == auth_hash
          Lita.logger.warn(t("auth_failed"), repo: repo)
          return
        end

        true
      end
    end

    Lita.register_handler(Travis)
  end
end

Lita.load_locales Dir[File.expand_path(
  File.join("..", "..", "..", "..", "locales", "*.yml"), __FILE__
)]
