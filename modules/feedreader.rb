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
# feedreader module for hungrybot
#
# Written by Tom Natt, March '08
#
# FUTURE: Allow users to add feeds via the bot, currently adding feeds requires an admin

require 'simple-rss'
require "net/http"

class FeedReader

	attr_reader :name, :commands, :times
	
	def initialize
		# file paths
		@feedreaderdirectory = "modules/feedreader"
		configfile = "#{@feedreaderdirectory}/feedsconfig.txt"
		@subscriptionfile = "#{@feedreaderdirectory}/feeds.txt"
		@lastitemfile = "#{@feedreaderdirectory}/lastmeal.txt"
	
		# defaults for config options
		@feedreaderinterval = 300
		@maxdescription = 600
		@proxy_addr = nil
		@proxy_port = nil

		# read config options and subscriptions
		readConfig(configfile)
		readSubscriptions
	
		@name = "FeedReader Module"
		@commands = {'feeds'=>'list feeds that are available', 
					'list'=>'list all your feeds',
					'add'=>'($feed) subscribe to the given feed',
					'subscribe'=>'as ADD',
					'remove'=>'($feed) unsubscribe from the given feed',
					'unsubscribe'=>'as REMOVE'}
		@times = [@feedreaderinterval]
	end
	
	def doCommand(command, sender)
		if (command =~ /^feeds$/) then
			return getFeeds, [sender]
		elsif (command =~/^list$/) then
			return doList(sender), [sender]
		elsif (command =~ /^add/ || command =~ /^subscribe/) then
			return doSubscribe(command, sender), [sender]
		elsif (command =~ /^remove/ || command =~ /^unsubscribe/) then
			return doUnsubscribe(command, sender), [sender]
		end
	end
	
	def doTime(time)
		if (time == @feedreaderinterval) then
			return pollFeeds
		end
	end
	
	
	private
		def readConfig(loc)
			file = File.new(loc, "r")
			file.each { |line|
				if line =~ /^interval/ then
					@feedreaderinterval = line.split("=",2)[1].strip.to_i
				elsif line=~ /^maxlength/ then
					@maxdescription = line.split("=",2)[1].strip.to_i
				elsif line=~ /^subscriptionfile/ then
					@subscriptionfile = @feedreaderdirectory + "/" + line.split("=",2)[1].strip
				elsif line=~ /^lastitemfile/ then
					@lastitemfile =  @feedreaderdirectory + "/" + line.split("=",2)[1].strip
				elsif line=~ /^proxy_addr/ then
					@proxy_addr = line.split("=",2)[1].strip
				elsif line=~ /^proxy_port/ then
					@proxy_port = line.split("=",2)[1].strip
				end
			}
			file.close
		end
		
		def readSubscriptions
			@subscriptions = Hash.new
			file = File.new(@subscriptionfile, "r")
			file.each { |line|
			if !(line =~ /^\#/) then
				url,allusers = line.split(" : ",2)
				users = allusers.split(",")
				users.each { |user|
					user.strip!
				}
				@subscriptions[url] = users
			end
			}
			file.close
		end
		
		def pollFeeds
			response = Hash.new
            # read in the last article
            lastarticles = Hash.new
            if (File.exists?(@lastitemfile)) then
                file = File.new(@lastitemfile, "r")
                file.each { |line|
                    url,last = line.split(" : ",2)
                    lastarticles[url] = last.strip
                }#{feedreaderdirectory}
                file.close
            end
            
            # for each feed read out any new articles and update the last article
            @subscriptions.keys.each { |feed|
				begin
					# read the feed into an array
					url = URI.parse(feed)
					req = Net::HTTP::Get.new(url.path)
					res = nil
					if (@proxy_addr == nil || @proxy_port == nil) then
						res = Net::HTTP.get(url) {|http|
							http.request(req)
						}
					else
						res = Net::HTTP::Proxy(@proxy_addr, @proxy_port).get(url) {|http|
							http.request(req)
						}
					end
			
					# need to check we got a 200 response here
					if (res == nil) then
						raise feed +' body was nil'
					end
			
					livefeed = SimpleRSS.parse(res).items
                rescue Exception
                    # something horrible happened
                    puts  "#{Time.now}: Hungrybot failed to parse #{feed}: "+$!
                end
					
				# process feed if we've read it properly	
				if (livefeed != nil) then	
                    # read the feed if it is not a new one
                    if (lastarticles.keys.include?(feed)) then 
                        lastitem = lastarticles[feed]
                        # read out all new articles for those subscribed (index 0 is newest post)
                        j = 0
                        while (j < livefeed.length && !(livefeed[j].link.strip.eql?(lastitem))) do
                            # response for subscribers
                            # send title if it isn't empty
                            title = ""
                            if (!(livefeed[j].title.eql?("")) && !(livefeed[j].title == nil)) then
                                title = livefeed[j].title
                            end
                            # send the desc of the feed if it isn't empty and isn't longer than configured length
                            description = ""
                            if (!(livefeed[j].description.eql?("")) && !(livefeed[j].description == nil) && !(livefeed[j].description.length > @maxdescription)) then
                                description = "("+livefeed[j].description+")"
                            end
                            text = "Hey! "+title + ": " +livefeed[j].link + " #{description}"
                            response[text] = @subscriptions[feed]
                            j += 1
                        end
                    end
                    # set the last article
                    lastarticles[feed] = livefeed.first.link
                end
            }
            
            # write the updated last articles to file
            file = File.new(@lastitemfile, "w")
            lastarticles.keys.each { |url|
                line = url + " : " + lastarticles[url] + "\n"
                file << line
            }
            file.close
			return response
		end
		# end of pollFeeds
		
		def writeConfig
			# write a modified config back to file
			file = File.new(@subscriptionfile, "w")
			@subscriptions.keys.each { |url|
				users = ""
				@subscriptions[url].each { |user|
					if users.eql?("") then
						users = user
					else
						users = users + "," + user
					end
				}
				line = url + " : " + users + "\n"
				file << line
			}
			file.close
		end
		
		def chopLocation(jid)
			# remove location information from the jid
			username,location = jid.split("/",2)
			return username
		end
		
		def getFeeds
			# list available feeds
			answer = Array.new
            answer << "The currently available feeds are:"
            @subscriptions.keys.each { |feed|
                answer << feed
            }
            return answer
		end
		
		def	doList(sender)
			sender = chopLocation(sender)
			answer = Array.new
            answer << "Currently you are subscribed to:"
            # list my subscribed feeds
            @subscriptions.select{|k,v| v.include?(sender)}.each {|feed|
                answer << feed[0]
            }
			return answer
		end
		
		def doSubscribe(command, sender)
			answer = Array.new
			sender = chopLocation(sender)
            # subscribe me to the given feed
            command,feed = command.split(" ",2)
            if @subscriptions.has_key?(feed) then
                if (!(@subscriptions[feed].include?(sender))) then
                    @subscriptions[feed].push(sender)
                    writeConfig
                    answer << "Ok, done"
                else
                    answer << "You already subscribe to that feed"
                end
            else
                answer << "Sorry, your feed url is pure balls"
            end
			return answer
		end
		
		def doUnsubscribe(command, sender)
			answer = Array.new
			sender = chopLocation(sender)
            # remove me from the given feed
            command,feed = command.split(" ",2)
            if @subscriptions.has_key?(feed) then
                if @subscriptions[feed].include?(sender) then
                    @subscriptions[feed].delete(sender)
                    writeConfig
					answer << "Ok, done"
                else
                    answer << "You don't subscribe to that feed"
                end
            else
                answer <<  "Sorry, your feed url is pure balls"
            end
			return answer
		end
end
