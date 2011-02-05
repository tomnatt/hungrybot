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

require "rubyful_soup"
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
        else
            url = URI.parse("http://www.bath.ac.uk/contact/?search=basic&pgeneralsearch="+URI.escape(id)+"&submit=Search&embed=true")
            # get the XML data as a string
            xml_data = Net::HTTP.get_response(url).body
            soup = BeautifulSoup.new(xml_data)
            results = soup.find_all(nil, :attrs => {'class' => 'vcard'})
              if (results.length == 0) then
                response << "I couldn't find anyone with those details, sorry!"
              elsif (results.length <= 10) then
                #response << "Name, Job title, Username, Phone number"
                soup.find_all(nil, :attrs => {'class' => 'vcard'}).each { |card|
                    # find and add the person's name
                    name = card.find(nil, :attrs => {'class' => 'fn'})
                    if (name != nil && name.a.string != nil) then
                        name = name.a.string
                    else
                        name = ""
                    end
                    # find and add the person's username
                    username = card.find(nil, :attrs => {'class' => 'username'})
                    if (username != nil && username.string != nil) then
                        username = username.string
                    else
                        username = ""
                    end
                    # find and add the person's job title
                    title = card.find(nil, :attrs => {'class' => 'title'})
                    if (title != nil && title.string != nil) then
                        title = title.string
                    else
                        title = ""
                    end
                    # find and add the person's phone number
                    phones = Array.new
                    card.find_all(nil, :attrs => {'class' => 'tel'}).each { |number|
                        phones << number.find(nil, :attrs => {'class' => 'value'}).string.strip
                    }
                    phonestring = ""
                    if phones.length>0
                        phonestring = "Their extension is "+phones.join(" or ")
                    end
                    response << name+" ("+username+") is a "+title+". "+phonestring
                }
              else
                response << "Your search has found too many people - please be more specific"
              end
        end
        return response
    end
end
