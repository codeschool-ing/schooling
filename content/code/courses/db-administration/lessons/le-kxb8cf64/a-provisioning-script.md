---
title: A provisioning script
version: 1
---

A file in a repository is half of the cure. The other half is a program that makes a server
match it, and the property that program needs above all is that **running it twice is the same as
running it once**. That property is called **idempotence**. A script with it can be run on a
machine with nothing on it, on a machine it built last month, and on a machine somebody has
edited by hand, and in each case it does only what is missing and says what that was.

The usual first attempt is a list of the commands somebody typed when building the first server:
`apt install`, `cp`, `echo >> pg_hba.conf`, `createuser`. It works once. The second time,
`createuser` fails because the role exists, `echo` adds the `pg_hba.conf` line a second time, and
the script stops halfway or, worse, carries on. **Every step has to check before it acts.** Here
is the whole script, in the parts that do that:

```schooling-example
{"language": "bash", "file": "provision.sh", "parts": [{"code": "#!/usr/bin/env bash\n# provision.sh: make this machine the shop's database server, or confirm\n# that it already is one. Run it as root, as often as you like.\nset -euo pipefail\nHERE=$(cd \"$(dirname \"$0\")\" && pwd)\ncd /\n", "note": "`set -euo pipefail` stops the script at the first command that fails, instead of carrying on and reporting success over a half-built server. `HERE` is the repository the script lives in, found from the script's own path, so it can be run from anywhere; `cd /` then keeps `sudo -u postgres` from complaining that it cannot enter your home directory."}, {"code": "ETC=/etc/postgresql/16/main\nchanged=no\nreload=no\nsay() { echo \"$*\"; changed=yes; }\n", "note": "`changed` records whether anything at all was done, `reload` whether the configuration was touched. `say` is how every step reports an action, and it sets `changed` as it prints, so a step cannot act without the script knowing."}, {"code": "if [ \"$(dpkg-query -W -f '${db:Status-Status}' postgresql 2>/dev/null)\" != installed ]; then\n    DEBIAN_FRONTEND=noninteractive apt-get install -y -q postgresql >/dev/null\n    say \"installed postgresql\"\nfi\n", "note": "**Check, then act.** Every step has this shape. Here the check is the package database: `dpkg-query` prints `installed` when PostgreSQL is there, and only otherwise does `apt-get` run. Its output goes to `/dev/null`, because this script's job is to say what it changed, in one line."}, {"code": "if ! cmp -s \"$HERE/conf.d/50-shop.conf\" \"$ETC/conf.d/50-shop.conf\"; then\n    install -o postgres -g postgres -m 644 \"$HERE/conf.d/50-shop.conf\" \"$ETC/conf.d/\"\n    say \"wrote $ETC/conf.d/50-shop.conf\"\n    reload=yes\nfi\n", "note": "`cmp -s` compares the repository's file with the deployed one and says nothing; it fails when they differ or when the deployed one does not exist yet. Only then is the file copied, with `install` setting its owner and mode in the same step, and only then is a reload asked for."}, {"code": "HBA='host    shop    shop_app    10.0.0.0/24    scram-sha-256'\nif ! grep -qxF \"$HBA\" \"$ETC/pg_hba.conf\"; then\n    echo \"$HBA\" >> \"$ETC/pg_hba.conf\"\n    say \"added the shop_app line to pg_hba.conf\"\n    reload=yes\nfi\n", "note": "`grep -qxF` looks for the whole line, exactly, as fixed text. A line already there is left alone; a missing one is appended. Appending is safe here only because nothing above it in Ubuntu's `pg_hba.conf` matches the network `10.0.0.0/24`."}, {"code": "if [ \"$reload\" = yes ]; then\n    systemctl reload postgresql@16-main\n    sleep 1\n    echo \"reloaded the configuration\"\nfi\n", "note": "**A reload only when something changed.** A reload is a signal, and the server applies it a moment later, so `sleep 1` gives it that moment before the script asks the server anything. A parameter that needs a restart is read here and left waiting; see the last part."}, {"code": "sql() { sudo -u postgres psql -XAtq -v ON_ERROR_STOP=1 -c \"$1\"; }\nif [ -z \"$(sql \"SELECT 1 FROM pg_roles WHERE rolname = 'shop_owner'\")\" ]; then\n    sql \"CREATE ROLE shop_owner NOLOGIN\"\n    say \"created role shop_owner\"\nfi\nif [ -z \"$(sql \"SELECT 1 FROM pg_roles WHERE rolname = 'shop_app'\")\" ]; then\n    sql \"CREATE ROLE shop_app LOGIN\"\n    say \"created role shop_app, with no password yet\"\nfi\nif [ -z \"$(sql \"SELECT 1 FROM pg_database WHERE datname = 'shop'\")\" ]; then\n    sudo -u postgres createdb --owner shop_owner shop\n    say \"created database shop\"\nfi\n", "note": "The same check-then-act for things that live inside the server. `sql` runs one statement as the `postgres` role and prints bare rows, so an empty answer means the role or database does not exist. `shop_app` gets no password: a password does not belong in a repository, and lesson 11 sets one with `\\password`. What each role may do is lessons 12 and 13."}, {"code": "waiting=$(sql \"SELECT string_agg(name, ', ') FROM pg_settings WHERE pending_restart\")\nif [ -n \"$waiting\" ]; then\n    echo \"RESTART NEEDED for: $waiting\"\nfi\nif [ \"$changed\" = no ]; then\n    echo \"nothing to change\"\nfi", "note": "**The script never restarts the server.** A restart drops every connection, and when to do that is a person's decision, so it says which parameters are waiting and stops. A run that did nothing says so — which is the line to look for the second time it runs."}]}
```

Save it as `shop-db/provision.sh` and commit it beside the configuration file:

```
ana@db:~$ git -C shop-db add provision.sh
ana@db:~$ git -C shop-db commit -m "provision.sh: build the shop server from nothing"
[main 2332b60] provision.sh: build the shop server from nothing
 1 file changed, 57 insertions(+)
 create mode 100644 provision.sh
ana@db:~$ git -C shop-db log --oneline
2332b60 provision.sh: build the shop server from nothing
6ab72d8 The shop server's settings, one file
```

## Where to run it

The script is written for **a new machine**: Ubuntu 24.04 built as lesson 3 built yours, and
stopped before `apt install postgresql`. A second virtual machine, or a copy of yours taken before
that step, is the right place. Copy the repository over however you move files between machines —
`git clone` from wherever you keep it, or `scp -r shop-db` — and run it there. On the recording
machine the same two files were written into a fresh server directly. Its prompt reads `ana@db`
too, because that is the name lesson 3 gives a server.

It is idempotent, so running it on your course server would not break anything, but it would not
be nothing either. Be clear about what it would do there: write `50-shop.conf`, which makes the
server listen on every address and asks for a restart for `shared_buffers`; append a line to
`pg_hba.conf`; and create the roles `shop_owner` and `shop_app`. It would **skip the database**,
because `shop` exists — and it would not notice that yours is owned by `ana` rather than
`shop_owner`, since the check asks only whether the name exists. That gap is worth remembering: a
script checks exactly what it was written to check.

## Twice

On the new machine, nothing is installed yet:

```
ana@db:~$ psql --version
-bash: line 1: psql: command not found
ana@db:~$ sudo bash shop-db/provision.sh
installed postgresql
wrote /etc/postgresql/16/main/conf.d/50-shop.conf
added the shop_app line to pg_hba.conf
reloaded the configuration
created role shop_owner
created role shop_app, with no password yet
created database shop
RESTART NEEDED for: listen_addresses, shared_buffers
ana@db:~$ sudo systemctl restart postgresql@16-main
ana@db:~$ sudo bash shop-db/provision.sh
nothing to change
```

The first run did every step and said so, one line each. It ended by reporting two parameters
waiting for a restart, because `listen_addresses` and `shared_buffers` are read only when the
server starts. On a machine nobody is connected to yet, now is a fine time, so the restart is the
next command. On a server in use it would wait for a quiet hour, and the script would go on
saying so every time it ran.

**The second run is the test of the script**, and it changed nothing: no file written, no line
added, no reload, no role. A provisioning script that changes something every time it runs is
either fighting another tool over the same file or carrying a bug, and either way you want to
know on the second run rather than the fiftieth.

## A change is a commit

Once a server is built this way, a change to it goes through the repository first. Edit the file,
read the difference, commit it with the reason, and run the script:

```
ana@db:~$ sed -i 's/^work_mem = 16MB/work_mem = 32MB/' shop-db/conf.d/50-shop.conf
ana@db:~$ git -C shop-db diff
diff --git a/conf.d/50-shop.conf b/conf.d/50-shop.conf
index 9150e27..714e6d4 100644
--- a/conf.d/50-shop.conf
+++ b/conf.d/50-shop.conf
@@ -2,7 +2,7 @@
 # defaults. provision.sh copies it into /etc/postgresql/16/main/conf.d/.
 listen_addresses = '*'               # the application connects from 10.0.0.0/24
 shared_buffers = 1GB                 # a quarter of a 4 GB machine (lesson 6)
-work_mem = 16MB
+work_mem = 32MB
 maintenance_work_mem = 256MB
 log_min_duration_statement = 500ms   # lesson 19
 log_lock_waits = on
ana@db:~$ git -C shop-db commit -q -am "work_mem 32MB: the nightly report sorts on disk"
ana@db:~$ sudo bash shop-db/provision.sh
wrote /etc/postgresql/16/main/conf.d/50-shop.conf
reloaded the configuration
```

`sed` stands in for your editor. `work_mem` needs only a reload, so this run printed no restart
line. The commit message carries the reason, which is what `git log` will answer with when
somebody asks in six months why this server sorts with 32 MB.
