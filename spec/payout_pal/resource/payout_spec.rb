require 'spec_helper'

describe PayoutPal::Resource::Payout do
  before do
    PayoutPal.configure do |config|
      config.mode = :sandbox
      config.client_id = "123XYZ"
      config.client_secret = "456ABC"
    end

    PayoutPal.instance_variable_set(:@token, nil)
    PayoutPal.instance_variable_set(:@expires_at, nil)
  end

  describe ".create_payout" do
    context "when successful" do
      it "creates a payout" do
        allow(PayoutPal).to receive(:token).and_return(double("token", access_token: "A015z9qL"))

        stub_request(:post, "https://api.sandbox.paypal.com/v1/payments/payouts?sync_mode=true")
          .with(headers: { "Accept" => "application/json", "Authorization" => "Bearer A015z9qL", "Content-Type" => "application/json" })
          .to_return(status: 201, body: PayoutPal::Stubs["create_payout"])

        batch_header = { email_subject: "Gobias Industries Payment" }

        payout_item = {
          note: "Thank you for shopping at Gobias Industries",
          amount: { value: "12.57", currency: "USD" },
          receiver: "michael@bluth.com",
          recipient_type: "EMAIL",
          sender_item_id: "123456789"
        }

        payout = PayoutPal.create_payout(payout_item, batch_header: batch_header)

        expect(payout.payout_item_id).to eq("P3FKTDYE3DHMG")
        expect(payout.transaction_id).to eq("9XG38325MU8441712")
        expect(payout.transaction_status).to eq("SUCCESS")
        expect(payout.payout_batch_id).to eq("PQT78VW24P758")

        payout_item_fee = payout.payout_item_fee
        expect(payout_item_fee.value).to eq("0.25")
        expect(payout_item_fee.currency).to eq("USD")

        payout_item = payout.payout_item
        expect(payout_item.recipient_type).to eq("EMAIL")
        expect(payout_item.receiver).to eq("michael@bluth.com")
        expect(payout_item.note).to eq("Thank you for shopping at Gobias Industries")
        expect(payout_item.sender_item_id).to eq("123456789")

        payout_item_amount = payout_item.amount
        expect(payout_item_amount.value).to eq("12.57")
        expect(payout_item_amount.currency).to eq("USD")

        batch_header = payout.batch_header
        expect(batch_header.payout_batch_id).to eq("PQT78VW24P758")
        expect(batch_header.batch_status).to eq("SUCCESS")
        expect(batch_header.time_created).to eq("2015-04-29T16:34:13Z")
        expect(batch_header.time_completed).to eq("2015-04-29T16:34:15Z")
        expect(batch_header.sender_batch_header.email_subject).to eq("Gobias Industries Payment")

        expect(batch_header.amount.value).to eq("12.57")
        expect(batch_header.amount.currency).to eq("USD")

        expect(batch_header.fees.value).to eq("0.25")
        expect(batch_header.fees.currency).to eq("USD")
      end
    end

    context "when unsuccessful" do
      context "when the request is malformed" do
        it "raises PayPal::BadRequest" do
          allow(PayoutPal).to receive(:token).and_return(double("token", access_token: "A015z9qL"))

          response_body_json = JSON.generate({
            name: "VALIDATION_ERROR",
            message: "Invalid request - see details.",
            debug_id: "11fe1c4873395",
            information_link: "https://developer.paypal.com/webapps/developer/docs/api/#VALIDATION_ERROR",
            details: [{
              field: "items[0].amount.value",
              issue: "Required field missing"
            }]
          })

          stub_request(:post, "https://api.sandbox.paypal.com/v1/payments/payouts?sync_mode=true")
            .with(headers: { "Accept" => "application/json", "Authorization" => "Bearer A015z9qL", "Content-Type" => "application/json" })
            .to_return(status: 400, body: response_body_json)

          batch_header = { email_subject: "Gobias Industries Payment" }

          payout_item = {
            note: "Thank you for shopping at Gobias Industries",
            amount: { currency: "USD" },
            receiver: "michael@bluth.com",
            recipient_type: "EMAIL",
            sender_item_id: "123456789"
          }

          expect(-> { PayoutPal.create_payout(payout_item, batch_header: batch_header) }).to raise_error(PayoutPal::BadRequest, response_body_json)
        end
      end

      context "when the server errors" do
        it "raises PayoutPal::Error" do
          allow(PayoutPal).to receive(:token).and_return(double("token", access_token: "A015z9qL"))

          stub_request(:post, "https://api.sandbox.paypal.com/v1/payments/payouts?sync_mode=true")
            .with(headers: { "Accept" => "application/json", "Authorization" => "Bearer A015z9qL", "Content-Type" => "application/json" })
            .to_return(status: 500, body: "")

          batch_header = { email_subject: "Gobias Industries Payment" }

          payout_item = {
            note: "Thank you for shopping at Gobias Industries",
            amount: { value: "12.57", currency: "USD" },
            receiver: "michael@bluth.com",
            recipient_type: "EMAIL",
            sender_item_id: "123456789"
          }

          expect(-> { PayoutPal.create_payout(payout_item, batch_header: batch_header) }).to raise_error(PayoutPal::Error, "HTTP Status: 500 | HTTP Body: ")
        end
      end
    end
  end

  describe ".payout" do
    context "when successful" do
      it "retrieves the payout" do
        allow(PayoutPal).to receive(:token).and_return(double("token", access_token: "A015z9qL"))

        payout_item_id = "P3FKTDYE3DHMG"

        stub_request(:get, "https://api.sandbox.paypal.com/v1/payments/payouts-item/#{ payout_item_id }")
          .with(headers: { "Accept" => "application/json", "Content-Type" => "application/json", "Authorization" => "Bearer A015z9qL" })
          .to_return(status: 200, body: PayoutPal::Stubs["payout"])

        payout = PayoutPal.payout(payout_item_id)

        expect(payout.payout_item_id).to eq(payout_item_id)
        expect(payout.transaction_id).to eq("9XG38325MU8441712")
        expect(payout.transaction_status).to eq("SUCCESS")
        expect(payout.payout_batch_id).to eq("PQT78VW24P758")

        payout_item_fee = payout.payout_item_fee
        expect(payout_item_fee.value).to eq("0.25")
        expect(payout_item_fee.currency).to eq("USD")

        payout_item = payout.payout_item
        expect(payout_item.recipient_type).to eq("EMAIL")
        expect(payout_item.receiver).to eq("michael@bluth.com")
        expect(payout_item.note).to eq("Thank you for shopping at Gobias Industries")
        expect(payout_item.sender_item_id).to eq("123456789")

        payout_item_amount = payout_item.amount
        expect(payout_item_amount.value).to eq("12.57")
        expect(payout_item_amount.currency).to eq("USD")

        batch_header = payout.batch_header
        expect(batch_header).to be_nil
      end
    end

    context "when unsuccessful" do
      context "when payout resource does not exist" do
        it "raises PayoutPal::NotFound" do
          response_body_json = JSON.generate({ name: "INVALID_RESOURCE_ID", message: "The requested resource ID was not found.", information_link: "https://developer.paypal.com/webapps/developer/docs/api/#INVALID_RESOURCE_ID" })

          allow(PayoutPal).to receive(:token).and_return(double("token", access_token: "A015z9qL"))

          payout_item_id = "0000000000000"

          stub_request(:get, "https://api.sandbox.paypal.com/v1/payments/payouts-item/#{ payout_item_id }")
            .with(headers: { "Accept" => "application/json", "Content-Type" => "application/json", "Authorization" => "Bearer A015z9qL" })
            .to_return(status: 404, body: response_body_json)

          expect(-> { PayoutPal.payout(payout_item_id) }).to raise_error(PayoutPal::NotFound, response_body_json)
        end
      end

      context "when the server errors" do
        it "raises PayoutPal::Error" do
          allow(PayoutPal).to receive(:token).and_return(double("token", access_token: "A015z9qL"))

          payout_item_id = "P3FKTDYE3DHMG"

          stub_request(:get, "https://api.sandbox.paypal.com/v1/payments/payouts-item/#{ payout_item_id }")
            .with(headers: { "Accept" => "application/json", "Content-Type" => "application/json", "Authorization" => "Bearer A015z9qL" })
            .to_return(status: 500, body: "")

          expect(-> { PayoutPal.payout(payout_item_id) }).to raise_error(PayoutPal::Error, "HTTP Status: 500 | HTTP Body: ")
        end
      end
    end
  end
end
