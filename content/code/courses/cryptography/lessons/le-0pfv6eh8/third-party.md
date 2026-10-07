---
title: A third party that vouches for a key
version: 1
---

**A certificate is a statement, signed by somebody you already trust, that a public key belongs to a
name.** That is the whole of the idea. Public key infrastructure, PKI, is everything needed to make
those statements trustworthy at the scale of the internet: who may sign them, how they are checked,
and what happens when one turns out to be false.

## The problem certificates solve

Lessons 2, 3 and 7 each stopped at the same point. A public key says nothing about whose it is, and
the signed key exchange that defeats a man in the middle only works if Ana knows which public key is
really the server's. She cannot ask the server: an impostor answers "yes, this is my key" exactly as
the real server would. She needs somebody else, who is not on the path, to have checked in advance.

For SSH, lesson 6 answered this by hand: an `allowed_signers` file, or the fingerprint a person
compares on first connection. That works for a team of ten. It does not work for a patient opening
Vereda's portal on a phone, who has never heard of a fingerprint and will never call anybody to
check one.

## Vereda's certificate authority, which you build

Every certificate in lessons 8 to 16 comes from one program, which plays Vereda's certificate
authority. It is long, and you do not need to follow it now: this lesson and the next explain every
field it sets, and it reads differently after lesson 9. Its keys come from lesson 2's `keys.py` and
its dates are fixed, so your certificates are the ones printed here, byte for byte. A real
authority does the same with `openssl ca` or a product built for it, with random keys, and never
keeps a private key in a directory like `pki/`.

```py
# ~/lab/tools/pki.py
"""vcrypt pki: Vereda's certificate authority, written into pki/, with keys
from keys.py and fixed dates, so that every certificate is the one in the
lessons, byte for byte.

    root         Vereda Root CA            RSA 3072  2026-01-01 .. 2041-01-01
    issuing1     Vereda Issuing CA 1       RSA 2048  2026-01-01 .. 2031-01-01
    portal       portal.vereda.example     P-256     2026-05-01 .. 2026-11-17
    agenda       agenda.vereda.example     P-256     2026-01-10 .. 2026-04-10  expired
    files        files.vereda.example      P-256     2026-02-01 .. 2026-08-20  revoked
    radius       radius.vereda.example     P-256     2026-03-01 .. 2030-12-31
    ldap         ldap.vereda.example       P-256     2026-04-01 .. 2030-12-31
    intranet     intranet.vereda.example   P-256     self-signed
    ana-mail     ana.lima@vereda.example   RSA 2048  2026-02-01 .. 2028-02-01  S/MIME
    bruno-mail   bruno.reis@vereda.example RSA 2048  2026-02-01 .. 2028-02-01  S/MIME
    impostor-root  "Vereda Root CA" again, with another key
    portal-impostor, radius-impostor  the impostor's certificates for those names
    issuing1.crl   the issuing CA's revocation list: files is on it

The lab's present is 2026-06-15 12:00 in Sao Paulo, epoch 1781535600, and
every check in the lessons passes it with -attime. radius and ldap run to
2030 because the programs that check them in lessons 12 and 16 use the
real clock and offer no way to move it.
"""
import datetime as dt
import os

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID

import keys


def day(y, m, d):
    return dt.datetime(y, m, d, tzinfo=dt.timezone.utc)


def name(cn, ou=None):
    parts = [x509.NameAttribute(NameOID.COUNTRY_NAME, "BR"),
             x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Vereda Fisioterapia")]
    if ou:
        parts.append(x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, ou))
    parts.append(x509.NameAttribute(NameOID.COMMON_NAME, cn))
    return x509.Name(parts)


def usage(**allowed):
    flags = ("digital_signature", "content_commitment", "key_encipherment", "data_encipherment",
             "key_agreement", "key_cert_sign", "crl_sign", "encipher_only", "decipher_only")
    return x509.KeyUsage(**{f: allowed.get(f, False) for f in flags})


def akid(issuer_key):
    return x509.AuthorityKeyIdentifier.from_issuer_public_key(issuer_key.public_key())


def ca_cert(subject, key, issuer, issuer_key, serial, start, end, pathlen):
    b = (x509.CertificateBuilder().subject_name(subject).issuer_name(issuer)
         .public_key(key.public_key()).serial_number(serial)
         .not_valid_before(start).not_valid_after(end)
         .add_extension(x509.BasicConstraints(ca=True, path_length=pathlen), critical=True)
         .add_extension(usage(key_cert_sign=True, crl_sign=True), critical=True)
         .add_extension(x509.SubjectKeyIdentifier.from_public_key(key.public_key()), critical=False))
    if issuer_key is not key:
        b = b.add_extension(akid(issuer_key), critical=False)
    return b.sign(issuer_key, hashes.SHA256())


def leaf_cert(host, key, issuer_cert, issuer_key, serial, start, end):
    crl = x509.DistributionPoint(
        full_name=[x509.UniformResourceIdentifier("http://pki.vereda.example/issuing1.crl")],
        relative_name=None, reasons=None, crl_issuer=None)
    return (x509.CertificateBuilder().subject_name(name(host))
            .issuer_name(issuer_cert.subject).public_key(key.public_key()).serial_number(serial)
            .not_valid_before(start).not_valid_after(end)
            .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
            .add_extension(usage(digital_signature=True), critical=True)
            .add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.SERVER_AUTH]), critical=False)
            .add_extension(x509.SubjectAlternativeName([x509.DNSName(host)]), critical=False)
            .add_extension(x509.SubjectKeyIdentifier.from_public_key(key.public_key()), critical=False)
            .add_extension(akid(issuer_key), critical=False)
            .add_extension(x509.CRLDistributionPoints([crl]), critical=False)
            .sign(issuer_key, hashes.SHA256()))


def pem(cert):
    return cert.public_bytes(serialization.Encoding.PEM)


def save(short, cert=None, key=None, chain=None):
    if cert is not None:
        open(f"pki/{short}.pem", "wb").write(pem(cert))
    if chain is not None:
        open(f"pki/{short}-chain.pem", "wb").write(pem(cert) + pem(chain))
    if key is not None:
        open(f"pki/{short}.key", "wb").write(key.private_bytes(
            serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,
            serialization.NoEncryption()))


os.makedirs("pki", exist_ok=True)

root_key = keys.rsa_key("pki/root", 3072)
root = ca_cert(name("Vereda Root CA"), root_key, name("Vereda Root CA"), root_key,
               0x1001, day(2026, 1, 1), day(2041, 1, 1), 1)
iss_key = keys.rsa_key("pki/issuing1", 2048)
iss = ca_cert(name("Vereda Issuing CA 1"), iss_key, root.subject, root_key,
              0x2001, day(2026, 1, 1), day(2031, 1, 1), 0)
save("root", root, root_key)
save("issuing1", iss, iss_key)

for short, host, serial, start, end in (
    ("portal", "portal.vereda.example", 0x3A01, day(2026, 5, 1), day(2026, 11, 17)),
    ("agenda", "agenda.vereda.example", 0x3A02, day(2026, 1, 10), day(2026, 4, 10)),
    ("files", "files.vereda.example", 0x3A03, day(2026, 2, 1), day(2026, 8, 20)),
    ("radius", "radius.vereda.example", 0x3A04, day(2026, 3, 1), day(2030, 12, 31)),
    ("ldap", "ldap.vereda.example", 0x3A05, day(2026, 4, 1), day(2030, 12, 31)),
):
    k = keys.ec_key("pki/" + short)
    save(short, leaf_cert(host, k, iss, iss_key, serial, start, end), k, chain=iss)

# S/MIME, for lesson 13: an e-mail address instead of a host name, and RSA,
# so that a signature comes out the same every time.
for who, address, serial in (("ana", "ana.lima@vereda.example", 0x5A01),
                             ("bruno", "bruno.reis@vereda.example", 0x5A02)):
    k = keys.rsa_key(f"pki/{who}-mail", 2048)
    c = (x509.CertificateBuilder().subject_name(name(address, "Clinical staff"))
         .issuer_name(iss.subject).public_key(k.public_key()).serial_number(serial)
         .not_valid_before(day(2026, 2, 1)).not_valid_after(day(2028, 2, 1))
         .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
         .add_extension(usage(digital_signature=True, key_encipherment=True), critical=True)
         .add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.EMAIL_PROTECTION]), critical=False)
         .add_extension(x509.SubjectAlternativeName([x509.RFC822Name(address)]), critical=False)
         .add_extension(akid(iss_key), critical=False)
         .sign(iss_key, hashes.SHA256()))
    save(f"{who}-mail", c, k)

k = keys.ec_key("pki/intranet")
save("intranet", x509.CertificateBuilder().subject_name(name("intranet.vereda.example"))
     .issuer_name(name("intranet.vereda.example")).public_key(k.public_key())
     .serial_number(0x4001).not_valid_before(day(2026, 1, 1)).not_valid_after(day(2027, 1, 1))
     .add_extension(x509.SubjectAlternativeName([x509.DNSName("intranet.vereda.example")]),
                    critical=False)
     .sign(k, hashes.SHA256()), k)

# The impostor: a root with the same name as Vereda's, and its own key.
imp_key = keys.rsa_key("pki/impostor", 3072)
impostor = ca_cert(name("Vereda Root CA"), imp_key, name("Vereda Root CA"), imp_key,
                   0x1001, day(2026, 1, 1), day(2041, 1, 1), 1)
save("impostor-root", impostor)
k = keys.ec_key("pki/portal-impostor")
save("portal-impostor", leaf_cert("portal.vereda.example", k, impostor, imp_key, 0x3A01,
                                  day(2026, 5, 1), day(2026, 11, 17)))
k = keys.ec_key("pki/radius-impostor")
save("radius-impostor", leaf_cert("radius.vereda.example", k, impostor, imp_key, 0x3A04,
                                  day(2026, 3, 1), day(2030, 12, 31)), k)

revoked = (x509.RevokedCertificateBuilder().serial_number(0x3A03)
           .revocation_date(day(2026, 5, 20))
           .add_extension(x509.CRLReason(x509.ReasonFlags.key_compromise), critical=False).build())
crl = (x509.CertificateRevocationListBuilder().issuer_name(iss.subject)
       .last_update(day(2026, 6, 1)).next_update(day(2026, 6, 30))
       .add_revoked_certificate(revoked).add_extension(x509.CRLNumber(7), critical=False)
       .sign(iss_key, hashes.SHA256()))
open("pki/issuing1.crl", "wb").write(crl.public_bytes(serialization.Encoding.PEM))
```

```sh
cd ~/lab
vcrypt pki
```

It takes a few seconds, for the same reason as lesson 2's `vcrypt pairs`, and writes these files:

```
ana@lab:~/lab$ ls pki
agenda-chain.pem
agenda.key
agenda.pem
ana-mail.key
ana-mail.pem
bruno-mail.key
bruno-mail.pem
files-chain.pem
files.key
files.pem
impostor-root.pem
intranet.key
intranet.pem
issuing1.crl
issuing1.key
issuing1.pem
ldap-chain.pem
ldap.key
ldap.pem
portal-chain.pem
portal-impostor.pem
portal.key
portal.pem
radius-chain.pem
radius-impostor.key
radius-impostor.pem
radius.key
radius.pem
root.key
root.pem
```

Each certificate is a `.pem` file. A `.key` beside it is its private key, which is how the lab can
start a server with that certificate in lesson 10; a `-chain.pem` is the certificate followed by the
issuing CA's, which is what a server sends. `issuing1.crl` is lesson 9's revocation list.

## What a certificate binds

Vereda's portal certificate names its subject, and the authority that issued it:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -subject -issuer
subject=C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
```

And it carries a public key:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -pubkey
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhJUPnGMjGZ+5QuxX+6XKfF1Nrfun
GJflFVDf4FVcfDEtMAY90zJYuJG9Ryt/UVgdqhUMOiN5NyKvI2D3RuAJKQ==
-----END PUBLIC KEY-----
```

That key is the public half of the private key the portal server holds, byte for byte:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -pubkey | cmp - <(openssl pkey -in pki/portal.key -pubout) && echo "the certificate carries the public half of portal.key"
the certificate carries the public half of portal.key
```

So the certificate binds three things together: a **name** (`portal.vereda.example`), a **public
key**, and an **issuer** who signed the pair. A browser that trusts the issuer, and checks the
issuer's signature, can believe that this key belongs to that name. It still checks one thing more:
during the handshake, the server proves it holds the matching private key by signing the exchange
(lesson 7). A certificate on its own is public; anybody can copy it. Holding the private key is what
the handshake tests.

## What the authority actually checks

A **certificate authority** (CA) signs only after checking that the requester controls the name. For
the certificates browsers use, that check is usually automatic and about the domain alone:

- **domain validation (DV)**: the requester proves control of the domain, by serving a file at a
  given address or publishing a DNS record. Let's Encrypt automates this with the ACME protocol, and
  it is most of the web's certificates;
- **organisation validation (OV)** and **extended validation (EV)** add checks on the company behind
  the domain. Browsers stopped showing EV differently around 2019, because users did not notice the
  difference.

A DV certificate therefore says "whoever asked for this controlled `portal.vereda.example` at the
time", not "this is a trustworthy clinic". That is exactly what the browser needs to know to rule out
a man in the middle, and nothing more.
