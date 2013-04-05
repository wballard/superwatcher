doc = """
Superforker!

Usage:
    server serve [PORT] [--root=<root>]
    server

Options:
    --root=<root>    Root directory, forked processes are relative to this.

Arguments:
    PORT  TCP port, serves HTTP and socket IO here [default: 8080]
"""

server = require '../src/server'

DEFAULT_PORT = '8080'
DEFAULT_ROOT = process.cwd()

{docopt} = require 'docopt'
options = docopt(doc)
options.serve and server(
    options['PORT'] or DEFAULT_PORT,
    options['--root'] or DEFAULT_ROOT)
