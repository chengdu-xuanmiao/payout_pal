module PayoutPal
  module Resource
    module Token

      # If token is already expired, or will expire within
      # `EXPIRATION_PADDING` seconds from now, refresh token.
      EXPIRATION_PADDING = 2.freeze

      def token
        if expired?
          time_request_was_issued = Time.now
          @token = request_token
          @expires_at = time_request_was_issued + (@token.expires_in - EXPIRATION_PADDING)
        end

        @token
      end


      private

      def expired?
        Time.now >= expires_at
      end

      def expires_at
        @expires_at || Time.now
      end

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
