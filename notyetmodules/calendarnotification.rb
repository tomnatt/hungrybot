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
#
# calendarnotication.rb
#
# Object using icalendar gem to read an ical file from a url 
# and return appointments within a given time (defined in minutes)
#
# String responses in the form $EventSummary, $location ($dtstart - $dtend)
#
# written by Tom Natt, Feb '08

require 'rubygems'
require 'icalendar'
require 'net/http'

class CalendarNotification

    attr_accessor :user, :url, :ahead
    attr_reader :daysevents, :daysremainingevents

    public
        def initialize(user, urls, ahead)
            @user = user
            @urls = urls
            @ahead = DateTime.now + Date.time_to_day_fraction(0, ahead, 0)
            readCalendars
            updateTodaysEvents
            updateTodaysLiveEvents
        end
        
        def updateCalendars
            readCalendars
            updateTodaysEvents
            updateTodaysLiveEvents
        end 
        
        #def nextEvent
        #    return @cal.events.first
        #end

        def getAlerts
            # return an array of all events in the next @ahead minutes
            eventstrings = Array.new
            @daysremainingevents.each { |event|
                if event.dtstart < @ahead then
                    eventstrings << generateTimeString(event)
                end
            }
            return eventstrings
        end
        
        def getTodaysEvents
            # return an array of all events for today in string form
            eventstrings = Array.new
            @daysevents.each { |event|
                eventstrings << generateTimeString(event)
            }
            return eventstrings
        end
        
        def getTodaysRemainingEvents
            # return an array of all remaining events for today in string form
            eventstrings = Array.new
            @daysremainingevents.each { |event|
                eventstrings << generateTimeString(event)
            }
            return eventstrings
        end
        
        def updateTodaysEvents
            # maintain a list of events for today
            today = Date::today
            @daysevents = Array.new
            @cals.each { |cal|
                cal.events.each { |event|
                    if event.dtstart.to_s =~ /^#{today}/
                        @daysevents << event
                    end
                }
            }
        end
        
        def updateTodaysLiveEvents
            # maintain a list of events for today that haven't yet occurred
            now = DateTime::now()
            @daysremainingevents = Array.new
            @daysevents.each { |event|
                # based off end time as we could be in the middle of a meeting when request made
                if event.dtend >=now then
                    @daysremainingevents << event
                end
            }
        end
    
    private
        def readCalendars
            @cals = Array.new
            @urls.each { |url|
                cal_data = Net::HTTP.get_response(url).body
                @cals << Icalendar.parse(cal_data).first
            }
        end

        def generateTimeString(event)
            # set the times
            starttime = ""
            if event.dtstart != nil then
                starttime = event.dtstart.strftime("%H:%M")
            end
            endtime = ""
            if event.dtend != nil then
                endtime = event.dtend.strftime("%H:%M")
            end
            times = "("+starttime+" - "+endtime+")"

            # set the name
            name = ""
            if event.summary != nil then
                name = event.summary
            end

            # set the location
            location = ""
            if event.location != nil then
                location = event.location
            end
                
            # set the entire string and return it
            return name + ", " + location + times
        end

end
