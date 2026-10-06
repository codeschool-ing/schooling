---
title: S/MIME, protegendo a mensagem em vez da conexão
version: 1
---

**O S/MIME assina e cifra a própria mensagem de e-mail, então a proteção fica com a mensagem em todo
servidor e caixa postal por onde ela passa.** O TLS entre servidores de e-mail protege cada trecho
da viagem, e cada servidor no caminho guarda a mensagem em texto claro. Um encaminhamento assinado e
cifrado com S/MIME chega exatamente como a Ana o mandou, legível só pelo Bruno, e ainda verificável
anos depois.

## Um certificado para um endereço

O S/MIME usa certificados como os de um servidor web, com duas diferenças que importam: o nome é um
endereço de e-mail, e o uso da chave é proteção de e-mail:

```
ana@lab:~/lab$ openssl x509 -in pki/ana-mail.pem -noout -subject -ext subjectAltName,extendedKeyUsage
subject=C = BR, O = Vereda Fisioterapia, OU = Clinical staff, CN = ana.lima@vereda.example
X509v3 Extended Key Usage: 
    E-mail Protection
X509v3 Subject Alternative Name: 
    email:ana.lima@vereda.example
```

A AC emissora da Vereda emitiu um para a Ana e um para o Bruno. Para e-mail entre organizações, os
certificados vêm de uma AC pública que emite certificados S/MIME, sob as regras de S/MIME do
CA/Browser Forum adotadas em 2023.

## Assinando

A Ana assina o encaminhamento. O `openssl cms` grava o resultado em CMS, a *Cryptographic Message
Syntax* sobre a qual o S/MIME é construído, aqui em forma PEM:

```
ana@lab:~/lab$ openssl cms -sign -nodetach -noattr -md sha256 -in data/referral.txt -signer pki/ana-mail.pem -inkey pki/ana-mail.key -certfile pki/issuing1.pem -outform PEM -out referral.p7s; head -3 referral.p7s
-----BEGIN CMS-----
MIIKAgYJKoZIhvcNAQcCoIIJ8zCCCe8CAQExDTALBglghkgBZQMEAgEwgb4GCSqG
SIb3DQEHAaCBsASBrVJlZmVycmFsIDIwMjYtMDQxNy4gUGF0aWVudDogTWFyaW5h
```

O bloco contém a carta, o certificado da Ana, o certificado da AC emissora e a assinatura RSA da Ana
sobre um resumo SHA-256 da carta: as aulas 3, 4 e 8 numa estrutura só. O Bruno, ou qualquer um com a
raiz da Vereda, a verifica e recebe a carta de volta:

```
ana@lab:~/lab$ openssl cms -verify -inform PEM -in referral.p7s -CAfile pki/root.pem -attime 1781535600 -purpose smimesign 2>&1
CMS Verification successful
Referral 2026-0417. Patient: Marina Duarte, 41.
Lower back pain after lifting, eight weeks. Eight sessions of physiotherapy.
Dr. Paulo Nogueira, CRM-SP 000000 (invented)
```

Um cliente de e-mail faz a mesma verificação e mostra o endereço de quem assinou, que ele compara
com a linha `From:` da mensagem. Uma assinatura de um certificado válido para um endereço
*diferente* do que está no `From:` é um sinal de alerta, não de tranquilidade.

## Cifrando para o Bruno

A cifragem é o esquema híbrido da aula 3: uma chave AES-256-GCM nova cifra a carta, e a chave é
cifrada com a chave pública RSA do Bruno usando OAEP. Imprimir a estrutura mostra exatamente isso:

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

`authEnvelopedData` é a cifragem autenticada do CMS. O destinatário é identificado pelo emissor e
pelo número de série do certificado dele (23042 é `0x5A02`, o do Bruno), e os dois algoritmos são os
nomeados. O Bruno decifra com a chave privada dele:

```
ana@lab:~/lab$ openssl cms -decrypt -inform PEM -in referral.p7m -recip pki/bruno-mail.pem -inkey pki/bruno-mail.key | head -1
Referral 2026-0417. Patient: Marina Duarte, 41.
```

A chave da Ana não a abre, embora tenha sido ela quem escreveu:

```
ana@lab:~/lab$ openssl cms -decrypt -inform PEM -in referral.p7m -recip pki/ana-mail.pem -inkey pki/ana-mail.key 2>&1 | head -1
Error decrypting CMS using private key
```

Um cliente de e-mail real, por isso, também cifra cada mensagem para o certificado do próprio
**remetente**, como segundo destinatário, para que a cópia enviada continue legível. Isso é mais um
destinatário na estrutura, não uma segunda cifragem da mensagem.

## O que o S/MIME deixa visível

Os cabeçalhos ficam em texto claro: quem escreveu para quem, quando, e a linha de assunto, a menos
que o cliente ponha uma cópia protegida do assunto lá dentro. E a cifragem dura só enquanto durar a
chave privada do destinatário: uma organização que cifra e-mail precisa manter recuperáveis as
chaves de cifragem dos destinatários (a custódia da aula 3), ou um notebook perdido leva anos de
correspondência junto. O **OpenPGP** oferece as mesmas duas operações com formato de chave próprio e
uma rede de confiança em vez de ACs; as decisões são as mesmas.
