---
title: The trust store, the list that decides everything
version: 1
---

**A trust store is the list of root certificates a system accepts without further proof, and every
certificate check ends at one of them.** Nothing in a certificate makes it trustworthy by itself. A
chain is trusted because its top is on this list, and the list was chosen by whoever ships the
operating system or the browser.

## Where the list comes from

On this Ubuntu machine the list is Mozilla's, shipped by the `ca-certificates` package:

```
ana@lab:~/lab$ ls /usr/share/ca-certificates/mozilla | wc -l
121
```

About a hundred and twenty organisations' roots, among them Let's Encrypt's (ISRG) and DigiCert's:

```
ana@lab:~/lab$ ls /usr/share/ca-certificates/mozilla | grep -i -E "isrg|digicert_global_root_g2"
DigiCert_Global_Root_G2.crt
ISRG_Root_X1.crt
ISRG_Root_X2.crt
```

There are four main lists in the world: **Mozilla's** (used by Firefox and most Linux distributions),
**Apple's**, **Microsoft's** and **Google's Chrome Root Store**. Each is run as a programme with
written requirements, audits and a public process for admitting and removing CAs. A Java runtime,
a Python environment with `certifi`, or a container image can carry its own copy, and that copy is
only as current as the last time it was updated.

## Vereda's root is not on it

Vereda's internal root is, correctly, on nobody's list. Verified against the system store, the
portal's chain stops at the issuing CA, whose issuer the store does not know:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -untrusted pki/issuing1.pem pki/portal.pem
C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
error 20 at 1 depth lookup: unable to get local issuer certificate
error pki/portal.pem: verification failed
```

That is the expected answer for an internal CA on a machine that was never told about it. Clients
that should trust Vereda's internal services get Vereda's root installed, by configuration
management or device policy. **Nobody fixes this by turning verification off.**

## The missing intermediate

Given the right root but **without** the issuing CA, verification fails too:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem pki/portal.pem
C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
error 20 at 0 depth lookup: unable to get local issuer certificate
error pki/portal.pem: verification failed
```

This is the error from section 03: the server sent its own certificate and forgot the intermediate.
Some browsers paper over it by fetching or caching intermediates, so a misconfigured server works on
one laptop and fails in `curl`, in a phone app or in another company's API client. The fix is on the
server: serve the full chain, as the lab's `portal-chain.pem` does.

## A name is not a key

The lab also holds an impostor: a root certificate with **exactly the same name** as Vereda's,
generated with a different key. The names match and the fingerprints do not:

```
ana@lab:~/lab$ openssl x509 -in pki/root.pem -noout -subject -fingerprint -sha256; openssl x509 -in pki/impostor-root.pem -noout -subject -fingerprint -sha256
subject=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
sha256 Fingerprint=B9:6C:9C:AC:42:71:58:AE:0F:32:96:89:BA:90:D5:99:D0:15:56:BD:AA:AE:CE:10:57:86:0D:EB:EA:6F:D4:1F
subject=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
sha256 Fingerprint=23:4F:F0:80:71:ED:FE:74:09:B5:5A:B9:56:C5:9E:B2:81:35:B0:AB:BB:BD:33:50:BF:49:63:1A:3A:37:80:6A
```

A portal certificate signed by the impostor fails against the real root, because verification
checks the signature with the root's key, not the issuer's name:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal-impostor.pem
C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
error 20 at 0 depth lookup: unable to get local issuer certificate
error pki/portal-impostor.pem: verification failed
```

But on a machine where somebody installed the impostor root, the same forged certificate verifies:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/impostor-root.pem pki/portal-impostor.pem
pki/portal-impostor.pem: OK
```

**Whoever can add a root to a trust store can impersonate any site to that machine.** That is why
installing a root is an administrative act, why corporate devices that inspect TLS traffic do it
deliberately and say so, and why malware that does it is serious. Auditing the trust store, on
servers and on the images you build, is part of hardening.
