path = require 'path'
fs = require 'fs'
crypto = require 'crypto'
child_process = require 'child_process'
repl = require 'repl'
io_client = require 'socket.io-client'
io = require 'socket.io'
url = require 'url'
util = require 'util'
_ = require 'underscore'
yaml = require 'js-yaml'

#It's a bird, it's a plane, it's GUID-like!
guid_like = () ->
    hash = crypto.createHash 'md5'
    for argument in arguments
        hash.update "#{argument}", 'utf8'
    hash.digest 'hex'

module.exports = (port, root) ->
    #fire up express with socket io
    app = require('express')()
    server = require('http').createServer(app)
    io = io.listen(server)
    #hooking into the authorization handshake sequence
    io.configure ->
        io.set 'authorization', (handshakeData, callback) ->
            #looking for a well know query string token called
            #authtoken, which will be passed to a well known program
            #auth, passing that token as the one parameter
            #auth is expected to return the user identity on success
            #or exit code non-zero on failure
            authpath = path.join root, 'auth'
            fs.exists authpath, (exists) ->
                #if we didn't supply an auth program, well, we aren't going
                #to auth now are we...
                if not exists
                    handshakeData.USER = handshakeData.query.authtoken
                    callback null, true
                else
                    child_process.execFile authpath, [handshakeData.query.authtoken],
                        (error, stdout, stderr) ->
                            if error
                                callback stderr, false
                            else
                                handshakeData.USER = yaml.safeLoad stdout
                                callback null, true
    error_count = 0
    #big block of environment handling and setup
    setup_environment = (message, environment={}, user) ->
        environment =
            PATH_INFO: message.command
            SCRIPT_NAME: path.basename(message.path)
            USER: yaml.dump(user)
        #flag to look for stdin, really just for testing
        if message.stdin
            environment.READ_STDIN = "TRUE"
        else
            environment.READ_STDIN = "FALSE"
        _.extend {}, process.env, environment
    #message processing at its finest
    io.on 'connection', (socket) ->
        util.log "connected as #{socket.handshake.USER}"
        socket.on 'exec', (message, ack) ->
            message.path = path.join root, message.command
            util.log message.path, root
            child_options =
                env: setup_environment(message, {}, socket.handshake.USER)
            childProcess = child_process.execFile message.path, message.args, child_options,
                (error, stdout, stderr) ->
                    if error
                        #big old error object in a JSON ball
                        error =
                            id: guid_like(Date.now(), error_count++)
                            at: Date.now()
                            error: error
                            message: stderr
                        errorString = JSON.stringify(error)
                        #for out own output so we can sweep this up in server logs
                        process.stderr.write errorString
                        process.stderr.write "\n"
                        socket.emit 'error', error
                        #non zero exit code, we are toast and not going
                        #on to any potential ack
                        return
                    else
                        #trap the stderr on the server here, no process
                        #exit code, just informational content, i.e.
                        #we only return stdout back in the messages
                        process.stderr.write stderr
                    if ack
                        #socket io paired callback case
                        try
                            ack(JSON.parse(stdout))
                        catch error
                            ack(stdout)
                    else
                        #or just a message back
                        try
                            socket.emit 'exec', JSON.parse(stdout)
                        catch error
                            socket.emit 'exec', stdout
            #if we have content, pipe it along to the forked process
            if message.stdin
                childProcess.stdin.on 'error', ->
                    util.log "error on stdin #{arguments}"
                childProcess.stdin.end JSON.stringify(message.stdin)
    #have socket.io not yell so much
    io.set 'log level', 0
    util.log "serving handlers from #{root} with node #{process.version}"
    server.listen port
