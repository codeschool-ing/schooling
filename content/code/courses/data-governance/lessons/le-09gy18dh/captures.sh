#!/usr/bin/env bash
# The terminal sessions quoted in lesson 3 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lessons 1 and 2 leave
# (`lab.sh state 2`); the lab CA in /etc/ipe-pki and its certificate for
# db.ipe.example, made by `lab.sh up` with openssl, which the lesson reads and
# installs but does not issue. The passphrase of the LUKS demonstration is
# given on standard input by the script; a person types it at the prompt.
#
# NOT RUN: `cryptsetup open` and everything after it. Opening a LUKS volume
# needs the kernel's device-mapper, which the machine this was recorded on does
# not offer; in the virtual machine lesson 1 recommends it works, and the
# lesson shows the commands and says they were not run here.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, OpenSSL 3, cryptsetup 2.7,
# 4 cores, TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 2 >/dev/null

block snakeoil
on 'sudo -u postgres psql -c "SHOW ssl" -c "SHOW ssl_cert_file"'
on 'sudo openssl x509 -in /etc/ssl/certs/ssl-cert-snakeoil.pem -noout -subject -issuer'

block stat-ssl
on 'psql service=bruno -c "SELECT ssl, version, cipher FROM pg_stat_ssl WHERE pid = pg_backend_pid()"'

block disable
on 'psql "service=bruno sslmode=disable" -c "SELECT ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()"'

block verify-full-fails
on 'psql "service=bruno sslmode=verify-full" -c "SELECT 1"'

block lab-cert
on 'openssl x509 -in /etc/ipe-pki/db.crt -noout -subject -issuer -ext subjectAltName'
on 'openssl verify -CAfile /etc/ipe-pki/ca.crt /etc/ipe-pki/db.crt'

put tls.sql <<'EOF'
-- The server's own certificate, signed by the lab CA, instead of the one
-- Ubuntu generated on the day the cluster was made.
ALTER SYSTEM SET ssl_cert_file = '/etc/postgresql/16/gov/db.crt';
ALTER SYSTEM SET ssl_key_file  = '/etc/postgresql/16/gov/db.key';
ALTER SYSTEM SET ssl_ca_file   = '/etc/postgresql/16/gov/ca.crt';
ALTER SYSTEM SET ssl_min_protocol_version = 'TLSv1.3';
SELECT pg_reload_conf();
EOF
code tls-sql tls.sql
block install-cert
on 'sudo install -o postgres -g postgres -m 644 /etc/ipe-pki/db.crt /etc/ipe-pki/ca.crt /etc/postgresql/16/gov/'
on 'sudo install -o postgres -g postgres -m 600 /etc/ipe-pki/db.key /etc/postgresql/16/gov/'
on 'sudo -u postgres psql < tls.sql'

block client-ca
on 'mkdir -p ~/.postgresql && cp /etc/ipe-pki/ca.crt ~/.postgresql/root.crt'
on 'psql "service=bruno sslmode=verify-full" -c "SELECT ssl, version FROM pg_stat_ssl WHERE pid = pg_backend_pid()"'

block service-verify
on "sed -i '/^user=/a sslmode=verify-full' ~/.pg_service.conf && grep -c verify-full ~/.pg_service.conf"
on 'psql service=carla -c "SELECT current_user, ssl FROM pg_stat_ssl WHERE pid = pg_backend_pid()"'

block wrong-name
on 'psql "host=127.0.0.1 port=5433 dbname=ipe user=bruno sslmode=verify-full" -c "SELECT 1"'

put pg_hba.conf <<'EOF'
# TYPE     DATABASE  USER        ADDRESS        METHOD
local      all       postgres                   peer
local      ipe       ana                        peer
hostnossl  all       all         all            reject
hostssl    ipe       etl_loader  127.0.0.1/32   cert
hostssl    ipe       all         127.0.0.1/32   scram-sha-256
host       all       all         all            reject
EOF
code hba-ssl pg_hba.conf
block require-tls
on 'sudo install -o postgres -g postgres -m 640 pg_hba.conf /etc/postgresql/16/gov/'
on 'sudo -u postgres psql -c "SELECT pg_reload_conf()" >/dev/null'
on 'psql "service=bruno sslmode=disable" -c "SELECT 1"'

block client-cert
on 'openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes -keyout etl_loader.key -subj "/O=Farmacia Ipe/CN=etl_loader" -out etl_loader.csr'
on 'sudo openssl x509 -req -in etl_loader.csr -CA /etc/ipe-pki/ca.crt -CAkey /etc/ipe-pki/ca.key -days 90 -sha256 -out etl_loader.crt'
on 'chmod 600 etl_loader.key && openssl x509 -in etl_loader.crt -noout -subject -enddate'

block cert-login
on 'psql "host=db.ipe.example port=5433 dbname=ipe user=etl_loader sslmode=verify-full sslcert=etl_loader.crt sslkey=etl_loader.key" -c "SELECT current_user"'
on 'psql "host=db.ipe.example port=5433 dbname=ipe user=etl_loader sslmode=verify-full" -c "SELECT 1"'
on 'sudo tail -n 2 /var/log/postgresql/postgresql-16-gov.log'

block all-sessions
put sessions.sql <<'EOF'
SELECT a.usename, a.client_addr, s.ssl, s.version, s.client_dn
FROM pg_stat_ssl s JOIN pg_stat_activity a USING (pid)
WHERE a.backend_type = 'client backend'
ORDER BY a.usename;
EOF
code sessions-sql sessions.sql
on 'psql "host=db.ipe.example port=5433 dbname=ipe user=etl_loader sslmode=verify-full sslcert=etl_loader.crt sslkey=etl_loader.key" -c "SELECT pg_sleep(3)" >/dev/null & psql service=bruno -c "SELECT pg_sleep(3)" >/dev/null & sleep 1; sudo -u postgres psql < sessions.sql; wait'

block on-disk
on 'sudo -u postgres psql -c "CHECKPOINT"'
on 'sudo -u postgres psql -Atc "SELECT pg_relation_filepath('"'"'sales.customers'"'"')"'
on 'sudo grep -a -o -m 1 "paula.cavalcanti@example.com" /var/lib/postgresql/16/gov/base/16384/16389'

block luks
on 'truncate -s 32M volume.img'
lab exec "printf 'ana@lab:~/gov\$ %s\n' 'cryptsetup luksFormat --batch-mode volume.img'; printf 'lab-passphrase-2026' | cryptsetup luksFormat --batch-mode --key-file=- volume.img 2>&1"
on 'cryptsetup luksDump volume.img'
quiet 'rm -f volume.img'

block dump
on 'sudo -u postgres pg_dump -d ipe -t sales.customers | grep -m 1 "paula.cavalcanti"'

put pgcrypto.sql <<'EOF'
-- pgcrypto in a schema of its own: the public schema is closed to
-- everybody (lab/schema.sql), and functions should not live there anyway.
CREATE SCHEMA crypto;
CREATE EXTENSION pgcrypto SCHEMA crypto;
GRANT USAGE ON SCHEMA crypto TO ipe_owner;
EOF
code pgcrypto-sql pgcrypto.sql
block pgcrypto
on 'sudo -u postgres psql < pgcrypto.sql'
put encrypt.sql <<'EOF'
-- A FIRST ATTEMPT: the CPF encrypted by the database, with a key in the SQL.
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD COLUMN cpf_enc bytea;
UPDATE sales.customers
   SET cpf_enc = crypto.pgp_sym_encrypt(cpf, 'chave-da-ipe-2026');
SELECT customer_id, cpf, left(encode(cpf_enc, 'hex'), 40) AS cpf_enc
FROM sales.customers WHERE customer_id = 1;
EOF
code encrypt-sql encrypt.sql
block encrypt
on 'psql -f encrypt.sql'

put leak.sql <<'EOF'
ALTER SYSTEM SET log_statement = 'all';
SELECT pg_reload_conf();
EOF
code leak-sql leak.sql
block leak
on 'sudo -u postgres psql < leak.sql'
on "psql -c \"SET ROLE ipe_owner\" -c \"SELECT crypto.pgp_sym_decrypt(cpf_enc, 'chave-da-ipe-2026') FROM sales.customers WHERE customer_id = 1\""
on 'sudo grep -c "chave-da-ipe-2026" /var/log/postgresql/postgresql-16-gov.log'
on 'sudo grep -m 1 "pgp_sym_decrypt" /var/log/postgresql/postgresql-16-gov.log'
quiet 'sudo -u postgres psql -c "ALTER SYSTEM RESET log_statement" -c "SELECT pg_reload_conf()"'
