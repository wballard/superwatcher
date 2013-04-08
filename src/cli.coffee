#This is a root level command to export the superforker
#suite of command line actions.

fs = require 'fs'
path = require 'path'
child_process = require 'child_process'
package_json = JSON.parse fs.readFileSync path.join(__dirname, '../package.json')
doc = """
#{package_json.description}

Usage:
    superforker [options] start
    superforker [options] (stop|handlers|environment|info)

Options:
    --help
    --version

"""
{docopt} = require 'docopt', version: package_json.version
options = docopt doc
process.env.SUPERFORKER_ROOT = path.join __dirname, '..'

#This is essentially exec in that we will be done with running
#when the sub command completes
exec = (program, args) ->
    running = child_process.spawn program, args
    running.stdout.on 'data', (data) ->
        process.stdout.write data
    running.stderr.on 'data', (data) ->
        process.stderr.write data
    running.on 'code', (code) ->
        process.exit code

if options.start
    exec path.join(__dirname, 'start')
