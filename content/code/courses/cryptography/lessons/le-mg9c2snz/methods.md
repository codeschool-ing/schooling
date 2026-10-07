---
title: EAP methods: EAP-TLS, PEAP and EAP-TTLS
version: 1
---

**EAP is a frame for authentication, not a method of its own. What a device actually proves, and how,
is decided by the EAP method, and three of them cover nearly every network in use.** All three start
the same way: a TLS session between the device and the RADIUS server, carried inside EAP, through an
access point that sees none of it.

| method | the server proves itself with | the person or device proves itself with |
| --- | --- | --- |
| EAP-TLS | a certificate | a certificate of its own, in the same TLS handshake |
| PEAP | a certificate | a password, through MSCHAPv2 inside the TLS tunnel |
| EAP-TTLS | a certificate | a password or another method, inside the tunnel |

## EAP-TLS: certificates on both sides

EAP-TLS is the TLS handshake of lesson 10 with one addition, the client certificate: the device
presents a certificate and proves it holds the private key, exactly as the server does. No password
crosses the network, so there is none to guess, phish or reuse. The cost is a certificate on every
device, issued and renewed by a CA, which is the PKI of lesson 8 put to work. Organisations that
manage their laptops with a device-management tool issue those certificates automatically, and
EAP-TLS is then the strongest choice and the least effort for staff.

## PEAP: a password inside a tunnel

PEAP keeps the server's certificate and replaces the client's with a password. The TLS session
becomes a tunnel, and inside it runs **MSCHAPv2**, Microsoft's challenge-response protocol from
1999. PEAP with MSCHAPv2 is the default on Windows and the commonest enterprise Wi-Fi in the world,
because it works with the accounts an organisation already has.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"PEAP drawn as nested layers. The outer layer is EAP, which carries only the outer identity, anonymous@vereda.example, readable by every access point and proxy on the way. Inside it, a TLS tunnel to the RADIUS server, opened only after the server&#x27;s certificate is checked. Inside the tunnel, MSCHAPv2 with the real identity, ana, and the password&#x27;s challenge and response, drawn in red because it is what an unchecked tunnel would hand to an impostor.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">EAP, readable on the way: outer identity</text><text x=\"684\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">anonymous@vereda.example</text><rect x=\"50\" y=\"56\" width=\"620\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"66\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">TLS tunnel, after checking the server&#x27;s certificate</text><rect x=\"80\" y=\"92\" width=\"560\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">MSCHAPv2: real identity, challenge and response</text><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ana</text></svg>", "caption": "PEAP: what each layer carries. The red core is only as safe as the certificate check around it."}
```

## PEAP on your own machine

No radio is needed to watch PEAP work. The access point only relays EAP between the laptop and a
RADIUS server, so a program that plays both the laptop and the access point, `eapol_test`, can talk
to a RADIUS server directly. Ubuntu packages both. Installing FreeRADIUS also starts it as a service
on every address, and the lab runs its own two instead, so the second line stops that one for good:

```sh
sudo apt-get install -y freeradius eapoltest
sudo systemctl disable --now freeradius
```

The two servers are Vereda's, on `127.0.0.1`, and an impostor, on `127.0.0.2`, which section 04
needs. One script starts both, from FreeRADIUS's own default configuration with a handful of lines
changed, each one commented:

```sh
#!/usr/bin/env bash
# ~/lab/bin/radius-servers
# sudo radius-servers start | stop: lesson 16's two RADIUS servers.
#
#   127.0.0.1  Vereda's own, with pki/radius-chain.pem; knows the user ana
#   127.0.0.2  an impostor, with pki/radius-impostor.pem: the same names,
#              issued by another root; knows nobody
#
# Both are FreeRADIUS, configured from Ubuntu's defaults in
# /etc/freeradius/3.0, offer PEAP, and accept the RADIUS secret
# lab-only-radius-secret from the loopback network. They listen on IPv4
# only: the defaults' IPv6 listeners would have the two fight over one
# address.
set -euo pipefail
lab=$(cd "$(dirname "$0")/.." && pwd)
run=/run/vereda-radius   # not in ~/lab: root writes here

server() {  # server NAME ADDRESS CERTIFICATE KEY INNER-PORT USERS
  local d=$run/$1
  rm -rf "$d"
  cp -r /etc/freeradius/3.0 "$d"
  printf 'client loopback {\n\tipaddr = 127.0.0.0/8\n\tsecret = lab-only-radius-secret\n}\n' > "$d/clients.conf"
  printf '%s\n' "$6" > "$d/mods-config/files/authorize"
  # run as root, so that it can read the keys in ~/lab
  sed -i 's/^\tuser = freerad/#&/; s/^\tgroup = freerad/#&/' "$d/radiusd.conf"
  sed -i "s|^\t\tprivate_key_password = whatever|#&|
          s|private_key_file = /etc/ssl/private/ssl-cert-snakeoil.key|private_key_file = $4|
          s|certificate_file = /etc/ssl/certs/ssl-cert-snakeoil.pem|certificate_file = $3|
          s|ca_file = /etc/ssl/certs/ca-certificates.crt|ca_file = $lab/pki/root.pem|
          s|default_eap_type = md5|default_eap_type = peap|" "$d/mods-available/eap"
  sed -i "s/port = 18120/port = $5/" "$d/sites-available/inner-tunnel"
  # Every IPv4 listener on ADDRESS instead of on all addresses; every IPv6
  # listener left out. A listener is a `listen { ... }` block, so this
  # counts braces rather than lines.
  python3 - "$d/sites-available/default" "$2" <<'PY'
import re
import sys
path, address = sys.argv[1], sys.argv[2]
text, out, i = open(path).read(), [], 0
while (j := text.find("listen {", i)) >= 0:
    depth, k = 0, j
    while True:
        depth += {"{": 1, "}": -1}.get(text[k], 0)
        if depth == 0 and text[k] == "}":
            break
        k += 1
    block = text[j:k + 1]
    out.append(text[i:j])
    if not re.search(r"^\s*ipv6addr", block, re.M):
        out.append(block.replace("ipaddr = *", f"ipaddr = {address}"))
    i = k + 1
out.append(text[i:])
open(path, "w").write("".join(out))
PY
  freeradius -d "$d" -l "$d/radius.log"
}

stop() {
  pkill -f "freeradius -d $run/" || true
}

start() {
  stop
  sleep 1
  mkdir -p "$run"
  server real 127.0.0.1 "$lab/pki/radius-chain.pem" "$lab/pki/radius.key" 18120 \
    'ana	Cleartext-Password := "lab only: ana na rede da equipe"'
  server impostor 127.0.0.2 "$lab/pki/radius-impostor.pem" "$lab/pki/radius-impostor.key" 18121 ''
  echo "RADIUS on 127.0.0.1 (Vereda's) and 127.0.0.2 (the impostor)"
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  *) echo "usage: sudo radius-servers start | stop" >&2; exit 2 ;;
esac
```

```sh
cd ~/lab
chmod +x bin/radius-servers
sudo ~/lab/bin/radius-servers start
```

They run until the machine restarts or you type `sudo ~/lab/bin/radius-servers stop`, and `start`
again restarts them.

The laptop's side is a profile in the format `wpa_supplicant` reads, the same file a Linux laptop
would use. It names the method, the person, the password and, in its last two lines, the server the
device is willing to talk to:

```sh
cd ~/lab
cat > peap.conf <<'EOF'
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
EOF
```

`eapol_test` plays the access point and the laptop at once, against Vereda's FreeRADIUS server. Its
debug output runs to a thousand lines, so it goes through `vcrypt eap-log`, which keeps the events
this lesson discusses and none of the session's keys. Like lesson 10's `tls-flow`, it is a reader
and nothing more:

```py
# ~/lab/tools/eap-log.py
"""vcrypt eap-log: read the debug output of `eapol_test` on standard input
and print what lesson 16 talks about: the identity sent in clear, the
method, the certificate the server presented and whether it was accepted,
what crossed inside the tunnel, and the result. The keys and nonces, which
differ on every run, are left out; the debug output itself is the evidence,
and this is a way of reading it."""
import re
import sys


def summary(lines):
    out, seen = [], set()

    def put(label, text):
        if text in seen:
            return
        seen.add(text)
        out.append(f"{label:27}{text}" if label else f"{'':27}{text}")

    attribute, certs = None, 0
    for raw in lines:
        line = raw.rstrip("\n")
        m = re.match(r"\s+Value: '(.+)'$", line)
        if m and attribute == "User-Name":
            put("outer identity, in clear:", m.group(1))
        m = re.match(r"\s+Attribute \d+ \(([\w-]+)\)", line)
        if m:
            attribute = m.group(1)
        m = re.search(r"CTRL-EVENT-EAP-METHOD EAP vendor 0 method \d+ \((\w+)\) selected", line)
        if m:
            put("method:", m.group(1))
        m = re.match(r"SSL: Using TLS version (\S+)", line)
        if m:
            put("TLS version:", m.group(1))
        m = re.search(r"CTRL-EVENT-EAP-PEER-CERT depth=(\d) subject='([^']+)'", line)
        if m:
            put("" if certs else "server certificate:", f"depth {m.group(1)}  {m.group(2)}")
            certs += 1
        m = re.search(r"CTRL-EVENT-EAP-PEER-ALT depth=(\d) (\S+)", line)
        if m:
            put("", f"depth {m.group(1)}  name {m.group(2)}")
        m = re.search(r"CTRL-EVENT-EAP-TLS-CERT-ERROR reason=\d+ depth=(\d) .* err='([^']+)'", line)
        if m:
            put("certificate REFUSED:", f"depth {m.group(1)}, {m.group(2)}")
        m = re.search(r"EAP: Status notification: local TLS alert \(param=(.+)\)", line)
        if m:
            put("", f"alert sent to the server: {m.group(1)}")
        if "EAP-PEAP: Phase 2 Request: type=1" in line:
            put("inside the tunnel:", "inner identity sent")
        if "EAP-MSCHAPV2: Generating Challenge Response" in line:
            put("", "MSCHAPv2 challenge answered")
        if "EAP-MSCHAPV2: Authentication succeeded" in line:
            put("", "MSCHAPv2: the server proved it knows the password")
        if line.startswith("PMK from EAPOL"):
            put("PMK:", "32 bytes, made by this session (not shown)")
        if line in ("SUCCESS", "FAILURE"):
            put("result:", line)
    return out


for line in summary(sys.stdin):
    print(line)
```

PEAP, read through it:

```
ana@lab:~/lab$ eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | vcrypt eap-log
outer identity, in clear:  anonymous@vereda.example
method:                    PEAP
TLS version:               TLSv1.2
server certificate:        depth 2  /C=BR/O=Vereda Fisioterapia/CN=Vereda Root CA
                           depth 1  /C=BR/O=Vereda Fisioterapia/CN=Vereda Issuing CA 1
                           depth 0  /C=BR/O=Vereda Fisioterapia/CN=radius.vereda.example
                           depth 0  name DNS:radius.vereda.example
inside the tunnel:         inner identity sent
                           MSCHAPv2 challenge answered
                           MSCHAPv2: the server proved it knows the password
PMK:                       32 bytes, made by this session (not shown)
result:                    SUCCESS
```

Read it from the top:

- The **outer identity**, `anonymous@vereda.example`, is the only name sent before the tunnel exists,
  and every access point and RADIUS proxy on the way can read it. The real one, `ana`, crossed only
  inside the tunnel. Setting `anonymous_identity` keeps the list of staff names off the air.
- The **server certificate** came with its chain, and the device accepted it. Section 04 is about that
  line.
- **MSCHAPv2 succeeded in both directions**: the device answered the server's challenge, and the server
  answered the device's, proving it knew the password too.
- The **PMK** came out of this session. Two sessions in a row give two different PMKs:

```
ana@lab:~/lab$ for i in 1 2; do eapol_test -c peap.conf -a 127.0.0.1 -s lab-only-radius-secret | grep 'PMK from EAPOL'; done | sort -u | wc -l
2
```

## Why MSCHAPv2 must never run outside a tunnel

MSCHAPv2 is built on the NT password hash and DES. In 2012 researchers showed that one recorded
MSCHAPv2 exchange reduces to finding a single 56-bit DES key, which a dedicated machine did
in under a day, and Microsoft has advised since then that MSCHAPv2 is only safe inside a tunnel. **PEAP is
that tunnel, and it protects MSCHAPv2 only if the device checked who is at the other end of it.** A
tunnel to the wrong server delivers the exchange to exactly the party it was meant to hide from.

EAP-TTLS has the same shape as PEAP and the same dependence. Inside its tunnel it may carry a plain
password (PAP), which is no worse than MSCHAPv2 once the tunnel is sound, and no better when it is not.
