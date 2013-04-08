#This is a root level command to export the superforker
#suite of command line actions.

fs = require 'fs'
path = require 'path'
child_process = require 'child_process'
forever = require 'forever'
package_json = JSON.parse fs.readFileSync path.join(__dirname, '../package.json')
doc = """
#{package_json.description}

Usage:
    superforker [options] start
    superforker [options] stop
    superforker [options] watchdog
    superforker [options] info
    superforker [options] init
    superforker [options] init handlers <giturl>
    superforker [options] init environment <giturl>
    superforker [options] daemon <port> <logs> <handlers>
    superforker [options] undaemon

Options:
    --help
    --version

"""
{docopt} = require 'docopt', version: package_json.version
options = docopt doc
process.env.SUPERFORKER_ROOT = path.join __dirname, '..'

#This is essentially exec in that we will be done with running
#when the sub command completes
exec = (program, args...) ->
    running = child_process.spawn program, args
    running.stdout.on 'data', (data) ->
        process.stdout.write data
    running.stderr.on 'data', (data) ->
        process.stderr.write data
    running.on 'code', (code) ->
        process.exit code

SERVER_SCRIPT = path.join(__dirname, 'server_shim.js')

daemon = (options) ->
    forever.list '', (ignore, jobs) ->
        for idx, job of jobs
            if job.file is SERVER_SCRIPT
                return
        #got here? time to really run
        rootdir = options['<root>']
        logdir = options['<logs>']
        process.env['PORT'] = options['<port>']
        process.env['LOG_DIR'] = logdir
        process.env['HANDLE_THIS'] = options['<handlers>']
        what = forever.startDaemon SERVER_SCRIPT,
            silent: true
            cwd: rootdir
            options: [options['<port>'], options['<handlers>']]
            logFile: path.join logdir, 'forever.log'
            outFile: path.join logdir, 'out.log'
            errFile: path.join logdir, 'err.log'

undaemon = (options) ->
    forever.list '', (ignore, jobs) ->
        for idx, job of jobs
            if job.file is SERVER_SCRIPT
                forever.stop idx

init = (options) ->
    if options.environment
        exec path.join(__dirname, 'environment'), options['<giturl>']
    else if options.handlers
        exec path.join(__dirname, 'handlers'), options['<giturl>']
    else
        exec path.join(__dirname, 'init')

options.start and exec path.join(__dirname, 'start')
options.stop and exec path.join(__dirname, 'stop')
options.watchdog and exec path.join(__dirname, 'watchdog')
options.info and exec path.join(__dirname, 'info')
options.init and init options
options.daemon and daemon options
options.undaemon and undaemon options
