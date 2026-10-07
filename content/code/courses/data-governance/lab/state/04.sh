# Where lesson 4 leaves the lab: OpenBao started, initialised with three key
# shares and a threshold of two, unseal keys and root token in
# /root/bao-init.txt (readable by root alone; lesson 4 says where they belong
# instead), unsealed, ana logged in with the root token; the transit engine
# with ipe-cpf (rotated to version 2, versions below 2 no longer decrypted)
# and ipe-backup; the site-app and support policies; and every CPF encrypted
# by OpenBao into sales.customers.cpf_ct, with lesson 3's cpf_enc gone.
set -euo pipefail
bash "$HERE/lab.sh" bao-start </dev/null >/dev/null 2>&1
as_ana() {
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(cat "$ENVFILE") bash -c "cd $GOV && $1"
}
as_ana 'bao operator init -key-shares=3 -key-threshold=2' > /root/bao-init.txt
chmod 600 /root/bao-init.txt
for n in 1 2; do
  k=$(sed -n "s/^Unseal Key $n: //p" /root/bao-init.txt)
  as_ana "bao operator unseal $k" >/dev/null
done
root=$(sed -n 's/^Initial Root Token: //p' /root/bao-init.txt)
as_ana "printf '%s' $root > ~/.vault-token && chmod 600 ~/.vault-token"
as_ana 'bao secrets enable transit >/dev/null
bao write -f transit/keys/ipe-cpf >/dev/null
bao write -f transit/keys/ipe-cpf/rotate >/dev/null
bao write transit/keys/ipe-cpf/config min_decryption_version=2 >/dev/null
bao write -f transit/keys/ipe-backup >/dev/null
printf "%s\n" "path \"transit/encrypt/ipe-cpf\" {" "  capabilities = [\"update\"]" "}" | bao policy write site-app - >/dev/null
printf "%s\n" "path \"transit/decrypt/ipe-cpf\" {" "  capabilities = [\"update\"]" "}" | bao policy write support - >/dev/null'
runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe -c "SET ROLE ipe_owner" \
  -c "ALTER TABLE sales.customers DROP COLUMN cpf_enc" -c "ALTER TABLE sales.customers ADD COLUMN cpf_ct text"
as_ana 'python3 - <<PY
import base64, csv, io, json, os, ssl, subprocess, urllib.request
TLS = ssl.create_default_context(cafile=os.environ["BAO_CACERT"])
TOKEN = open(os.path.expanduser("~/.vault-token")).read().strip()
def psql(sql):
    return subprocess.run(["psql", "-X", "-q", "-f", "-"], input=sql, capture_output=True, text=True, check=True).stdout
rows = list(csv.reader(io.StringIO(psql("SET ROLE ipe_owner;\nCOPY (SELECT customer_id, cpf FROM sales.customers ORDER BY 1) TO STDOUT (FORMAT csv);"))))
pairs = []
for i in range(0, len(rows), 250):
    chunk = rows[i:i + 250]
    body = json.dumps({"batch_input": [{"plaintext": base64.b64encode(c.encode()).decode()} for _, c in chunk]}).encode()
    req = urllib.request.Request(os.environ["BAO_ADDR"] + "/v1/transit/encrypt/ipe-cpf", data=body, method="POST", headers={"X-Vault-Token": TOKEN})
    with urllib.request.urlopen(req, context=TLS) as r:
        pairs += zip([c for c, _ in chunk], [b["ciphertext"] for b in json.load(r)["data"]["batch_results"]])
values = ",\n".join(f"({c}, \x27{ct}\x27)" for c, ct in pairs)
psql("SET ROLE ipe_owner;\nUPDATE sales.customers c SET cpf_ct = v.ct FROM (VALUES " + values + ") AS v(id, ct) WHERE c.customer_id = v.id;")
PY'
