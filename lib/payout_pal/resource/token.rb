module PayoutPal
  module Resource
    module Token

      module Expiration
        # Some extra time (in seconds) to pad the actual
        # `expires_at` value, so that it will expire slightly
        # before its original expiration value.
        EXPIRATION_PADDING = 2.freeze

        private

        def expired?
          Time.now >= expires_at
        end

        def expires_at
          @expires_at || epoch_time
        end

        def expires_at=(time)
          @expires_at = (time - EXPIRATION_PADDING)
        end

        def epoch_time
          Time.at(0)
        end
      end
      include Expiration


      def token
        if expired?
          time_request_was_issued = Time.now
          self.token = request_token
          self.expires_at = time_request_was_issued + @token.expires_in
        end

        @token
      end


      private

      attr_writer :token

      def serialized_authorization_params
        [ basic_auth_user_password ].pack('m').delete("\r\n")
      end

      def basic_auth_user_password
        config.client_id + ":" + config.client_secret
      end

      def request_token
        headers = {
          "Content-Type" => "application/x-www-form-urlencoded",
          "Authorization" => "Basic #{ serialized_authorization_params }"
        }

        body = {
          grant_type: "client_credentials",
          response_type: "token"
        }

        post "/v1/oauth2/token", params: body, headers: headers do |response, *_|
          case response.code
          when 200
            Hashie::Mash.new(JSON.parse response.body)
          when 401
            raise PayoutPal::BadRequest.new(response.body)
          else
            raise generic_error(response.code, response.body)
          end
        end
      end

    end
  end
end
