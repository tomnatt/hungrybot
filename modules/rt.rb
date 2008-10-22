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
# RT module for hungrybot
# Periodically gives you a list of your open tickets
#
# Written by Tom Natt, August '08
#

require 'rubygems'
require 'simple-rss'
require "net/https"
require 'uri'

class RT

    attr_reader :name, :commands, :times
    
    
	def initialize
        # file paths
	    rtdirectory = "modules/rt"
	    subscriptionsfile = "#{rtdirectory}/users.txt"
	    configfile = "#{rtdirectory}/rt.config"
	    
	    # defaults for config options
	    rtuser="account-manager"
        rtpassword=""
        
        # read config files 
	    readSubscriptions(subscriptionsfile)
	    readConfig(configfile)
	
	    @name = "RT Module - to subscribe talk to Tom"
		@commands = {'rt_list'=>'List your active RT tickets',
                    'rtlist'=>'as RT_LIST'}
		# frequency that hungrybot reads the tickets to the users
        @times = Array.new
	end
	
	def doCommand(command, sender)
	    if (command =~ /^rt_list$/ || command =~ /^rtlist$/) then
		    return listTickets(sender)
        end
	end
	
	private
	    def readSubscriptions(loc)
	        @users = Hash.new
	        file = File.new(loc, "r")
			file.each { |line|
				if !(line =~ /^\#/) then
					uid,rtid = line.split("=",2)
					@users[uid.strip] = rtid.strip
				end
			}
			file.close
	    end
	    
	    def readConfig(loc)
	        file = File.new(loc, "r")
			file.each { |line|
				if line =~ /^username/ then
					@rtuser = line.split("=",2)[1].strip
				elsif line=~ /^password/ then
					@rtpassword = line.split("=",2)[1].strip
				end
			}
			file.close
        end
        
        def listTickets(sender)
            
            username,location = sender.split("@",2)
            user = @users[username].to_s
    
            # construct feed - we add password after escaping else it all breaks        
            feed = "https://rt.bath.ac.uk/Search/Results.rdf?Query= Owner='"+user+"' AND ( Status = 'new' OR Status = 'open')&user="+@rtuser+"&pass="
            feed = URI.escape(feed)
            url = URI.parse(feed+@rtpassword)
            
            # get the tickets from RT
            http = Net::HTTP.new(url.host, url.port)
            http.use_ssl = true
            data = http.post(url.path,url.query)
            livefeed = SimpleRSS.parse(data.body).items
            
            # return the information
            response = Array.new
            response << "You have #{livefeed.length} new or open RT tickets"
            livefeed.each { |item|
                response << item.title
                response << item.link
            }
            return response
        end
	
end