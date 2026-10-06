---
title: Os campos de um certificado X.509
version: 1
---

**Um certificado TLS é um documento X.509 versão 3: um conjunto fixo de campos, uma lista de
extensões e uma assinatura do emissor sobre tudo isso.** O OpenSSL imprime o certificado inteiro do
portal da Vereda assim:

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

Tudo acima de `Signature Algorithm`, perto do fim, são os dados que o emissor assinou, chamados de
parte *a ser assinada* (*to-be-signed*). O último bloco é a assinatura do emissor sobre isso, 256
bytes porque a AC emissora da Vereda tem uma chave RSA de 2048 bits. Mude um byte em qualquer ponto
acima e essa assinatura deixa de verificar, e foi assim que o impostor do laboratório na aula 8 foi
pego.

## Os campos, de cima para baixo

| campo | no certificado do portal | o que um cliente faz com ele |
|---|---|---|
| Version | 3 | todo certificado em uso é versão 3, a que tem extensões |
| Serial Number | `0x3a01` | único por emissor; é como uma lista de revogação nomeia um certificado |
| Signature Algorithm | `sha256WithRSAEncryption` | como o emissor assinou; SHA-1 ou MD5 aqui é recusado (aula 4) |
| Issuer | Vereda Issuing CA 1 | qual certificado procurar a seguir na cadeia |
| Validity | 1º de maio a 17 de novembro de 2026 | recusado fora dessas datas, seção 03 |
| Subject | `CN = portal.vereda.example` | um rótulo para pessoas; não é contra ele que o nome do host é conferido |
| Subject Public Key Info | chave P-256 | a chave que o servidor precisa provar que tem |

## As extensões que decidem

As extensões carregam a maior parte do que importa hoje. As marcadas `critical` precisam ser
entendidas pelo cliente, ou o certificado inteiro é recusado:

- **Basic Constraints** `CA:FALSE`: este certificado não pode assinar outros certificados (aula 8).
- **Key Usage** `Digital Signature`: a chave só pode assinar, que no TLS 1.3 é tudo o que a chave de
  um servidor faz.
- **Extended Key Usage** `TLS Web Server Authentication`: a chave é para um servidor TLS, não para
  assinar código ou e-mail. Um cliente que confere um servidor recusa um certificado sem isso.
- **Subject Alternative Name** `DNS:portal.vereda.example`: **os nomes de host para os quais o
  certificado vale**, seção 04.
- **Subject Key Identifier** e **Authority Key Identifier**: impressões digitais da chave deste
  certificado e da chave do emissor. Elas deixam um cliente achar o emissor certo mesmo quando duas
  ACs têm o mesmo nome, que é exatamente o caso do impostor.
- **CRL Distribution Points**: onde buscar a lista de revogação do emissor, seção 05.

## Codificações que você vai encontrar

O arquivo é **PEM**: Base64 entre linhas `-----BEGIN CERTIFICATE-----` (a aula 11 explica o
Base64). Dentro dele está o **DER**, a codificação binária da mesma estrutura. O Windows costuma usar
`.cer` e `.crt` para qualquer um dos dois; Java e Windows também empacotam um certificado com sua
chave privada num arquivo **PKCS#12** (`.p12`, `.pfx`), protegido por senha. O
`openssl x509 -inform DER` lê a forma binária, e o `openssl pkcs12` abre um pacote. O conteúdo é o
mesmo em todos eles; só o embrulho muda.
