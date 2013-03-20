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

* The _message name_ becomes the path to the command line program
* The _message_ is written to the command line program STDIN
* Environment variables matching CGI are supplied to the command line
program
* STDOUT is captured and written back as a Socket.IO message
* STDERR is captured and logged server side

Superforker connect HTTP with the following protocol:

* The _request path_ becomes the path to the command line program
* The _request parameters_ are transformed into switches `--name=value`
* The POST body is written to the command line program STDIN
* Environment variables matching CGI are supplied to the command line
program
* STDOUT is captured and written back as the response
* STDERR is captured and logged server side

So, you just write a program, read STDIN, do stuff, write STDOUT. This
bridges building HTTP APIs with simple shell programming. You an send
any text you like.

# The Server #
The server is a node.js program, with socket.io, providing both the
server and client library.

## Setup ##
Superforker runs in a directory, its cwd. By convention, all the
commands it runs are relative to this directory. In practice this means
you do one of two things to deploy a server:

* make git submodules in a directory to pull in other sets of commands
* symlink like a fiend to pull things into your namespace

This is to avoid the need to _configure a root directory_, and also has
the benefit of keeping you from running any old command in `bin` -- like
our friend `rm` for example.

### Example ###
So, finally, after all this text...

```
npm install superforker
npm start superforker
```

Now you are running, put it in the background.
In the same directory, make a shell script:

```
#!/usr/bin/env bash
echo Pants
```

save it to a file, I like the name `pants`. Now, the magic:

```
curl http://localhost:8080/pants
```

Should, unshockingly give you **Pants**.


Now, socket.io is a bit more complex, in that you don't just get to
block and wait for a response. So we're provided a handy command line
tool to let you poke at the server. It uses socket.io under the hood.

```
superforker poke http://localhost:8080
```

This gives you a really simple REPL shell. It's a shell, but messagse can
come in any time from the server.

```
> pants
```

And, it'll talk back. It does that.

```
< pants 
Pants
```

So, what's going on? Superforker is taking the `cwd`, and tacking on
`/pants`, running it, then streaming the message back.

## Testing ##
Here is the trick. Run your command line program. Pipe in the input you
want, assert the output. Done. We tend to use `diff`, saving the input
and output. 

## Events ##
In addition to running commands for you, superforker will give you file
change events. This fits with how we like to program, shell-inspired,
where each user has a home directory in which we can write them messages
and data in simple files.

To use this, just connect socket.io to
`http://[host]:[port]/watch/[directory]`. [directory] needs to be
relative to superforker `cwd`. This will give you back an event on each
file change, with the name of the file as the message, and a bit of
metadata about the change, and a nice URL you can GET it from.
