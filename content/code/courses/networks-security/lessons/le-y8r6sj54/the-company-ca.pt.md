---
title: A autoridade da própria empresa, campo a campo
version: 1
---

O laboratório tem uma CA desde a aula 2: uma **raiz** (*root*), que assina uma **CA emissora**
(*issuing CA*), que assina os servidores. Aqui ela fica em `admin`. Os três certificados, com os
campos que decidem o que cada um pode fazer:

```
root@admin:~# cd ca; for c in root issuing www.example.com; do echo "== $c"; openssl x509 -in $c.crt -noout -subject -issuer -dates -ext basicConstraints,keyUsage,extendedKeyUsage,subjectAltName 2>/dev/null; done
== root
subject=O = Example Corp, CN = Example Corp Root CA
issuer=O = Example Corp, CN = Example Corp Root CA
notBefore=Sep  1 00:00:00 2026 GMT
notAfter=Sep  1 00:00:00 2036 GMT
X509v3 Basic Constraints: critical
    CA:TRUE
X509v3 Key Usage: critical
    Certificate Sign, CRL Sign
== issuing
subject=O = Example Corp, CN = Example Corp Issuing CA
issuer=O = Example Corp, CN = Example Corp Root CA
notBefore=Sep  1 00:00:00 2026 GMT
notAfter=Sep  1 00:00:00 2031 GMT
X509v3 Basic Constraints: critical
    CA:TRUE, pathlen:0
X509v3 Key Usage: critical
    Certificate Sign, CRL Sign
== www.example.com
subject=CN = www.example.com
issuer=O = Example Corp, CN = Example Corp Issuing CA
notBefore=Sep  1 00:00:00 2026 GMT
notAfter=Nov 30 00:00:00 2026 GMT
X509v3 Basic Constraints: critical
    CA:FALSE
X509v3 Key Usage: critical
    Digital Signature
X509v3 Extended Key Usage: 
    TLS Web Server Authentication
X509v3 Subject Alternative Name: 
    DNS:www.example.com, DNS:example.com
```

Leia-os como três funções diferentes:

| certificado | emissor | válido por | pode assinar certificados? |
|---|---|---|---|
| Example Corp Root CA | ele mesmo | 10 anos | sim, `CA:TRUE` |
| Example Corp Issuing CA | a raiz | 5 anos | sim, mas `pathlen:0`: só certificados finais, nunca outra CA |
| www.example.com | a CA emissora | 90 dias | não, `CA:FALSE`; só `Digital Signature` e `TLS Web Server Authentication` |

**A raiz assina a si mesma**, com sujeito e emissor iguais. Nada responde por ela; ela é confiável
porque alguém a instalou no repositório de confiança (*trust store*), a lista de raízes em que uma
máquina acredita. No `laptop`:

```
ana@laptop:~$ ls -l /etc/ssl/certs/ | grep -i example; openssl x509 -in /etc/ssl/certs/example-corp-root-ca.pem -noout -subject -fingerprint -sha256
lrwxrwxrwx 1 root root     24 Sep 28 17:47 89e5d190.0 -> example-corp-root-ca.pem
lrwxrwxrwx 1 root root     57 Sep 28 17:47 example-corp-root-ca.pem -> /usr/local/share/ca-certificates/example-corp-root-ca.crt
subject=O = Example Corp, CN = Example Corp Root CA
sha256 Fingerprint=13:89:5E:5B:39:9B:02:5D:08:40:35:7B:8D:2B:41:15:12:F7:CC:BA:A9:9B:CB:D9:10:46:20:32:B7:51:10:D8
```

A raiz da empresa fica ao lado das públicas, e a impressão digital dela é o que um administrador lê
em voz alta, ou publica internamente, para que quem a instala possa conferir que tem o arquivo certo.

## Por que dois níveis

A chave privada da raiz poderia assinar os servidores diretamente. Não assina, porque **a raiz é a
única chave cuja perda não tem conserto**: toda máquina que confia nela teria de ser reconfigurada.
Então a raiz assina uma CA emissora uma vez e depois fica offline, numa empresa de verdade em uma
máquina que nunca foi ligada a uma rede, guardada num cofre e usada poucas vezes em dez anos. A CA
emissora faz o trabalho do dia a dia, e se a chave dela um dia se perder, a raiz a revoga e assina
uma nova, e os repositórios de confiança das máquinas não mudam.

`pathlen:0` e `CA:FALSE` são os limites que tornam isso seguro: o certificado de um servidor não pode
ser usado para assinar outro certificado, e a CA emissora não pode criar uma CA própria.
