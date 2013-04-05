doc = """
Superforker Poke! The Superpoker!

Usage:
    poke

"""
{docopt} = require 'docopt'
repl = require 'repl'
io_client = require 'socket.io-client'
util = require 'util'

options = docopt(doc)

do () ->
    #this starts up a command line repl, so there are 'sub verbs in here'
    socket = null
    #and here we start
    poker = repl.start
        prompt: ":)"
        input: process.stdin
        output: process.stdout
    .on 'exit', ->
        console.log 'cya'
    #use this for self test
    poker.context.test = (host, port, name, content, args) ->
        message =
            command: name
            stdin: content
            args: args
        socket = io_client.connect("http://#{host}:#{port}")
        socket.on 'connect', ->
            socket.emit 'exec', message, (reply) ->
                console.log "reply to poke #{reply}"
                process.exit()
        ''
