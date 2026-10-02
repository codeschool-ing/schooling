---
title: Puppet, a manifest and a catalogue
version: 1
---

Puppet describes a machine as a set of **resources**, each with a type, a title and attributes, written
in a language of its own. It is not YAML and not Ruby, though Puppet itself is written in Ruby. Ana's
first manifest manages a directory, two files and a command that should run only when the
configuration file changes:

```
$root = '/home/ana/web'

file { $root:
  ensure => directory,
  mode   => '0755',
}

file { "${root}/index.html":
  ensure  => file,
  content => "<h1>shop</h1>\n",
  mode    => '0644',
}

file { "${root}/shop.conf":
  ensure  => file,
  content => "listen 80;\nroot ${root};\n",
  mode    => '0644',
  notify  => Exec['reload-web'],
}

exec { 'reload-web':
  command     => "/bin/sh -c 'echo reloaded >> ${root}/reloads.log'",
  refreshonly => true,
}
```

On a real web server those paths would be under `/var/www` and `/etc/nginx`. **In the lab they are in
Ana's home**, because she is not root and the laptop is the only machine there is; the resources and
the way Puppet applies them are the same. `$root` is a variable, and `"${root}/index.html"` puts it into
a string, which works only in double quotes. Each `file` says what must be true (`ensure => file`, this
`content`, this `mode`) and not how to get there.

The last two resources are joined. `notify => Exec['reload-web']` on `shop.conf` says: when this
resource changes, tell that one. `refreshonly => true` on the `exec` says it runs only when told. On a
server the command would reload nginx; here it appends a line to a log, so you can count how often it
ran. Lesson 18 has the same idea as a handler.

A manifest can be checked without running it, and that is worth doing before an agent fetches it:

```
ana@laptop:~/shop/puppet$ puppet parser validate site.pp && echo valid
valid
```

## The first run, and the second

```
ana@laptop:~/shop/puppet$ puppet apply site.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.03 seconds
Notice: /Stage[main]/Main/File[/home/ana/web]/ensure: created
Notice: /Stage[main]/Main/File[/home/ana/web/index.html]/ensure: defined content as '{sha256}783652ab6a6189ef05ab6994f3bdeb6fc0cdcec3150ad6df4f6c56fff8a0a993'
Notice: /Stage[main]/Main/File[/home/ana/web/shop.conf]/ensure: defined content as '{sha256}292f046193dabb234e26be4c8d5cb125558e85ac5094b1419ffed38a4d949aae'
Notice: /Stage[main]/Main/Exec[reload-web]: Triggered 'refresh' from 1 event
Notice: Applied catalog in 0.03 seconds
```

Read it from the top. The warning is the lab's: Facter, the part of Puppet that gathers facts about
the machine, found no network address, because a lab run has no network. **`Compiled catalog for
laptop` is the important line.** The catalogue is the manifest worked out for one machine: every
resource, with variables filled in and relationships resolved. With an agent, the server compiles it
and sends it down; `puppet apply` compiles it on the spot. Then one `Notice` per change: the
directory created, two files written (Puppet records their content as a SHA-256 checksum), and the
`exec` run once because `shop.conf` changed.

The second run of the same manifest:

```
ana@laptop:~/shop/puppet$ puppet apply site.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.03 seconds
Notice: Applied catalog in 0.01 seconds
```

Nothing between compiling and applying: every resource was already as described. This is the property
lesson 1 called idempotent, and it is what lets an agent run every thirty minutes without doing
anything most of the time.

Now somebody edits the configuration by hand, and Puppet runs again:

```
ana@laptop:~/shop/puppet$ echo "listen 8080;" > ~/web/shop.conf
ana@laptop:~/shop/puppet$ puppet apply site.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.03 seconds
Notice: /Stage[main]/Main/File[/home/ana/web/shop.conf]/content: content changed '{sha256}717bae503ae6108953042113e8bb6284b71a2c1c73665b7cc9cc06711dbe7138' to '{sha256}292f046193dabb234e26be4c8d5cb125558e85ac5094b1419ffed38a4d949aae'
Notice: /Stage[main]/Main/Exec[reload-web]: Triggered 'refresh' from 1 event
Notice: Applied catalog in 0.03 seconds
ana@laptop:~/shop/puppet$ cat ~/web/shop.conf ~/web/reloads.log
listen 80;
root /home/ana/web;
reloaded
reloaded
```

Puppet compared the file with the description, found a different checksum, wrote the described
content back, and told the `exec`, which ran a second time. The log has two lines, one per change. An
agent would have done this on its own, at the next run.

## Package, file, service

The shape that a real web server gets is three resource types that appear in almost every Puppet
codebase:

```
package { 'nginx':
  ensure => installed,
}

file { '/etc/nginx/sites-enabled/shop':
  ensure  => file,
  content => "server { listen 80; root /var/www/shop; }\n",
  require => Package['nginx'],
  notify  => Service['nginx'],
}

service { 'nginx':
  ensure => running,
  enable => true,
}
```

`require` and `notify` are **relationships**: install the package before writing its configuration,
and restart the service when the configuration changes. Puppet builds a graph from them and applies
resources in an order that respects it. Where two resources have no relationship, it follows the order
of the manifest, but a manifest that depends on that order without saying so breaks the day somebody
moves a resource into another file.

Ana is not root and the lab has no network for `apt`, so this one runs with `--noop`, which compares
and reports without changing anything:

```
ana@laptop:~/shop/puppet$ puppet apply --noop server.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.27 seconds
Notice: /Stage[main]/Main/Package[nginx]/ensure: current_value 'purged', should be 'present' (noop)
Notice: /Stage[main]/Main/File[/etc/nginx/sites-enabled/shop]/ensure: current_value 'absent', should be 'file' (noop)
Notice: /Stage[main]/Main/Service[nginx]/ensure: current_value 'stopped', should be 'running' (noop)
Notice: Class[Main]: Would have triggered 'refresh' from 3 events
Notice: Stage[main]: Would have triggered 'refresh' from 1 event
Notice: Applied catalog in 1.68 seconds
```

Each line has the current value and the one it should have. Without `--noop`, the package fails, and
the graph shows its worth:

```
ana@laptop:~/shop/puppet$ puppet apply server.pp
Warning: Could not retrieve either serverip or serverip6 fact
Notice: Compiled catalog for laptop in environment production in 0.27 seconds
Error: Execution of '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install nginx' returned 100: E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), are you root?
Error: /Stage[main]/Main/Package[nginx]/ensure: change from 'purged' to 'present' failed: Execution of '/usr/bin/apt-get -q -y -o DPkg::Options::=--force-confold install nginx' returned 100: E: Could not open lock file /var/lib/dpkg/lock-frontend - open (13: Permission denied)
E: Unable to acquire the dpkg frontend lock (/var/lib/dpkg/lock-frontend), are you root?
Notice: /Stage[main]/Main/File[/etc/nginx/sites-enabled/shop]: Dependency Package[nginx] has failures: true
Warning: /Stage[main]/Main/File[/etc/nginx/sites-enabled/shop]: Skipping because of failed dependencies
Warning: /Stage[main]/Main/Service[nginx]: Skipping because of failed dependencies
Notice: Applied catalog in 1.45 seconds
```

The file and the service were **skipped because their dependency failed**, rather than tried
anyway. A configuration file for a package that is not installed, and a service started without it,
are exactly what the `require` exists to prevent.

`puppet resource` turns the same machinery round and describes what exists, in Puppet's own syntax:

```
ana@laptop:~/shop/puppet$ puppet resource package nginx
package { 'nginx':
  ensure   => 'purged',
  provider => 'apt',
}
```

`provider => 'apt'` is the part of Puppet that turns the general `package` type into commands for
Ubuntu's package manager; on another system a different one is chosen. The word means something else
in Terraform, where a provider is the program that knows a cloud's API.

Puppet code is shared as **modules**, with a public collection called the Puppet Forge, and the data
that differs per machine or environment is usually kept apart from the code in **Hiera**. Both are
worth recognising in an existing codebase; neither is needed to read one manifest.
