## Why Care

Sure, you can watch for local file changes and react to those with a
script, but can you watch for remote file changes in a `git` repository?

## What It Does

`superwatcher`:

* watches `git` repositories for you
* keeps those repositores up to date
* triggers an update hook script on each update

With this simple tool combined with [forever](https://github.com/nodejitsu/forever)
you can create an auto updating, auto restarting server. All you need to
do to autodeploy to as many nodes as you like is `git push`.

Unlike pretty much every other autodeploy tool, `superwatcher` doesn't
assume any specific workflow, you can watch any repository and branch
you like, triggering an optional script after each update. Since that is
just a shell script, you can do what you like

## What It Is

`superwatcher` is a command line program that leverages good old `cron`
to create a series of repository watchdogs.

Seems like folks are generally in love with git hooks, which works great
except when one of your nodes is down and misses the hook and jams up
the works. Using hooks is a *push* method. Using `cron` is a *pull*
method. The benefit is that nodes that are down will eventually catch up
as they pull in new changes. Self healing.

Cron is also nice in that is:

* survives reboots
* is already there and doesn't require installing another daemon as root

The watchdogs will leave configuration in `~/.superwatcher`, just as
plain text so you can hack and poke as you see fit.

## How To Use It

`npm install -g superwatcher`

Yep, you'll need node.

`superwatcher --help`

...get the lay of the land

## Update Triggers

These are just shell scripts, in the root of each watched repository.

Hooks wrap the auto update sequence, which goes like this:

1. Ask the git remote if there are missing local changes
2. If no, go back to sleep
3. If yes, run the `superwatcher_before_update` currently on disk, this
   will be the *prior* version, not the one incoming from the remote
4. Use git to fetch and reset to the current remote revision
5. Run the `superwatcher_after_update` currently on disk, this may have
   been freshly pulled

## Environment

Cron is nice, except when it isn't. The exact environment you get in a
cron job isn't always what you would expect, so `superwatcher` lets you
set it explicitly. This will be sourced before every autoupdate
sequence, and lets you do fun stuff like pick the right `node`, set
`PATH`, etc.

## Enough Already! #

Ok, here is how you use the thing:

```
npm install -g superwatcher

superwatcher init

superwatcher watch git://github.com/wballard/superwatcher.demo.git ~/demo
superwatcher environment ~/demo/environment
superwatcher start

```

At this point, everything should run. All you need to do in order to
push changes is update the git repository, which is ... well, you'll
need to switch to your own repository :).

You can see what is going on with:

```
superwatcher info
```

And shut the whole thing down with:

```
superwatcher stop
```

## Make a Sandwich

To get a super simple, self updating server, combine `superwatcher` with
`forever --watch --watchDirectory`. This will give you auto update, and self restart on
update.
