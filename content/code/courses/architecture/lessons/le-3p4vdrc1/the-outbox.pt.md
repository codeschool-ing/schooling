---
title: O outbox transacional
version: 1
---

A loja grava um pedido no seu banco e publica uma mensagem para os pagamentos cobrarem. São **duas
escritas em dois sistemas**, e nenhuma transação cobre as duas, a garantia perdida da aula 1 de novo.
Cada ordem das duas tem uma falha:

| a loja faz | e cai entre as duas | resultado |
| --- | --- | --- |
| grava o pedido, depois publica | depois da gravação | um pedido que ninguém nunca vai cobrar |
| publica, depois grava o pedido | depois da publicação | um pagamento de um pedido que não existe |

A correção comum a que as pessoas recorrem, publicar dentro da transação do banco, não ajuda: a
publicação não faz parte da transação e não é desfeita com ela.

## Escreva a mensagem onde está o pedido

O **outbox transacional** põe a mensagem no próprio banco da loja, numa tabela `outbox`, na mesma
transação do pedido. Então o pedido e a intenção de anunciá-lo são um fato só: os dois gravados ou
nenhum. Um **relay** separado lê as linhas não enviadas, publica cada uma, espera a confirmação do broker,
e só então marca a linha como enviada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"O outbox transacional. A loja grava a linha do pedido e uma linha no outbox numa transação, no seu próprio banco. Um relay separado lê as linhas não enviadas do outbox, publica cada uma no broker, espera a confirmação do broker e então marca a linha como enviada. O broker entrega ao consumidor de pagamentos.\"><defs><marker id=\"l7-outbox-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l7-outbox-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"250\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"30\" y=\"40\" width=\"290\" height=\"180\" rx=\"4\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"6 4\"></rect><text x=\"44\" y=\"56\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o banco da loja, uma transação</text><rect x=\"50\" y=\"76\" width=\"250\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"101\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">orders: o-1, 649</text><rect x=\"50\" y=\"146\" width=\"250\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"175\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">outbox: o-1, sent = 0</text><text x=\"175\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">→ sent = 1 depois da confirmação</text><rect x=\"360\" y=\"146\" width=\"100\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"410\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">relay</text><rect x=\"500\" y=\"146\" width=\"90\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"171\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">broker</text><rect x=\"500\" y=\"50\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595\" y=\"75\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consumidor de pagamentos</text><path d=\"M302 171 L358 171\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-outbox-ah-amber)\"></path><path d=\"M462 171 L498 171\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-outbox-ah-amber)\"></path><path d=\"M545 144 L565 102\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l7-outbox-ah-phosphor)\"></path><text x=\"410\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">repetido até o broker confirmar</text></svg>", "caption": "O pedido e a sua mensagem são gravados juntos, num banco. Levar a mensagem ao broker é um passo separado que pode ser tentado de novo até dar certo.", "same": ["relay", "broker"]}
```

O `outbox.py` é as duas metades. Pare o broker para deixar o ponto claro, e faça um pedido. `--no-deps`
impede o Compose de iniciar o broker de novo só porque o serviço `tools` depende dele:

```
ana@vm:~/lab/delivery$ docker compose stop rabbitmq
 Container delivery-rabbitmq-1 Stopping 
 Container delivery-rabbitmq-1 Stopped 
ana@vm:~/lab/delivery$ docker compose --progress quiet run --rm --no-deps tools python outbox.py order o-1 649
order o-1 saved, its message waits in the outbox
ana@vm:~/lab/delivery$ docker compose --progress quiet run --rm --no-deps tools python outbox.py relay
broker unreachable; 1 message(s) wait in the outbox
```

**O pedido está gravado, e a mensagem dele também**, embora o broker esteja inalcançável; o relay não
conseguiu entregá-la, disse isso, e a deixou no outbox. Inicie o broker e rode o relay de novo:

```
ana@vm:~/lab/delivery$ docker compose start rabbitmq
 Container delivery-rabbitmq-1 Starting 
 Container delivery-rabbitmq-1 Started 
ana@vm:~/lab/delivery$ $R outbox.py relay
relayed o-1
ana@vm:~/lab/delivery$ $R pay.py
charged o-1: 649 cents (redelivered: False)
```

O relay publicou `o-1`, o broker confirmou, e o consumidor de pagamentos cobrou.

## O que o outbox não elimina

O relay pode cair depois de o broker confirmar e antes de marcar a linha como enviada, e a próxima
execução vai publicar a mesma mensagem de novo. **O outbox transforma "talvez nunca" em "pelo menos uma
vez"**, e é por isso que o consumidor continua precisando ser idempotente: a mensagem carrega o id do
pedido, e `processed` pega a repetição. Os dois padrões são metades de um mesmo projeto, e nenhum funciona
sem o outro.

Em produção o relay raramente é um script que alguém roda. É um laço no serviço, ou uma ferramenta de
captura de mudanças como o Debezium, que lê o log de mudanças confirmadas do próprio banco e publica as
linhas do outbox a partir dali sem consultar a tabela repetidamente.
