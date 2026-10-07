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

Here it is in the lab. The profile names the method, the person, the password and, in its last two
lines, the server the device is willing to talk to:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"PEAP drawn as nested layers. The outer layer is EAP, which carries only the outer identity, anonymous@vereda.example, readable by every access point and proxy on the way. Inside it, a TLS tunnel to the RADIUS server, opened only after the server&#x27;s certificate is checked. Inside the tunnel, MSCHAPv2 with the real identity, ana, and the password&#x27;s challenge and response, drawn in red because it is what an unchecked tunnel would hand to an impostor.\"><rect x=\"20\" y=\"20\" width=\"680\" height=\"160\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"36\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">EAP, readable on the way: outer identity</text><text x=\"684\" y=\"40\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">anonymous@vereda.example</text><rect x=\"50\" y=\"56\" width=\"620\" height=\"110\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"66\" y=\"76\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">TLS tunnel, after checking the server&#x27;s certificate</text><rect x=\"80\" y=\"92\" width=\"560\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">MSCHAPv2: real identity, challenge and response</text><text x=\"360\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">ana</text></svg>", "caption": "PEAP: what each layer carries. The red core is only as safe as the certificate check around it."}
```

```
ana@lab:~/lab$ cat peap.conf
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
```

`eapol_test` plays the access point and the laptop at once, against the lab's FreeRADIUS server.
Its debug output runs to a thousand lines; `vcrypt eap-log` keeps the events this lesson discusses:

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
