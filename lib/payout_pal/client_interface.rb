require 'rest-client'
require 'hashie'
require 'payout_pal/configuration'
require 'payout_pal/error'

module PayoutPal
  module ClientInterface
    include PayoutPal::Configuration

    LIVE_BASE_URL = "https://api.paypal.com".freeze
    SANDBOX_BASE_URL = "https://api.sandbox.paypal.com".freeze

    def token
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

    def create_payout(payout_item, batch_header: {})
      sender_batch_header = { email_subject: "You have a payment." }.merge(batch_header)

      payout = {
        items: [ payout_item ],
        sender_batch_header: sender_batch_header
      }

      post "/v1/payments/payouts?sync_mode=true", params: JSON.generate(payout), headers: authorization_header do |response, *_|
        case response.code
        when 201
          payout_batch = JSON.parse(response.body)
          payout_item = payout_batch["items"].first
          payout_item["links"] += payout_batch["links"]
          payout_item["batch_header"] = payout_batch["batch_header"]
          Hashie::Mash.new(payout_item)
        when 400
          raise PayoutPal::BadRequest.new(response.body)
        else
          raise generic_error(response.code, response.body)
        end
      end
    end

    def payout(payout_item_id)
      get "/v1/payments/payouts-item/#{ payout_item_id }", headers: authorization_header do |response, *_|
        case response.code
        when 200
          Hashie::Mash.new(JSON.parse response.body)
        when 404
          raise PayoutPal::NotFound.new(response.body)
        else
          raise generic_error(response.code, response.body)
        end
      end
    end


    private

    def authorization_header
      { authorization:  "Bearer #{ token.access_token }" }
    end

    def get(endpoint, params: {}, headers: {}, &block)
      url = build_url(endpoint, params)
      headers = build_headers(headers)
      RestClient.get(url, headers, &block)
    end

    def post(endpoint, params: nil, headers: {}, &block)
      url = build_url(endpoint)
      headers = build_headers(headers)
      RestClient.post(url, params, headers, &block)
    end

    def build_url(endpoint, params = {})
      uri = URI.parse(base_url + endpoint)
      uri.query = URI.encode_www_form(params) unless params.empty?
      uri.to_s
    end

    def build_headers(headers)
      {
        "Content-Type" => "application/json",
        "Accept" => "application/json",
        "Accept-Language" => "en_US"
      }.merge(headers)
    end

    def base_url
      case config.mode.to_s
      when "live"
        LIVE_BASE_URL
      else
        SANDBOX_BASE_URL
      end
    end

    def serialized_authorization_params
      [ basic_auth_user_password ].pack('m').delete("\r\n")
    end

    def basic_auth_user_password
      config.client_id + ":" + config.client_secret
    end

    def generic_error(code, body)
      PayoutPal::Error.new("HTTP Status: #{ code } | HTTP Body: #{ body }")
    end

  end
end
