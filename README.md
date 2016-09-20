# fluent-plugin-gsvsoc_pubsub

**Build Status**

master:
[![Build Status](https://travis-ci.com/guardsight/fluent-plugin-gsvsoc_pubsub.svg?token=vj7aEcqv8qvpJXs3fVLL&branch=master)](https://travis-ci.com/guardsight/fluent-plugin-gsvsoc_pubsub)
develop:
[![Build Status](https://travis-ci.com/guardsight/fluent-plugin-gsvsoc_pubsub.svg?token=vj7aEcqv8qvpJXs3fVLL&branch=develop)](https://travis-ci.com/guardsight/fluent-plugin-gsvsoc_pubsub)

# SYNOPSIS

Event Delivery Service: [Fluentd](http://www.fluentd.org/) \[fluent-plugin-gsvsoc_pubsub] -> [Google Pub/Sub](https://cloud.google.com/pubsub/) <- \[gs-vsoc-subscriber] [GuardSight](https://www.guardsight.com)

# DESCRIPTION

## Prologue
[Treasure Data's Fluentd](http://www.fluentd.org/) is an open source tool for collecting, parsing, transforming, and storing intelligence streams (logs / messages). Fluentd tries to structure data as JSON as much as possible to unify all facets of processing log data: collecting, filtering, buffering, and outputting logs across multiple sources and destinations.

[Google's Pub/Sub](https://cloud.google.com/pubsub/) is a secure and highly available communication system providing many-to-many, asynchronous messaging that decouples senders and receivers. A publisher application creates and sends messages to a topic. Subscriber applications create a subscription to a topic to receive messages from it.

[GuardSight](https://www.guardsight.com) uses these technologies as an Event Delivery Service to distribute messages for its Security Point Of Presence (SPOP) and Virtual Security Operations Center (VSOC) systems. [fluent-plugin-gsvsoc_pubsub](https://github.com/guardsight/fluent-plugin-gsvsoc_pubsub) is a plugin for the Fluentd agent that provides a coupling between an SPOP and Pub/Sub.

Features of the plugin:

1. Flexible message sources
2. Reliable message delivery
3. Parallel message processing
4. Encrypted message delivery
5. Sufficient message rate throughput
6. Stable embedded version of Ruby with td-agent

## Prerequisites
1. Google Pub/Sub Account
2. Authorized Administrative Access/Roles On Plugin Systems and Pub/Sub Account
3. GEMS
    1. google-api-client
    2. googleauth
    3. parallel
	4. fluent-plugin-ping-message

# INSTRUCTION

## Install Fluentd (td-agent)

Ubuntu 14.04

``` Shell
	1. $ curl https://packages.treasuredata.com/GPG-KEY-td-agent | sudo apt-key add -
	2. $ echo "deb http://packages.treasuredata.com/2/ubuntu/trusty/ trusty contrib" | sudo tee /etc/apt/sources.list.d/treasure-data.list
	3. $ sudo apt-get update
	4. $ sudo apt-get install td-agent
```

Ubuntu 16.04

``` Shell
	1. $ curl https://packages.treasuredata.com/GPG-KEY-td-agent | sudo apt-key add -
	2. $ echo "deb http://packages.treasuredata.com/2/ubuntu/xenial/ xenial contrib" | sudo tee /etc/apt/sources.list.d/treasure-data.list
	3. $ sudo apt-get update
	4. $ sudo apt-get install td-agent
```

## Install the plugin

``` Shell
    1. $ sudo /usr/sbin/td-agent-gem install fluent-plugin-gsvsoc_pubsub --no-document 
	2. $ sudo /usr/sbin/td-agent-gem install fluent-plugin-ping-message --no-document 
    -or-
    1. $ git clone https://github.com/guardsight/fluent-plugin-gsvsoc_pubsub.git 
    2. $ cd fluent-plugin-gsvsoc_pubsub; sudo cp lib/fluent/plugin/out_gsvsoc_pubsub.rb /etc/td-agent/plugin
	3. $ sudo /usr/sbin/td-agent-gem install google-api-client --no-document 
	4. $ sudo /usr/sbin/td-agent-gem install googleauth --no-document 
	5. $ sudo /usr/sbin/td-agent-gem install parallel --no-document 
	6. $ sudo /usr/sbin/td-agent-gem install fluent-plugin-ping-message --no-document 

``` 

## Add a custom configuration file

``` ApacheConf
/etc/td-agent/td-agent.conf:
# If changes have not been made to /etc/td-agent.conf then 
# replace it with this otherwise add this to the first line:

    @include /etc/td-agent/conf.d/*.conf
```

``` ApacheConf
/etc/td-agent/conf.d/td-agent.gsvsoc.conf:
     
    <source>
    @type syslog
    tag syslog.tcp
    port 5140
    bind 127.0.0.1
    protocol_type tcp
    </source>
     		  
    <source>
    @type ping_message
    tag health.ping
    interval 300
    data hello from ${hostname}
    </source>
     				  
    <match health.ping>
    @type gsvsoc_pubsub
    buffer_type memory
    topic projects/<project-name>/topics/<topic-name> # replace <project-name> and <topic-name> with appropriate values
    key /path/to/secret/pubsub-key.json # secret key - protect accordingly!
    attrs type:health # comma sep for multiple attrs - foo:bar,biz:baz
    </match>
     						
    <match syslog.**>
    @type gsvsoc_pubsub
    buffer_type file
    buffer_path /var/log/td-agent/buffer/gsvsoc_pubsub*.buffer
    topic projects/<project-name>/topics/<topic-name> # replace <project-name> and <topic-name> with appropriate values
    key /path/to/secret/pubsub-key.json # secret key - protect accordingly!
	attrs type:log # comma sep for multiple attrs - foo:bar,biz:baz
    </match>
```

## Install the pubsub secret key

   /path/to/secret/pubsub-key.json
	   
``` Shell
    Example: /opt/gs-vsoc/pubsub/etc/locker/gs-pubsub-wo.json
	1. $ cd /opt/gs-vsoc/pubsub/etc/locker 
	2. $ sudo chown root:gs-vsoc gs-pubsub-wo.json; sudo chmod 440 gs-pubsub-wo.json; sudo usermod -a -G gs-vsoc td-agent
```

## Start / reload the service

``` Shell
	1. $ sudo service td-agent <start|reload>
```

## Push messages

logger

``` Shell
	1. $ logger -V
	util-linux 2.27.1
	2. $ /usr/bin/logger --rfc3164 -P 5140 -n 127.0.0.1 --tcp -t foo-tag "GO SOX!"
``` 

netcat
``` Shell
	1. $ echo "<13>$(date "+%h %d %H:%M:%S") $(hostname -s) $(whoami): GO SOX!" | nc 127.0.0.1 5140
```

rsyslog
``` Shell
	/etc/rsyslog.d/10-d_gsvsoc.conf
		*.* @@127.0.0.01:5140
```

syslog-ng
``` Shell
	/etc/syslog-ng/custom.d/10-d_gsvsoc.conf: 
		destination d_tcp_gsvsoc { network("127.0.0.1" port(5140) flush-lines(2) flags(no-multi-line)); }; # adjust flush-lines in production
	/etc/syslog-ng/custom.d/10-l_tcpEverything.conf: 
		log {   source(s_local); source(s_network); destination(d_tcp_gsvsoc); };
```

syslog
``` Shell
	/etc/syslog.conf:
		*.* @@127.0.0.01:5140
```

## Pull messages

gcloud
``` Shell
	1. $ gcloud alpha pubsub subscriptions pull <subscription-name> --auto-ack
	{"tag":["syslog.tcp.user.notice"],"timestamp":"1970-00-00T00:00:00-00:00","record":{"host":"myhost","ident":"syslog.notice","message":"GO SOX!"}} | 00000000000000 | type=log 
``` 

## Diagnostics

``` Shell	
	1. $ sudo tail -f /var/log/td-agent/td-agent.log
	1970-01-01 00:00:00 -0000 [info]: listening syslog socket on 127.0.0.1:5140 with tcp
	1970-01-01 00:00:00 -0000 [info]: listening fluent socket on 0.0.0.0:24224
	1970-01-01 00:00:00 -0000 [info]: listening dRuby uri="druby://127.0.0.1:24230" object="Engine"
	1970-01-01 00:00:10 -0000 [info]: messages count: 3 /* total message count for this chunk */
	1970-01-01 00:00:10 -0000 [info]: messages size of group_4473929821954934392: 1 /* number of groups slices */
	1970-01-01 00:00:10 -0000 [info]: messages count sent for group_4473929821954934392-0-0: 3 /* number of messages pushed for this group-slice-worker */
	1970-01-01 00:00:11 -0000 [info]: messages count acks for group_4473929821954934392-0-0: 3 /* number of messages pulled for this group-slice-worker */
```

``` Shell
	1. $ sudo /usr/sbin/td-agent -v
```

## Tests

``` Shell
	1. $ bundle exec rake test
	2. $ bundle exec rake test topic=projects/<project-name>/topics/<topic-name> key=</path/to/secret/pubsub-key.json>
	   1. $ gcloud alpha pubsub subscriptions pull <subscription-name> --auto-ack
	   {"tag":["test"],"timestamp":"1970-01-01T00:00:00-00:00","record":{"message":"gsvsoc_pubsub write success!"}}
```

# NOTES

https (tcp/443) to the following destination IPV4/IPV6 addresseses are required if egress firewall / proxy controls are in use:
``` Shell
	$ host pubsub.googleapis.com
	pubsub.googleapis.com is an alias for googleapis.l.google.com.
	googleapis.l.google.com has address 216.58.193.202
	googleapis.l.google.com has address 216.58.216.10
	googleapis.l.google.com has address 172.217.4.138
	googleapis.l.google.com has address 216.58.217.202
	googleapis.l.google.com has address 216.58.219.42
	googleapis.l.google.com has address 172.217.4.170
	googleapis.l.google.com has IPv6 address 2607:f8b0:4007:808::200a

```

# SEE ALSO
1. http://www.fluentd.org/
2. https://cloud.google.com/pubsub/

Copyright (c) GuardSight (tm), Inc.
