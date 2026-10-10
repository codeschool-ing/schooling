#!/usr/bin/env bash
# The terminal sessions quoted in lesson 9 of db-administration, as a script
# that produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh build     # once
#   sudo bash captures.sh
#
# It starts where lesson 5 starts: PostgreSQL 16 with the course's database
# shop loaded.
#
# STAGED: the small filesystems this lesson fills are files formatted ext4 and
# mounted through a loop device, exactly as the lesson tells the student to
# make them. A container gets no /dev/loop* nodes of its own, so the script
# creates /dev/loop-control and /dev/loop0..63 before anything else; on the
# student's virtual machine they already exist and nothing needs doing. For
# the same reason the full WAL filesystem is grown offline (unmounted, then
# resize2fs on the file): the container is not allowed the online resize
# ioctl. The offline way is the one the lesson prints, and it works on the
# virtual machine too.
#
# pg_test_fsync's numbers are the recording computer's: a container whose
# disk is a virtual disk shared with other machines. They are slow, and they
# move between runs. The root filesystem's mount options are the recording
# computer's as well, inherited by the container.
#
# Everything the lesson creates is removed at the end: the tables, the
# tablespace, pg_wal moved back into the data directory, both filesystems
# unmounted and their files deleted.
set -uo pipefail
cd "$(dirname "$0")"
export LAB_NAME=${LAB_NAME:-db}
. ../../lab/capture.sh

lab reset 5
lab root '[ -e /dev/loop-control ] || mknod /dev/loop-control c 10 237; for i in $(seq 0 63); do [ -e /dev/loop$i ] || mknod /dev/loop$i b 7 $i; done'

block pages
printf 'SHOW block_size;\nSHOW wal_block_size;\nSELECT relpages, pg_relation_size(%s) AS bytes,\n       pg_relation_size(%s) / relpages AS bytes_per_page\n  FROM pg_class WHERE relname = %s;\n' "'customers'" "'customers'" "'customers'" | session shop
on 'stat --file-system --format="%T, block size %S" /var/lib/postgresql/16/main'

block filesystems
on 'findmnt --target /var/lib/postgresql/16/main'

block fsync
on 'sudo -u postgres /usr/lib/postgresql/16/bin/pg_test_fsync -s 2 -f /var/lib/postgresql/fsync-test'
on 'sudo mkdir /mnt/ram && sudo mount -t tmpfs -o size=64M tmpfs /mnt/ram && sudo chmod 1777 /mnt/ram'
on 'sudo -u postgres /usr/lib/postgresql/16/bin/pg_test_fsync -s 2 -f /mnt/ram/fsync-test | head -10'
lab as 'sudo umount /mnt/ram && sudo rmdir /mnt/ram'

block wal
on 'sudo du -sh /var/lib/postgresql/16/main/pg_wal'
on 'psql shop -Atc "SHOW max_wal_size"'
on 'sudo truncate -s 512M /srv/wal.img'
on 'sudo mkfs.ext4 -q /srv/wal.img'
on 'sudo mkdir /srv/wal'
on 'sudo mount -o loop /srv/wal.img /srv/wal'
on 'sudo systemctl stop postgresql@16-main'
on 'sudo mv /var/lib/postgresql/16/main/pg_wal /srv/wal/pg_wal'
on 'sudo -u postgres ln -s /srv/wal/pg_wal /var/lib/postgresql/16/main/pg_wal'
on 'sudo systemctl start postgresql@16-main'
on 'sudo ls -l /var/lib/postgresql/16/main | grep pg_wal'
on 'df -h /srv/wal'

block small
on 'sudo truncate -s 64M /srv/small.img'
on 'sudo mkfs.ext4 -q /srv/small.img'
on 'sudo mkdir /srv/small'
on 'sudo mount -o loop /srv/small.img /srv/small'
on 'df -h /srv/small'
on 'sudo tune2fs -l /srv/small.img | grep -E "^(Block count|Reserved block count|Block size)"'
on 'sudo install -d -o postgres -g postgres -m 700 /srv/small/pg'
printf "CREATE TABLESPACE small LOCATION '/srv/small/pg';\nCREATE TABLE filler (id bigint, pad text) TABLESPACE small;\nINSERT INTO filler SELECT i, repeat('x', 500) FROM generate_series(1, 200000) AS i;\nSELECT count(*) FROM filler;\nSELECT pg_size_pretty(pg_relation_size('filler'));\nSELECT count(*) FROM orders;\n" | session shop
on 'df -h /srv/small'
on 'sudo tail -n 3 /var/log/postgresql/postgresql-16-main.log'
printf 'VACUUM filler;\n' | session shop
on 'sudo tune2fs -m 0 "$(findmnt --noheadings --output SOURCE /srv/small)"'
on 'df -h /srv/small'
printf "VACUUM filler;\nSELECT pg_size_pretty(pg_relation_size('filler'));\n" | session shop
on 'df -h /srv/small'
on 'sudo tune2fs -m 5 "$(findmnt --noheadings --output SOURCE /srv/small)"'

block walfull
printf "CREATE TABLE walfill AS SELECT * FROM orders;\n" | session shop
on 'for i in 1 2 3 4 5 6; do psql shop -c "INSERT INTO walfill SELECT * FROM orders" || break; done'
lab as 'while pg_lsclusters -h | grep -q online; do sleep 0.5; done; sleep 2'
on 'pg_lsclusters'
on 'df -h /srv/wal'
on 'sudo grep -E "PANIC|terminated by signal|redo done|FATAL|shut down" /var/log/postgresql/postgresql-16-main.log | tail -n 7'

block grow
on 'sudo systemctl stop postgresql@16-main'
on 'sudo umount /srv/wal'
on 'sudo truncate -s 2G /srv/wal.img'
on 'sudo e2fsck -f -p /srv/wal.img'
on 'sudo resize2fs /srv/wal.img'
on 'sudo mount -o loop /srv/wal.img /srv/wal'
on 'df -h /srv/wal'
on 'sudo systemctl start postgresql@16-main'
on 'sudo tail -n 6 /var/log/postgresql/postgresql-16-main.log'
on 'psql shop -c "SELECT count(*) FROM walfill"'

block cleanup
printf 'DROP TABLE walfill;\nDROP TABLE filler;\nDROP TABLESPACE small;\n' | session shop
on 'sudo systemctl stop postgresql@16-main'
on 'sudo rm /var/lib/postgresql/16/main/pg_wal'
on 'sudo mv /srv/wal/pg_wal /var/lib/postgresql/16/main/pg_wal'
on 'sudo systemctl start postgresql@16-main'
on 'sudo umount /srv/wal /srv/small'
on 'sudo rm /srv/wal.img /srv/small.img && sudo rmdir /srv/wal /srv/small'
on 'pg_lsclusters'

lab down
