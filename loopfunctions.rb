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
# functions for the main hungrybot loop

def processMessage(message)
    puts "Received message from #{message.from}: #{message.body}"

    # grab the first word of the incoming message in lower case, removing the first \ if present
    com = message.body.split(" ",2)[0].downcase.sub(/^\//,'')
    
    # request for help (ie the command list)
    if (com.eql?("commands") || com.eql?("help")) then
        @loaded.each { |mod|
            @im.deliver(message.from, mod.name)
            mod.commands.each { |command, desc|
                response = "#{command.upcase} - #{desc}"
                @im.deliver(message.from, response)
            }
        }
        return
    else
        # request to one of the modules
        @loaded.each { |mod|
            # hunt through the command list, looking for a match
            mod.commands.each_key { |command|
                if (com.eql?(command.downcase)) then
                    # send command to module in lower case removing the leading / if present
                    request = message.body.downcase.sub(/^\//,'')
                    answer, recipients = mod.doCommand(request, message.from.to_s)
                    
                    # if no recipient specified, default to the person who sent the message
                    if (recipients == nil) then
                        recipients = [message.from]
                    end

                    if (answer != nil) then
                        # if there is an answer, broadcast it to each user line by line
                        recipients.each { |recipient|
                            answer.each_line { |line|
                                @im.deliver(recipient, line)
                            }
                        }
                    end
                    return
                end
            }
        }
    end
    # if all else fails, echo back
    @im.deliver(message.from, message.body)
end

def doTimeTrigger(count)
    @loaded.each { |mod|
        mod.times.each { |time|
            if (count.divmod(time)[1] == 0) then
                # responses will be a hash [info => user to receive]
                responses = mod.doTime(time)
                if (responses != nil) then
                    responses.each { |info, users|
                        users.each { |user| 
                            if (user != nil) then 
                                if (info != nil) then
                                    info.each { |line|
                                        @im.deliver(user, line)
                                    }
                                end
                            end
                        }
                    }
                end
            end
        }
    }
end
