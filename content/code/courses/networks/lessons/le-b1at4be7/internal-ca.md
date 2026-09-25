---
title: The office's own authority
version: 1
---

The office's intranet, `intranet.example.com`, uses a certificate from the office's own certificate
authority, which many organisations run for their internal servers. The laptop does not trust it:

```
ana@laptop:~$ curl -sS -o /dev/null https://intranet.example.com/
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ openssl x509 -in office-ca.crt -noout -subject -issuer -fingerprint -sha256
subject=O = Example Ltd, CN = Example Ltd Office CA
issuer=O = Example Ltd, CN = Example Ltd Office CA
sha256 Fingerprint=2C:36:FD:F3:D1:2C:F5:D9:A0:5E:07:F3:AB:92:82:24:85:50:B5:31:94:D8:2D:D9:CA:F9:42:31:88:EA:07:75
ana@laptop:~$ sudo cp office-ca.crt /usr/local/share/ca-certificates/example-office-ca.crt
ana@laptop:~$ sudo update-ca-certificates
Updating certificates in /etc/ssl/certs...
rehash: warning: skipping ca-certificates.crt,it does not contain exactly one certificate or CRL
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
ana@laptop:~$ curl -sS -o /dev/null -w '%{http_code}\n' https://intranet.example.com/
200
```

The same `unable to get local issuer certificate` as the missing intermediate, for a different reason:
this time nothing in the laptop's store signed anything in the chain. The office CA's certificate
arrived from a colleague, and `openssl` printed its **fingerprint**, the SHA-256 of the certificate.
Before trusting a root, that is the number to compare with one obtained some other way, read out over
the phone by whoever runs the CA, say. Then it went into the store, `update-ca-certificates` reported
`1 added`, and the intranet now answers `200`.

**That fingerprint check is not ceremony.** A root certificate in the trust store can vouch for any
name at all, `www.example.com` or a bank's, and the machine will believe it. Installing one is giving
whoever holds its private key the power to impersonate every website to this computer. Company
networks that inspect HTTPS traffic work exactly this way: they install their own root on every
laptop, and their proxy makes certificates on the fly. Install a root only from a source you can
verify, and only on machines that need it.
