#!/usr/bin/env bash
# The terminal sessions quoted in lesson 2 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# Lesson 2 comes before the lesson that builds the server, so the student reads
# these rather than types them; the lesson says how to repeat them after
# lesson 3. The server here is in lesson 4's starting state (PostgreSQL and a
# role for ana) with MySQL 8.0 installed beside it from Ubuntu's archive, as the
# lesson's optional step says. SQL Server and Oracle were not run.
set -uo pipefail
cd "$(dirname "$0")"
. ../../lab/capture.sh

lab reset 4
lab as 'sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -q mysql-server-8.0 >/dev/null 2>&1'

block versions
on 'psql --version'
on 'mysql --version'

block processes
on 'ps -eo user,pid,cmd | grep -E "^(postgres|mysql) " | grep -v grep'

block datadirs
on 'psql -XAtc "SHOW data_directory"'
on 'sudo mysql -N -e "SELECT @@datadir"'
on 'sudo ls /var/lib/mysql'

block databases
printf '\\l\n' | session
on 'sudo mysql -t -e "SHOW DATABASES"'

block schemas
on 'sudo mysql -t -e "CREATE DATABASE shop; CREATE SCHEMA billing; SHOW DATABASES"'
printf 'CREATE SCHEMA billing;\n\\dn\n' | session

block users
on 'sudo mysql -t -e "SELECT user, host, plugin FROM mysql.user"'
printf "SELECT rolname, rolsuper, rolcanlogin FROM pg_roles WHERE rolname NOT LIKE 'pg\\_%%';\n" | session

block logs
on 'sudo ls /var/log/mysql /var/log/postgresql'

block strict
# not quoted; proves the sentence in "Why this course is PostgreSQL-shaped"
on "sudo mysql -e \"SELECT '1abc' = 1; SHOW WARNINGS\""
on "psql -XAc \"SELECT '1abc' = 1\""

lab down
