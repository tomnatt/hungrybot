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
# Tell a user what events are in What's On
#
# Written by Phil Wilson 18/09/2008

require 'simple-rss'
require 'net/http'
require 'chronic'

# first class in the file must be the desired object
class WhatsOnModule

	# must have getters for these three items
	attr_reader :name, :commands, :times

	def initialize
		# name is the name of the module (for the HELP option)
		@name = "What's On Module"
		# commands is a hash of user commands (ie those that can be said to the bot)
		# to the description of the command (as it appears in HELP).
		# commands should be in lower case (but are accessed in upper case or /lowercase)
		@commands = {'whatson'=>'Find out what\'s on at the University'}
        @times = Array.new
	end

	# doCommand is a method which accepts one of the commands and
	# the user who made the request and triggers an action. Commands are sent
	# from bot to module in lower case
	def doCommand(command, sender)
        # use Chronic to get the date and pass that through to getWhatsOn
        # http://chronic.rubyforge.org/
        mydate = command.split(" ",2)[1]

        if mydate!=nil
            begin
                day = Chronic.parse(mydate).day
                month = Chronic.parse(mydate).month
                year = Chronic.parse(mydate).year
            rescue Exception
                return ["Sorry, I couldn't understand that date! Try again"]
            end
        else
            now = Time.new
            day = now.day
            month = now.month
            year = now.year
        end
        
        return getWhatsOn(day.to_s, month.to_s, year.to_s)
	end    

	def getWhatsOn(whichday, whichmonth, whichyear)
        answer = "No events found"
        begin
            # read the feed into an array
            whatsonUrl = "http://www.bath.ac.uk/whats-on/rssevents.php?period=1&currDay="+whichday+"&currMonth="+whichmonth+"&currYear="+whichyear
            #puts whatsonUrl
            url = URI.parse(whatsonUrl)
            res = Net::HTTP.get_response(url).body

            # need to check we got a 200 response here
            if (res == nil) then
                raise 'search results body was nil'
            end

            feed = SimpleRSS.parse(res)

            answer = "What's on:"
            if feed.items.size > 0
                for i in 0..4
                    if feed.items[i] != nil
                        answer=answer+"\n"+feed.items[i].title+"\n"+feed.items[i].link
                    end
                end
            else
                answer += "\nNo events!"
            end

        rescue Exception
            # something horrible happened
            puts  "#{Time.now}: WhatsOn failed to do something: "+$!
        end

        # the return must be an array of strings
		return [answer]
	end

end
