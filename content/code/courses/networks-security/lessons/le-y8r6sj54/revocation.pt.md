---
title: Revogando um certificado
version: 1
---

A chave de `app.corp.example.com` foi copiada para um notebook que depois foi roubado. O certificado
vale até 28 de dezembro, e qualquer um que tenha a chave pode apresentá-lo. **Revogação**
(*revocation*) é a CA dizendo, antes da data de expiração, que não responde mais por um certificado:

```
root@admin:~# cd ca; openssl ca -config ca.cnf -cert issuing.crt -keyfile issuing.key -revoke app.crt -crl_reason keyCompromise 2>&1 | tail -1
Database updated
```

O registro é atualizado, mas os clientes nunca leem o registro da CA. A CA publica uma **lista de
certificados revogados** (*certificate revocation list*, CRL), uma lista de números de série
revogados, assinada pela CA e válida por um período declarado:

```
root@admin:~# cd ca; openssl ca -config ca.cnf -cert issuing.crt -keyfile issuing.key -gencrl -crldays 7 -out issuing.crl 2>/dev/null; openssl crl -in issuing.crl -noout -text | grep -E "Last Update|Next Update|Serial Number|Revocation Date|Key Compromise"
        Last Update: Sep 28 20:47:40 2026 GMT
        Next Update: Oct  5 20:47:40 2026 GMT
    Serial Number: 1003
        Revocation Date: Sep 28 20:47:40 2026 GMT
                Key Compromise
```

Número de série 1003, revogado, motivo `Key Compromise`, e um `Next Update` daqui a sete dias: os
clientes podem guardar a lista em cache por esse tempo, e a CA promete uma nova até lá. Um verificador
que consulta a CRL recusa o certificado revogado e continua aceitando os outros:

```
root@admin:~# cd ca; cat issuing.crt root.crt > chain.pem; openssl verify -crl_check -CAfile chain.pem -CRLfile issuing.crl app.crt; openssl verify -crl_check -CAfile chain.pem -CRLfile issuing.crl www.example.com.crt
CN = app.corp.example.com
error 23 at 0 depth lookup: certificate revoked
error app.crt: verification failed
www.example.com.crt: OK
```

Erro 23, `certificate revoked`, para `app`; `OK` para `www`. O registro agora marca a linha com `R`,
com a data e o motivo:

```
root@admin:~# cd ca; tail -2 index.txt
V	261130000000Z		1002	unknown	/CN=www.example.com
R	261228000000Z	260928204740Z,keyCompromise	1003	unknown	/CN=app.corp.example.com
```

## Por que a revogação é o elo fraco

Tudo acima funciona quando o verificador confere. **Na web pública, muitos clientes simplesmente não
conferem**, ou conferem e seguem em frente se a lista não puder ser baixada, que é exatamente o que
alguém usando uma chave roubada providenciaria. As alternativas trocam, cada uma, alguma coisa:

| mecanismo | como | sua fraqueza |
|---|---|---|
| CRL | o cliente baixa a lista da CA | as listas crescem; os clientes as pulam |
| OCSP | o cliente pergunta à CA sobre um certificado | uma consulta por conexão, e a CA fica sabendo o que todo mundo visita |
| OCSP stapling | o servidor busca a resposta e a envia no handshake | só ajuda se o cliente exigir |
| validade curta | certificados válidos por dias ou semanas, renovados automaticamente | exige automação em toda parte |

O caminho que a web tomou é a última linha: quando um certificado vive algumas semanas, uma chave
roubada serve por algumas semanas, com revogação ou sem. Dentro de uma empresa a CA controla as duas
pontas, então pode fazer o que a web pública não pode: **obrigar todo cliente a consultar a CRL e a
recusar quando não conseguir**.
