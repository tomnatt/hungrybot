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
            mod.commands.each_key { |command|
                if (com.eql?(command.downcase)) then
                    # send command to module in lower case removing the leading / if present
                    request = message.body.downcase.sub(/^\//,'')
                    answer = mod.doCommand(request, message.from.to_s)
                    if (answer != nil) then
                        answer.each { |line|
                            @im.deliver(message.from, line)
                        }
                    end
                    return
                end
            }
        }
    end
    default_action(message)
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
                                @im.deliver(user, info)
                            end
                        }
                    }
                end
            end
        }
    }
end

def default_action(message)
    # if the message starts with four numbers, try and find a matching phone number owner
    # otherwise just echo the message back to the sender
    if message.body =~ /\d{4}/
        # we already have PhoneFinder somewhere in @loaded - is looping the best way to find it?
        # PhoneFinder.new
    else
        @im.deliver(message.from, message.body)
    end
end