#This is a root level command to export the superforker
#suite of command line actions.

fs = require 'fs'
yaml = require 'js-yaml'
path = require 'path'
child_process = require 'child_process'
require 'colors'
package_json = JSON.parse fs.readFileSync path.join(__dirname, '../package.json')
doc = """
#{package_json.description}

Usage:
    superwatcher [options] init
    superwatcher [options] info
    superwatcher [options] start
    superwatcher [options] stop
    superwatcher [options] watch <giturl> <directory>
    superwatcher [options] main <commandline>...
    superwatcher [options] environment <shellscript>

Options:
    --help
    --version

"""
{docopt} = require 'docopt', version: package_json.version
options = docopt doc
process.env.SUPERWATCHER_HOME = path.join(process.env.HOME, '.superwatcher')


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

init = (options) ->
    if not fs.existsSync process.env.SUPERWATCHER_HOME
        fs.mkdirSync process.env.SUPERWATCHER_HOME
    console.log "superwatcher ready in #{process.env.SUPERWATCHER_HOME}".green

watch = (options) ->
    watchfile = path.join process.env.SUPERWATCHER_HOME, 'watch.yaml'
    if fs.existsSync watchfile
        watches = yaml.safeLoad fs.readFileSync(watchfile, 'utf8')
    else
        watches = {}
    watches[options['<giturl>']] = options['<directory>']
    fs.writeFileSync watchfile, yaml.safeDump(watches)
    console.log "Watching #{options['<giturl>']}".green

options.init and init options
options.watch and watch options
options.start and exec path.join(__dirname, 'start')
options.stop and exec path.join(__dirname, 'stop')
options.info and exec path.join(__dirname, 'info')
