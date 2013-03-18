#!/usr/bin/env ./node_modules/coffee-script/bin/coffee
# vim: set syntax=coffee:

doc = """
Superforker!

Usage:
    superforker start [PORT]
    superforker stop
    superforker poke

Arguments:
    PORT  TCP port, serves HTTP and socket IO here [default: 8080]
"""

{docopt} = require 'docopt'
path = require 'path'
crypto = require 'crypto'
child_process = require 'child_process'

options = docopt(doc)

#docopt doesn't quite understand defaults for positionals
options.PORT = options.PORT or '8080'

console.log options


#It's a bird, it's a plane, it's GUID-like!
guid_like = () ->
    hash = crypto.createHash 'md5'
    for argument in arguments
        hash.update "#{argument}", 'utf8'
    hash.digest 'hex'

#here are all the root level verbs, options will be in scope, so
#we aren't bothering to pass them, just nice places so each has their
#own function induced variable scope
verbs =
    start: () ->
        #fire up express with socket io
        app = require('express')()
        server = require('http').createServer(app)
        io = require('socket.io').listen(server)
        error_count = 0
        cwd = process.cwd()
        #running of commands via GET, nothing is routed to STDIN
        handleError = (response, error, stdout, stderr) ->
            #big old error object in a JSON ball
            error =
                id: guid_like(Date.now(), error_count++)
                at: Date.now()
                error: error
                message: stderr.toString()
            errorString = JSON.stringify(error)
            #for out own output so we can sweep this up in server logs
            process.stderr.write errorString
            process.stderr.write "\n"
            response.status(500).end errorString
        app.get '/*', (request, response) ->
            toRun = path.join cwd, request.path
            response.set 'Content-Type', 'application/json'
            options =
                env:
                    METHOD: 'GET'
            child_process.execFile toRun, options, (error, stdout, stderr) ->
                if error
                    handleError response, error, stdout, stderr
                else
                    #and a program that runs just fine, go ahead and
                    #just send back the results, we're counting on you
                    #to return JSON, since we are telling the client this
                    #is going to be JSON above
                    response.end(stdout)
                    #and we'll keep the error bits to our server for logging
                    process.stderr.write stderr
        #POST is a lot like GET, but we don't repeat the comments
        app.post '/*', (request, response) ->
            toRun = path.join cwd, request.path
            response.set 'Content-Type', 'application/json'
            options =
                env:
                    METHOD: 'POST'
            childProcess = child_process.execFile toRun, options, (error, stdout, stderr) ->
                if error
                    handleError response, error, stdout, stderr
                else
                    process.stderr.write stderr
                    response.end(stdout)
            #stream along the body
            request.on 'data', (chunk) ->
                childProcess.stdin.write chunk
            request.on 'end', ->
                childProcess.stdin.end()
        io.set 'log level', 0
        server.listen options.PORT
    stop: () ->
    poke: () ->

for verb, __ of options
    if verbs[verb]
        verbs[verb]()
