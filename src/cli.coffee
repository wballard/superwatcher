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
    superwatcher watchdog
    superwatcher watch <giturl> <directory>
    superwatcher environment <source_this_script>
    superwatcher --help | --version

Info:
    You can watch any git url, which will let you watch at specific branches. As
    automatic updates run, they respect the current git origin and branch, so
    you can always manually switch a watched local directory to a different git.

Notes:
  start: this installs superwatcher as a cron job
  stop: this removes superwatchers as a cron job
  watchdog: this runs superwatcher in the shell with a timeout, useful
    for testing and to set up under LXC containers like docker

"""
{docopt} = require 'docopt'
_ = require 'lodash'
options = docopt doc, version: package_json.version
options.timeout = 60*1000

#the all important 'where are we' variable
process.env.SUPERWATCHER_HOME = path.join(process.env.HOME, '.superwatcher')
watchfile = path.join process.env.SUPERWATCHER_HOME, 'watch'
environmentfile = path.join process.env.SUPERWATCHER_HOME, 'environment'

#This is essentially exec in that we will be done with running
#when the sub command completes
exec = (program, args...) ->
    if _.isFunction(_.last(args))
      callback = args.pop()
    else
      callback = (code) ->
        process.exit code
    running = child_process.spawn program, args
    running.stdout.on 'data', (data) ->
        process.stdout.write data
    running.stderr.on 'data', (data) ->
        process.stderr.write data
    running.on 'exit', callback

watch = (options) ->
    #a configuration file keeping track of everything we are watching
    if fs.existsSync watchfile
        watches = fs.readFileSync(watchfile, 'utf8').split '\n'
    else
        watches = []
    watches = _.union watches, [options['<directory>']]
    fs.writeFileSync watchfile,
        (_.filter watches, (x) -> x.length).join('\n') + '\n'
    if fs.existsSync(options['<directory>'])
        console.log "WARNING: directory already exists, will watch it anyhow, but this directory will not be a fresh clone".red
    else
        exec 'git', 'clone', options['<giturl>'], options['<directory>']

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
  if not fs.existsSync process.env.SUPERWATCHER_HOME
    wrench.mkdirSyncRecursive process.env.SUPERWATCHER_HOME

info = (options) ->
    if fs.existsSync watchfile
        console.log "watching:".blue
        for line in fs.readFileSync(watchfile, 'utf8').split('\n')
          console.log "\t#{line}"
    if fs.existsSync environmentfile
        console.log "environment present:".blue
        console.log fs.readFileSync(environmentfile, 'utf8').trim()

watchdog = (options) ->
  exec path.join(__dirname, 'watchdog'), ->
    setTimeout ->
      watchdog options
    , options.timeout

#command dispatch via short circuit
options.watch and watch options
options.environment and environment options
options.start and start options
options.stop and stop options
options.init and init options
options.info and info options
options.watchdog and watchdog options
