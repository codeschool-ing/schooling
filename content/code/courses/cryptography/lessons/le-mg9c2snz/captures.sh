#!/usr/bin/env bash
# The terminal sessions quoted in lesson 16 of cryptography, as a script that
# produces them.
#
# THE SCRIPT IS THE SOURCE AND ITS OUTPUT IS NOT COMMITTED. Every transcript in
# this lesson was copied from running it:
#
#   bash captures.sh            # beside this file; it finds ../../lab.sh
#
# It rebuilds ~/lab with lab.sh reset under its own HOME, so nothing of yours
# is touched, and prints each command after a prompt, ana@lab:~/lab$,
# followed by what it printed.
#
# What is STAGED rather than typed:
#
#   - the whole of ~/lab, built by lab.sh, including the two RADIUS
#     certificates: radius.pem, issued by Vereda's own CA, and
#     radius-impostor.pem, which carries the same names and is issued by the
#     lab's impostor root;
#   - two FreeRADIUS 3.2 servers, which this script configures from the
#     packaged defaults and starts (it must run as root to do so). The real one
#     answers on 127.0.0.1 with radius.pem and knows the user ana; the other
#     answers on 127.0.0.2 with radius-impostor.pem and knows nobody. Both
#     accept the RADIUS secret lab-only-radius-secret from the loopback
#     network. The IPv6 listeners of the packaged configuration are removed,
#     because the recording machine has no IPv6;
#   - peap.conf and peap-lax.conf, the two client profiles, written below and
#     shown in the lesson.
#
# eapol_test plays the access point and the laptop at once: it speaks EAP to
# a RADIUS server exactly as an access point relays it, with no radio. Its
# debug output is long and carries the session's random values, so the
# transcripts pass it through `vcrypt eap-log`, which keeps the events the
# lesson discusses and none of the keys; the PMK comparison prints only how
# many different PMKs two sessions produced.
#
# ana's password is the lab's own and protects nothing. Nothing here is
# pointed at a network the lab did not build.
#
# Recorded with FreeRADIUS 3.2.5 and eapol_test from wpa_supplicant 2.10,
# TZ=America/Sao_Paulo.

set -uo pipefail
here=$(cd "$(dirname "$0")" && pwd)
export TZ=America/Sao_Paulo LC_ALL=C.UTF-8 COLUMNS=100 PYTHONDONTWRITEBYTECODE=1
export HOME=${LAB_HOME:-/var/tmp/cryptography}
mkdir -p "$HOME"
bash "$here/../../lab.sh" reset >/dev/null
cd "$HOME/lab"
export PATH=$HOME/lab/bin:$PATH
on() { printf 'ana@lab:~/lab$ %s\n' "$*"; bash -c "$*" 2>&1; }
block() { printf '##### %s\n' "$1"; }

# --- the two RADIUS servers -------------------------------------------------
pkill -x freeradius 2>/dev/null; sleep 1
radius() { # radius DIR ADDRESS CERT KEY INNER_PORT USERS
    rm -rf "$1"; cp -r /etc/freeradius/3.0 "$1"
    printf 'client loopback {\n\tipaddr = 127.0.0.0/8\n\tsecret = lab-only-radius-secret\n}\n' > "$1/clients.conf"
    printf '%s\n' "$6" > "$1/mods-config/files/authorize"
    sed -i 's/^\tuser = freerad/#&/; s/^\tgroup = freerad/#&/' "$1/radiusd.conf"
    sed -i "s|^\t\tprivate_key_password = whatever|#&|
            s|private_key_file = /etc/ssl/private/ssl-cert-snakeoil.key|private_key_file = $4|
            s|certificate_file = /etc/ssl/certs/ssl-cert-snakeoil.pem|certificate_file = $3|
            s|ca_file = /etc/ssl/certs/ca-certificates.crt|ca_file = $HOME/lab/pki/root.pem|
            s|default_eap_type = md5|default_eap_type = peap|" "$1/mods-available/eap"
    sed -i "s/port = 18120/port = $5/" "$1/sites-available/inner-tunnel"
    python3 - "$1/sites-available/default" "$2" <<'PY'
import re
import sys
p, addr = sys.argv[1], sys.argv[2]
s, out, i = open(p).read(), [], 0
while True:
    j = s.find("listen {", i)
    if j < 0:
        out.append(s[i:]); break
    depth, k = 0, j
    while True:
        depth += {"{": 1, "}": -1}.get(s[k], 0)
        if depth == 0 and s[k] == "}":
            break
        k += 1
    blk = s[j:k + 1]
    out.append(s[i:j])
    if not re.search(r"^\s*ipv6addr", blk, re.M):
        out.append(blk.replace("ipaddr = *", f"ipaddr = {addr}"))
    i = k + 1
open(p, "w").write("".join(out))
PY
    freeradius -d "$1" -l "$1/radius.log"
}
chmod -R a+rX "$HOME/lab/pki"
radius "$HOME/radius-real" 127.0.0.1 "$HOME/lab/pki/radius-chain.pem" "$HOME/lab/pki/radius.key" 18120 \
    'ana	Cleartext-Password := "lab only: ana na rede da equipe"'
radius "$HOME/radius-fake" 127.0.0.2 "$HOME/lab/pki/radius-impostor.pem" "$HOME/lab/pki/radius-impostor.key" 18121 ''
sleep 2

cat > peap.conf <<'CONF'
network={
	ssid="Vereda-Equipe"
	key_mgmt=WPA-EAP
	eap=PEAP
	identity="ana"
	anonymous_identity="anonymous@vereda.example"
	password="lab only: ana na rede da equipe"
	phase2="auth=MSCHAPV2"
	ca_cert="pki/root.pem"
	domain_suffix_match="radius.vereda.example"
}
CONF
grep -v -e ca_cert -e domain_suffix_match peap.conf > peap-lax.conf

block cert
on "openssl x509 -in pki/radius.pem -noout -subject -issuer -ext subjectAltName,extendedKeyUsage"
on "openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/radius.pem"

block peap
on "cat peap.conf"
on "eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | vcrypt eap-log"
on "for i in 1 2; do eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | grep 'PMK from EAPOL'; done | sort -u | wc -l"

block impostor
on "openssl x509 -in pki/radius-impostor.pem -noout -subject -issuer -ext subjectAltName"
on "eapol_test -c peap.conf -a 127.0.0.2 -s lab-only-radius-secret | vcrypt eap-log"
on "diff peap.conf peap-lax.conf"
on "eapol_test -c peap-lax.conf -a 127.0.0.2 -s lab-only-radius-secret | vcrypt eap-log"

pkill -x freeradius
