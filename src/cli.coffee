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
    superwatcher init
    superwatcher info
    superwatcher start
    superwatcher stop
    superwatcher watch <giturl> <directory>
    superwatcher environment <source_this_script>
    superwatcher --help | --version

"""
{docopt} = require 'docopt'
options = docopt doc, version: package_json.version

#the all important 'where are we' variable
process.env.SUPERWATCHER_HOME = path.join(process.env.HOME, '.superwatcher')
watchfile = path.join process.env.SUPERWATCHER_HOME, 'watch'
environmentfile = path.join process.env.SUPERWATCHER_HOME, 'environment'

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

environment = (options) ->
    if fs.existsSync environmentfile
        fs.unlinkSync environmentfile
    fs.symlinkSync options['<source_this_script>'], environmentfile

start = (options) ->
    #the watchdog itself, this is the main shell script run from cron
    watchdogfile = path.join process.env.SUPERWATCHER_HOME, 'watchdog'
    watchdogsourcefile = path.join __dirname, 'watchdog'
    if fs.existsSync watchdogfile
        fs.unlinkSync watchdogfile
    fs.symlinkSync watchdogsourcefile, watchdogfile
    #the git updating script, called from the watchdog
    updatefile = path.join process.env.SUPERWATCHER_HOME, "update_repo_as_needed"
    updatesourcefile = path.join __dirname, "..", "bin", "update_repo_as_needed"
    if fs.existsSync updatefile
        fs.unlinkSync updatefile
    fs.symlinkSync updatesourcefile, updatefile
    #hand off the the shell script part
    exec path.join(__dirname, 'start')

stop = (options) ->
    exec path.join(__dirname, 'stop')

init = (options) ->
    exec path.join(__dirname, 'init')

info = (options) ->
    if fs.existsSync watchfile
        console.log "watching".green
        console.log fs.readFileSync(watchfile, 'utf8').trim().blue
    if fs.existsSync environmentfile
        console.log "environment present".green
        console.log fs.readFileSync(environmentfile, 'utf8').trim().blue

#command dispatch via short circuit
options.watch and watch options
options.environment and environment options
options.start and start options
options.stop and stop options
options.init and init options
options.info and info options
