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
            @im.deliver(message.from, "Available commands for CALENDAR:")
            @im.deliver(message.from, "CAL LIST- list all subscribed calendars")
            @im.deliver(message.from, "CAL ADD $name:$ical - receive notifications from the calendar (name to refer to calendar:url of ical file)")
            @im.deliver(message.from, "CAL DEL $name - stop receiving notifications from the calendar (name of calendar)")
            @im.deliver(message.from, "CAL SETTIME $mins - set time ahead to be notified of event (minutes)")
            @im.deliver(message.from, "CAL TIME - shows time ahead to be notified of event (minutes)")