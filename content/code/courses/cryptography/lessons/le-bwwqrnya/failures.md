---
title: Five ways the handshake fails, and what each means
version: 1
---

**A certificate error is the client refusing to talk to a server it cannot identify, and every one
of them has a specific cause that can be found and fixed on the server.** Section 02 started four
servers, and three of them have a different problem each. `s_client` with `-verify_return_error` behaves like a browser: it
stops the handshake when a check fails. Only the verdict lines are shown here.

## A working one, for comparison

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -verify_hostname portal.vereda.example 2>&1 | grep -E '^Verif'
Verification: OK
Verified peername: portal.vereda.example
Verify return code: 0 (ok)
```

## The four failures

The server on 8444 has the right certificate but sends it **without** the issuing CA:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8444 -servername portal.vereda.example -verify_hostname portal.vereda.example 2>&1 | grep -E '^Verif'
Verification error: unable to get local issuer certificate
Verify return code: 20 (unable to get local issuer certificate)
```

The server on 8445 sends the agenda's certificate, which **expired** on 10 April:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8445 -servername agenda.vereda.example -verify_hostname agenda.vereda.example 2>&1 | grep -E '^Verif'
Verification error: certificate has expired
Verify return code: 10 (certificate has expired)
```

The portal's server again, but the client asked for `www.vereda.example`, a **name** the certificate
does not carry:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8443 -servername portal.vereda.example -verify_hostname www.vereda.example 2>&1 | grep -E '^Verif'
Verification error: hostname mismatch
Verify return code: 62 (hostname mismatch)
```

The intranet server uses a **self-signed** certificate that no trust store contains:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8446 -servername intranet.vereda.example -verify_hostname intranet.vereda.example 2>&1 | grep -E '^Verif'
Verification error: self-signed certificate
Verify return code: 18 (self-signed certificate)
```

## What the server sees

The client does not fail silently. It sends a TLS **alert** naming the reason and closes the
connection. The end of the trace of the expired case:

```
ana@lab:~/lab$ echo | openssl s_client -CAfile pki/root.pem -attime 1781535600 -verify_return_error -connect 127.0.0.1:8445 -servername agenda.vereda.example -trace 2>&1 | vcrypt tls-flow | tail -6
    certificate: Vereda Issuing CA 1
client -> server  Alert: fatal, certificate expired
client: verify error:num=10:certificate has expired
result: Verification error: certificate has expired
result: New, TLSv1.3, Cipher is TLS_AES_256_GCM_SHA384
result: Verify return code: 10 (certificate has expired)
```

The server never reaches CertificateVerify or Finished: the client stopped as soon as the Certificate
message failed the check. A server's logs show these alerts as failed handshakes, and a spike of
`certificate expired` alerts on a Monday morning is the monitoring that section 03 of lesson 9 should
have provided.

## Reading an error, and fixing it

| what the client says | cause | the fix, on the server |
|---|---|---|
| `unable to get local issuer certificate` | intermediate not sent, or root not trusted by this client | serve the full chain; for an internal CA, install its root on the clients |
| `certificate has expired` | past `Not After`, or the client's clock is wrong | renew, and automate renewal; check the client's clock |
| `hostname mismatch` | the name is not in the SAN | issue a certificate covering that name, or use the name it covers |
| `self-signed certificate` | nobody vouches for the key | use a certificate from a CA the clients trust |
| `certificate revoked` | the issuer withdrew it | new key, new certificate |

None of these rows says "disable verification". Each failure is the client doing exactly what this
course has argued it must do. A client that accepted any of them would accept the same thing from an
impostor, because to the client an impostor's certificate looks precisely like a server with one of
these problems.
