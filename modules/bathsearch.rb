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
# Search the Uni of Bath website using Google Search Appliances RSS output
#
# Written by Phil Wilson 17/09/2008

require 'simple-rss'
require 'net/http'
require 'cgi'

# first class in the file must be the desired object
class BathSearchModule

	# must have getters for these three items
	attr_reader :name, :commands, :times

	def initialize
		# name is the name of the module (for the HELP option)
		@name = "Bath Search Module"
		# commands is a hash of user commands (ie those that can be said to the bot)
		# to the description of the command (as it appears in HELP).
		# commands should be in lower case (but are accessed in upper case or /lowercase)
		@commands = {'find' => '$searchterm Search the University website',
					'search' => 'As FIND'}
        @times = Array.new
	end

	# doCommand is a method which accepts one of the commands and
	# the user who made the request and triggers an action. Commands are sent
	# from bot to module in lower case
	def doCommand(command, sender)
        return doSearch(command)
	end

	def doSearch(command)
        answer = "No results found!"
        searchterm = command.split(" ",2)[1]
        begin
            # read the feed into an array
            url = URI.parse("http://search.bath.ac.uk/search?site=default_collection&output=xml&client=multifunction_frontend&proxystylesheet=multifunction_frontend&markup=atom&q="+CGI.escape(searchterm))
            res = Net::HTTP.get_response(url).body

            # need to check we got a 200 response here
            if (res == nil) then
                raise 'search results body was nil'
            end

            feed = SimpleRSS.parse(res)

            answer = "Search results for: " +searchterm
            if feed.items.size > 0
                for i in 0..4
                    if feed.items[i] != nil
                        answer=answer+"\n"+feed.items[i].title+"\n"+feed.items[i].link
                    end
                end
            else
                answer += "\nNo results found!"
            end
        rescue SimpleRSSError
            puts  "#{Time.now}: couldn't parse the results from the search for"+searchterm+": "+$!
        rescue Exception
            # something horrible happened
            puts  "#{Time.now}: BathSearch failed to do something: "+$!
        end

        # the return must be an array of strings
		return [answer]
	end

end
