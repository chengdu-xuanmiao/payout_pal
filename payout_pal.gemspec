# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'payout_pal/version'

Gem::Specification.new do |spec|
  spec.name          = "payout_pal"
  spec.version       = PayoutPal::VERSION
  spec.authors       = ["Ben Reinhart"]
  spec.email         = ["benjreinhart@gmail.com"]

  spec.summary       = %q{PayPal Payouts}
  spec.description   = %q{Simplify PayPal Payouts}
  spec.homepage      = "https://github.com/bjornco/payout_pal"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com' to prevent pushes to rubygems.org, or delete to allow pushes to any server."
  end

  spec.add_development_dependency "bundler", "~> 1.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"

  spec.add_dependency "hashie", "~> 3.4"
  spec.add_dependency "rest-client", "1.8.0"
end
