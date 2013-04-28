# Overview #

Auto-update by watching git repositories. Keep your main process
running with a watchdog.

## Assumptions ##

* Nothing is run as root, so you will need to serve high number ports
from any scripts
* Your program consists of one or more Git repositories, and a single
entry point that can be invoked from the command line
* Your program follows the [12 factor app](http://www.12factor.net)
approach, specifically in that it is
  * Just a program, not a daemon itself
  * Reads from `ENV`
  * Logs to `STDOUT` and `STDERR`
  * Does not expect input from `STDIN`
* You will only have one `superwatcher` based program per shell account

## Watchdog ##

The watchdog is the core that makes superwatcher work.

The watchdog is a simple `cron` job that makes sure everything is running
as well as driving the auto update loop. This lets the system survive a
reboot, and doesn't require you to fuss with `init` and friends or other startup
daemons. And, it doesn't require you to do anything as `root`. This
approach has the advantage of working across multiple Unix/Linux/OSX
versions, `cron` is always there!

## Auto Update ##

The assumption is that your code is in Git, and that doing a release is
driven by git push to a designated branch. Superwatcher will watch Git
urls and pull in any changes.

## Main ##

A single command line is provided as the main. This is run forever with
[forever](https://github.com/nodejitsu/forever), and monitored by the
watchdog.

## Environment ##

A script can be designated as the environment, which will be sourced
before running your main program. Ideally, this script is in a git
repository as well, so it is autoupdated.

## Restart Triggers ##

Restarts are trigged by files changing as a result of an Auto Update.
If any of these files change, the `Main` script is stopped then
restarted to pick up the environment.

