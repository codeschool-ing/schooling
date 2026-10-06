---
title: The hellos: what each side offers and chooses
version: 1
---

**A TLS 1.3 handshake takes one round trip: the client sends one flight of messages, the server
answers with one, and the client can send data with its next.** Everything from lessons 1 to 9
happens inside it: a key exchange (lesson 7), a certificate chain (lessons 8 and 9), a signature
(lesson 3), HKDF (lesson 7) and AES-GCM (lesson 1). This lesson watches it on Vereda's portal.

## The handshake in the lab

The lab runs `openssl s_server` on `127.0.0.1:8443` with the portal's certificate and its issuing
CA. `openssl s_client` connects, trusting Vereda's root, and `-trace` prints every message. A trace
is long and full of random bytes that change on every connection, so it goes through
`vcrypt tls-flow`, which keeps the message names and the fields this lesson discusses:

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
