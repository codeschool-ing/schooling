---
title: "Event buses: regras que escolhem os alvos"
version: 1
---

Um tópico e um bus entregam uma mensagem a vários lugares, o que faz o EventBridge parecer o SNS com
outro nome. **A diferença é quem decide para onde um evento vai.** No SNS, o assinante assina e
filtra por conta própria. No EventBridge, o produtor só diz o que aconteceu, como um evento
estruturado, e **regras** no bus decidem quais alvos o recebem, comparando o conteúdo dele. O
produtor não conhece consumidor nenhum, e um consumidor novo é uma regra nova que ninguém a montante
precisa mudar.

## Um bus da própria loja

Toda conta tem um bus chamado `default`, onde os serviços da AWS publicam os próprios eventos: uma
instância EC2 mudando de estado, um objeto criado no S3, uma execução do Step Functions falhando. Um
**bus custom** é para os eventos da aplicação, para que as regras dela não se misturem com as da
AWS:

```
ana@laptop:~/aws$ aws events create-event-bus --name shop --query EventBusArn --output text
arn:aws:events:sa-east-1:123456789012:event-bus/shop
```

Uma regra é um **padrão**, um documento JSON com o formato dos eventos que ele casa. Cada campo lista
os valores que casam, e um valor também pode ser um teste, como `numeric`. Esta regra casa pedidos
acima de 1000:

```
ana@laptop:~/aws$ aws events put-rule --name big-orders --event-bus-name shop --event-pattern '{"source": ["shop.orders"], "detail-type": ["OrderPlaced"], "detail": {"total": [{"numeric": [">", 1000]}]}}' --query RuleArn --output text
arn:aws:events:sa-east-1:123456789012:rule/shop/big-orders
```

**Um padrão casa quando todo campo que ele cita casa.** Campos que o padrão não cita podem ter
qualquer coisa, e um evento sem um campo que o padrão cita não casa. O alvo da regra é uma fila
onde alguém revisa os pedidos grandes:

```
ana@laptop:~/aws$ aws sqs create-queue --queue-name review --query QueueUrl --output text
http://localhost:4567/123456789012/review
ana@laptop:~/aws$ aws events put-targets --rule big-orders --event-bus-name shop --targets Id=review,Arn=arn:aws:sqs:sa-east-1:123456789012:review --query FailedEntryCount
0
```

Na AWS, como no SNS, a fila precisa de uma política que deixe `events.amazonaws.com` mandar para
ela, e o moto não a verifica. Uma regra pode ter até cinco alvos, e um alvo pode ser uma função
Lambda, uma máquina de estados do Step Functions, um tópico do SNS, outro bus, ou um API destination
que chama um endereço HTTPS fora da AWS.

## Pondo eventos no bus

Um evento tem uma origem, um tipo de detalhe e um detalhe, que é o JSON da própria aplicação como
string. Salve dois pedidos como `~/aws/entries.json`:

```json
[
  {"EventBusName": "shop", "Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"id\": \"42\", \"total\": 1500}"},
  {"EventBusName": "shop", "Source": "shop.orders", "DetailType": "OrderPlaced", "Detail": "{\"id\": \"43\", \"total\": 300}"}
]
```

```
ana@laptop:~/aws$ aws events put-events --entries file://entries.json --query FailedEntryCount
0
ana@laptop:~/aws$ aws sqs receive-message --queue-url "$Q/review" --max-number-of-messages 10 --query "Messages[].Body" --output text | jq .
{
  "id": "f2f06ca8-9757-4aa3-b44a-5a25e9165420",
  "time": "2026-10-16T16:47:14Z",
  "version": "0",
  "detail-type": "OrderPlaced",
  "source": "shop.orders",
  "region": "sa-east-1",
  "resources": [],
  "detail": {
    "id": "42",
    "total": 1500
  }
}
```

**Um evento chegou à fila de revisão, e o outro não foi a lugar nenhum.** O pedido de 300 não casou
nenhuma regra, e um evento que não casa nenhuma regra é descartado: não há fila atrás do bus que o
guarde, a menos que você crie um archive, que guarda eventos para reprocessar depois. O evento que
chegou é o envelope do EventBridge, com um `id`, um `time`, o `source` e o `detail-type` que a regra
casou, e o `detail` como JSON e não como string. Um evento real também traz a `account`; o moto a
deixa de fora.

A AWS consegue testar um padrão contra um evento sem mandar nada, com
`aws events test-event-pattern`. O moto 5.2.3 dá a esse comando uma resposta vazia, então no
laboratório um padrão é testado mandando eventos, como acima.

## Regras com horário, e o scheduler

Uma regra também pode disparar num horário, `rate(5 minutes)` ou uma expressão `cron`, sem evento
nenhum. Para trabalho novo a AWS indica o **EventBridge Scheduler**, um serviço separado em que cada
agenda é um recurso próprio, com fuso horário e política de novas tentativas, e que pode iniciar uma
única execução num momento dado. Um relatório noturno rodado como workflow Standard da aula 20,
iniciado às 03:00 de São Paulo, é uma agenda do Scheduler.

## Qual dos três

**Uma fila quando um consumidor precisa fazer o trabalho, um tópico quando vários consumidores
conhecidos precisam cada um de uma cópia, um bus quando os consumidores não são conhecidos de
antemão e o conteúdo decide.** Os três são usados juntos o tempo todo: o alvo de uma regra é uma
fila, para que o consumidor atrás dela tenha as novas tentativas e a dead-letter queue da primeira
seção; um tópico distribui para filas, para que cada time mantenha o seu ritmo. O preço está na
próxima seção, e na tabela um evento custom custa mais que uma publicação no SNS, então o bus não é
o padrão para um fluxo de alto volume com consumidores fixos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Três formas lado a lado. Uma fila: um produtor manda para a fila work, e de dois workers só um recebe cada mensagem. Um tópico: quem publica manda para o tópico orders, que copia a mensagem para as filas billing e shipping; a assinatura de shipping tem um filtro que barra pedidos digitais. Um event bus: os eventos vão para o bus shop, a regra big-orders casa totais acima de 1000 e os manda para a fila review, e um evento com total 300 não casa nenhuma regra e não vai a lugar nenhum.\"><defs><marker id=\"shapes-p\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"shapes-a\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"16\" y=\"12\" width=\"220\" height=\"236\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"126\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">fila</text><text x=\"126\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma mensagem, um consumidor a pega</text><rect x=\"252\" y=\"12\" width=\"220\" height=\"236\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"362\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">tópico</text><text x=\"362\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma mensagem, uma cópia por assinatura</text><rect x=\"488\" y=\"12\" width=\"220\" height=\"236\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"598\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">event bus</text><text x=\"598\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">um evento, toda regra que casa</text><rect x=\"36\" y=\"70\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"81\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">produtor</text><path d=\"M81 100 L81 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"36\" y=\"128\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"81\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">work</text><path d=\"M70 158 L54 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><path d=\"M92 158 L110 196\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#shapes-a)\"></path><rect x=\"20\" y=\"198\" width=\"76\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"58\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">worker</text><rect x=\"102\" y=\"198\" width=\"76\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\" stroke-dasharray=\"4 3\"></rect><text x=\"140\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">worker</text><rect x=\"286\" y=\"70\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"331\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">publish</text><path d=\"M331 100 L331 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"286\" y=\"128\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"331\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">orders</text><path d=\"M316 158 L290 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><path d=\"M346 158 L372 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"258\" y=\"198\" width=\"84\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"300\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">billing</text><rect x=\"348\" y=\"198\" width=\"84\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"390\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shipping</text><text x=\"390\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">filtro barra digital</text><rect x=\"522\" y=\"70\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"567\" y=\"85\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">put-events</text><path d=\"M567 100 L567 126\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"522\" y=\"128\" width=\"90\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"567\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop</text><path d=\"M560 158 L540 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#shapes-p)\"></path><rect x=\"490\" y=\"198\" width=\"100\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"540\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">review</text><text x=\"540\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper-dim)\">big-orders</text><path d=\"M590 158 L640 190\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#shapes-a)\"></path><text x=\"650\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--amber)\">total 300: nenhuma regra</text></svg>", "caption": "Quem recebe o quê. Uma fila entrega cada mensagem a um consumidor; um tópico dá a cada assinatura a sua própria cópia, filtrada por assinatura; um bus manda cada evento aos alvos de toda regra cujo padrão ele casa, e a ninguém se nenhuma casar.", "same": ["event bus", "worker"]}
```
