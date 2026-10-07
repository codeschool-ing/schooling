---
title: Salt, states in YAML with Jinja around them
version: 2
---

Salt calls its descriptions **states**, kept in `.sls` files, and writes them in YAML. Before the YAML
is read, each file goes through **Jinja**, the same template language lesson 18 uses for its
templates, so a state file can hold variables, loops and conditions. The rest of the vocabulary is
short: the server is the *master*, the agent is the *minion*, the facts a minion gathers about its
machine are *grains*, and data a master hands to particular minions, secrets among it, is *pillar*.

**Installing Salt.** Salt is a Python program, and it goes into an environment of its own with
`pipx`, which lesson 14 installed. If you skipped that lesson, run `sudo apt-get install -y pipx`
and `pipx ensurepath`, and open a new terminal. Then:

```sh
pipx install salt==3008.3
```

There is no master here, as there is no Puppet server. Salt runs masterless with `salt-call --local`,
as Ana, an ordinary user, from a directory she owns, `~/shop/salt`. The minion's configuration is the
file `etc/minion` in that directory, and it says where everything is:

```yaml
id: laptop
user: ana
file_client: local
root_dir: /home/ana/shop/salt/run
file_roots:
  base:
    - /home/ana/shop/salt/states
```

`file_client: local` is the masterless switch: read states from this machine's disk instead of asking a
master. `file_roots` is that place. `root_dir` moves the cache, the logs and the keys Salt would keep
under `/var` and `/etc` into Ana's directory, and `user: ana` stops Salt expecting to be root. `id` is
the minion's name. In yours, put your own user name in place of `ana`, both in `user:` and in the
two paths. Left to itself, a minion also knows where it would look for a master:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc config.get master
local:
    salt
```

A host called `salt`, as Puppet's agent looks for `puppet`.

## A top file and a state

The **top file**, `states/top.sls`, says which states apply to which minions. `'*'` is every minion,
and `web` names `web.sls` in the same directory:

```yaml
base:
  '*':
    - web
```

The state itself is `states/web.sls`, with your own home in place of `/home/ana` in its first line:

```
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
```

Each block starts with an **ID** and calls a state function: `file.directory`, `file.managed`,
`cmd.run`. The first line is Jinja and sets `root`, and `{{ grains['os'] }}` writes a fact about the
machine into the page. The two **requisites** say the same things Puppet's relationships did:
`require` puts the directory before the file, and `onchanges` runs the command only when the page
changed. The grain it will use:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc grains.item os osrelease
local:
    ----------
    os:
        Ubuntu
    osrelease:
        24.04
```

## Test, apply, apply again

`test=True` is Salt's dry run, the counterpart of Puppet's `--noop`. `--state-output=terse` prints one
line per state:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc state.apply test=True --state-output=terse
local:
  Name: /home/ana/www - Function: file.directory - Result: Differs - Started: 12:28:34.769907 - Duration: 3.206 ms
  Name: /home/ana/www/index.html - Function: file.managed - Result: Differs - Started: 12:28:34.773342 - Duration: 2.283 ms
  Name: echo reloaded >> /home/ana/www/reloads.log - Function: cmd.run - Result: Differs - Started: 12:28:34.776856 - Duration: 0.378 ms

Summary for local
------------
Succeeded: 3 (unchanged=3, changed=3)
Failed:    0
------------
Total states run:     3
Total run time:   5.867 ms
```

`Differs` on all three: nothing exists yet. Then the real run, with the changes shown in full:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc state.apply --state-output=changes
local:
----------
          ID: /home/ana/www
    Function: file.directory
      Result: True
     Comment: 
     Started: 12:28:36.117267
    Duration: 3.326 ms
     Changes:   
              ----------
              /home/ana/www:
                  ----------
                  directory:
                      new
----------
          ID: /home/ana/www/index.html
    Function: file.managed
      Result: True
     Comment: File /home/ana/www/index.html updated
     Started: 12:28:36.120786
    Duration: 3.532 ms
     Changes:   
              ----------
              diff:
                  New file
              mode:
                  0644
----------
          ID: reload-web
    Function: cmd.run
        Name: echo reloaded >> /home/ana/www/reloads.log
      Result: True
     Comment: Command "echo reloaded >> /home/ana/www/reloads.log" run
     Started: 12:28:36.125298
    Duration: 4.487 ms
     Changes:   
              ----------
              pid:
                  9073
              retcode:
                  0
              stderr:
              stdout:

Summary for local
------------
Succeeded: 3 (changed=3)
Failed:    0
------------
Total states run:     3
Total run time:  11.345 ms
```

The directory is new, the file is new with mode `0644`, and the command ran because the file changed;
for `cmd.run` Salt reports the process id and the exit code, `retcode: 0`. **The summary is the line to
read first**: three states, three changed, none failed. The second run:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc state.apply --state-output=terse
local:
  Name: /home/ana/www - Function: file.directory - Result: Clean - Started: 12:28:37.505507 - Duration: 3.028 ms
  Name: /home/ana/www/index.html - Function: file.managed - Result: Clean - Started: 12:28:37.508741 - Duration: 3.496 ms
  Name: echo reloaded >> /home/ana/www/reloads.log - Function: cmd.run - Result: Clean - Started: 12:28:37.513170 - Duration: 0.007 ms

Summary for local
------------
Succeeded: 3
Failed:    0
------------
Total states run:     3
Total run time:   6.531 ms
```

`Clean` on all three. The command is clean too, because `onchanges` found nothing that changed.

Then the same hand edit as before, and a run that prints only the states that did something:

```
ana@laptop:~/shop/salt$ echo "<h1>closed</h1>" > ~/www/index.html
ana@laptop:~/shop/salt$ salt-call --local -c etc state.apply --state-verbose=False
local:
----------
          ID: /home/ana/www/index.html
    Function: file.managed
      Result: True
     Comment: File /home/ana/www/index.html updated
     Started: 12:28:38.943959
    Duration: 8.947 ms
     Changes:   
              ----------
              diff:
                  --- 
                  +++ 
                  @@ -1 +1 @@
                  -<h1>closed</h1>
                  +<h1>shop</h1> on Ubuntu
----------
          ID: reload-web
    Function: cmd.run
        Name: echo reloaded >> /home/ana/www/reloads.log
      Result: True
     Comment: Command "echo reloaded >> /home/ana/www/reloads.log" run
     Started: 12:28:38.954103
    Duration: 4.216 ms
     Changes:   
              ----------
              pid:
                  9242
              retcode:
                  0
              stderr:
              stdout:

Summary for local
------------
Succeeded: 3 (changed=2)
Failed:    0
------------
Total states run:     3
Total run time:  19.422 ms
```

The diff is the whole story: the hand edit is the `-` line, the description is the `+` line, and the
`+` line already has `Ubuntu` in it, filled in from the grain. Two states changed, and the third, the
directory, was already right.

## Order, and the renderer in front of the YAML

Salt runs states in the order they are written in the file, unless a requisite says otherwise. It
numbers them to do it, and `state.show_sls` shows what it received after Jinja had run:

```
ana@laptop:~/shop/salt$ salt-call --local -c etc state.show_sls web --out=yaml | grep -E "^  [^ ]|order"
  /home/ana/www:
    - order: 10000
  /home/ana/www/index.html:
    - order: 10001
  reload-web:
    - order: 10002
```

Ten thousand, ten thousand and one, ten thousand and two: file order. `state.show_sls` is worth more
than that, though. **Jinja runs first and produces text, and only then is the text read as YAML**, so a
mistake in a template can produce a perfectly valid state that says something else. Reading the
rendered result is how you see what Salt will actually do.

With a master, the same `web.sls` is applied from the master to every minion at once, with `salt '*'
state.apply`, and the minions run it the moment the command arrives. That is the push half of Salt,
over the connections the minions opened. The same channel runs any single command on every
minion, `salt '*' cmd.run 'uptime'`, which makes a Salt master a remote control as well as a
description.
