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
# personfinder module for hungrybot
#
# Written by Tom Natt, March '08

require "nokogiri"
require "net/http"

class PersonFinder

    attr_reader :name, :commands, :times
    
    def initialize
        @name = "Personfinder Module"
        @commands = {'whois' => '($name / $uid) search ldap for the details of person',
                    'who' => 'As whois'}
        @times = Array.new
    end
    
    def doCommand(command, sender)
        return findPerson(command)
    end

    def findPerson(command)
        # object to return
        response = Array.new
        id = command.split(" ",2)[1]
        if id == nil then
            response << "You must specify a name or username"
        elsif id.length <= 3 then
            response << "You must give me at least three characters"
        else
            url = URI.parse("http://www.bath.ac.uk/contact/?search=basic&pgeneralsearch="+URI.escape(id)+"&submit=Search")
            # get the XML data as a string
            xml_data = Net::HTTP.get_response(url).body
            doc = Nokogiri::HTML(xml_data)
            results = doc.search('.vcard')
            if (results.length == 0) then
                response << "I couldn't find anyone with those details, sorry!"
            elsif (results.length <= 10) then 
                #response << "Name, Job title, Username, Phone number"
                results = doc.search('.vcard').each { |card|
                    # find and add the person's name
                    namesoup = card.search('.fn')

                    # remove <span> from input
                    name = Array.new
                    namesoup.search('a').each { |t|
                        name << t.content
                    }
                    name = name.join(' ')

                    # find and add the person's username, removing any <span>s
                    username = ""
                    card.search('.username').each { |t|
                        username = t.content
                    }

                    # find and add the person's job title
                    title = ""
                    card.search('.title').each { |t|
                        if (t != nil && t.content != nil) then
                            title = t.content
                        else
                            t = ""
                        end
                    }

                    # find and add the person's phone number
                    phones = Array.new
                    card.search('.tel').each { |number|
                        phones << number.search('.value a')[0].content.strip
                    }
                    phonestring = ""
                    if phones.length > 0
                        phonestring = "Their extension is "+phones.join(" or ")
                    end                    
                    response << name + " (" + username + ") is a " + title + ". " + phonestring
                }
            else
                response << "Your search has found too many people - please be more specific"
            end         
        end
        return response
    end
end
