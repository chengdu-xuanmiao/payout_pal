# PayoutPal

This gem aims to simplify the [payouts](https://developer.paypal.com/docs/api/#payouts) endpoint of PayPal's [rest API](https://developer.paypal.com/docs/api).


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'payout_pal'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install payout_pal

## Usage

```ruby
PayoutPal.configure do |config|
  config.mode = :live
  config.client_id = config.paypal.client_id
  config.client_secret = config.paypal.client_secret
end

batch_header = { email_subject: "Gobias Industries Payment" }

payout_item = {
  note: "Thank you for shopping at Gobias Industries",
  amount: { value: "12.57", currency: "USD" },
  receiver: "michael@bluth.com",
  recipient_type: "EMAIL",
  sender_item_id: "123456789"
}

# Creates a single Payout Item in sync mode (this endpoint: /v1/payments/payouts?sync_mode=true)
payout_item = PayoutPal.create_payout(payout_item, batch_header: batch_header)


# ...

# Retrieve PayPal Payout item (this endpoint: /v1/payments/payouts-item/<Payout-Item-Id>)
payout_item = PayoutPal.payout(payout_item_id)
```


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

1. Fork it ( https://github.com/[my-github-username]/payout_pal/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
