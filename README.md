# whatsinstalled

Checks which version of an application is installed on your servers.
It is meant to be used with applications deployed using capistrano or Chef, where deployment is essentially a git 
checkout, symlinked to a "current" directory.  It can also report the version of installed Debian packages on a system.

## Philosophy (Requirements)

While it's one thing to say "we're going to deploy version 1.2.3 of the web app," it's quite another thing to actually do it.
One of the most annoying (and common!) things that can happen in distributed environments is chasing down "which server was left out of the
deploy -- e.g. four web servers were bumped up to version 1.2.3, while a fifth failed or simply wasn't run.  These partial
updates lead to reports of "feature X works 80% of the time, and doesn't work the other 20%.  Can you check that all of the
servers are up to date?"

Another problem that Whichsapp solves is the question of which assay got pushed to production in ticket XYZ.  While our Chef handlers
report that an assay was successfully pushed, it doesn't report which commit was actually pushed.  Chef is also very wordy and its
reports can be hard to read, so we have been sampling one "representative" server, verifying that "something" got pushed to production for
a specific customer, and assuming that no reports of failures in the Chef hipchat room means the deploy was successful.

Instead of dispatching someone to look at all the current versions of an app, an assay, or a package in response to a problem,
Whichsapp checks these versions regularly.  Its default check frequency is once every 20 seconds (a la collectd).  Because the
commands to check each application's version are very light (git rev-parse and dpkg), setting a low check frequency presents very 
little overhead on the monitored server.

Storing app versions in a memory-backed key/value store speeds up reads.  Whichsapp sets a low TTL on each key that it advertises,
meaning a server that has stopped reporting its apps' versions becomes immediately obvious in the web UI.  Data is either very fresh, or
missing (which is actually desired).  Finally, because there's a key/value store between monitored servers and the web UI, we don't 
need to worry about using SSH keys to allow remote logins to grab software versions in real time.

## Components

There are three components to Whichsapp: agents, an etcd server (or cluster), and a Sinatra-based front end.  Both the agents
and the front end read a common config.yml file, an example of which is included as config.yml.example.  In the config.yml file, there
are four sections: 

- settings: includes the ip address and port of the etcd server (info\_server and port, respectively), as well as the check 
  interval and key TTL (in seconds)
- apps: a hash of app names and filesystem paths.
- assays: a single directory containing customers' assays.  This feature is probably only useful for Indigo Bioautomation.
- packages: a list of debian packages

## Installation

For simplicity's sake, I install the Sinatra components on the same box where etcd is installed.  The agent gets installed on all of
the servers that I want to monitor.  See the whatsinstalled Chef cookbook at https://github.com/gswallow/whatsinstalled-chef.

To configure the agent, pass in some attributes (probably through the node's role):

```
default_attributes(
  'whatsinstalled' => {
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
```
## Risks

Risks of running this product are extremely low.  You may wish to password-protect access to the web UI, or restrict its access based on
network location.

## TODO

- Write tests!
- Determine what "type" of server an instance is.  Maybe read /etc/chef/first-run.json or something.
- Extend the agent to Microsoft Windows.
