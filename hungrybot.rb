#   Copyright 2008 University of Bath
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#
# HungryBot
# v4.0 written by Tom Natt
#
# Loose Ruby framework for a jabber bot
# Allows additional functionality to be added via a module mechanism
#
# ISSUES: the sleep statements are a bit crap. This can probably be gotten round by sending
# code blocks to be called on callback. They exist to ensure we have a response from the 
# server before we try to use it
#

require 'rubygems'
require 'xmpp4r'
require 'xmpp4r/roster/iq/roster'
require 'xmpp4r-simple'

require 'loopfunctions'

# config parameters all default to nil
@username = nil
@password = nil
@modules = nil
@pause = 1

# read in the config file
@configfile = "./hungryconfig.txt"
file = File.new(@configfile, "r")
file.each { |line|
	if line =~ /^username/ then
		@username = line.split("=",2)[1].strip
	elsif line=~ /^password/ then
		@password = line.split("=",2)[1].strip
	elsif line=~ /^modules/ then
		@modules = line.split("=",2)[1].strip
	elsif line=~ /^pause/ then
		@pause = line.split("=",2)[1].strip.to_i
	end
}
file.close

# dynamically load all modules from the given directory
@loaded = Array.new
# how many iterations to loop for before reseting counter to 0
@maxcount = 1
Dir.new(@modules).entries.each { |file| 
	if file =~ /.+\.rb$/ then
		require "#{@modules}/#{file}"
		# for each module find the object name and initialize it
		modnum = 0
		modulefile = File.new("#{@modules}/#{file}", "r")
		modulefile.each { |line|
			if line =~ /^class (\w+)/ then
				mod = $1
				mod = Module.const_get(mod).new
				mod.times.each { |time|
					if (time > @maxcount) then
						@maxcount = time
					end
				}
				@loaded << mod
				break
			end
		}
	end
}

# Connect
@im = Jabber::Simple.new(@username, @password)
@im.status(nil,"Available")
@im.accept_subscriptions = true
# create query for contacts TODO: fix this - it doesn't work
@friends = Array.new
@im.client.add_iq_callback { |i|
    @friends = Array.new
    if i.type == :result and i.query.kind_of?(Jabber::Roster::IqQueryRoster)
        i.query.each_element { |e|
            @friends << e.jid.to_s
        }
    end
}

sleep 5

# the bot loop
count = 0
loop do
    
    count += 1
    #puts count
    
    # respond to user commands
    @im.received_messages do |message|
        processMessage(message)
    end

	doTimeTrigger(count)
	
	if count == @maxcount
		count = 0
	end

	# Every 20 seconds ensure we remain connected
    if count.divmod(20)[1] == 0 then
        @im.status(nil,"Available")
    end
    
    # pause in loop
    sleep @pause
end
