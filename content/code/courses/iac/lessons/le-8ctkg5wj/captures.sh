#!/usr/bin/env bash
# The terminal sessions quoted in lesson 19 of iac, as a script that produces
# them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it, so the next person can run it and see
# what moved.
#
#   sudo bash ../../lab.sh tools     # once: the software the lab runs
#   sudo bash captures.sh
#
# Puppet (Ubuntu's package) and Salt run here as ana, on the laptop itself,
# with no server and no master: `puppet apply` and `salt-call --local`. They
# manage files in ana's home, standing in for /etc and /var/www on a server,
# because ana is not root and the lab has no network to install a package
# from. The one manifest that names a package and a service is run with
# --noop, and once without it to show the refusal. No containers are used,
# and moto plays no part in this lesson.
#
# Chef is not installed in the lab. Its recipe in the lesson is illustrative
# and was never run; the last block below only shows that it is not here.
#
# What is STAGED rather than typed, and not shown in the lesson: the files ana
# wrote (put below), whose contents the lesson shows in full, and Puppet's
# certname, set to `laptop` in ana's puppet.conf so that the name Puppet
# prints is the one in the prompt rather than the lab machine's hostname. The
# timings and the Salt pids in the output change on every run.
#
# Recorded on Ubuntu 24.04, TZ=America/Sao_Paulo.

. "$(dirname "$0")/../../capture.sh"

quiet 'mkdir -p ~/.puppet/etc && printf "[main]\ncertname = laptop\n" > ~/.puppet/etc/puppet.conf'

block pull-settings
run 'puppet config print --section agent runinterval server certname'

mkdir -p shop/puppet && cd shop/puppet
block puppet
put site.pp <<'CODE'
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
CODE
block puppet-validate
run 'puppet parser validate site.pp && echo valid'
block puppet-apply-1
run 'puppet apply site.pp'
block puppet-apply-2
run 'puppet apply site.pp'
block puppet-drift
run 'echo "listen 8080;" > ~/web/shop.conf'
run 'puppet apply site.pp'
run 'cat ~/web/shop.conf ~/web/reloads.log'

block puppet-server
put server.pp <<'CODE'
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
CODE
block puppet-noop
run 'puppet apply --noop server.pp'
block puppet-not-root
run 'puppet apply server.pp'
block puppet-resource
run 'puppet resource package nginx'

cd ~
mkdir -p shop/salt && cd shop/salt
block salt
put etc/minion <<'CODE'
id: laptop
user: ana
file_client: local
root_dir: /home/ana/shop/salt/run
file_roots:
  base:
    - /home/ana/shop/salt/states
CODE
put states/top.sls <<'CODE'
base:
  '*':
    - web
CODE
put states/web.sls <<'CODE'
{% set root = '/home/ana/www' %}
{{ root }}:
  file.directory:
    - mode: '0755'

{{ root }}/index.html:
  file.managed:
    - contents: "<h1>shop</h1> on {{ grains['os'] }}"
    - mode: '0644'
    - require:
      - file: {{ root }}

reload-web:
  cmd.run:
    - name: echo reloaded >> {{ root }}/reloads.log
    - onchanges:
      - file: {{ root }}/index.html
CODE
block salt-master
run 'salt-call --local -c etc config.get master'
block salt-grains
run 'salt-call --local -c etc grains.item os osrelease'
block salt-test
run 'salt-call --local -c etc state.apply test=True --state-output=terse'
block salt-apply-1
run 'salt-call --local -c etc state.apply --state-output=changes'
block salt-apply-2
run 'salt-call --local -c etc state.apply --state-output=terse'
block salt-drift
run 'echo "<h1>closed</h1>" > ~/www/index.html'
run 'salt-call --local -c etc state.apply --state-verbose=False'
block salt-order
run 'salt-call --local -c etc state.show_sls web --out=yaml | grep -E "^  [^ ]|order"'

block chef
run 'command -v chef-client cinc-client knife || echo "none of them"'
