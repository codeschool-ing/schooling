---
title: Revogação: tomar de volta um certificado antes de expirar
version: 1
---

**Revogação é o emissor declarar que um certificado não deve mais ser confiável, antes da data
`Not After`: porque a chave vazou, porque foi emitido errado ou porque o nome mudou de dono.** O
mecanismo existe e funciona no laboratório. Na web pública ele nunca funcionou bem, e essa é uma boa
parte do motivo de a vida dos certificados estar encolhendo.

## A Vereda revoga um

Em 20 de maio, a chave privada de `files.vereda.example` foi achada num repositório público. A AC
emissora da Vereda acrescentou o número de série do certificado à sua **lista de certificados
revogados** (CRL), um arquivo que ela assina e publica:

```
ana@lab:~/lab$ openssl crl -in pki/issuing1.crl -noout -text | head -15
Certificate Revocation List (CRL):
        Version 2 (0x1)
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
        Last Update: Jun  1 00:00:00 2026 GMT
        Next Update: Jun 30 00:00:00 2026 GMT
        CRL extensions:
            X509v3 CRL Number: 
                7
Revoked Certificates:
    Serial Number: 3A03
        Revocation Date: May 20 00:00:00 2026 GMT
        CRL entry extensions:
            X509v3 CRL Reason Code: 
                Key Compromise
```

A lista nomeia o emissor, quando foi feita (`Last Update`), quando a próxima é esperada
(`Next Update`) e cada número de série revogado, com data e motivo. `3A03` é o número de série do
servidor de arquivos, o mesmo número que o certificado dele traz no campo `Serial Number`. A CRL é
assinada pela AC emissora, então ninguém mais consegue acrescentar ou remover entradas.

## Uma verificação que precisa ser pedida

Conferido do jeito das seções anteriores, o certificado do servidor de arquivos passa. Cadeia, datas
e assinatura estão todas certas:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/files.pem
pki/files.pem: OK
```

Só quando a verificação é mandada consultar a CRL ela falha:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -crl_check -CRLfile pki/issuing1.crl -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/files.pem
C = BR, O = Vereda Fisioterapia, CN = files.vereda.example
error 23 at 0 depth lookup: certificate revoked
error pki/files.pem: verification failed
```

Essa é a fraqueza da revogação num par de comandos. **Um cliente que não olha não fica sabendo.** E
a própria CRL expira: passada a `Next Update`, não dá mais para confiar que a lista esteja atual, e
um cliente que a exige recusa tudo, aqui um certificado que nunca foi revogado:

```
ana@lab:~/lab$ openssl verify -attime $(date -d "2026-07-15 12:00 -03" +%s) -crl_check -CRLfile pki/issuing1.crl -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem
C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
error 12 at 0 depth lookup: CRL has expired
error pki/portal.pem: verification failed
```

## Onde o cliente olha, e por que muitas vezes não olha

Cada certificado diz onde o emissor publica a CRL:

```
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -ext crlDistributionPoints
X509v3 CRL Distribution Points: 
    Full Name:
      URI:http://pki.vereda.example/issuing1.crl
```

Três jeitos de conferir foram tentados na web pública, e cada um tem um problema:

- **CRLs** podem ficar grandes, e baixar uma a cada conexão é lento;
- o **OCSP**, um serviço que o cliente consulta sobre um certificado, conta à AC quais sites cada
  usuário visita, e quando o respondedor não responde os navegadores sempre **seguiram em frente**
  (*soft-fail*), então um atacante capaz de bloquear a consulta a derrota. O *OCSP stapling*, em que
  o servidor busca a resposta e a manda no handshake, resolve os problemas de privacidade e de
  velocidade, mas exige que todo servidor o faça. O Let's Encrypt, a maior AC, encerrou o serviço de
  OCSP em 2025 e passou a publicar CRLs;
- **listas mantidas pelos navegadores**: os CRLSets do Chrome e o CRLite do Firefox comprimem as
  revogações que importam numa lista que o navegador baixa, e é assim que a revogação de
  certificados públicos funciona, na maior parte, hoje.

A conclusão que o setor tirou é aquela com que a aula 8 terminou: **se não dá para confiar na
revogação, faça os certificados expirarem depressa.** Um certificado de 47 dias que vaza é um
problema muito menor que um de 398 dias cuja revogação ninguém confere.

Numa AC **interna** a situação é melhor, porque os clientes são seus: você pode exigir a verificação
da CRL, publicar a CRL num lugar que todo cliente alcança e renová-la bem antes da `Next Update`. A
captura da CRL expirada, acima, é o que acontece no dia em que essa renovação falha.
