---
title: Três jeitos de um evento entrar
version: 1
---

O Lambda tem uma lista longa de serviços capazes de iniciar uma função, e é tentador aprendê-los um
por um. **Por baixo há só três formatos, e o formato decide quem espera, quem tenta de novo e onde um
evento que falhou vai parar.** Uma origem ou chama a função e espera a resposta, ou entrega o evento
e vai embora, ou é lida pelo próprio Lambda. Aprenda os três e cada origem nova vira a pergunta de
qual deles ela é.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"Três jeitos de um evento chegar a uma função Lambda. Push síncrono, do API Gateway, de uma URL de função ou de um invoke: quem chama envia o evento e espera a resposta ou o erro. Push assíncrono, do S3, do SNS ou do EventBridge: a origem entrega o evento à fila do próprio Lambda e fica sabendo que foi aceito; o Lambda chama a função e tenta de novo, e depois manda uma falha para um destino. Poller, para SQS, DynamoDB Streams e Kinesis: um mapeamento de origem de eventos rodado pelo Lambda lê a fila ou o stream e chama a função com lotes.\"><defs><marker id=\"w-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"w-ah-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"20\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">push síncrono</text><text x=\"20\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">API Gateway, uma URL de função, aws lambda invoke</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">push assíncrono</text><text x=\"20\" y=\"158\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">S3, SNS, EventBridge</text><text x=\"20\" y=\"250\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">um poller</text><text x=\"20\" y=\"268\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SQS, DynamoDB Streams, Kinesis</text><rect x=\"20\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">quem chama</text><rect x=\"420\" y=\"60\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a função</text><path d=\"M152 72 L418 72\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><path d=\"M418 90 L152 90\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah-a)\"></path><text x=\"285\" y=\"64\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o evento</text><text x=\"285\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a resposta, ou o erro</text><text x=\"570\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">quem chama espera, e repete</text><rect x=\"20\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a origem</text><rect x=\"220\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"285\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a fila do Lambda</text><rect x=\"420\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a função</text><rect x=\"590\" y=\"170\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"645\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">destino</text><path d=\"M152 190 L218 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><path d=\"M352 190 L418 190\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><path d=\"M552 190 L588 190\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah-a)\"></path><text x=\"185\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">aceito na hora</text><text x=\"385\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">chama, repete duas vezes</text><rect x=\"20\" y=\"280\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">fila ou stream</text><rect x=\"220\" y=\"280\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"285\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mapeamento de origem</text><rect x=\"420\" y=\"280\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"485\" y=\"300\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a função</text><path d=\"M218 300 L152 300\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><path d=\"M352 300 L418 300\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#w-ah)\"></path><text x=\"185\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o Lambda consulta</text><text x=\"385\" y=\"332\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um lote por chamada</text><text x=\"570\" y=\"300\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o registro fica até dar certo</text></svg>", "caption": "Quem espera, e quem tenta de novo. Num push síncrono quem chama segura a conexão e é dono da nova tentativa; num push assíncrono o Lambda põe o evento na fila e tenta de novo; com um poller o Lambda lê a origem por conta própria, e um registro que falhou fica na sua fila ou no seu shard.", "same": ["SQS, DynamoDB Streams, Kinesis", "S3, SNS, EventBridge"]}
```

## Push síncrono: quem chama espera

O API Gateway, uma URL de função e o `aws lambda invoke` chamam a função e **seguram a conexão até
ela responder**. A resposta, ou o erro, volta direto para quem chamou, exatamente como o `curl` do
emulador recebeu na aula 14. Aqui o Lambda não tenta nada de novo: se a função falha, quem chamou
fica sabendo, e tentar outra vez é decisão de quem chamou. Um pedido web pelo API Gateway é o caso
comum, e o timeout do próprio API Gateway, menor que os quinze minutos do Lambda, é um dos assuntos
da aula 19.

## Push assíncrono: o Lambda fica com o evento e com as novas tentativas

O S3, o SNS e o EventBridge invocam uma função de forma **assíncrona**. O Lambda põe o evento numa
fila própria e responde na hora à origem que ele foi aceito, e depois chama a função a partir dessa
fila. Se a função falha, o Lambda tenta de novo, duas vezes por padrão, com uma espera entre as
tentativas; um evento que continua falhando, ou que espera mais que a sua idade máxima, seis horas
por padrão, é descartado, a menos que a função tenha para onde mandá-lo. Os dois números e o lugar
para onde mandar as falhas são configurações da função, e o moto as guarda:

```
ana@laptop:~/aws$ aws lambda put-function-event-invoke-config --function-name thumbs --maximum-retry-attempts 1 --maximum-event-age-in-seconds 3600 --destination-config '{"OnFailure": {"Destination": "arn:aws:sqs:sa-east-1:123456789012:thumbs-failed"}}'
{
    "LastModified": "2026-10-16T13:50:02.926000-03:00",
    "FunctionArn": "arn:aws:lambda:sa-east-1:123456789012:function:thumbs",
    "MaximumRetryAttempts": 1,
    "MaximumEventAgeInSeconds": 3600,
    "DestinationConfig": {
        "OnFailure": {
            "Destination": "arn:aws:sqs:sa-east-1:123456789012:thumbs-failed"
        }
    }
}
```

Uma nova tentativa em vez de duas, uma hora em vez de seis, e um **destino em caso de falha**: uma
fila SQS que recebe o evento e o erro quando o Lambda desiste. **Esta é a configuração para procurar
primeiro em qualquer função assíncrona**, porque sem ela um evento que falhou não deixa nada além de
uma linha no log. Um destino também pode ser um tópico SNS, outra função ou um barramento do
EventBridge, e um destino em caso de sucesso também é possível. O mecanismo mais antigo, uma
dead-letter queue na função, faz a metade da falha do mesmo trabalho.

O que o moto não faz é a fila em si: ele nunca chama a função, então nenhuma nova tentativa foi
executada aqui, e a configuração acima é um registro. **A consequência das novas tentativas, porém,
é sua na AWS**: o mesmo evento pode rodar a função mais de uma vez, então um handler assíncrono
precisa ser seguro para rodar duas vezes com o mesmo evento. A aula 21 chama isso de idempotência e
constrói em cima disso.

## Um poller: o Lambda lê a origem

O SQS, o DynamoDB Streams e o Kinesis não chamam nada. Uma fila ou um stream espera ser lido, e quem
lê é um **mapeamento de origem de eventos** (event source mapping): um poller que o Lambda roda por
você, que lê a origem, junta registros num lote e invoca a função de forma síncrona com ele. O
tratamento de falhas é do mapeamento e da origem: uma mensagem que a função não terminou fica na sua
fila e volta a ficar visível, e um registro de stream fica no seu shard e é tentado de novo, então
por padrão nada se perde, e as perguntas passam a ser por quanto tempo um registro ruim é tentado de
novo e o que ele segura enquanto isso. A seção 04 trata dessas perguntas.

## Qual deles uma origem é

| origem | formato | quem tenta de novo |
| --- | --- | --- |
| API Gateway, URL de função, `invoke` | push síncrono | quem chama |
| S3, SNS, EventBridge | push assíncrono | o Lambda, duas vezes por padrão |
| SQS | poller | o mapeamento, pelo visibility timeout da fila |
| DynamoDB Streams, Kinesis | poller | o mapeamento, segurando o shard até dar certo ou desistir |

**A tabela é o motivo de duas funções com o mesmo código se comportarem de jeitos diferentes em
produção.** Um handler que levanta uma exceção num evento ruim custa a um usuário web uma página de
erro atrás do API Gateway, mais duas tentativas e um destino atrás do S3, e atrás de um stream, um
shard que para de andar até alguém olhar. O resto desta aula pega cada formato com uma origem de
verdade e roda o handler de cada um no emulador, com o evento que aquela origem envia.
