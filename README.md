# Overview #

Stick a FORK in HTTP!

Superforker is trying to go back in time, to a happy place where we
didn't have to worry about framework and threads. Our conjecture is that
you can make a perfectly good, modern JSON API using a mixture of three
techniques:

* CGI style fork per request
* Socket.IO connectivity
* File system events

In this setup, you can use any language you like, as long as you can
create a command line program with it. The novel aspect is connecting Socket.IO,
making one durable request for a single page app, paired with fork per
request. This avoids the overhead of connecting over HTTP each request,
freeing up that latency time to be invested in going framework free.

# How It Works #
Superforker connects Socket.IO to simple command line programs
with the following protocol:

* You send a message called `exec`
* It has properties `command`, `stdin`, and an array `args`
program
* STDOUT is captured and written back as a Socket.IO message
* STDERR is captured and logged server side

So, you just write a program, read STDIN, do stuff, write STDOUT. This
bridges building HTTP APIs with simple shell programming. You an send
any text you like. If you send JSON, the server will respond with a
message this is structured JSON, otherwise it'll be a string.

# The Server #
The server is a node.js program, with socket.io, providing both the
server and client library.

