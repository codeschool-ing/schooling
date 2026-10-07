---
title: The keys a handshake produces
version: 1
---

**A TLS 1.3 handshake does not produce one key. It runs HKDF over the shared secret to produce a
small family of secrets, each for one direction and one stage, and derives the actual AES keys from
those.** Seeing them is useful when debugging, and the way to see them is a feature that must never
be switched on in production.

## The key log

OpenSSL, browsers and most TLS libraries can write the secrets of each connection to a file, the
*key log*, in a format Wireshark reads to decrypt a capture. `s_client -keylogfile` does it for the
lab connection:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -keylogfile session.keys >/dev/null 2>&1; grep -v '^#' session.keys | cut -d' ' -f1 | sort
CLIENT_HANDSHAKE_TRAFFIC_SECRET
CLIENT_TRAFFIC_SECRET_0
EXPORTER_SECRET
SERVER_HANDSHAKE_TRAFFIC_SECRET
SERVER_TRAFFIC_SECRET_0
```

Five secrets, one per line, each tagged with the ClientHello's random value so that a tool can match
it to its connection:

| secret | protects |
|---|---|
| `CLIENT_HANDSHAKE_TRAFFIC_SECRET` | the client's encrypted handshake messages, its Finished |
| `SERVER_HANDSHAKE_TRAFFIC_SECRET` | the server's EncryptedExtensions, Certificate, CertificateVerify and Finished |
| `CLIENT_TRAFFIC_SECRET_0` | application data from client to server |
| `SERVER_TRAFFIC_SECRET_0` | application data from server to client |
| `EXPORTER_SECRET` | keys that an application derives for its own use from the connection |

Each is as long as the suite's hash, SHA-384 here:

```
ana@lab:~/lab$ grep CLIENT_TRAFFIC_SECRET_0 session.keys | awk '{print length($3)/2 " bytes"}'
48 bytes
```

The `_0` counts: a long connection can update its keys, giving `_1`, `_2` and so on, so that a
single key never encrypts an unlimited amount of data. And the client and server directions have
separate keys, so a record sent one way cannot be reflected back the other way.

## What the log means for security

The key log is exactly what forward secrecy (lesson 7) promises nobody will ever have: the secrets
of a past session. With it, a recording of that session decrypts. So:

- it is a **debugging tool for your own traffic**, on your own machine, for the time it takes to find
  a bug;
- the `SSLKEYLOGFILE` environment variable switches it on in browsers, curl and many libraries, which
  means a variable left in a server's environment or a container image silently logs every session's
  keys. Checking for it belongs in the review of any production configuration;
- the file is deleted when the debugging is done.

Forward secrecy holds because the ephemeral keys and these secrets exist only in memory, for the
life of the connection. Writing them to disk undoes it on purpose, which is fine for a lab and a
serious incident on a server.
