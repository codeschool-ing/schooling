#!/usr/bin/env bash
# The terminal sessions quoted in lesson 23 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# TWO MACHINES, ONE AFTER THE OTHER.
#   1. The course server as lesson 5 onwards finds it (shop loaded). The drift
#      section makes a second cluster, 16/staging, to stand for a second
#      server, makes main drift with ALTER SYSTEM and ALTER DATABASE, compares
#      the two and puts everything back. The repository shop-db is made in
#      ana's home there and changes nothing on the server.
#   2. A fresh server in lesson 3's starting state: Ubuntu, no PostgreSQL. The
#      lesson tells the student to copy shop-db to a new machine; here the
#      same files are written into ana's home there, taken out of this
#      lesson's own .md (settings, 50-shop.conf, and provision.sh joined from
#      the parts of its schooling-example, as the copy button joins them) and
#      committed with the same commands. provision.sh is then run as printed.
#      apt installs from the machine's cache, with no network; the script
#      sends apt's output to /dev/null, so nothing of it is quoted.
#   The hand edit in "checking the running server" is a printf | tee into the
#   deployed file, standing for somebody's editor.
set -uo pipefail
export LAB_NAME=${LAB_NAME:-db}
cd "$(dirname "$0")"
. ../../lab/capture.sh
L=le-kxb8cf64

example() { # the program a schooling-example in FILE shows, as the copy button joins it
  python3 - "$LAB_DIR/lessons/$1" "$2" <<'PY'
import json, re, sys
text = open(sys.argv[1], encoding='utf-8').read()
hits = [json.loads(b) for b in re.findall(r'```schooling-example\n(.*?)\n```', text, re.S)]
hits = [h for h in hits if h.get('file') == sys.argv[2]]
assert len(hits) == 1, 'want one example of %s, found %d' % (sys.argv[2], len(hits))
sys.stdout.write('\n'.join(p['code'] for p in hits[0]['parts']) + '\n')
PY
}
pgsession() { lab root "su - postgres -c 'python3 /usr/local/lib/lab/session.py $*'"; }

repo() { # shop-db as one-file-per-concern and a-provisioning-script build it
  lab as 'git config --global user.name "Ana" && git config --global user.email ana@example.com && git config --global init.defaultBranch main'
  lab as 'mkdir -p shop-db/conf.d'
  fence $L/one-file-per-concern.md '# 50-shop.conf' | lab as 'cat > shop-db/conf.d/50-shop.conf'
  example $L/a-provisioning-script.md provision.sh | lab as 'cat > shop-db/provision.sh'
}

############################################################ 1. the course server
lab reset 5
fence $L/the-drift.md '-- settings.sql' | lab as 'cat > settings.sql'

block staging
on 'sudo pg_createcluster --start 16 staging >/dev/null'
on 'pg_lsclusters'

block make-drift
printf "ALTER SYSTEM SET work_mem = '64MB';\nSELECT pg_reload_conf();\nALTER DATABASE shop SET random_page_cost = 1.1;\n" | session shop

block compare
on "psql -XAt -F ' = ' -f settings.sql > main.txt"
on "sudo -u postgres psql -p 5433 -XAt -F ' = ' < settings.sql > staging.txt"
on 'diff main.txt staging.txt'

block where
printf "SELECT name, setting, unit, sourcefile, sourceline FROM pg_settings WHERE name = 'work_mem';\n\\\\drds\n" | session shop

block put-back
printf "ALTER SYSTEM RESET work_mem;\nALTER DATABASE shop RESET random_page_cost;\nSELECT pg_reload_conf();\n" | session shop
on 'sudo pg_dropcluster --stop 16 staging'
on 'pg_lsclusters'

block main-file
on 'wc -l /etc/postgresql/16/main/postgresql.conf'
on "grep -n '^include_dir' /etc/postgresql/16/main/postgresql.conf"

block repo
lab as 'git config --global user.name "Ana" && git config --global user.email ana@example.com && git config --global init.defaultBranch main'
on 'mkdir -p shop-db/conf.d'
fence $L/one-file-per-concern.md '# 50-shop.conf' | lab as 'cat > shop-db/conf.d/50-shop.conf'
on 'git -C shop-db init'
on 'git -C shop-db add conf.d/50-shop.conf'
on 'git -C shop-db commit -m "The shop server'"'"'s settings, one file"'

block repo-script
example $L/a-provisioning-script.md provision.sh | lab as 'cat > shop-db/provision.sh'
on 'git -C shop-db add provision.sh'
on 'git -C shop-db commit -m "provision.sh: build the shop server from nothing"'
on 'git -C shop-db log --oneline'
lab as 'rm -rf shop-db settings.sql main.txt staging.txt'

lab down

############################################################ 2. a new machine
lab reset 3
repo
lab as 'cd shop-db && git init -q && git add . && git commit -q -m "provision.sh and the shop settings"'

block first-run
on 'psql --version'
on 'sudo bash shop-db/provision.sh'
on 'sudo systemctl restart postgresql@16-main'
on 'sudo bash shop-db/provision.sh'

block change
on "sed -i 's/^work_mem = 16MB/work_mem = 32MB/' shop-db/conf.d/50-shop.conf"
on 'git -C shop-db diff'
on 'git -C shop-db commit -q -am "work_mem 32MB: the nightly report sorts on disk"'
on 'sudo bash shop-db/provision.sh'

block running
printf "SELECT name, setting, unit, sourceline, pending_restart FROM pg_settings WHERE sourcefile = '/etc/postgresql/16/main/conf.d/50-shop.conf' ORDER BY sourceline;\n" | pgsession postgres

block hand-edit
on "printf 'work_mem = 64MB\nlog_min_duraton_statement = 250ms\n' | sudo tee -a /etc/postgresql/16/main/conf.d/50-shop.conf"
on 'sudo systemctl reload postgresql@16-main'
lab as 'sleep 1'
on 'sudo tail -n 4 /var/log/postgresql/postgresql-16-main.log'

block file-settings
printf "SELECT sourceline, name, setting, applied, error FROM pg_file_settings WHERE sourcefile LIKE '%%50-shop.conf' ORDER BY sourceline;\nSHOW work_mem;\n" | pgsession postgres

block repo-wins
on 'diff shop-db/conf.d/50-shop.conf /etc/postgresql/16/main/conf.d/50-shop.conf'
on 'sudo bash shop-db/provision.sh'
printf "SELECT count(*) FROM pg_file_settings WHERE error IS NOT NULL;\nSHOW work_mem;\n" | pgsession postgres

lab down
