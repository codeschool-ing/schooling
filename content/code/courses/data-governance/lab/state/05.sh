# Where lesson 5 leaves the lab: support reads customers only through the
# masked view support.customer_card, which finds them by cpf_hmac; every CPF
# has an HMAC from OpenBao's ipe-cpf-index key; the plaintext cpf column is
# gone; the support policy may decrypt ipe-cpf and HMAC with ipe-cpf-index;
# and the key ipe-analytics-ref exists for pseudonymous exports.
set -euo pipefail
as_ana() {
  # shellcheck disable=SC2046
  runuser -u ana -- env -i HOME=/home/ana USER=ana $(cat "$ENVFILE") bash -c "cd $GOV && $1"
}
pg() { runuser -u postgres -- env PGPORT=$PORT psql -X -q -v ON_ERROR_STOP=1 -d ipe "$@"; }
pg <<'SQL'
SET ROLE ipe_owner;
CREATE FUNCTION support.mask_cpf(cpf text) RETURNS text
  LANGUAGE sql IMMUTABLE
  RETURN '***.' || substr(cpf, 5, 7) || '-**';
CREATE FUNCTION support.mask_email(email text) RETURNS text
  LANGUAGE sql IMMUTABLE
  RETURN left(email, 1) || '***@' || split_part(email, '@', 2);
GRANT EXECUTE ON FUNCTION support.mask_cpf(text), support.mask_email(text) TO support_agent;
REVOKE SELECT ON sales.customers FROM support_agent;
ALTER TABLE sales.customers ADD COLUMN cpf_hmac text;
SQL
as_ana 'bao write -f transit/keys/ipe-cpf-index >/dev/null
bao write -f transit/keys/ipe-analytics-ref >/dev/null
printf "%s\n" "path \"transit/decrypt/ipe-cpf\" {" "  capabilities = [\"update\"]" "}" "path \"transit/hmac/ipe-cpf-index\" {" "  capabilities = [\"update\"]" "}" | bao policy write support - >/dev/null'
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
    body = json.dumps({"batch_input": [{"input": base64.b64encode(c.encode()).decode()} for _, c in chunk]}).encode()
    req = urllib.request.Request(os.environ["BAO_ADDR"] + "/v1/transit/hmac/ipe-cpf-index", data=body, method="POST", headers={"X-Vault-Token": TOKEN})
    with urllib.request.urlopen(req, context=TLS) as r:
        pairs += zip([c for c, _ in chunk], [b["hmac"] for b in json.load(r)["data"]["batch_results"]])
values = ",\n".join(f"({c}, \x27{h}\x27)" for c, h in pairs)
psql("SET ROLE ipe_owner;\nUPDATE sales.customers c SET cpf_hmac = v.h FROM (VALUES " + values + ") AS v(id, h) WHERE c.customer_id = v.id;")
PY'
pg <<'SQL'
SET ROLE ipe_owner;
CREATE INDEX ON sales.customers (cpf_hmac);
CREATE OR REPLACE VIEW sales.customer_profile AS
SELECT customer_id,
       state,
       CASE WHEN age < 18 THEN 'under 18'
            WHEN age < 30 THEN '18-29'
            WHEN age < 50 THEN '30-49'
            WHEN age < 70 THEN '50-69'
            ELSE '70+' END AS age_band,
       created_at::date AS customer_since
FROM (SELECT customer_id, state, created_at,
             extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age
      FROM sales.customers) c;
ALTER TABLE sales.customers DROP COLUMN cpf;
CREATE VIEW support.customer_card WITH (security_barrier) AS
SELECT customer_id, full_name, cpf_hmac, cpf_ct,
       support.mask_email(email) AS email, city, state
FROM sales.customers
WHERE state IN (SELECT r.state FROM support.agent_regions r
                WHERE r.agent = current_user);
GRANT SELECT ON support.customer_card TO support_agent;
SQL
