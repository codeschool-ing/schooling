---
title: The fields of an X.509 certificate
version: 1
---

**A TLS certificate is an X.509 version 3 document: a fixed set of fields, a list of extensions,
and a signature by the issuer over all of it.** OpenSSL prints the whole of Vereda's portal
certificate like this:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -text
Certificate:
    Data:
        Version: 3 (0x2)
        Serial Number: 14849 (0x3a01)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
        Validity
            Not Before: May  1 00:00:00 2026 GMT
            Not After : Nov 17 00:00:00 2026 GMT
        Subject: C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
        Subject Public Key Info:
            Public Key Algorithm: id-ecPublicKey
                Public-Key: (256 bit)
                pub:
                    04:84:95:0f:9c:63:23:19:9f:b9:42:ec:57:fb:a5:
                    ca:7c:5d:4d:ad:fb:a7:18:97:e5:15:50:df:e0:55:
                    5c:7c:31:2d:30:06:3d:d3:32:58:b8:91:bd:47:2b:
                    7f:51:58:1d:aa:15:0c:3a:23:79:37:22:af:23:60:
                    f7:46:e0:09:29
                ASN1 OID: prime256v1
                NIST CURVE: P-256
        X509v3 extensions:
            X509v3 Basic Constraints: critical
                CA:FALSE
            X509v3 Key Usage: critical
                Digital Signature
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Subject Alternative Name: 
                DNS:portal.vereda.example
            X509v3 Subject Key Identifier: 
                85:D6:5C:BC:C7:98:A5:28:54:C2:EA:91:38:A3:7E:C0:32:93:41:DD
            X509v3 Authority Key Identifier: 
                8B:BF:ED:E1:A9:76:95:42:70:FD:A7:53:2F:75:28:D3:A3:77:41:A6
            X509v3 CRL Distribution Points: 
                Full Name:
                  URI:http://pki.vereda.example/issuing1.crl
    Signature Algorithm: sha256WithRSAEncryption
    Signature Value:
        0a:86:21:ef:12:db:39:a1:c3:15:c8:de:35:bd:78:40:06:56:
        b6:32:9e:db:6f:28:86:fe:46:2e:61:d0:ec:6d:ca:15:f6:42:
        71:18:15:cd:26:29:08:f0:6a:c3:9b:31:85:a7:f9:87:59:01:
        90:11:b6:9d:7b:68:63:79:e6:2b:b8:45:e8:fd:5c:0d:4a:bf:
        a9:a3:fb:ea:2e:fe:8a:4e:19:7c:3d:e3:a9:2d:97:b8:5f:ab:
        77:82:65:16:28:8c:01:87:73:38:02:aa:29:47:91:c9:73:e5:
        d4:aa:25:51:28:6b:a5:09:86:24:ed:f4:e9:6d:bc:ec:53:ea:
        92:20:3f:11:2e:1c:e9:54:c5:6b:b2:09:bc:02:bd:b5:92:ca:
        97:cb:f8:f9:4b:fd:e1:e1:c2:86:f9:12:7b:b0:33:26:be:5d:
        c0:ca:99:85:91:56:ad:f2:93:90:ac:4a:cb:51:8c:c2:00:77:
        56:58:88:45:4b:ac:07:e6:c1:0f:6c:72:cc:03:65:3a:b0:c5:
        04:d9:a8:6a:d8:ae:b0:e7:01:0a:d6:ac:de:96:f5:74:fa:be:
        cd:47:91:20:b6:ba:45:57:52:81:ec:8c:77:9d:76:f4:98:00:
        21:0c:59:ec:cb:fa:0e:98:e2:6b:48:ad:38:e4:ee:1a:b1:1e:
        d8:c0:29:07
```

Everything above `Signature Algorithm` near the bottom is the data the issuer signed, called the
*to-be-signed* part. The last block is the issuer's signature over it, 256 bytes because Vereda's
issuing CA has a 2048-bit RSA key. Change one byte anywhere above and that signature no longer
verifies, which is how the lab's impostor in lesson 8 was caught.

## The fields, top to bottom

| field | in the portal's certificate | what a client does with it |
|---|---|---|
| Version | 3 | every certificate in use is version 3, the one with extensions |
| Serial Number | `0x3a01` | unique per issuer; it is how a revocation list names a certificate |
| Signature Algorithm | `sha256WithRSAEncryption` | how the issuer signed; SHA-1 or MD5 here is refused (lesson 4) |
| Issuer | Vereda Issuing CA 1 | which certificate to look for next in the chain |
| Validity | 1 May to 17 November 2026 | refused outside those dates, section 03 |
| Subject | `CN = portal.vereda.example` | a label for people; not what the host name is checked against |
| Subject Public Key Info | P-256 key | the key the server must prove it holds |

## The extensions that decide

Extensions carry most of what matters now. Those marked `critical` must be understood by the client
or the whole certificate refused:

- **Basic Constraints** `CA:FALSE`: this certificate may not sign other certificates (lesson 8).
- **Key Usage** `Digital Signature`: the key may only sign, which in TLS 1.3 is all a server key does.
- **Extended Key Usage** `TLS Web Server Authentication`: the key is for a TLS server, not for
  signing code or e-mail. A client checking a server refuses a certificate without it.
- **Subject Alternative Name** `DNS:portal.vereda.example`: **the host names the certificate is
  for**, section 04.
- **Subject Key Identifier** and **Authority Key Identifier**: fingerprints of this certificate's key
  and of its issuer's key. They let a client find the right issuer even when two CAs have the same
  name, which is exactly the impostor's case.
- **CRL Distribution Points**: where to fetch the issuer's revocation list, section 05.

## Encodings you will meet

The file is **PEM**: Base64 between `-----BEGIN CERTIFICATE-----` lines (lesson 11 explains Base64).
Inside it is **DER**, the binary encoding of the same structure. Windows tends to use `.cer` and
`.crt` for either; Java and Windows also bundle a certificate with its private key in a **PKCS#12**
file (`.p12`, `.pfx`), protected by a password. `openssl x509 -inform DER` reads the binary form, and
`openssl pkcs12` opens a bundle. The content is the same in all of them; only the wrapping differs.
