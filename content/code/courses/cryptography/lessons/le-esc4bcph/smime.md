---
title: S/MIME, protecting the message rather than the connection
version: 1
---

**S/MIME signs and encrypts an e-mail message itself, so the protection stays with the message in
every server and mailbox it passes through.** TLS between mail servers protects each hop of the
journey, and each server along the way holds the message in clear text. A referral signed and
encrypted with S/MIME arrives exactly as Ana sent it, readable only by Bruno, and still verifiable
years later.

## A certificate for an address

S/MIME uses certificates like a web server's, with two differences that matter: the name is an
e-mail address, and the key usage is e-mail protection:

```
ana@lab:~/lab$ openssl x509 -in pki/ana-mail.pem -noout -subject -ext subjectAltName,extendedKeyUsage
subject=C = BR, O = Vereda Fisioterapia, OU = Clinical staff, CN = ana.lima@vereda.example
X509v3 Extended Key Usage: 
    E-mail Protection
X509v3 Subject Alternative Name: 
    email:ana.lima@vereda.example
```

Vereda's issuing CA issued one for Ana and one for Bruno. For mail between organisations, the
certificates come from a public CA that issues S/MIME certificates, under the CA/Browser Forum's
S/MIME rules adopted in 2023.

## Signing

Ana signs the referral. `openssl cms` writes the result in CMS, the *Cryptographic Message Syntax*
that S/MIME is built on, here in PEM form:

```
ana@lab:~/lab$ openssl cms -sign -nodetach -noattr -md sha256 -in data/referral.txt -signer pki/ana-mail.pem -inkey pki/ana-mail.key -certfile pki/issuing1.pem -outform PEM -out referral.p7s; head -3 referral.p7s
-----BEGIN CMS-----
MIIKAgYJKoZIhvcNAQcCoIIJ8zCCCe8CAQExDTALBglghkgBZQMEAgEwgb4GCSqG
SIb3DQEHAaCBsASBrVJlZmVycmFsIDIwMjYtMDQxNy4gUGF0aWVudDogTWFyaW5h
```

The block holds the letter, Ana's certificate, the issuing CA's certificate, and Ana's RSA signature
over a SHA-256 digest of the letter: lessons 3, 4 and 8 in one structure. Bruno, or anybody with
Vereda's root, verifies it and gets the letter back:

```
ana@lab:~/lab$ openssl cms -verify -inform PEM -in referral.p7s -CAfile pki/root.pem -attime 1781535600 -purpose smimesign 2>&1
CMS Verification successful
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
```

A mail client does the same check and shows the signer's address, which it compares with the
message's `From:` line. A signature from a valid certificate for a *different* address than the one
in `From:` is a warning sign, not a reassurance.

## Encrypting to Bruno

Encryption is the hybrid scheme of lesson 3: a fresh AES-256-GCM key encrypts the letter, and the key
is encrypted with Bruno's RSA public key using OAEP. Printing the structure shows exactly that:

```
ana@lab:~/lab$ openssl cms -encrypt -aes-256-gcm -recip pki/bruno-mail.pem -keyopt rsa_padding_mode:oaep -in data/referral.txt -outform PEM -out referral.p7m
ana@lab:~/lab$ openssl cms -cmsout -print -inform PEM -in referral.p7m | grep -E 'contentType|algorithm:|issuer:|serialNumber'
  contentType: id-smime-ct-authEnvelopedData (1.2.840.113549.1.9.16.1.23)
          issuer: C=BR, O=Vereda Fisioterapia, CN=Vereda Issuing CA 1
          serialNumber: 23042
          algorithm: rsaesOaep (1.2.840.113549.1.1.7)
      contentType: pkcs7-data (1.2.840.113549.1.7.1)
        algorithm: aes-256-gcm (2.16.840.1.101.3.4.1.46)
```

`authEnvelopedData` is CMS's authenticated encryption. The recipient is identified by the issuer and
serial number of his certificate (23042 is `0x5A02`, Bruno's), and the two algorithms are the ones
named. Bruno decrypts with his private key:

```
ana@lab:~/lab$ openssl cms -decrypt -inform PEM -in referral.p7m -recip pki/bruno-mail.pem -inkey pki/bruno-mail.key | head -1
Referral 2026-0417. Patient: Marina Duarte, 41.
```

Ana's key cannot open it, although she wrote it:

```
ana@lab:~/lab$ openssl cms -decrypt -inform PEM -in referral.p7m -recip pki/ana-mail.pem -inkey pki/ana-mail.key 2>&1 | head -1
Error decrypting CMS using private key
```

A real mail client therefore also encrypts each message to the **sender's** own certificate, as a
second recipient, so that the sent copy remains readable. That is one more recipient in the
structure, not a second encryption of the message.

## What S/MIME leaves visible

The headers stay in clear text: who wrote to whom, when, and the subject line, unless the client puts
a protected copy of the subject inside. And encryption is only as durable as the recipient's private
key: an organisation that encrypts mail must keep recipients' encryption keys recoverable (lesson 3's
escrow), or a lost laptop takes years of correspondence with it. **OpenPGP** offers the same two
operations with its own key format and a web of trust instead of CAs; the decisions are the same.
