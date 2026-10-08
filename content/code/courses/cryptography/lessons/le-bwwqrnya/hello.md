---
title: The hellos: what each side offers and chooses
version: 1
---

**A TLS 1.3 handshake takes one round trip: the client sends one flight of messages, the server
answers with one, and the client can send data with its next.** Everything from lessons 1 to 9
happens inside it: a key exchange (lesson 7), a certificate chain (lessons 8 and 9), a signature
(lesson 3), HKDF (lesson 7) and AES-GCM (lesson 1). This lesson watches it on Vereda's portal.

## Four servers on your own machine

This lesson needs TLS servers to talk to, and OpenSSL has one built in, `openssl s_server`. Four of
them, each on its own port of `127.0.0.1` and each with one of lesson 8's certificates, cover
everything the lesson shows: the portal, done right, on 8443; the same certificate without the
issuing CA on 8444; the agenda's expired certificate on 8445; and the intranet's self-signed one on
8446. Section 05 is about the last three.

```sh
cd ~/lab
serve() { openssl s_server -accept "127.0.0.1:$1" -www -quiet "${@:2}" </dev/null >/dev/null 2>&1 & }
serve 8443 -cert pki/portal.pem -key pki/portal.key -cert_chain pki/issuing1.pem
serve 8444 -cert pki/portal.pem -key pki/portal.key
serve 8445 -cert pki/agenda.pem -key pki/agenda.key -cert_chain pki/issuing1.pem
serve 8446 -cert pki/intranet.pem -key pki/intranet.key
```

`serve` is a shell function, so that the four lines differ only in what differs. Each server runs
in the background until you stop it, which at the end of the lesson is
`pkill -f 'openssl s_server'`, or until the machine restarts; after a restart, type the five lines
again. Nothing outside the machine can reach them, because `127.0.0.1` is the machine talking to
itself.

## The handshake, message by message

`openssl s_client` connects to the portal, trusting Vereda's root, and `-trace` prints every
message. A trace is long and full of random bytes that change on every connection, so it goes
through `vcrypt tls-flow`, which keeps the message names and the fields this lesson discusses. It
is a reader for the trace and nothing more, and you do not need to follow its code to use it:

```py
# ~/lab/tools/tls-flow.py
"""vcrypt tls-flow: read the output of `openssl s_client -trace` on standard
input and print the handshake as a list of messages, with the fields lesson
10 talks about and none of the random bytes, which differ on every
connection. The trace itself is the evidence; this is a way of reading it."""
import re
import sys


def flow(lines):
    out, direction, encrypted = [], None, False
    msg = None
    pending_versions, in_versions = [], False
    for raw in lines:
        line = raw.rstrip("\n")
        if line.startswith("Sent Record"):
            direction, msg = "client -> server", None
            continue
        if line.startswith("Received Record"):
            direction, msg = "server -> client", None
            continue
        m = re.match(r"  Content Type = (\w+)", line)
        if m and m.group(1) == "ChangeCipherSpec":
            out.append(f"{direction}  ChangeCipherSpec")
            continue
        if line.startswith("  Inner Content Type") and not encrypted:
            encrypted = True
            out.append("---- everything below is encrypted with the handshake keys ----")
        m = re.match(r"  Inner Content Type = (\w+)", line)
        if m and m.group(1) == "ApplicationData":
            out.append(f"{direction}  application data (encrypted)")
            continue
        m = re.match(r"    ([A-Z][A-Za-z]+), Length=\d+", line)
        if m:
            msg = m.group(1)
            out.append(f"{direction}  {msg}")
            in_versions = False
            continue
        if msg is None:
            m = re.match(r"\s+Level=(\w+)\(\d+\), description=(.+)\(\d+\)", line)
            if m:
                out.append(f"{direction}  Alert: {m.group(1)}, {m.group(2)}")
            continue
        s = line.strip()
        if msg == "ClientHello":
            if "extension_type=server_name" in s:
                out.append("    server_name: (see below)")
            if s.startswith("extension_type=supported_versions"):
                in_versions = True
                continue
            if in_versions:
                m = re.match(r"(TLS \d\.\d)", s)
                if m:
                    pending_versions.append(m.group(1))
                    continue
                out.append("    offers versions: " + ", ".join(pending_versions))
                pending_versions, in_versions = [], False
            m = re.match(r"NamedGroup: (\S+)", s)
            if m:
                out.append(f"    key_share: {m.group(1)}")
            m = re.match(r"cipher_suites \(len=(\d+)\)", s)
            if m:
                out.append(f"    offers {int(m.group(1)) // 2} cipher suites")
        elif msg == "ServerHello":
            m = re.match(r"cipher_suite \{.*\} (\S+)", s)
            if m:
                out.append(f"    chosen cipher suite: {m.group(1)}")
            m = re.match(r"(TLS \d\.\d) \(\d+\)", s)
            if m:
                out.append(f"    chosen version: {m.group(1)}")
            m = re.match(r"NamedGroup: (\S+)", s)
            if m:
                out.append(f"    key_share: {m.group(1)}")
        elif msg == "Certificate":
            m = re.match(r"Subject: (.*)", s)
            if m:
                out.append(f"    certificate: {m.group(1).split('CN = ')[-1]}")
        elif msg == "CertificateVerify":
            m = re.match(r"Signature Algorithm: (\S+)", s)
            if m:
                out.append(f"    signed with: {m.group(1)}")
    # the server name sits in a hex dump; take it from the dump's text column
    text = "".join(lines)
    for i, l in enumerate(out):
        if l.endswith("(see below)"):
            m = re.search(r"server_name\(0\)[^\n]*\n((?:\s+[0-9a-f]{4} - .*\n)+)", text)
            name = ""
            if m and m.group(1):
                name = "".join(row.split("   ")[-1].strip() for row in m.group(1).splitlines())
                name = re.sub(r"^\.+", "", name)
            out[i] = f"    server_name: {name}"
    for l in lines:
        s = l.strip()
        if s.startswith("verify error:"):
            out.append("client: " + s)
        if s.startswith("New, ") or s.startswith("Verify return code") or s.startswith("Verification error"):
            out.append("result: " + s)
    return out


print("\n".join(flow(sys.stdin.readlines())))
```

The portal's handshake, read through it:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -trace 2>&1 | vcrypt tls-flow
client -> server  ClientHello
    offers 31 cipher suites
    server_name: portal.vereda.example
    offers versions: TLS 1.3, TLS 1.2
    key_share: ecdh_x25519
server -> client  ServerHello
    chosen cipher suite: TLS_AES_256_GCM_SHA384
    chosen version: TLS 1.3
    key_share: ecdh_x25519
server -> client  ChangeCipherSpec
---- everything below is encrypted with the handshake keys ----
server -> client  EncryptedExtensions
server -> client  Certificate
    certificate: portal.vereda.example
    certificate: Vereda Issuing CA 1
server -> client  CertificateVerify
    signed with: ecdsa_secp256r1_sha256
server -> client  Finished
client -> server  ChangeCipherSpec
client -> server  Finished
client -> server  application data (encrypted)
client -> server  Alert: warning, close notify
result: New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
result: Verify return code: 0 (ok)
```

The rest of this section reads the first two messages. The next one reads the rest.

## ClientHello

The client opens with everything the server needs to choose:

- **cipher suites** it supports, 31 here. In TLS 1.3 a suite names only the AEAD and the hash, such
  as `TLS_AES_256_GCM_SHA384`. The other 28 are older TLS 1.2 suites, offered in case the server is
  older;
- **supported versions**, TLS 1.3 and TLS 1.2. The version field in the record header still says
  1.2, or even 1.0, for compatibility with old middleboxes that would drop anything unfamiliar; the
  real negotiation happens in this extension;
- **server_name**, the host name the client wants, `portal.vereda.example`. This is **SNI**, and it
  lets one IP address serve many sites, each with its own certificate. It travels in clear text in
  the ClientHello, which is the main thing an observer of TLS 1.3 still learns. (Encrypted Client
  Hello, ECH, is being deployed to hide it.)
- **key_share**: the client's ephemeral X25519 public key, 32 bytes. The client does not wait to be
  asked; it guesses that the server supports X25519, and almost all do. That guess is what saves a
  round trip compared with TLS 1.2.

## ServerHello

The server picks one of everything:

- **version** TLS 1.3, **cipher suite** `TLS_AES_256_GCM_SHA384`;
- **key_share**: its own ephemeral X25519 public key.

At this point each side holds its own ephemeral private key and the other's public key, which is
exactly lesson 7's exchange. Both compute the same shared secret, run HKDF over it, and derive the
**handshake keys**. Everything after the ServerHello is encrypted with them, which is the line
`vcrypt tls-flow` draws. An observer of the network sees the two hellos and then only encrypted
records: not even the certificate is visible in TLS 1.3, unlike TLS 1.2.

The `ChangeCipherSpec` messages in the list carry nothing. TLS 1.3 sends them only because some
middleboxes break connections that do not look enough like TLS 1.2.
