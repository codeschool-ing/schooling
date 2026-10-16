---
title: Lendo um registro
version: 1
---

Um registro do CloudTrail é um objeto JSON, e cinco dos seus campos respondem à maioria das perguntas.
Este é resumido do formato que a AWS documenta, como o dia inventado da próxima seção o escreve:

```json
{
  "eventTime": "2026-10-15T14:05:00Z",
  "eventSource": "s3.amazonaws.com",
  "eventName": "DeleteBucket",
  "awsRegion": "sa-east-1",
  "sourceIPAddress": "198.51.100.77",
  "userAgent": "aws-cli/2.37.4",
  "userIdentity": {
    "type": "AssumedRole",
    "arn": "arn:aws:sts::123456789012:assumed-role/shop-admin/bruno",
    "accountId": "123456789012",
    "sessionContext": {
      "sessionIssuer": { "type": "Role", "userName": "shop-admin", "arn": "arn:aws:iam::123456789012:role/shop-admin" }
    }
  },
  "requestParameters": { "bucketName": "shop-exports-old" },
  "readOnly": false
}
```

| campo | responde |
|---|---|
| `eventTime` | quando, sempre em UTC |
| `eventSource`, `eventName` | que serviço, que operação |
| `userIdentity` | quem, e por qual role |
| `sourceIPAddress`, `userAgent` | de onde, e com que programa |
| `requestParameters`, `errorCode` | sobre o quê, e se funcionou |

## Quem, através de uma role

Pessoas numa conta bem cuidada não têm usuários com chaves; elas **assumem roles**, como o
`aws-foundations` e a lição 17 ensinaram. Então `userIdentity.type` é `AssumedRole`, e a identidade tem duas
partes. A **role**, `shop-admin`, diz o que quem chamou podia fazer. O **nome da sessão**, a última parte do
ARN, `bruno`, diz quem foi, desde que o jeito de as pessoas entrarem na conta o defina com o próprio nome,
o que o IAM Identity Center faz e um script compartilhado com nome de sessão fixo não faz. **Um log de
auditoria que diz `assumed-role/admin/session` para todo mundo responde *quem* com *alguém*.**

`readOnly` separa as leituras das mudanças, e costuma ser o primeiro filtro: uma conta faz milhares de
chamadas `Describe` por dia e um punhado de mudanças, e a pergunta é quase sempre sobre uma mudança. Um
registro que falhou traz `errorCode` e `errorMessage`, e **falhas também são evidência**: uma rajada de
`AccessDenied` de uma identidade é alguém testando portas.
