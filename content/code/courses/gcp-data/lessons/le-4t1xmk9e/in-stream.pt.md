---
title: O mesmo pipeline, alimentado pelo Pub/Sub
version: 1
---

**A ponta do fluxo muda duas coisas e mantém tudo o que há entre elas.** Lê de uma assinatura do
Pub/Sub em vez de um arquivo, e corta as mensagens em janelas de um minuto antes que o meio as some.
Rodando com `--streaming`, o programa nunca termina sozinho: uma coleção ilimitada não tem último
elemento, então não há um momento em que o job está pronto, só momentos em que uma janela está.

## O emulador, e três tópicos

O emulador do Pub/Sub roda num terminal próprio, iniciado com o mesmo comando da aula 19, depois de
`cd ~/gcp` e da segunda linha de "Every time you open a terminal":

```sh
gcloud beta emulators pubsub start --project=planner-dev --host-port=localhost:8085
```

Depois, no terminal em que você digita, três tópicos: o em que a loja publica, o para onde vão os
totais e um para as linhas ilegíveis. O primeiro recebe a assinatura do próprio pipeline, e os
outros dois uma cada, para você ver o que chega:

```
ana@laptop:~/gcp$ gcloud pubsub topics create order-events order-totals order-totals-unreadable
Created topic [projects/planner-dev/topics/order-events].
Created topic [projects/planner-dev/topics/order-totals].
Created topic [projects/planner-dev/topics/order-totals-unreadable].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create order-events-beam --topic=order-events
Created subscription [projects/planner-dev/subscriptions/order-events-beam].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create order-totals-check --topic=order-totals
Created subscription [projects/planner-dev/subscriptions/order-totals-check].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create order-totals-unreadable-check --topic=order-totals-unreadable
Created subscription [projects/planner-dev/subscriptions/order-totals-unreadable-check].
```

**`order-events-beam` é a assinatura do próprio pipeline.** Uma assinatura é um cursor que pertence
a um leitor, o ponto da aula 19, e um pipeline que dividisse uma com outro programa receberia mais
ou menos metade de cada fluxo de mensagens. No Dataflow também, cada pipeline tem a sua assinatura.

## Sem a janela

Primeiro, a linha de que um fluxo não abre mão. `--window 0` tira o `WindowInto`:

```
ana@laptop:~/gcp$ timeout 60 python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming --window 0 2>&1 | tail -1
ValueError: GroupByKey cannot be applied to an unbounded PCollection with global windowing and a default trigger
```

**O Beam recusa antes de ler uma única mensagem.** Na janela global, com o gatilho padrão, um grupo
é emitido quando a janela termina, e a janela global de uma coleção ilimitada nunca termina. O
`CombinePerKey` esperaria para sempre e não emitiria nada, então o Beam rejeita o grafo em vez de
rodá-lo. As duas saídas são as duas metades da aula 22: cortar o fluxo em janelas que terminam, ou
manter a janela global e dar a ela um gatilho que dispara antes do fim. Este programa fica com a
primeira.

## Com a janela

Num terceiro terminal, depois das mesmas duas linhas, inicie o pipeline:

```sh
timeout 120 python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming
```

```
ana@laptop:~/gcp$ timeout 120 python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming
```

**Ele não imprime nada, do começo ao fim, e isso está certo.** A saída dele vai para um tópico, e
ele está esperando mensagens. `timeout 120` o encerra depois de dois minutos, porque nada mais o
encerraria: um pipeline de streaming roda até alguém pará-lo, o que no Dataflow é um drain ou um cancel, duas coisas diferentes que a próxima seção separa. `Ctrl+C` não é uma saída confiável
do DirectRunner, cujas threads continuam rodando depois que a principal é interrompida.

De volta ao terminal em que você digita, a loja começa a publicar. Este programa manda cada linha do
mesmo `events.jsonl` como uma mensagem. Salve como `~/gcp/publish.py`:

`publish.py`:

```python
"""publish.py: every line of events.jsonl, published to the topic order-events."""
from google.cloud import pubsub_v1

publisher = pubsub_v1.PublisherClient()
topic = publisher.topic_path('planner-dev', 'order-events')
with open('events.jsonl', encoding='utf-8') as f:
    futures = [publisher.publish(topic, line.rstrip('\n').encode('utf-8')) for line in f]
for future in futures:
    future.result()
print(f'{len(futures):,} messages published to {topic}')
```

Espere o fim do minuto e veja o que o pipeline publicou:

```
ana@laptop:~/gcp$ python3 publish.py
2,001 messages published to projects/planner-dev/topics/order-events
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull order-totals-check --auto-ack --limit=20 --format='value(message.data)' | sort
{"window": "15:33:00", "neighbourhood": "Butantã", "orders": 150, "reais": "23835.54"}
{"window": "15:33:00", "neighbourhood": "Moema", "orders": 138, "reais": "22737.55"}
{"window": "15:33:00", "neighbourhood": "Pinheiros", "orders": 161, "reais": "24949.60"}
{"window": "15:33:00", "neighbourhood": "Santana", "orders": 140, "reais": "22367.32"}
{"window": "15:33:00", "neighbourhood": "Tatuapé", "orders": 152, "reais": "26061.58"}
ana@laptop:~/gcp$ gcloud pubsub subscriptions pull order-totals-unreadable-check --auto-ack --limit=5 --format='value(message.data)'
{"order_id": "o-12000", "event": "placed", "total_cents": 
```

**Os mesmos cinco totais da execução da noite, até o centavo, e a mesma linha ruim ao lado.** O
meio do programa não mudou, e a resposta dele também não. O que mudou é a janela: os totais agora dizem de que minuto são. E o minuto é o momento em que
esta execução publicou os eventos, na tarde do dia em que foi gravada, e não a noite de 15 de
outubro que o `at` diz. As 2.001 mensagens
chegaram dentro de um minuto, então uma janela recebeu todas. Publicadas ao longo de uma hora, como
o aplicativo da loja de fato publica, teriam saído como sessenta conjuntos de totais, um para cada
minuto.

**Esse minuto é o horário em que o Pub/Sub recebeu cada mensagem, não o horário do pedido.** O
`ReadFromPubSub` dá a cada elemento o horário de publicação da mensagem, a menos que mandem ler um
timestamp de um atributo, e o celular de um entregador que manda um evento dez minutos atrasado põe
o evento no minuto errado. Esse é o assunto da aula 22, e o motivo de ela existir.

## O que esta execução diz, e o que não diz

Ela diz que o programa está correto nos dois modos: os mesmos eventos dão os mesmos totais, uma
linha ruim vai para o seu destino próprio nos dois, e o fluxo recusa um agrupamento que nunca
poderia terminar. **Não diz nada sobre o Dataflow.** Um processo leu a assinatura; não houve worker
para ligar, nem escalonamento automático, nem shuffle entre máquinas, nem estado guardado fora do
processo. E a entrega aqui não é a que a aula 20 faria esperar. **O DirectRunner confirma cada
mensagem no momento em que a puxa**, antes de qualquer passo vê-la, o que o próprio código-fonte
dele diz num comentário: uma execução que morresse no meio perderia as mensagens que tinha puxado, em
vez de contá-las duas vezes. O Dataflow faz o contrário, como a documentação dele descreve: só
confirma uma mensagem quando o trabalho sobre ela está guardado de forma durável, e remove pelo id
da mensagem as duplicatas que o Pub/Sub entrega de novo. A próxima seção é o que o Dataflow
acrescenta, a partir da documentação do Google, e nada dela rodou aqui.
