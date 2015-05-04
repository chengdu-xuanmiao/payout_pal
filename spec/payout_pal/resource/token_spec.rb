require 'spec_helper'

describe PayoutPal::Resource::Token do
  before do
    PayoutPal.configure do |config|
      config.mode = :sandbox
      config.client_id = "123XYZ"
      config.client_secret = "456ABC"
    end

    @local_time = Time.local(2015, 3, 14, 10, 5, 0)
    Timecop.freeze(@local_time)
  end

  after do
    PayoutPal.instance_variable_set(:@token, nil)
    PayoutPal.instance_variable_set(:@expires_at, nil)
  end

  describe ".token" do
    it "requests and caches a token for the duration of the token's life" do
      stub_request(:post, "https://123XYZ:456ABC@api.sandbox.paypal.com/v1/oauth2/token")
        .with({
          body: { grant_type: "client_credentials", response_type: "token" },
          headers: { "Accept" => "application/json", "Content-Type" => "application/x-www-form-urlencoded" }
        })
        .to_return(status: 200, body: PayoutPal::Stubs["token"])


      allow(RestClient).to receive(:post).and_call_original

      # First call, there is no cached token,
      # make an API request for a new token.
      token1 = PayoutPal.token
      expect(RestClient).to have_received(:post).exactly(1).times

      expect(token1.scope).to eq("https://uri.paypal.com/services/subscriptions https://api.paypal.com/v1/payments/.* https://api.paypal.com/v1/vault/credit-card https://uri.paypal.com/services/applications/webhooks openid https://uri.paypal.com/services/invoicing https://uri.paypal.com/payments/payouts https://api.paypal.com/v1/vault/credit-card/.*")
      expect(token1.access_token).to eq("A015z9qL")
      expect(token1.token_type).to eq("Bearer")
      expect(token1.app_id).to eq("APP-80W284485P519543T")

      # The token expires in 1 hour
      expect(token1.expires_in).to eq(3600)


      # 55 minutes since we recieved the token, a second call is made.
      # A non-expired, cached token exists, so let's return that.
      Timecop.travel(@local_time + 3300)
      token2 = PayoutPal.token
      expect(RestClient).to have_received(:post).exactly(1).times

      # This new token is the same object in memory
      expect(token2).to equal(token1)


      # 59 minutes and 59 seconds since we received the token,
      # a third call is made. We do have a cached token, but it
      # is now expired. Make an API request for a new token.
      Timecop.travel(@local_time + 3599)
      token3 = PayoutPal.token
      expect(RestClient).to have_received(:post).exactly(2).times

      # This new token is NOT the same object in memory
      expect(token3).not_to equal(token1)


      expect(token3.scope).to eq("https://uri.paypal.com/services/subscriptions https://api.paypal.com/v1/payments/.* https://api.paypal.com/v1/vault/credit-card https://uri.paypal.com/services/applications/webhooks openid https://uri.paypal.com/services/invoicing https://uri.paypal.com/payments/payouts https://api.paypal.com/v1/vault/credit-card/.*")
      expect(token3.access_token).to eq("A015z9qL")
      expect(token3.token_type).to eq("Bearer")
      expect(token3.app_id).to eq("APP-80W284485P519543T")
      expect(token3.expires_in).to eq(3600)
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
