#!/usr/bin/env bash
# The lab of the cryptography course: ~/lab, a directory of keys,
# certificates and data, and one command of its own, `vcrypt`, beside the
# openssl command line every lesson uses.
#
#   bash lab.sh reset      rebuild ~/lab from nothing
#
# It needs the openssl command line, xxd, Python 3.9 or later, and two Python
# packages: `cryptography` 44 or later (Argon2id arrived in 44) and `bcrypt`.
# No network, no account, no server outside the machine. Every lesson's
# captures.sh starts by running it. Set LAB to build it somewhere other than
# ~/lab.
#
# THE STORY. Vereda Fisioterapia is a small chain of physiotherapy clinics in
# São Paulo, with a patient portal at portal.vereda.example. Vereda is
# invented, and so is every name, record and password in ~/lab/data.
#
# WHAT IS IN IT
#
#   vlab/        the Python behind `vcrypt`: drbg.py (where every key comes
#                from, below), keys.py, pki.py (the certificate authority)
#                and cli.py (every subcommand)
#   bin/vcrypt   the command line
#   keys/        symmetric keys and IVs as hex, and the RSA, P-256, Ed25519
#                and X25519 key pairs of the asymmetric lessons
#   pki/         Vereda's CA: a root, an issuing CA, four server
#                certificates, a self-signed one, a CRL, and an impostor
#                root with the same name as the real one (pki.py lists them)
#   data/        what the lessons encrypt, hash and sign
#
# WHAT IS FIXED ON PURPOSE, AND WHY IT WOULD BE A DEFECT ANYWHERE ELSE
#
#   - EVERY KEY IS DERIVED FROM A PUBLIC LABEL (vlab/drbg.py), so that a
#     reset gives the same keys on every machine and the transcripts repeat
#     byte for byte. Anybody who reads this repository can rebuild them. That
#     is the lab's convenience and lesson 17's first mistake; no key from
#     here belongs anywhere but here.
#   - The IVs and nonces the captures pass are written in the captures, for
#     the same reason. Lesson 1 says why a real IV is never chosen like that,
#     and lesson 17 shows what a repeated nonce gives away.
#   - The lab's present is 2026-06-15 12:00 in São Paulo. Certificates carry
#     fixed dates and every check passes that instant explicitly (-attime),
#     so "expired" means the same thing whenever the capture is run.
#   - The weaknesses the lessons show are shown on this data and nothing
#     else: Vereda's own files, keys and lab-made password lists.

set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
LAB=${LAB:-$HOME/lab}

reset() {
  rm -rf "$LAB"
  mkdir -p "$LAB"/{bin,keys,data}
  cp -r "$here/lab/vlab" "$LAB/vlab"
  find "$LAB/vlab" -name '__pycache__' -prune -exec rm -rf {} +
  cat > "$LAB/bin/vcrypt" <<'SH'
#!/usr/bin/env bash
lab=$(cd "$(dirname "$0")/.." && pwd)
PYTHONPATH="$lab" PYTHONDONTWRITEBYTECODE=1 exec python3 -m vlab.cli "$@"
SH
  chmod +x "$LAB/bin/vcrypt"
  cd "$LAB"
  PYTHONPATH="$LAB" PYTHONDONTWRITEBYTECODE=1 python3 - <<'PY'
from vlab import drbg, keys, pki
w = lambda p, s: open(p, "w").write(s)
w("keys/aes-256.hex", drbg.stream("aes-256", 32).hex() + "\n")
w("keys/aes-256-b.hex", drbg.stream("aes-256-b", 32).hex() + "\n")
w("keys/aes-128.hex", drbg.stream("aes-128", 16).hex() + "\n")
w("keys/pepper.hex", drbg.stream("pepper", 32).hex() + "\n")
w("keys/webhook.hex", drbg.stream("webhook", 32).hex() + "\n")
w("keys/iv-a.hex", drbg.stream("iv-a", 16).hex() + "\n")
w("keys/iv-b.hex", drbg.stream("iv-b", 16).hex() + "\n")
for label, bits in (("rsa-2048", 2048), ("rsa-3072", 3072)):
    k = keys.rsa_key("keys/" + label, bits)
    keys.write_private(k, f"keys/{label}.key"); keys.write_public(k, f"keys/{label}.pub")
k = keys.ec_key("keys/p256"); keys.write_private(k, "keys/p256.key"); keys.write_public(k, "keys/p256.pub")
for who in ("ana", "bruno"):
    k = keys.ed25519_key("keys/ed25519-" + who)
    keys.write_private(k, f"keys/ed25519-{who}.key"); keys.write_public(k, f"keys/ed25519-{who}.pub")
    k = keys.x25519_key("keys/x25519-" + who)
    keys.write_private(k, f"keys/x25519-{who}.key"); keys.write_public(k, f"keys/x25519-{who}.pub")
pki.build("pki")
import hashlib, os
from vlab import webhook
from cryptography.hazmat.primitives import serialization
# Ana's Ed25519 key again, in OpenSSH's format, for ssh-keygen -Y in lesson 6.
k = keys.ed25519_key("keys/ed25519-ana")
open("keys/ana_ssh", "wb").write(k.private_bytes(serialization.Encoding.PEM,
    serialization.PrivateFormat.OpenSSH, serialization.NoEncryption()))
os.chmod("keys/ana_ssh", 0o600)
pub = k.public_key().public_bytes(serialization.Encoding.OpenSSH, serialization.PublicFormat.OpenSSH).decode()
open("keys/ana_ssh.pub", "w").write(pub + " ana@vereda.example\n")
open("data/allowed_signers", "w").write("ana@vereda.example " + pub + "\n")
# The SFTP server's host key for lesson 12, derived like every other key so
# that its fingerprint repeats.
k = keys.ed25519_key("keys/sftp-host")
open("keys/sftp_host_ed25519", "wb").write(k.private_bytes(serialization.Encoding.PEM,
    serialization.PrivateFormat.OpenSSH, serialization.NoEncryption()))
os.chmod("keys/sftp_host_ed25519", 0o600)
# Four deliveries from the payment gateway, as lesson 6 receives them. The
# lab's present is 1781535600 (2026-06-15 12:00 in Sao Paulo).
os.makedirs("data/webhooks", exist_ok=True)
key = drbg.stream("webhook", 32)
NOW = 1781535600
events = {
    "evt-1": (NOW - 42, b'{"event":"payment.confirmed","booking":4471,"amount":12000}', None),
    "evt-2": (NOW - 37, b'{"event":"payment.confirmed","booking":4472,"amount":15000}', b'{"event":"payment.confirmed","booking":4472,"amount":1500}'),
    "evt-3": (NOW - 86400, b'{"event":"payment.confirmed","booking":4471,"amount":12000}', None),
    "evt-4": (NOW - 12, b'{"event":"refund.issued","booking":4471,"amount":12000}', "nokey"),
}
for name, (t, body, delivered) in events.items():
    header = webhook.sign(key, t, body)
    if delivered == "nokey":
        header = webhook.sign(b"a key that is not the gateway's", t, body)
        delivered = None
    open(f"data/webhooks/{name}.json", "wb").write(delivered or body)
    open(f"data/webhooks/{name}.sig", "w").write(header + "\n")
os.makedirs("data/release", exist_ok=True)
open("data/release/portal-2.4.1.tar", "wb").write(drbg.stream("release/portal-2.4.1", 20480))
open("data/release/NOTES.txt", "w").write("Vereda portal 2.4.1: booking reminders by SMS.\n")
with open("data/release/SHA256SUMS", "w") as f:
    for n in ("NOTES.txt", "portal-2.4.1.tar"):
        f.write(hashlib.sha256(open("data/release/" + n, "rb").read()).hexdigest() + "  " + n + "\n")
PY
  data
}

data() {
  # Monday's thirty-two appointment slots in room 1, 08:00 to 16:45 in
  # quarters of an hour, one fixed-width record of sixteen bytes per slot, so
  # that a record is exactly one AES block. The time is the record's
  # position, as in any fixed-record file. Booked and free records repeat,
  # which is what lets lesson 1 read the pattern through ECB.
  : > "$LAB/data/slots.dat"
  for h in 08 09 10 11 13 14 15 16; do
    for m in 00 15 30 45; do
      case "$h$m" in
        0815|0900|0930|1000|1100|1330|1345|1500|1600|1630) printf 'room1 BOOKED   \n' ;;
        *) printf 'room1 free     \n' ;;
      esac >> "$LAB/data/slots.dat"
    done
  done
  # Eight staff accounts of the portal, with passwords the course wrote to
  # be bad in the usual ways: three people chose the same one, two more
  # share another. Nobody real has these passwords for anything.
  cat > "$LAB/data/users.csv" <<'TXT'
user,password
ana.lima,Vereda@2026
bruno.reis,fisio123
carla.souza,Vereda@2026
diego.alves,correct horse battery staple
elisa.prado,fisio123
fabio.nunes,Vereda@2026
gabi.torres,m4r3-alta-em-ub@tub@
hugo.matos,Primavera#2026
TXT
  # Two configuration files of the kind lesson 11 finds in real systems,
  # each holding a password that is encoded or obfuscated and called
  # protected. The password is the lab's own.
  cat > "$LAB/data/portal-secret.yaml" <<'TXT'
apiVersion: v1
kind: Secret
metadata:
  name: portal-db
type: Opaque
data:
  username: cG9ydGFs
  password: Vi1kYi1zM2NyZXQtMjAyNg==
TXT
  cat > "$LAB/data/scheduler.ini" <<'TXT'
[database]
host = db.vereda.example
user = scheduler
; password is protected (ROT13 then Base64, see the vendor's manual)
password = SS1xby1mM3BlcmctMjAyNg==
TXT
  cat > "$LAB/data/referral.txt" <<'TXT'
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
TXT
}

case "${1:-}" in
  reset) reset ;;
  *) echo "usage: bash lab.sh reset" >&2; exit 2 ;;
esac
