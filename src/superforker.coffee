doc = """
Superforker!

Usage:
    superforker serve [PORT] [--root=<root>]
    superforker start
    superforker stop

Options:
    --root=<root>    Root directory, forked processes are relative to this.

Arguments:
    PORT  TCP port, serves HTTP and socket IO here [default: 8080]
"""

server = require '../src/server'
require('shellscript').globalize()

DEFAULT_PORT = '8080'
DEFAULT_ROOT = process.cwd()

{docopt} = require 'docopt'
options = docopt(doc)

options.serve and server(
    options['PORT'] or DEFAULT_PORT,
    options['--root'] or DEFAULT_ROOT)

options.start and shell("#{__dirname}/../bin/start")
options.stop and shell("#{__dirname}/../bin/stop")
