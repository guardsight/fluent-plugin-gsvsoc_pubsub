#
# NAME - gsvsoc_pubsub_test
#
# SYNOPSIS
# rake test
# rake test topic=projects/<project-name>/topics/<topic-name> key=</path/to/secret/key.json>
#
# DESCRIPTION
# Test class for out_gsvsoc_pubsub
# 
# AUTHOR
# johnmac@guardsight.com
# 
# SEE ALSO
# W-0085
# https://github.com/guardsight
# http://docs.fluentd.org/v0.14/articles/api-plugin-output#writing-tests
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


require_relative "../../test_helper"

class GsvsocPubSubOutputTest < Minitest::Test
  
  CONFIG = <<-EOC
    type gsvsoc_pubsub
    topic topic_name
    key key_file
    flush_interval 1
  EOC

  ReRaisedError = Class.new(RuntimeError)
  
  def setup
    Fluent::Test.setup
  end
  
  def create_driver(conf = CONFIG)
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::GsvsocPubSubOutput).configure(conf)
  end

  # "Test configuration mappings"
  def test_configure
    d = create_driver()
    
    assert_equal 'topic_name', d.instance.topic
    assert_equal 'key_file', d.instance.key
    assert_equal 1, d.instance.flush_interval
  end

  # "Test message submission - rake test topic=projects/<project-name>/topics/<topic-name> key=</path/to/secret/key.json>"
  def test_write
    if ENV['topic'] && ENV['key']
      d = create_driver(<<-EOC)
	type gsvsoc_pubsub
	topic #{ENV['topic']}
	key #{ENV['key']}
	flush_interval 1
      EOC
      d.run do
        record = {"message" => "gsvsoc_pubsub write success!"}
        d.emit(record)
        # $ gcloud alpha pubsub subscriptions pull <topic-name> --auto-ack
        # {"tag":["test"],"timestamp":"1970-01-01T00:00:00-00:00","record":{"message":"gsvsoc_pubsub write success!"}}
      end
    end
    pass
  end

end


