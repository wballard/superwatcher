#This is a root level command to export the superforker
#suite of command line actions.

fs = require 'fs'
yaml = require 'js-yaml'
path = require 'path'
wrench = require 'wrench'
child_process = require 'child_process'
require 'colors'
_ = require 'underscore'

package_json = JSON.parse fs.readFileSync path.join(__dirname, '../package.json')
doc = """
#{package_json.description}

Usage:
    superwatcher [options] init
    superwatcher [options] logs
    superwatcher [options] info
    superwatcher [options] start
    superwatcher [options] restart
    superwatcher [options] stop
    superwatcher [options] watch <directory>
    superwatcher [options] watch <giturl> <directory>
    superwatcher [options] environment <source_this_script>
    superwatcher [options] main <commandline>...

Options:
    --help
    --version

"""
{docopt} = require 'docopt', version: package_json.version
options = docopt doc
process.env.SUPERWATCHER_HOME = path.join(process.env.HOME, '.superwatcher')
watchfile = path.join process.env.SUPERWATCHER_HOME, 'watch'
environmentfile = path.join process.env.SUPERWATCHER_HOME, 'environment'
mainfile = path.join process.env.SUPERWATCHER_HOME, 'main'
updatefile = path.join process.env.SUPERWATCHER_HOME, "..", "bin", "update_repo_as_needed"

silence = ->
    process.stdout.write = ->
    process.stderr.write = ->

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

watch = (options) ->
    #a configuration file keeping track of everything we are watching
    if fs.existsSync watchfile
        watches = fs.readFileSync(watchfile, 'utf8').split '\n'
    else
        watches = []
    watches = _.union watches, [options['<directory>']]
    fs.writeFileSync watchfile,
        (_.filter watches, (x) -> x.length).join('\n') + '\n'
    if options['<giturl>']
        exec path.join(__dirname, 'clone_and_watch'), options['<giturl>'], options['<directory>']
    else
        exec path.join(__dirname, 'watch'), options['<directory>']

environment = (options) ->
    if fs.existsSync environmentfile
        fs.unlinkSync environmentfile
    fs.symlinkSync options['<source_this_script>'], environmentfile

main = (options) ->
    #shell script with an exec to replace so this will end up being
    #the daemon
    commandline = options['<commandline>'].join ' '
    fs.writeFileSync mainfile,
        """
        if [ -f "#{environmentfile}" ]; then
            source "#{environmentfile}"
        fi
        exec #{commandline}

        """
    fs.chmodSync mainfile, '644'

start = (options) ->
    watchdogfile = path.join process.env.SUPERWATCHER_HOME, 'watchdog'
    watchdogsourcefile = path.join __dirname, 'watchdog'
    if fs.existsSync watchdogfile
        fs.unlinkSync watchdogfile
    fs.symlinkSync watchdogsourcefile, watchdogfile
    if fs.existsSync updatefile
        fs.unlinkSync updatefile
    #hand off the the shell script part
    if options.restart
        exec path.join(__dirname, 'start'), 'restart'
    else
        exec path.join(__dirname, 'start')

info = (options) ->
    if fs.existsSync watchfile
        console.log "watching".green
        console.log fs.readFileSync(watchfile, 'utf8').trim().blue
    if fs.existsSync environmentfile
        console.log "environment present".green
        console.log fs.readFileSync(environmentfile, 'utf8').trim().blue
    if fs.existsSync mainfile
        console.log "main present".green
        console.log fs.readFileSync(mainfile, 'utf8').trim().split('\n')[-1..][0].blue

options.watch and watch options
options.environment and environment options
options.main and main options
options.start and start options
options.restart and start options
options.stop and exec path.join(__dirname, 'stop')
options.init and exec path.join(__dirname, 'init')
options.logs and exec path.join(__dirname, 'logs')
options.info and info options
