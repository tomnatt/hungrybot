# Getting started with Hungrybot

Hungrybot logs in to a Jabber/XMPP server and responds to commands you send. 
Each command is provided by a Ruby file in the modules/ directory. To write a 
new module see the "Writing modules" section below.

First up, a warning! This code was only written to work at the University of 
Bath, UK (http://www.bath.ac.uk/) so there may be parts which don't work
on your setup. With that in mind:

For help, ideas or to submit patches contact web-support@bath.ac.uk

We ported hungrybot to ruby 1.9.

## Getting started

This will get the basics of hungrybot up and running - some bits won't work!

* Make a copy of hungryconfig.txt.example and rename it to hungryconfig.txt
* open hungryconfig.txt change the username and password fields to a user with
an account on your Jabber/XMPP server
* Open modules/feedreader and make a copy of feeds.txt.example and rename it
to feeds.txt
* Open modules/rt and make a copy of users.txt.example and rename it
to users.txt
* from the command line run 'bundle install'
* from the command line run 'ruby hungrybot.rb'
* add hungrybot to your roster and send it the message "commands"

Congratulations! Hungrybot works!

Configuring the Feed Reader module
----------------------------------

The feed reader module provides a fixed list of feeds which users can receive
updates from.

* Open modules/feedreader/feeds.txt
* For each feed you want people to be able to subscribe to put the URL on a 
new line followed by a space and a colon
* Done! Users can now list the available feeds by typing "feeds" and subscribe
to feeds by sending "add feedurl" (which will updates feeds.txt) 

Writing modules
---------------

There is a demo module called hellomodule.rb.example in the modules/directory.
Every module MUST have two methods: initialise() and doCommand(command, sender)
A module can be configured to run a method on a regular interval by adding a
doTime(time) method.

Background
----------

Hungrybot was written almost exclusively by Tom Natt after a couple of 
"wouldn't it be nice if..." conversations. Thanks Tom!
