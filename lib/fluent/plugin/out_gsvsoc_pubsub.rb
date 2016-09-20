#
# NAME - out_gsvsoc_pubsub
#
# SYNOPSIS
# @type gsvsoc_pubsub
# buffer_type file
# buffer_path /var/log/td-agent/buffer/gsvsoc_pubsub*.buffer
# topic projects/project-name/topics/topic-name
# key /path/to/secret/pubsub-key.json
# attrs type:log # comma sep for multiple attrs - foo:bar,biz:baz
#
# DESCRIPTION
# Fluentd (td-agent) output plugin for Google Pub/Sub 
# 
# AUTHOR
# johnmac@guardsight.com
# 
# SEE ALSO
# W-0085
# https://github.com/guardsight
# http://docs.fluentd.org/articles/output-plugin-overview
#
# LICENSE
# This software is licensed in accordance with the GPLv3 (http://www.gnu.org/licenses/quick-guide-gplv3.en.html)
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR 
# THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

require 'fluent/output'
require 'date'
require 'google/apis/pubsub_v1' # td-agent-gem install google-api-client
require 'googleauth' # td-agent-gem install googleauth
require 'parallel' # td-agent-gem install parallel

module Fluent
  class GsvsocPubSubOutput < BufferedOutput
    Fluent::Plugin.register_output('gsvsoc_pubsub', self)
    Pubsub = Google::Apis::PubsubV1

    config_set_default :flush_interval,             1
    config_set_default :try_flush_interval,         0.05
    config_set_default :buffer_chunk_records_limit, 900 # <= keep below PubSub 1K message max
    config_set_default :buffer_chunk_limit,         1843200
    config_set_default :buffer_queue_limit,         128
    config_set_default :parallel_in_threads,         50 # max number of 'Parallel' publish calls

    config_param :buffer_type,        :string,  :default => 'memory'
    config_param :topic,              :string,  :default => nil
    config_param :key,                :string,  :default => nil
    config_param :attrs,              :string, :default => "type:log" 

    unless method_defined?(:log)
      define_method("log") { $log }
    end

    unless method_defined?(:router)
      define_method("router") { Fluent::Engine }
    end

    def configure(conf)
      super
      raise Fluent::ConfigError, "buffer_chunk_records_limit may not exceed 999" if @buffer_chunk_records_limit > 999
      raise Fluent::ConfigError, "'key' must be specified as /path/to/key.json (e.g. service_account .json file)" unless @key
      raise Fluent::ConfigError, "'topic' must be specified as projects/<project-name>/topics/<topic-name>" unless @topic
    end

    def start
      super
      ENV['GOOGLE_APPLICATION_CREDENTIALS']=@key
      pubsub = Pubsub::PubsubService.new
      pubsub.authorization = Google::Auth.get_application_default([Pubsub::AUTH_PUBSUB])
      @client = pubsub
      @client.request_options.retries = 2
      @client.request_options.timeout_sec = 30
      @client.request_options.open_timeout_sec = 30
    end

    def format(tag, time, record)
      { :tag => [tag], :timestamp => Time.at(time).to_datetime.strftime, :record => record }.to_json.to_msgpack
    end

    def publish(giw = 0, data, attributes)
      request = Pubsub::PublishRequest.new(messages: [])
      data.each do |d|
        request.messages << Pubsub::Message.new(data: d, attributes: attributes)
      end
      m = @client.publish_topic(@topic, request)
      log.info "messages count acks for group_#{giw}: ", m.message_ids.size
    rescue => e
      log.error "error publishing record: ", :error=>$!.to_s
      log.error_backtrace
      raise e
    end
    
    def write(chunk)
      messages = []
      chunk.msgpack_each { |m| messages << m }
      
      if messages.length > 0
        # attributes arrive as key:val,key:val,key:val
        attributes = Hash[@attrs.split(",").map {|str| str.split(":")}]
        log.info "messages attributes: ", attributes
        log.info "messages count: ", messages.count
        
        # the messages array is split into multiples of @buffer_chunk_records_limit
        gofmsgs = messages.each_slice(@buffer_chunk_records_limit).to_a

        gid = chunk.hash.abs
        log.info "messages size of group_#{gid}: ", gofmsgs.size
        
        # group of messages is published in parallel
        Parallel.each_with_index(gofmsgs, in_threads: @parallel_in_threads) do |data, i|
          log.info "messages count sent for group_#{gid}-#{i}-#{Parallel.worker_number}: ", data.size
          publish("#{gid}-#{i}-#{Parallel.worker_number}", data, attributes)
        end
      end
    rescue => e
      log.error "unexpected error", :error=>$!.to_s
      log.error_backtrace
      raise e
    end
  end
end
  
