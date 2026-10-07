"""Vereda's certificate authority, built with fixed dates and fixed keys so
that every certificate in ~/lab/pki is the same file on every machine.

    root         Vereda Root CA          RSA 3072   2026-01-01 .. 2041-01-01
    issuing      Vereda Issuing CA 1     RSA 2048   2026-01-01 .. 2031-01-01
    portal       portal.vereda.example   P-256      2026-05-01 .. 2026-11-17
    agenda       agenda.vereda.example   P-256      2026-01-10 .. 2026-04-10  expired
    files        files.vereda.example    P-256      2026-02-01 .. 2026-08-20  revoked
    radius       radius.vereda.example   P-256      2026-03-01 .. 2030-12-31
    ldap         ldap.vereda.example     P-256      2026-04-01 .. 2030-12-31
    intranet     intranet.vereda.example P-256      self-signed
    ana-mail     ana.lima@vereda.example RSA 2048   2026-02-01 .. 2028-02-01  S/MIME
    bruno-mail   bruno.reis@vereda.example RSA 2048 2026-02-01 .. 2028-02-01  S/MIME
    impostor     "Vereda Root CA"        RSA 3072   same name as root, another key
    portal-impostor, radius-impostor     the impostor's leaves for those names

The lab's present is 2026-06-15 12:00 in São Paulo (NOW below); every check
the lessons make passes it explicitly, so that a capture taken next year
says what this one said.
"""
import datetime as dt

from cryptography import x509
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.x509.oid import ExtendedKeyUsageOID, NameOID

from . import keys

BRT = dt.timezone(dt.timedelta(hours=-3))
NOW = dt.datetime(2026, 6, 15, 12, 0, tzinfo=BRT)


def day(y, m, d):
    return dt.datetime(y, m, d, 0, 0, tzinfo=dt.timezone.utc)


def name(cn, ou=None):
    parts = [x509.NameAttribute(NameOID.COUNTRY_NAME, "BR"),
             x509.NameAttribute(NameOID.ORGANIZATION_NAME, "Vereda Fisioterapia")]
    if ou:
        parts.append(x509.NameAttribute(NameOID.ORGANIZATIONAL_UNIT_NAME, ou))
    parts.append(x509.NameAttribute(NameOID.COMMON_NAME, cn))
    return x509.Name(parts)


def _ski(pub):
    return x509.SubjectKeyIdentifier.from_public_key(pub)


def ca_cert(subject, key, issuer, issuer_key, serial, start, end, pathlen):
    b = (x509.CertificateBuilder().subject_name(subject).issuer_name(issuer)
         .public_key(key.public_key()).serial_number(serial)
         .not_valid_before(start).not_valid_after(end)
         .add_extension(x509.BasicConstraints(ca=True, path_length=pathlen), critical=True)
         .add_extension(x509.KeyUsage(digital_signature=False, content_commitment=False,
                                      key_encipherment=False, data_encipherment=False,
                                      key_agreement=False, key_cert_sign=True, crl_sign=True,
                                      encipher_only=False, decipher_only=False), critical=True)
         .add_extension(_ski(key.public_key()), critical=False))
    if issuer_key is not key:
        b = b.add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(issuer_key.public_key()),
                            critical=False)
    return b.sign(issuer_key, hashes.SHA256())


def leaf_cert(host, key, issuer_cert, issuer_key, serial, start, end, eku=ExtendedKeyUsageOID.SERVER_AUTH):
    b = (x509.CertificateBuilder().subject_name(name(host))
         .issuer_name(issuer_cert.subject).public_key(key.public_key()).serial_number(serial)
         .not_valid_before(start).not_valid_after(end)
         .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
         .add_extension(x509.KeyUsage(digital_signature=True, content_commitment=False,
                                      key_encipherment=False, data_encipherment=False,
                                      key_agreement=False, key_cert_sign=False, crl_sign=False,
                                      encipher_only=False, decipher_only=False), critical=True)
         .add_extension(x509.ExtendedKeyUsage([eku]), critical=False)
         .add_extension(x509.SubjectAlternativeName([x509.DNSName(host)]), critical=False)
         .add_extension(_ski(key.public_key()), critical=False)
         .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(issuer_key.public_key()),
                        critical=False)
         .add_extension(x509.CRLDistributionPoints([x509.DistributionPoint(
             full_name=[x509.UniformResourceIdentifier("http://pki.vereda.example/issuing1.crl")],
             relative_name=None, reasons=None, crl_issuer=None)]), critical=False))
    return b.sign(issuer_key, hashes.SHA256())


def pem(cert):
    return cert.public_bytes(serialization.Encoding.PEM)


def build(out):
    import os
    os.makedirs(out, exist_ok=True)
    w = lambda f, b: open(os.path.join(out, f), "wb").write(b)

    root_key = keys.rsa_key("pki/root", 3072)
    root = ca_cert(name("Vereda Root CA"), root_key, name("Vereda Root CA"), root_key,
                   0x1001, day(2026, 1, 1), day(2041, 1, 1), 1)
    iss_key = keys.rsa_key("pki/issuing1", 2048)
    iss = ca_cert(name("Vereda Issuing CA 1"), iss_key, root.subject, root_key,
                  0x2001, day(2026, 1, 1), day(2031, 1, 1), 0)
    w("root.pem", pem(root))
    w("issuing1.pem", pem(iss))
    keys.write_private(root_key, os.path.join(out, "root.key"))
    keys.write_private(iss_key, os.path.join(out, "issuing1.key"))

    leaves = {
        "portal": ("portal.vereda.example", 0x3A01, day(2026, 5, 1), day(2026, 11, 17)),
        "agenda": ("agenda.vereda.example", 0x3A02, day(2026, 1, 10), day(2026, 4, 10)),
        "files": ("files.vereda.example", 0x3A03, day(2026, 2, 1), day(2026, 8, 20)),
        # The directory's and the RADIUS server's certificates are checked by
        # libldap and by FreeRADIUS and eapol_test against the real clock,
        # which no option moves, so they run to 2030 to keep the transcripts
        # of lessons 12 and 16 valid; every other check in the lab passes
        # -attime.
        "radius": ("radius.vereda.example", 0x3A04, day(2026, 3, 1), day(2030, 12, 31)),
        "ldap": ("ldap.vereda.example", 0x3A05, day(2026, 4, 1), day(2030, 12, 31)),
    }
    for short, (host, serial, start, end) in leaves.items():
        k = keys.ec_key("pki/" + short)
        c = leaf_cert(host, k, iss, iss_key, serial, start, end)
        w(short + ".pem", pem(c))
        w(short + "-chain.pem", pem(c) + pem(iss))
        keys.write_private(k, os.path.join(out, short + ".key"))

    # S/MIME certificates for lesson 13: RSA, so that signatures repeat, an
    # e-mail address instead of a host name, and e-mail protection as usage.
    for who, serial in (("ana", 0x5A01), ("bruno", 0x5A02)):
        address = f"{who}.{'lima' if who == 'ana' else 'reis'}@vereda.example"
        k = keys.rsa_key(f"pki/{who}-mail", 2048)
        c = (x509.CertificateBuilder().subject_name(name(address, "Clinical staff"))
             .issuer_name(iss.subject).public_key(k.public_key()).serial_number(serial)
             .not_valid_before(day(2026, 2, 1)).not_valid_after(day(2028, 2, 1))
             .add_extension(x509.BasicConstraints(ca=False, path_length=None), critical=True)
             .add_extension(x509.KeyUsage(digital_signature=True, content_commitment=False,
                                          key_encipherment=True, data_encipherment=False,
                                          key_agreement=False, key_cert_sign=False, crl_sign=False,
                                          encipher_only=False, decipher_only=False), critical=True)
             .add_extension(x509.ExtendedKeyUsage([ExtendedKeyUsageOID.EMAIL_PROTECTION]), critical=False)
             .add_extension(x509.SubjectAlternativeName([x509.RFC822Name(address)]), critical=False)
             .add_extension(x509.AuthorityKeyIdentifier.from_issuer_public_key(iss_key.public_key()),
                            critical=False)
             .sign(iss_key, hashes.SHA256()))
        w(f"{who}-mail.pem", pem(c))
        keys.write_private(k, os.path.join(out, f"{who}-mail.key"))

    k = keys.ec_key("pki/intranet")
    self_signed = (x509.CertificateBuilder().subject_name(name("intranet.vereda.example"))
                   .issuer_name(name("intranet.vereda.example")).public_key(k.public_key())
                   .serial_number(0x4001).not_valid_before(day(2026, 1, 1))
                   .not_valid_after(day(2027, 1, 1))
                   .add_extension(x509.SubjectAlternativeName([x509.DNSName("intranet.vereda.example")]),
                                  critical=False)
                   .sign(k, hashes.SHA256()))
    w("intranet.pem", pem(self_signed))
    keys.write_private(k, os.path.join(out, "intranet.key"))

    imp_key = keys.rsa_key("pki/impostor", 3072)
    impostor = ca_cert(name("Vereda Root CA"), imp_key, name("Vereda Root CA"), imp_key,
                       0x1001, day(2026, 1, 1), day(2041, 1, 1), 1)
    w("impostor-root.pem", pem(impostor))
    k = keys.ec_key("pki/portal-impostor")
    fake = leaf_cert("portal.vereda.example", k, impostor, imp_key, 0x3A01,
                     day(2026, 5, 1), day(2026, 11, 17))
    w("portal-impostor.pem", pem(fake))
    k = keys.ec_key("pki/radius-impostor")
    fake = leaf_cert("radius.vereda.example", k, impostor, imp_key, 0x3A04,
                     day(2026, 3, 1), day(2030, 12, 31))
    w("radius-impostor.pem", pem(fake))
    keys.write_private(k, os.path.join(out, "radius-impostor.key"))

    crl = (x509.CertificateRevocationListBuilder().issuer_name(iss.subject)
           .last_update(day(2026, 6, 1)).next_update(day(2026, 6, 30))
           .add_revoked_certificate(x509.RevokedCertificateBuilder().serial_number(0x3A03)
                                    .revocation_date(day(2026, 5, 20))
                                    .add_extension(x509.CRLReason(x509.ReasonFlags.key_compromise),
                                                   critical=False).build())
           .add_extension(x509.CRLNumber(7), critical=False)
           .sign(iss_key, hashes.SHA256()))
    w("issuing1.crl", crl.public_bytes(serialization.Encoding.PEM))
