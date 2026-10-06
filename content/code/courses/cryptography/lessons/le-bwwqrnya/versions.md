---
title: TLS 1.2, older versions, and what a server should accept
version: 1
---

**TLS 1.3 (2018) and TLS 1.2 (2008) are the only versions a server should accept today; SSL 2.0,
SSL 3.0, TLS 1.0 and TLS 1.1 are prohibited by their own standards bodies.** Most of what a TLS
configuration decides is which of TLS 1.2's many options to keep, because TLS 1.3 removed almost all
of the dangerous ones.

## The same server, over TLS 1.2

The lab's portal server accepts both versions. Forced to TLS 1.2, the client sees a longer
conversation:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_2 -trace 2>&1 | vcrypt tls-flow
client -> server  ClientHello
    offers 28 cipher suites
    server_name: portal.vereda.example
server -> client  ServerHello
    chosen cipher suite: TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384
server -> client  Certificate
    certificate: portal.vereda.example
    certificate: Vereda Issuing CA 1
server -> client  ServerKeyExchange
server -> client  ServerHelloDone
client -> server  ClientKeyExchange
client -> server  ChangeCipherSpec
client -> server  Finished
server -> client  NewSessionTicket
server -> client  ChangeCipherSpec
server -> client  Finished
client -> server  Alert: warning, close notify
result: New, TLSv1.2, Cipher is ECDHE-ECDSA-AES256-GCM-SHA384
result: Verify return code: 0 (ok)
```

The differences from the TLS 1.3 handshake of section 02:

- **two round trips.** The key exchange happens in `ServerKeyExchange` and `ClientKeyExchange`, after
  the hellos, because a TLS 1.2 client does not send a key share in its first message;
- **the certificate travels in clear text**, before any key exists, so an observer learns which
  certificate the server presented;
- the cipher suite names **everything**: `TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384` is an ephemeral
  elliptic-curve exchange (`ECDHE`), an ECDSA certificate, AES-256-GCM and SHA-384. Here it chose
  well, because this server's configuration and this client prefer the strong options.

## What is refused, and by whom

The client offers TLS 1.1 only if told to, and this OpenSSL refuses even that:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_1 2>&1 | grep -o 'no protocols available\|alert protocol version\|unsupported protocol' | head -1
no protocols available
```

OpenSSL 3's default security level will not speak TLS 1.0 or 1.1 at all. RFC 8996 deprecated both
in 2021, and browsers removed them in 2020. A server that still accepts them is a finding in any
audit, whatever its clients are.

A TLS 1.2 client that insists on `AES256-GCM-SHA384`, an **RSA key transport** suite with no forward
secrecy (lesson 7), gets nowhere either:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -tls1_2 -cipher AES256-GCM-SHA384 2>&1 | grep -o 'handshake failure\|no shared cipher\|no ciphers available' | head -1
handshake failure
```

The portal's certificate holds an ECDSA key, which cannot be used to encrypt a key for transport, so
there is no suite both sides can use. On a server with an RSA certificate, refusing those suites is a
configuration decision, and the right one.

## A configuration to aim for

The safe, widely compatible baseline is what Mozilla publishes as its *intermediate* configuration:

- versions: **TLS 1.3 and TLS 1.2** only;
- TLS 1.2 suites: only **ECDHE** (or DHE) key exchange with an **AEAD** cipher, AES-GCM or
  ChaCha20-Poly1305. No RSA key transport, no CBC, no RC4, no 3DES;
- certificates: P-256 or RSA-2048 and above, with the full chain served.

Tools that test a server against such a baseline from outside include `testssl.sh`, Qualys SSL Labs
and `nmap --script ssl-enum-ciphers`. The lab does not run them, because they connect to real
addresses; against a server you are responsible for, they turn this section into a report.
