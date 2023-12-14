module PayoutPal
  module Resource
    module Payout

      def create_payout(payout_item, batch_header: {})
        sender_batch_header = { email_subject: "You have a payment." }.merge(batch_header)

        payout = {
          items: [ payout_item ],
          sender_batch_header: sender_batch_header
        }

        post "/v1/payments/payouts", params: JSON.generate(payout), headers: authorization_header do |response, *_|
          case response.code
          when 201
            puts '----------------'
            puts response.body
            puts '----------------'
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

    end
  end
end
