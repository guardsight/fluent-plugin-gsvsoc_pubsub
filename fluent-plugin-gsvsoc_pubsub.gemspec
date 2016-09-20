# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fluent/plugin/gsvsoc_pubsub/version'

Gem::Specification.new do |spec|
  spec.name          = "fluent-plugin-gsvsoc_pubsub"
  spec.version       = Fluent::Plugin::GsvsocPubsub::VERSION
  spec.authors       = ["pivelpin"]
  spec.email         = ["johnmac@guardsight.com"]
  spec.license       = "GPL-3.0"
  spec.summary       = "Fluentd plugin for Google Cloud Pub/Sub"
  spec.description   = "A plugin for the Fluentd event collection agent that provides a coupling between a GuardSight SPOP and Google Cloud Pub/Sub"
  spec.homepage      = "https://github.com/guardsight/fluent-plugin-gsvsoc_pubsub"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "fluentd", "~> 0.12.29"
  spec.add_runtime_dependency "google-api-client", "~> 0.9.11"
  spec.add_runtime_dependency "googleauth", "~> 0.5.1"
  spec.add_runtime_dependency "parallel", "~> 1.9"
  
  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "<=10.2.4"
  spec.add_development_dependency "minitest", "~> 5.9"
  spec.add_development_dependency "test-unit"
end
