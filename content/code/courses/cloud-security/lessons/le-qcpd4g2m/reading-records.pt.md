---
title: Lendo os registros de uma tarde ruim
version: 1
---

**Uma investigação lê uma trilha com três perguntas, nesta ordem: o que mudou, quem mudou, e o que
aconteceu enquanto estava mudado.** As respostas são filtros sobre um arquivo de registros, e o `jq`,
que a aula 1 instalou, basta para escrevê-los.

O moto não registra nada, então os registros aqui são um arquivo que esta aula entrega a você. **Eles
foram escritos para o curso, não gravados pela AWS**: seis registros no formato que a AWS documenta
para o CloudTrail, resumidos aos campos da tabela da seção anterior, sobre uma tarde na clínica que a
aula 1 reconheceria. Os endereços vêm das faixas reservadas para documentação. Salve-o como
`trail.json`:

```json
{
  "Records": [
    {
      "eventTime": "2026-10-14T12:02:11Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "PutBucketPolicy",
      "eventCategory": "Management",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "203.0.113.24",
      "userAgent": "aws-cli/2.37.4",
      "userIdentity": {
        "type": "IAMUser",
        "arn": "arn:aws:iam::123456789012:user/caio",
        "accountId": "123456789012",
        "accessKeyId": "AKIAEXAMPLECAIO00001",
        "userName": "caio"
      },
      "requestParameters": {
        "bucketName": "clinic-exports",
        "bucketPolicy": {
          "Version": "2012-10-17",
          "Statement": [
            {
              "Effect": "Allow",
              "Principal": "*",
              "Action": "s3:GetObject",
              "Resource": "arn:aws:s3:::clinic-exports/*"
            }
          ]
        }
      }
    },
    {
      "eventTime": "2026-10-14T12:40:05Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "GetObject",
      "eventCategory": "Data",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "198.51.100.77",
      "userAgent": "curl/8.5.0",
      "userIdentity": {
        "type": "AWSAccount",
        "accountId": "ANONYMOUS_PRINCIPAL"
      },
      "requestParameters": {
        "bucketName": "clinic-exports",
        "key": "2026-10-14.csv"
      }
    },
    {
      "eventTime": "2026-10-14T13:15:42Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "GetObject",
      "eventCategory": "Data",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "198.51.100.140",
      "userAgent": "python-requests/2.32.3",
      "userIdentity": {
        "type": "AWSAccount",
        "accountId": "ANONYMOUS_PRINCIPAL"
      },
      "requestParameters": {
        "bucketName": "clinic-exports",
        "key": "2026-10-13.csv"
      }
    },
    {
      "eventTime": "2026-10-14T14:03:09Z",
      "eventSource": "cloudtrail.amazonaws.com",
      "eventName": "StopLogging",
      "eventCategory": "Management",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "192.0.2.10",
      "userAgent": "aws-cli/2.31.0",
      "userIdentity": {
        "type": "IAMUser",
        "arn": "arn:aws:iam::123456789012:user/dani",
        "accountId": "123456789012",
        "accessKeyId": "AKIAEXAMPLEDANI00001",
        "userName": "dani"
      },
      "requestParameters": {
        "name": "clinic-trail"
      },
      "errorCode": "AccessDenied",
      "errorMessage": "User: arn:aws:iam::123456789012:user/dani is not authorized to perform: cloudtrail:StopLogging"
    },
    {
      "eventTime": "2026-10-14T15:30:27Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "DeleteBucketPolicy",
      "eventCategory": "Management",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "203.0.113.8",
      "userAgent": "aws-cli/2.37.4",
      "userIdentity": {
        "type": "IAMUser",
        "arn": "arn:aws:iam::123456789012:user/ana",
        "accountId": "123456789012",
        "accessKeyId": "AKIAEXAMPLEANA000001",
        "userName": "ana"
      },
      "requestParameters": {
        "bucketName": "clinic-exports"
      }
    },
    {
      "eventTime": "2026-10-14T15:31:02Z",
      "eventSource": "s3.amazonaws.com",
      "eventName": "GetObject",
      "eventCategory": "Data",
      "awsRegion": "sa-east-1",
      "sourceIPAddress": "198.51.100.77",
      "userAgent": "curl/8.5.0",
      "userIdentity": {
        "type": "AWSAccount",
        "accountId": "ANONYMOUS_PRINCIPAL"
      },
      "requestParameters": {
        "bucketName": "clinic-exports",
        "key": "2026-10-14.csv"
      },
      "errorCode": "AccessDenied",
      "errorMessage": "Access Denied"
    }
  ]
}
```

## O que mudou

Comece contando o que aconteceu, que é o formato da tarde num comando só:

```
ana@laptop:~/aws$ jq -r '.Records[] | .eventName' trail.json | sort | uniq -c
      1 DeleteBucketPolicy
      3 GetObject
      1 PutBucketPolicy
      1 StopLogging
```

## Quem mudou

A mudança que importa é a política do `clinic-exports`. Peça os registros que mudaram a política de
um bucket, e fique com os campos que nomeiam uma pessoa:

```
ana@laptop:~/aws$ jq -c '.Records[] | select(.eventName | test("BucketPolicy")) | {eventTime, eventName, user: .userIdentity.userName, ip: .sourceIPAddress, bucket: .requestParameters.bucketName}' trail.json
{"eventTime":"2026-10-14T12:02:11Z","eventName":"PutBucketPolicy","user":"caio","ip":"203.0.113.24","bucket":"clinic-exports"}
{"eventTime":"2026-10-14T15:30:27Z","eventName":"DeleteBucketPolicy","user":"ana","ip":"203.0.113.8","bucket":"clinic-exports"}
```

**O caio o abriu às 12:02 e a ana o fechou às 15:30, em UTC.** A clínica fica em São Paulo, três horas
atrás, então o bucket ficou público das 09:02 às 12:30 no horário local. Todo horário que uma trilha
imprime é UTC, e uma linha do tempo que o mistura com um relógio de parede põe os eventos na ordem
errada.

A política em si está no registro, em `requestParameters`. **A trilha guarda o que foi pedido, e é
assim que você sabe que a mudança foi uma concessão pública e não outra edição qualquer:**

```
ana@laptop:~/aws$ jq -c '.Records[] | select(.eventName == "PutBucketPolicy") | .requestParameters.bucketPolicy.Statement[] | {Principal, Action}' trail.json
{"Principal":"*","Action":"s3:GetObject"}
```

## O que aconteceu enquanto estava mudado

As leituras que importam são as que ninguém assinou. Um chamador anônimo não tem ARN; o CloudTrail o
registra com a conta `ANONYMOUS_PRINCIPAL`:

```
ana@laptop:~/aws$ jq -r '.Records[] | select(.userIdentity.accountId == "ANONYMOUS_PRINCIPAL") | [.eventTime, .sourceIPAddress, .requestParameters.key, (.errorCode // "served")] | @tsv' trail.json
2026-10-14T12:40:05Z	198.51.100.77	2026-10-14.csv	served
2026-10-14T13:15:42Z	198.51.100.140	2026-10-13.csv	served
2026-10-14T15:31:02Z	198.51.100.77	2026-10-14.csv	AccessDenied
```

**Duas exportações foram servidas a dois endereços que ninguém na clínica conhece, dentro da janela,
e o mesmo endereço que voltou depois da correção foi recusado.** Essa é a evidência de que o relatório
do incidente precisa: quais arquivos, os pacientes de que dia, por quanto tempo ficaram expostos. As
aulas 20 e 21 do curso `soc-response` transformam exatamente isso num relatório e numa notificação
pela LGPD. Sem os eventos de dados que a seção anterior pagou, a primeira consulta ainda acharia a
mudança do caio, e esta não acharia nada.

## E o que foi recusado

```
ana@laptop:~/aws$ jq -r '.Records[] | select(.errorCode) | [.eventTime, (.userIdentity.userName // .userIdentity.accountId), .eventName, .errorCode] | @tsv' trail.json
2026-10-14T14:03:09Z	dani	StopLogging	AccessDenied
2026-10-14T15:31:02Z	ANONYMOUS_PRINCIPAL	GetObject	AccessDenied
```

A segunda linha nem é sobre o bucket. **A dani, que saiu em março, tentou parar a trilha de um
endereço que a clínica não usa, e foi recusada.** Um `StopLogging` recusado é um dos registros que
merecem um alarme por si só, e a próxima seção trata de garantir que a tentativa continue recusada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l15-timeline\" aria-label=\"Uma linha do tempo da tarde nos registros de exemplo da aula, em UTC, das 12:00 às 16:00. Às 12:02 o caio aplica uma política de bucket que torna o clinic-exports público, e a janela de exposição abre. Às 12:40 um chamador anônimo em 198.51.100.77 recebe o 2026-10-14.csv, e às 13:15 outro em 198.51.100.140 recebe o 2026-10-13.csv. Às 14:03 a chave da dani tenta StopLogging e é recusada. Às 15:30 a ana apaga a política do bucket, e a janela fecha depois de 3 horas e 28 minutos. Às 15:31 o primeiro endereço anônimo volta e é recusado.\"><path d=\"M55.3 122.0 L610.0 122.0\" stroke=\"var(--amber)\" stroke-width=\"3\" fill=\"none\"></path><path d=\"M55.3 116.0 L55.3 128.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><path d=\"M610.0 116.0 L610.0 128.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"332.7\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">público por 3 h 28 min</text><path d=\"M50.0 150.0 L690.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M50.0 146.0 L50.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"50.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">12:00</text><path d=\"M210.0 146.0 L210.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"210.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">13:00</text><path d=\"M370.0 146.0 L370.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"370.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14:00</text><path d=\"M530.0 146.0 L530.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"530.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">15:00</text><path d=\"M690.0 146.0 L690.0 154.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"690.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">16:00</text><text x=\"690.0\" y=\"180.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">UTC</text><path d=\"M55.3 150.0 L55.3 112.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"55.3\" cy=\"150.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"59.3\" y=\"94.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o caio o torna público</text><text x=\"59.3\" y=\"108.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">PutBucketPolicy</text><path d=\"M156.7 150.0 L156.7 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"156.7\" cy=\"150.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"160.7\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">servido a um chamador anônimo</text><text x=\"160.7\" y=\"210.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.77</text><path d=\"M250.0 150.0 L250.0 230.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"250.0\" cy=\"150.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"254.0\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">servido a outro</text><text x=\"254.0\" y=\"250.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.140</text><path d=\"M378.0 150.0 L378.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"378.0\" cy=\"150.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"382.0\" y=\"54.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a chave da dani, recusada</text><text x=\"382.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">StopLogging</text><path d=\"M610.0 150.0 L610.0 112.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"610.0\" cy=\"150.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"606.0\" y=\"94.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">a ana o fecha</text><text x=\"606.0\" y=\"108.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">DeleteBucketPolicy</text><path d=\"M612.7 150.0 L612.7 190.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"2 3\"></path><circle cx=\"612.7\" cy=\"150.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><text x=\"608.7\" y=\"196.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">o primeiro chamador, recusado</text><text x=\"608.7\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">198.51.100.77</text></svg>", "caption": "Os eventos de gerenciamento dizem quando a janela abriu e fechou; só os eventos de dados dizem o que passou por ela."}
```
