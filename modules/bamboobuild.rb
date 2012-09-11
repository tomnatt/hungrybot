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
# Rebroadcast the output from Bamboo build plans
#
# Written by Tom Natt, September '12

# first class in the file must be the desired object
class BambooBuild
        
    # must have getters for these three items
    attr_reader :name, :commands, :times

    def initialize
        # name is the name of the module (for the HELP option)
        @name = "Bamboo build module"
        # commands is a hash of user commands (ie those that can be said to the bot)
        # to the description of the command (as it appears in HELP).
        # commands should be in lower case
        @commands = {'homepage'=>'broadcast build message to group'}
        # times is an array of the time (in seconds) when things are fired off
        @times = Array.new
    end
        
    # doCommand is a method which accepts one of the commands and 
    # the user who made the request and triggers an action. Commands are sent 
    # from bot to module in lower case
    def doCommand(command, sender)
        if (command =~ /^homepage/) then
            recipients = [Jabber::JID.new("example@example.com")]
            # any response should be an array of strings (in case of multiline response), can optionally also include an array of recipient JIDs
            return broadcastHomepageBuild(command), recipients
        end 
    end

    def broadcastHomepageBuild(command)
        response = Array.new

        # match blah@bath and capture blah
        regex = /([a-z0-9]+)@bath/
        commit_list = command.scan(regex)

        # match build 15 and capture 15
        regex = /build ([0-9]+)/
        build = command.scan(regex)

        if (command =~ /live/) then
            if (command =~ /successful/) then
                response << "Live homepage updated successfully. " + 
                            (if commit_list.length > 0 then "Go and congratulate " + commit_list.join(" and ") else "" end)
                response << "All changes can be see here:"
                response << "http://vcs.example.com/bamboo/browse/PROJECT-PLAN-" + build[0].to_s + "/commit"
                response << ""
                response << "View the awesome at:"
                response << "http://www.example.com/homepage/"
            else
                response << "Live homepage update has failed. PANIC! " + 
                            (if commit_list.length > 0 then "Especially if you're " + commit_list.join(" or ") else "" end)
                response << "All changes can be see here:"
                response << "http://vcs.example.com/bamboo/browse/PROJECT-PLAN-" + build[0].to_s + "/commit"
                response << ""
                response << "Check this is still there!"
                response << "http://www.example.com/homepage/"
            end
        elsif (command =~/test/) then
            if (command =~ /successful/) then
                response << "Test homepage updated successfully. " + 
                            (if commit_list.length > 0 then "This message brought to you by " + commit_list.join(" and ") else "" end)
                response << "All changes can be see here:"
                response << "http://vcs.example.com/bamboo/browse/PROJECT-PLAN-" + build[0].to_s + "/commit"
                response << ""
                response << "View the new awesome at:"
                response << "http://www.test.example.com/homepage/"
            else
                response << "Test homepage update has failed. "
                            (if commit_list.length > 0 then "It has been broken by " + commit_list.join(" or ") else "" end)
                response << "All changes can be see here:"
                response << "http://vcs.example.com/bamboo/browse/PROJECT-PLAN-" + build[0].to_s + "/commit"
                response << ""
                response << "View the fail at:"
                response << "http://www.test.example.com/homepage/"
            end
        end
        
        return response
    end

end
