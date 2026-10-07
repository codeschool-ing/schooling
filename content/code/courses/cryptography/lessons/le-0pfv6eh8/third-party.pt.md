---
title: Um terceiro que responde por uma chave
version: 1
---

**Um certificado é uma declaração, assinada por alguém em quem você já confia, de que uma chave
pública pertence a um nome.** Essa é a ideia inteira. A infraestrutura de chaves públicas, PKI, é
tudo o que é preciso para tornar essas declarações confiáveis na escala da internet: quem pode
assiná-las, como são conferidas, e o que acontece quando uma se revela falsa.

## O problema que os certificados resolvem

As aulas 2, 3 e 7 pararam todas no mesmo ponto. Uma chave pública não diz de quem é, e a troca de
chaves assinada que derrota um homem no meio só funciona se a Ana souber qual chave pública é mesmo
a do servidor. Ela não pode perguntar ao servidor: um impostor responde "sim, esta é a minha chave"
exatamente como o servidor real responderia. Ela precisa de mais alguém, que não esteja no caminho,
que tenha conferido antes.

No SSH, a aula 6 respondeu isso à mão: um arquivo `allowed_signers`, ou a impressão digital que uma
pessoa compara na primeira conexão. Isso funciona para uma equipe de dez. Não funciona para um
paciente abrindo o portal da Vereda num celular, que nunca ouviu falar de impressão digital e nunca
vai ligar para ninguém para conferir uma.

## A autoridade certificadora da Vereda, montada por você

Todo certificado das aulas 8 a 16 vem de um único programa, que faz o papel da autoridade
certificadora da Vereda. Ele é longo, e você não precisa acompanhá-lo agora: esta aula e a próxima
explicam cada campo que ele preenche, e ele se lê de outro jeito depois da aula 9. As chaves vêm do
`keys.py` da aula 2 e as datas são fixas, então os seus certificados são os impressos aqui, byte a
byte. Uma autoridade de verdade faz o mesmo com o `openssl ca` ou com um produto feito para isso,
com chaves aleatórias, e nunca guarda uma chave privada num diretório como `pki/`.

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

Ele leva alguns segundos, pelo mesmo motivo do `vcrypt pairs` da aula 2, e grava estes arquivos:

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

Cada certificado é um arquivo `.pem`. Um `.key` ao lado dele é a sua chave privada, e é assim que o
laboratório consegue subir um servidor com aquele certificado na aula 10; um `-chain.pem` é o
certificado seguido do da CA emissora, que é o que um servidor envia. O `issuing1.crl` é a lista de
revogação da aula 9.

## O que um certificado amarra

O certificado do portal da Vereda nomeia o titular e a autoridade que o emitiu:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -subject -issuer
subject=C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
```

E carrega uma chave pública:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -pubkey
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEhJUPnGMjGZ+5QuxX+6XKfF1Nrfun
GJflFVDf4FVcfDEtMAY90zJYuJG9Ryt/UVgdqhUMOiN5NyKvI2D3RuAJKQ==
-----END PUBLIC KEY-----
```

Essa chave é a metade pública da chave privada que o servidor do portal guarda, byte a byte:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -pubkey | cmp - <(openssl pkey -in pki/portal.key -pubout) && echo "the certificate carries the public half of portal.key"
the certificate carries the public half of portal.key
```

Então o certificado amarra três coisas: um **nome** (`portal.vereda.example`), uma **chave pública**
e um **emissor** que assinou o par. Um navegador que confia no emissor, e confere a assinatura do
emissor, pode acreditar que essa chave pertence a esse nome. Ele ainda confere mais uma coisa:
durante o handshake, o servidor prova que tem a chave privada correspondente assinando a troca
(aula 7). Um certificado sozinho é público; qualquer um pode copiá-lo. Ter a chave privada é o que o
handshake testa.

## O que a autoridade de fato confere

Uma **autoridade certificadora** (AC) só assina depois de conferir que quem pede controla o nome.
Nos certificados que os navegadores usam, essa verificação costuma ser automática e só sobre o
domínio:

- **validação de domínio (DV)**: quem pede prova que controla o domínio, servindo um arquivo num
  endereço dado ou publicando um registro DNS. O Let's Encrypt automatiza isso com o protocolo ACME,
  e é a maioria dos certificados da web;
- **validação de organização (OV)** e **validação estendida (EV)** acrescentam verificações sobre a
  empresa por trás do domínio. Os navegadores pararam de mostrar o EV de forma diferente por volta de
  2019, porque os usuários não percebiam a diferença.

Um certificado DV diz, portanto, "quem pediu isto controlava `portal.vereda.example` naquele
momento", não "esta é uma clínica confiável". É exatamente o que o navegador precisa saber para
descartar um homem no meio, e nada além disso.
