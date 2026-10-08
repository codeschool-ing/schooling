# Where lesson 3 leaves the database: the lab CA's certificate on the server,
# TLS 1.3 at least, TLS required by pg_hba.conf with etl_loader logging in by
# client certificate, the CA in ana's ~/.postgresql/root.crt, pgcrypto in the
# schema `crypto`, and lesson 3's first attempt at column encryption (cpf_enc,
# with the key in the SQL) still in the table for lesson 4 to replace.
set -euo pipefail
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
install -o postgres -g postgres -m 644 $PKI/db.crt $PKI/ca.crt /etc/postgresql/16/gov/
install -o postgres -g postgres -m 600 $PKI/db.key /etc/postgresql/16/gov/
cat > /etc/postgresql/16/gov/pg_hba.conf <<'HBA'
# TYPE     DATABASE  USER        ADDRESS        METHOD
local      all       postgres                   peer
local      ipe       ana                        peer
hostnossl  all       all         all            reject
hostssl    ipe       etl_loader  127.0.0.1/32   cert
hostssl    ipe       all         127.0.0.1/32   scram-sha-256
host       all       all         all            reject
HBA
chown postgres:postgres /etc/postgresql/16/gov/pg_hba.conf
chmod 640 /etc/postgresql/16/gov/pg_hba.conf
pg <<'SQL' >/dev/null
ALTER SYSTEM SET ssl_cert_file = '/etc/postgresql/16/gov/db.crt';
ALTER SYSTEM SET ssl_key_file  = '/etc/postgresql/16/gov/db.key';
ALTER SYSTEM SET ssl_ca_file   = '/etc/postgresql/16/gov/ca.crt';
ALTER SYSTEM SET ssl_min_protocol_version = 'TLSv1.3';
SELECT pg_reload_conf();
CREATE SCHEMA crypto;
CREATE EXTENSION pgcrypto SCHEMA crypto;
GRANT USAGE ON SCHEMA crypto TO ipe_owner;
SET ROLE ipe_owner;
ALTER TABLE sales.customers ADD COLUMN cpf_enc bytea;
UPDATE sales.customers SET cpf_enc = crypto.pgp_sym_encrypt(cpf, 'chave-da-ipe-2026');
SQL
mkdir -p /home/ana/.postgresql
cp $PKI/ca.crt /home/ana/.postgresql/root.crt
openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
  -keyout $GOV/etl_loader.key -subj "/O=Farmacia Ipe/CN=etl_loader" -out $GOV/etl_loader.csr 2>/dev/null
openssl x509 -req -in $GOV/etl_loader.csr -CA $PKI/ca.crt -CAkey $PKI/ca.key -days 90 \
  -sha256 -out $GOV/etl_loader.crt 2>/dev/null
chmod 600 $GOV/etl_loader.key
sed -i '/^user=/a sslmode=verify-full' /home/ana/.pg_service.conf
chown -R ana:ana /home/ana/.postgresql $GOV
