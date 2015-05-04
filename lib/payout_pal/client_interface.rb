require 'rest-client'
require 'hashie'
require 'payout_pal/configuration'
require 'payout_pal/resource/token'
require 'payout_pal/resource/payout'
require 'payout_pal/error'

module PayoutPal
  module ClientInterface
    LIVE_BASE_URL = "https://api.paypal.com".freeze
    SANDBOX_BASE_URL = "https://api.sandbox.paypal.com".freeze

    include PayoutPal::Configuration
    include PayoutPal::Resource::Token
    include PayoutPal::Resource::Payout


    private

    def authorization_header
      { "Authorization" => "Bearer #{ token.access_token }" }
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

    def generic_error(code, body)
      PayoutPal::Error.new("HTTP Status: #{ code } | HTTP Body: #{ body }")
    end

  end
end
