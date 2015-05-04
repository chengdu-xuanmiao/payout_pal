require 'spec_helper'

describe PayoutPal::Resource::Token do
  before do
    PayoutPal.configure do |config|
      config.mode = :sandbox
      config.client_id = "123XYZ"
      config.client_secret = "456ABC"
    end

    PayoutPal.instance_variable_set(:@token, nil)
    PayoutPal.instance_variable_set(:@expires_at, nil)

    @local_time = Time.local(2015, 3, 14, 10, 5, 0)
    @cached_token = Hashie::Mash.new(JSON.parse(PayoutPal::Stubs["token"]))

    Timecop.freeze(@local_time)
  end

  describe ".token" do
    context "when no previous access token exists" do
      it "requests the access token from the API" do
        stub_request(:post, "https://123XYZ:456ABC@api.sandbox.paypal.com/v1/oauth2/token")
          .with({
            body: { grant_type: "client_credentials", response_type: "token" },
            headers: { "Accept" => "application/json", "Content-Type" => "application/x-www-form-urlencoded" }
          })
          .to_return(status: 200, body: PayoutPal::Stubs["token"])

        # Ensure HTTP POST request IS being made
        expect(RestClient).to receive(:post).exactly(1).times.and_call_original

        token = PayoutPal.token

        expect(token.scope).to eq("https://uri.paypal.com/services/subscriptions https://api.paypal.com/v1/payments/.* https://api.paypal.com/v1/vault/credit-card https://uri.paypal.com/services/applications/webhooks openid https://uri.paypal.com/services/invoicing https://uri.paypal.com/payments/payouts https://api.paypal.com/v1/vault/credit-card/.*")
        expect(token.access_token).to eq("A015z9qL")
        expect(token.token_type).to eq("Bearer")
        expect(token.app_id).to eq("APP-80W284485P519543T")
        expect(token.expires_in).to eq(28800)

        # New token and expiration values are cached
        expect(PayoutPal.instance_variable_get(:@token)).to eq(token)
        expect(PayoutPal.instance_variable_get(:@expires_at)).to eq(@local_time + 28800 - PayoutPal::Resource::Token::EXPIRATION_PADDING)
      end
    end

    context "when an access token exists" do
      context "when expired" do
        it "requests a new token" do
          PayoutPal.instance_variable_set(:@token, @cached_token)
          PayoutPal.instance_variable_set(:@expires_at, @local_time)

          stub_request(:post, "https://123XYZ:456ABC@api.sandbox.paypal.com/v1/oauth2/token")
            .with({
              body: { grant_type: "client_credentials", response_type: "token" },
              headers: { "Accept" => "application/json", "Content-Type" => "application/x-www-form-urlencoded" }
            })
            .to_return(status: 200, body: PayoutPal::Stubs["token"])

          # Ensure HTTP POST request IS being made
          expect(RestClient).to receive(:post).exactly(1).times.and_call_original

          token = PayoutPal.token

          expect(token.scope).to eq("https://uri.paypal.com/services/subscriptions https://api.paypal.com/v1/payments/.* https://api.paypal.com/v1/vault/credit-card https://uri.paypal.com/services/applications/webhooks openid https://uri.paypal.com/services/invoicing https://uri.paypal.com/payments/payouts https://api.paypal.com/v1/vault/credit-card/.*")
          expect(token.access_token).to eq("A015z9qL")
          expect(token.token_type).to eq("Bearer")
          expect(token.app_id).to eq("APP-80W284485P519543T")
          expect(token.expires_in).to eq(28800)

          # New token and expiration values are cached
          expect(PayoutPal.instance_variable_get(:@token)).to eq(token)
          expect(PayoutPal.instance_variable_get(:@expires_at)).to eq(@local_time + 28800 - PayoutPal::Resource::Token::EXPIRATION_PADDING)
        end
      end

      context "when not expired" do
        it "uses the cached token" do
          expires_at = @local_time + 20

          PayoutPal.instance_variable_set(:@token, @cached_token)
          PayoutPal.instance_variable_set(:@expires_at, expires_at)

          # Ensure HTTP POST request is NOT being made
          expect(RestClient).to receive(:post).exactly(0).times.and_call_original

          token = PayoutPal.token

          expect(token.scope).to eq("https://uri.paypal.com/services/subscriptions https://api.paypal.com/v1/payments/.* https://api.paypal.com/v1/vault/credit-card https://uri.paypal.com/services/applications/webhooks openid https://uri.paypal.com/services/invoicing https://uri.paypal.com/payments/payouts https://api.paypal.com/v1/vault/credit-card/.*")
          expect(token.access_token).to eq("A015z9qL")
          expect(token.token_type).to eq("Bearer")
          expect(token.app_id).to eq("APP-80W284485P519543T")
          expect(token.expires_in).to eq(28800)

          # Token and expiration values are unchanged
          expect(PayoutPal.instance_variable_get(:@token)).to eq(token)
          expect(PayoutPal.instance_variable_get(:@expires_at)).to eq(expires_at)
        end
      end
    end

    context "when credentials are invalid" do
      it "raises PayoutPal::BadRequest" do
        response_body_json = JSON.generate({error: "invalid_client", error_description: "Client secret does not match for this client"})

        stub_request(:post, "https://123XYZ:456ABC@api.sandbox.paypal.com/v1/oauth2/token")
          .with({
            body: { grant_type: "client_credentials", response_type: "token" },
            headers: { "Accept" => "application/json", "Content-Type" => "application/x-www-form-urlencoded" }
          })
          .to_return(status: 401, body: response_body_json)

        expect(-> { PayoutPal.token }).to raise_error(PayoutPal::BadRequest, response_body_json)
      end
    end

    context "when the server errors" do
      it "raises PayoutPal::Error" do
        stub_request(:post, "https://123XYZ:456ABC@api.sandbox.paypal.com/v1/oauth2/token")
          .with({
            body: { grant_type: "client_credentials", response_type: "token" },
            headers: { "Accept" => "application/json", "Content-Type" => "application/x-www-form-urlencoded" }
          })
          .to_return(status: 500, body: "")

        expect(-> { PayoutPal.token }).to raise_error(PayoutPal::Error, "HTTP Status: 500 | HTTP Body: ")
      end
    end
  end
end
