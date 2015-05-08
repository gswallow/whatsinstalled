# whichsapp

A play on the super-popular "Whatsapp," whichsapp checks which version of an application is installed on your servers.
It is meant to be used with applications deployed using capistrano or Chef, where deployment is essentially a git 
checkout, symlinked to a "current" directory.  It can also report the version of installed Debian packages on a system.

## Philosophy

While it's one thing to say "we're going to deploy version 1.2.3 of the web app," it's quite another thing to actually do it.
One of the most annoying things that can happen in distributed environments is chasing down "which server was left out of the
deploy -- e.g. four web servers were bumped up to version 1.2.3, while a fifth failed or simply wasn't run.  These partial
updates lead to reports of "feature X works 50% of the time, and doesn't work the other 50%.  Can you check that all of the
servers are up to date?

Whichsapp solves this problem by scanning the server's application root very often -- more than once per minute.  Its default
check frequency is once every 20 seconds (a la collectd).  Because the commands to check the application's version are very light
(git rev-parse and an etcd client), setting a very low check frequency presents very little overhead on the monitored server.

## Components

There are three components to Whichsapp: agents, an etcd server (or cluster), and a Sinatra-based front end.  Both the agents
and the front end read a common config.yml file, an example of which is included as config.yml.example.  In the config.yml file, there
are four sections: 

- settings: includes the ip address and port of the etcd server (info\_server and port, respectively), as well as the check 
  interval and key TTL (in seconds)
- apps: a hash of app names and filesystem paths.
- assays: a single directory containing customers' assays.  This is probably useful for Indigo Bioautomation.
- packages: a list of debian packages

## Installation

For simplicity's sake, I install the Sinatra components on the same box where etcd is installed.  The agent gets installed on all of
the servers that I want to monitor.  See the whichsapp Chef cookbook at https://github.com/gswallow/whichsapp-chef.

To configure the agent, pass in some attributes:

...
default_attributes(
  'whichsapp' => {
    'apps' => {
      'web' => '/var/www/apps/ascent-web/current',
      'compute_runner' => '/var/scripts/compute-runner/current'
    },
    'assays' => '/var/scripts/assays',
    'packages' => [
      'tokumx-clients',
      'tokumx-common',
      'indigo-compute-3.4.1',
      'indigo-compute-core-3.4.1',
      'referee'
    ]
  }
)
...
