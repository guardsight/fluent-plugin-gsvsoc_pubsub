require 'rubygems'
require 'bundler'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'minitest/autorun'


require 'fluent/test'
require 'fluent/plugin/out_gsvsoc_pubsub'

class Minitest::Test
end
