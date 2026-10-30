---
title: A signing request, made and checked with openssl
version: 1
---

**To get a certificate you send Apple a certificate signing request, and only the public half of
your key goes in it.** A CSR holds your public key and a name, signed with your private key to prove
you hold it. Apple's help page *Create a certificate signing request*, read on 30 October 2026, makes
one with Keychain Access on a Mac: an email address, a common name, and "Saved to disk". The same
page shows `openssl genrsa` and `openssl req` for the certificate types that need a key made at the
command line. **`openssl` is on every Ubuntu**, so the request itself can be made and inspected here.
Uploading it, and the certificate Apple would send back, were not run.

## The key and the request

Make a directory for it and run:

```
ana@vm:~/signing$ openssl genrsa -out dev.key 2048
ana@vm:~/signing$ openssl req -new -key dev.key -out dev.certSigningRequest -subj "/emailAddress=ana@example.com/CN=Ana Dev Key/C=BR"
ana@vm:~/signing$ openssl req -in dev.certSigningRequest -noout -verify -subject
Certificate request self-signature verify OK
subject=emailAddress = ana@example.com, CN = Ana Dev Key, C = BR
ana@vm:~/signing$ openssl req -in dev.certSigningRequest -noout -text | grep -E "Public-Key|Signature Algorithm" | sort -u
                Public-Key: (2048 bit)
    Signature Algorithm: sha256WithRSAEncryption
ana@vm:~/signing$ ls -l
total 8
-rw-r--r-- 1 ana ana  956 Oct 30 15:59 dev.certSigningRequest
-rw------- 1 ana ana 1704 Oct 30 15:59 dev.key
```

`genrsa` makes a 2048-bit RSA private key and prints nothing. `req -new` makes the request from it,
with the three fields Keychain Access asks for: an email address, a common name and a country. The
next two commands read the request back. **`self-signature verify OK` is the proof of possession**:
the request is signed with the private key whose public half it carries, so whoever sends it holds
that key. Look at `ls -l` before going on. The request is world-readable because it is public, and
the key is `-rw-------`, readable by you alone, because it is the one secret in this lesson.

## A chain, made for practice

Apple's certificate authority cannot be run here, and should not be imitated. What can be shown is
the mechanism, with a certificate authority made for the purpose and named as a toy: a root, an
intermediate signed by the root, and your request signed by the intermediate, the shape of section
04's figure.

```
ana@vm:~/signing$ openssl req -x509 -newkey rsa:2048 -nodes -keyout root.key -out root.pem -days 3650 -subj "/CN=Toy Root CA" 2>/dev/null
ana@vm:~/signing$ openssl req -newkey rsa:2048 -nodes -keyout inter.key -out inter.csr -subj "/CN=Toy Intermediate CA" 2>/dev/null
ana@vm:~/signing$ printf "basicConstraints=critical,CA:TRUE\n" > ca.ext
ana@vm:~/signing$ openssl x509 -req -in inter.csr -CA root.pem -CAkey root.key -extfile ca.ext -days 1825 -out inter.pem
Certificate request self-signature ok
subject=CN = Toy Intermediate CA
ana@vm:~/signing$ openssl x509 -req -in dev.certSigningRequest -CA inter.pem -CAkey inter.key -days 365 -out dev.pem
Certificate request self-signature ok
subject=emailAddress = ana@example.com, CN = Ana Dev Key, C = BR
ana@vm:~/signing$ openssl x509 -in dev.pem -noout -subject -issuer -enddate
subject=emailAddress = ana@example.com, CN = Ana Dev Key, C = BR
issuer=CN = Toy Intermediate CA
notAfter=Oct 30 18:59:35 2027 GMT
```

The `ca.ext` file marks the intermediate as a certificate authority; without it, a certificate it
signed would not verify. Your certificate's subject is the one in your request, its issuer is the
intermediate, and it expires a year from the day it was made.

## Checking it, and the missing intermediate

```
ana@vm:~/signing$ openssl verify -CAfile root.pem -untrusted inter.pem dev.pem
dev.pem: OK
ana@vm:~/signing$ openssl verify -CAfile root.pem dev.pem
emailAddress = ana@example.com, CN = Ana Dev Key, C = BR
error 20 at 0 depth lookup: unable to get local issuer certificate
error dev.pem: verification failed
```

**The first check passes and the second fails, with the same files.** Given the root as trusted and
the intermediate as a link it may use, `openssl` builds the chain to the root. Given the root alone,
it cannot get from your certificate to it: `unable to get local issuer certificate` is the message
for a missing intermediate. It is section 04's forgotten middle link, and on a Mac it shows up as a
certificate Xcode will not trust until the current WWDR intermediate is installed.

When you are done, delete the toy files. `dev.key` would be a real private key if it were ever used,
and nothing in this course uses it again.
