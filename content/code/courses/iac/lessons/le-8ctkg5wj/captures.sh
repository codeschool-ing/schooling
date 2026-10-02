. "$(dirname "$0")/../../capture.sh"
quiet 'mkdir -p ~/.puppet/etc && printf "[main]\ncertname = laptop\n" > ~/.puppet/etc/puppet.conf'
mkdir -p shop/puppet && cd shop/puppet
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
run 'puppet apply --noop server.pp'
run 'puppet apply server.pp'
cd ~
mkdir -p shop/salt && cd shop/salt
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
run 'salt-call --local -c etc state.apply test=True --state-output=terse'
run 'salt-call --local -c etc state.apply --state-output=changes'
run 'salt-call --local -c etc state.apply --state-output=terse'
run 'echo "<h1>closed</h1>" > ~/www/index.html'
run 'salt-call --local -c etc state.apply --state-verbose=False'
run 'salt-call --local -c etc state.show_sls web --out=yaml | head -20'
run 'salt-call --local -c etc grains.item os osrelease id'
