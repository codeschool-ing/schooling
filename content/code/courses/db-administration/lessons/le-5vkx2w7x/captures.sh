#!/usr/bin/env bash
# The terminal sessions quoted in lesson 5 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 4 ends: PostgreSQL 16 from Ubuntu's packages, a
# superuser role and a database for ana, and the shop database loaded. The
# conf.d file the lesson asks for is taken out of the lesson's own .md. The
# student edits pg_hba.conf with an editor; here the same one-line edit is
# made with sed, and the line is printed after it. Everything the lesson
# changes is undone before the end, as the lesson's last section says.
#
# STAGED: the machine's network has only loopback in it, so "another address"
# in the-handful is 127.0.0.2, which is still this machine. The lab has no
# IPv6 on loopback, so the server listens on 127.0.0.1 only where a virtual
# machine also shows [::1]:5432; the lesson says so.
set -uo pipefail
cd "$(dirname "$0")"
export LAB_NAME=${LAB_NAME:-db}
. ../../lab/capture.sh

lab reset 5

C=/etc/postgresql/16/main
LOG=/var/log/postgresql/postgresql-16-main.log

block where
printf 'ana@db:~$ psql\n'
printf 'SHOW config_file;\nSHOW hba_file;\nSHOW work_mem;\n\\q\n' | session
on "wc -l $C/postgresql.conf"
on "grep -Ev '^\\s*(#|$)' $C/postgresql.conf"
on "sed -n 129,135p $C/postgresql.conf"
on "ls -l $C/conf.d"

block settings
printf 'ana@db:~$ psql\n'
printf "SELECT name, setting, unit, source, sourceline, context\n  FROM pg_settings\n WHERE name IN ('shared_buffers', 'work_mem', 'max_connections',\n                'log_min_duration_statement', 'data_directory');\nSHOW shared_buffers;\nSELECT count(*) FROM pg_settings;\nSELECT context, count(*) FROM pg_settings GROUP BY context ORDER BY count(*) DESC;\n\\\\q\n" | session

block reload
fence le-5vkx2w7x/reload-or-restart.md '# /etc/postgresql/16/main/conf.d/50-course.conf' | lab root "cat > $C/conf.d/50-course.conf"
on "cat $C/conf.d/50-course.conf"
on 'sudo systemctl reload postgresql'
lab as 'sleep 1'
on "sudo tail -n 4 $LOG"
printf 'ana@db:~$ psql\n'
printf "SELECT name, setting, unit, pending_restart\n  FROM pg_settings\n WHERE name IN ('shared_buffers', 'log_min_duration_statement');\n\\\\q\n" | session
on 'sudo systemctl restart postgresql'
printf 'ana@db:~$ psql\n'
printf "SELECT name, setting, unit, pending_restart\n  FROM pg_settings\n WHERE name IN ('shared_buffers', 'log_min_duration_statement');\n\\\\q\n" | session

block typo
on "echo 'work_mem = 64mb' | sudo tee -a $C/conf.d/50-course.conf"
on 'sudo systemctl reload postgresql'
lab as 'sleep 1'
on "sudo tail -n 4 $LOG"
printf 'ana@db:~$ psql\n'
printf "SHOW work_mem;\nSELECT sourcefile, sourceline, name, setting, error\n  FROM pg_file_settings\n WHERE error IS NOT NULL;\n\\\\q\n" | session

block preflight
on "sudo -u postgres /usr/lib/postgresql/16/bin/postgres -C work_mem -c config_file=$C/postgresql.conf"
on "sudo sed -i '/^work_mem/d' $C/conf.d/50-course.conf"
on "sudo -u postgres /usr/lib/postgresql/16/bin/postgres -C work_mem -c config_file=$C/postgresql.conf"

block altersystem
printf 'ana@db:~$ psql\n'
printf "ALTER SYSTEM SET work_mem = '64mb';\nALTER SYSTEM SET work_mem = '16MB';\nSELECT pg_reload_conf();\nSHOW work_mem;\n\\\\q\n" | session
on 'sudo cat /var/lib/postgresql/16/main/postgresql.auto.conf'

block precedence
on "echo 'work_mem = 8MB' | sudo tee -a $C/conf.d/50-course.conf"
on 'sudo systemctl reload postgresql'
lab as 'sleep 1'
printf 'ana@db:~$ psql\n'
printf "SELECT seqno, sourcefile, sourceline, setting, applied\n  FROM pg_file_settings\n WHERE name = 'work_mem';\nSHOW work_mem;\n\\\\q\n" | session

block levels
printf 'ana@db:~$ psql\n'
printf "ALTER DATABASE shop SET work_mem = '32MB';\nALTER DATABASE shop SET shared_buffers = '1GB';\n\\\\c shop\nSELECT setting, unit, source FROM pg_settings WHERE name = 'work_mem';\nSET work_mem = '64MB';\nSELECT setting, unit, source FROM pg_settings WHERE name = 'work_mem';\nALTER DATABASE shop RESET work_mem;\nALTER SYSTEM RESET work_mem;\nSELECT pg_reload_conf();\n\\\\q\n" | session
on 'sudo cat /var/lib/postgresql/16/main/postgresql.auto.conf'

block hba
on "sudo grep -n -Ev '^\\s*(#|$)' $C/pg_hba.conf"
printf 'ana@db:~$ psql\n'
printf "SELECT line_number, type, database, user_name, address, auth_method\n  FROM pg_hba_file_rules;\n\\\\q\n" | session

block matched
on 'PGPASSWORD=not-my-password psql -h 127.0.0.1'
on "sudo tail -n 3 $LOG"

block narrow
lab root "sed -i '125s/^host    all             all/host    shop            all/' $C/pg_hba.conf"
on "sudo sed -n 125p $C/pg_hba.conf"
on 'sudo systemctl reload postgresql'
lab as 'sleep 1'
on 'PGPASSWORD=not-my-password psql -h 127.0.0.1'
on "sudo tail -n 1 $LOG"
on 'PGPASSWORD=not-my-password psql -h 127.0.0.1 shop'
lab root "sed -i '125s/^host    shop            all/host    all             all/' $C/pg_hba.conf"
on "sudo sed -n 125p $C/pg_hba.conf"
on 'sudo systemctl reload postgresql'

block listen
printf 'ana@db:~$ psql\n'
printf 'SHOW listen_addresses;\n\\q\n' | session
on "ss -ltn 'sport = 5432'"
on 'psql -h 127.0.0.2'
on "echo \"listen_addresses = '*'\" | sudo tee $C/conf.d/60-listen.conf"
on 'sudo systemctl restart postgresql'
on "ss -ltn 'sport = 5432'"
on 'psql -h 127.0.0.2'

block revert
on "sudo rm $C/conf.d/50-course.conf $C/conf.d/60-listen.conf"
on 'sudo systemctl restart postgresql'
on "ls -l $C/conf.d"
printf 'ana@db:~$ psql\n'
printf "SELECT name, setting, unit, source\n  FROM pg_settings\n WHERE name IN ('shared_buffers', 'work_mem', 'listen_addresses',\n                'log_min_duration_statement')\n    OR pending_restart;\n\\\\q\n" | session

lab down
