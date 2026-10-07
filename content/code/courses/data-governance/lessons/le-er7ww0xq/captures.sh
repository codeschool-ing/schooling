#!/usr/bin/env bash
# The terminal sessions quoted in lesson 4 of data-governance, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it.
#
#   sudo bash ../../lab.sh up        # once
#   sudo LAB_SH=../../lab.sh bash captures.sh
#
# STAGED, and not typed in the lesson: the state lessons 1 to 3 leave
# (`lab.sh state 3`); OpenBao started as the user `bao` by `lab.sh bao-start`
# with the configuration lab.sh writes to /etc/bao/bao.hcl, which the lesson
# prints. The unseal keys and the root token are typed at OpenBao's hidden
# prompts by lab/typein.py, which prints the prompts and not the answers; they
# are read from the output of `bao operator init` that the lesson shows. Those
# keys are this lab's, generated on the run, and gone when it is reset.
#
# NOT RUN: every command of AWS KMS, Google Cloud KMS and Azure Key Vault. No
# account on any of them is reachable from where this was recorded, and the
# lesson says so beside each one.
#
# Every ciphertext, token and key in the output is random and differs from run
# to run; the lesson quotes none of them in its prose.
#
# Recorded on Ubuntu 24.04, PostgreSQL 16, OpenBao 2.5.5, 4 cores,
# TZ=America/Sao_Paulo.
. ../../lab/capture.sh
lab reset >/dev/null
lab state 3 >/dev/null
cp ../../lab/typein.py /usr/local/bin/typein.py
lab bao-start >/dev/null 2>&1 </dev/null
TYPEIN="python3 /usr/local/bin/typein.py"

block config
on 'cat /etc/bao/bao.hcl'

block status-new
on 'bao status'

block init
on 'bao operator init -key-shares=3 -key-threshold=2 | tee init.txt'
K1=$(lab exec "sed -n 's/^Unseal Key 1: //p' init.txt")
K3=$(lab exec "sed -n 's/^Unseal Key 3: //p' init.txt")
ROOT=$(lab exec "sed -n 's/^Initial Root Token: //p' init.txt")
quiet 'rm -f init.txt'

block unseal
printf 'ana@lab:~/gov$ %s\n' 'bao operator unseal'
lab exec "$TYPEIN $K1 -- bao operator unseal"
printf 'ana@lab:~/gov$ %s\n' 'bao operator unseal'
lab exec "$TYPEIN $K3 -- bao operator unseal"

block login
printf 'ana@lab:~/gov$ %s\n' 'bao login -no-print'
lab exec "$TYPEIN $ROOT -- bao login -no-print"
on 'bao token lookup -format=json | python3 -c "import json, sys; d = json.load(sys.stdin)['"'"'data'"'"']; print(d['"'"'policies'"'"'], d['"'"'ttl'"'"'])"'

block transit
on 'bao secrets enable transit'
on 'bao write -f transit/keys/ipe-cpf'

block encrypt
on "printf '372.874.168-09' | base64"
on 'bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk= > cpf.ct'
on 'cat cpf.ct; echo'
on 'bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo'

put site-app.hcl <<'EOF'
# The website encrypts a CPF when a customer signs up, and never reads one.
path "transit/encrypt/ipe-cpf" {
  capabilities = ["update"]
}
EOF
put support.hcl <<'EOF'
# Support decrypts a CPF to confirm who is calling, and never encrypts.
path "transit/decrypt/ipe-cpf" {
  capabilities = ["update"]
}
EOF
code site-app-hcl site-app.hcl
code support-hcl support.hcl
block policies
on 'bao policy write site-app site-app.hcl'
on 'bao policy write support support.hcl'
on 'bao token create -policy=site-app -ttl=1h -field=token > site-app.token && wc -c site-app.token'
on 'bao token create -policy=support -ttl=1h -field=token > support.token && wc -c support.token'

block policy-test
on 'BAO_TOKEN=$(cat site-app.token) bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk=; echo'
on 'BAO_TOKEN=$(cat site-app.token) bao write transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct)'
on 'BAO_TOKEN=$(cat support.token) bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo'
on 'BAO_TOKEN=$(cat support.token) bao read transit/keys/ipe-cpf'

block audit
on 'sudo tail -n 1 /var/log/bao/audit.log | python3 -m json.tool'

block datakey
on 'bao write -f transit/keys/ipe-backup'
on 'bao write -f -format=json transit/datakey/plaintext/ipe-backup > datakey.json && python3 -c "import json; d = json.load(open('"'"'datakey.json'"'"'))['"'"'data'"'"']; print(sorted(d))"'

block backup-encrypt
on "python3 -c \"import json; print(json.load(open('datakey.json'))['data']['ciphertext'])\" > backup.key.wrapped"
on "python3 -c \"import json; print(json.load(open('datakey.json'))['data']['plaintext'])\" > backup.key && rm datakey.json"
on 'sudo -u postgres pg_dump -d ipe -t sales.customers | openssl enc -aes-256-cbc -pbkdf2 -pass file:backup.key -out customers.sql.enc'
on 'shred -u backup.key && ls -l customers.sql.enc backup.key.wrapped'
on 'grep -c paula.cavalcanti customers.sql.enc'

block backup-restore
on 'bao write -field=plaintext transit/decrypt/ipe-backup ciphertext=$(cat backup.key.wrapped) > backup.key'
on 'openssl enc -d -aes-256-cbc -pbkdf2 -pass file:backup.key -in customers.sql.enc | grep paula.cavalcanti | cut -f 1-4; shred -u backup.key'

block rotate
on 'bao write -f transit/keys/ipe-cpf/rotate'
on 'bao read -field=latest_version transit/keys/ipe-cpf; echo'
on 'bao write -field=ciphertext transit/encrypt/ipe-cpf plaintext=MzcyLjg3NC4xNjgtMDk=; echo'
on 'bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct) | base64 -d; echo'

block rewrap
on 'bao write -field=ciphertext transit/rewrap/ipe-cpf ciphertext=$(cat cpf.ct); echo'
on 'bao write transit/keys/ipe-cpf/config min_decryption_version=2'
on 'bao write transit/decrypt/ipe-cpf ciphertext=$(cat cpf.ct)'

put column.sql <<'EOF'
-- Lesson 3's first attempt goes, and a column for ciphertext the
-- database receives and cannot read takes its place.
SET ROLE ipe_owner;
ALTER TABLE sales.customers DROP COLUMN cpf_enc;
ALTER TABLE sales.customers ADD COLUMN cpf_ct text;
EOF
code column-sql column.sql
block column
on 'psql -f column.sql'

put encrypt_cpf.py <<'EOF'
"""Encrypt every customer's CPF with the website's key, in batches, and
write the ciphertexts back. The database never sees the key: it receives
ciphertext, which it stores and cannot read."""
import base64, csv, io, json, os, ssl, subprocess, urllib.request

ADDR = os.environ["BAO_ADDR"]
TOKEN = open("site-app.token").read().strip()
TLS = ssl.create_default_context(cafile=os.environ["BAO_CACERT"])

def psql(sql):
    return subprocess.run(["psql", "-X", "-q", "-f", "-"], input=sql,
                          capture_output=True, text=True, check=True).stdout

def encrypt(values):
    body = json.dumps({"batch_input": [
        {"plaintext": base64.b64encode(v.encode()).decode()} for v in values]})
    req = urllib.request.Request(f"{ADDR}/v1/transit/encrypt/ipe-cpf",
                                 data=body.encode(), method="POST",
                                 headers={"X-Vault-Token": TOKEN})
    with urllib.request.urlopen(req, context=TLS) as r:
        return [b["ciphertext"] for b in json.load(r)["data"]["batch_results"]]

rows = list(csv.reader(io.StringIO(psql(
    "SET ROLE ipe_owner;\n"
    "COPY (SELECT customer_id, cpf FROM sales.customers ORDER BY 1) TO STDOUT (FORMAT csv);"))))
pairs = []
for i in range(0, len(rows), 250):
    chunk = rows[i:i + 250]
    pairs += zip([c for c, _ in chunk], encrypt([cpf for _, cpf in chunk]))
values = ",\n".join(f"({c}, '{ct}')" for c, ct in pairs)
psql("SET ROLE ipe_owner;\n"
     "UPDATE sales.customers c SET cpf_ct = v.ct\n"
     f"FROM (VALUES {values}) AS v(id, ct) WHERE c.customer_id = v.id;")
print(len(pairs), "CPFs encrypted by", ADDR)
EOF
code encrypt-py encrypt_cpf.py
block app-encrypt
on 'python3 encrypt_cpf.py'
on 'psql -c "SET ROLE ipe_owner" -c "SELECT customer_id, left(cpf_ct, 40) AS cpf_ct FROM sales.customers ORDER BY 1 LIMIT 3"'
CT1=$(lab exec 'psql -Atc "SET ROLE ipe_owner" -c "SELECT cpf_ct FROM sales.customers WHERE customer_id = 1"' | tail -1)
on "BAO_TOKEN=\$(cat support.token) bao write -field=plaintext transit/decrypt/ipe-cpf ciphertext=$CT1 | base64 -d; echo"

block shred-key
on 'bao write -f transit/keys/ipe-customer-4711'
CT2=$(lab exec "bao write -field=ciphertext transit/encrypt/ipe-customer-4711 plaintext=\$(printf 'notes about customer 4711' | base64)")
on "printf '%s\n' $CT2"
on 'bao write transit/keys/ipe-customer-4711/config deletion_allowed=true'
on 'bao delete transit/keys/ipe-customer-4711'
on "bao write transit/decrypt/ipe-customer-4711 ciphertext=$CT2"
