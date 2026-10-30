---
title: O horário do evento vindo do Pub/Sub, aqui e no Dataflow
version: 1
---

**Um TestStream é onde se aprende janelas; o Pub/Sub é onde elas têm de funcionar.** Duas coisas
mudam quando a fonte é de verdade. O horário do evento tem de viajar com cada mensagem, porque o
Pub/Sub só sabe quando recebeu cada uma. E a marca d'água deixa de ser sua: a fonte a estima, e o
quanto ela acerta decide quais dados contam como atrasados. Esta seção roda a primeira parte no
emulador, mostra que a estimativa do DirectRunner não é a do Dataflow, e ensina a do Dataflow a
partir da documentação do Google, sem rodá-la.

## Mandando o horário do evento

**`ReadFromPubSub(timestamp_attribute='placed')` tira o timestamp de cada elemento de um atributo da
mensagem em vez do horário de publicação.** O atributo traz milissegundos desde a época ou um
horário RFC 3339, e quem publica tem de defini-lo, porque só quem publica sabe quando o pedido foi
feito. Este programa publica metade da noite de cada vez, com o horário de cada pedido num atributo
chamado `placed`. Salve como `~/gcp/publish_evening.py`:

`publish_evening.py`:

```python
"""publish_evening.py: half of the evening's orders, with the time each was placed.

    python3 publish_evening.py first        the first five orders
    python3 publish_evening.py second       the other five
"""
import json
import sys
from datetime import datetime, timezone

from google.cloud import pubsub_v1

from evening import ORDERS, at

half = ORDERS[:5] if sys.argv[1] == 'first' else ORDERS[5:]
publisher = pubsub_v1.PublisherClient()
topic = publisher.topic_path('planner-dev', 'evening')
for order, customer, neighbourhood, cents, placed, arrived in half:
    when = datetime.fromtimestamp(at(placed), timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    data = json.dumps({'order_id': order, 'neighbourhood': neighbourhood, 'cents': cents})
    publisher.publish(topic, data.encode(), placed=when).result()
    print(f'{order} placed {placed}, published with placed={when}')
```

E um pipeline que os lê, em janelas de cinco minutos desse atributo. Salve como
`~/gcp/from_pubsub.py`:

`from_pubsub.py`:

```python
"""from_pubsub.py: orders from Pub/Sub, in five-minute windows of the time each was placed."""
import json

import apache_beam as beam
from apache_beam.options.pipeline_options import PipelineOptions
from apache_beam.transforms.window import FixedWindows

from evening import clock


class Show(beam.DoFn):
    def process(self, total, window=beam.DoFn.WindowParam):
        neighbourhood, cents = total
        print(f'{clock(window.start)}-{clock(window.end)}  {neighbourhood:<10} {cents / 100:>7.2f}',
              flush=True)


options = PipelineOptions(['--streaming'], runner='BundleBasedDirectRunner')
with beam.Pipeline(options=options) as p:
    (p
     | beam.io.ReadFromPubSub(subscription='projects/planner-dev/subscriptions/evening-beam',
                              timestamp_attribute='placed')
     | beam.Map(json.loads)
     | beam.Map(lambda o: (o['neighbourhood'], o['cents']))
     | beam.WindowInto(FixedWindows(5 * 60))
     | beam.CombinePerKey(sum)
     | beam.ParDo(Show()))
```

Com o emulador do Pub/Sub rodando no terminal dele, como na aula 21, um tópico e a assinatura do
pipeline:

```
ana@laptop:~/gcp$ gcloud pubsub topics create evening
Created topic [projects/planner-dev/topics/evening].
ana@laptop:~/gcp$ gcloud pubsub subscriptions create evening-beam --topic=evening
Created subscription [projects/planner-dev/subscriptions/evening-beam].
```

Num terceiro terminal, o pipeline, por noventa segundos:

```sh
timeout 90 python3 from_pubsub.py
```

De volta ao terminal em que você digita, os cinco primeiros pedidos e, uns vinte segundos depois,
os outros cinco:

```
ana@laptop:~/gcp$ python3 publish_evening.py first
o-501 placed 19:01:10, published with placed=2026-10-15T22:01:10Z
o-502 placed 19:02:05, published with placed=2026-10-15T22:02:05Z
o-503 placed 19:03:30, published with placed=2026-10-15T22:03:30Z
o-504 placed 19:04:20, published with placed=2026-10-15T22:04:20Z
o-505 placed 19:06:00, published with placed=2026-10-15T22:06:00Z
ana@laptop:~/gcp$ python3 publish_evening.py second
o-506 placed 19:07:45, published with placed=2026-10-15T22:07:45Z
o-507 placed 19:04:50, published with placed=2026-10-15T22:04:50Z
o-508 placed 19:11:15, published with placed=2026-10-15T22:11:15Z
o-509 placed 19:13:40, published with placed=2026-10-15T22:13:40Z
o-510 placed 19:09:10, published with placed=2026-10-15T22:09:10Z
```

**O atributo está em UTC**, `22:01:10Z` para 19:01:10 em São Paulo, e o pipeline o converte de volta
para o horário local ao imprimir. O terminal do pipeline, depois dos noventa segundos:

```
ana@laptop:~/gcp$ timeout 90 python3 from_pubsub.py
19:00:00-19:05:00  Moema        55.80
19:00:00-19:05:00  Pinheiros   128.00
```

**Três pedidos de dez entraram numa janela**: `o-501`, `o-502` e `o-503`, os três primeiros
publicados, 55,80 para Moema e 128,00 para Pinheiros. Os outros sete foram descartados, sem
mensagem, o mesmo silêncio das seções anteriores. O motivo está no próprio código-fonte do
DirectRunner: depois de cada leitura do Pub/Sub, o leitor de Pub/Sub dele põe a marca d'água em
`time.time()`, o relógio da parede, com um comentário no código dizendo que o valor certo ainda está
por fazer. A primeira leitura, que nesta execução trouxe três mensagens, foi lida antes de a marca
d'água ter andado, então o que ela trouxe contou como no horário. Dali em diante a marca d'água era
a tarde do dia em que isto foi gravado, e todo pedido de 15 de outubro estava duas semanas atrás
dela. **Com dados antigos, o DirectRunner lendo o Pub/Sub chama quase tudo de atrasado**, e quanto
sobrevive depende de quantas mensagens a primeira leitura calhou de trazer. Esse é o limite deste
laboratório para marcas d'água, e o motivo de as seções anteriores usarem um TestStream.

## O que o Dataflow faz no lugar

Daqui em diante, nada foi rodado. A documentação do Dataflow descreve como a fonte de Pub/Sub dele
estima a marca d'água, e três pontos dela importam para esta aula:

- **A estimativa vem do acúmulo, não do relógio da parede.** O Dataflow olha os horários de evento
  das mensagens ainda não confirmadas na assinatura, e segura a marca d'água por volta da mais
  antiga delas. Quando `timestamp_attribute` está definido, o Dataflow cria uma segunda assinatura,
  de acompanhamento, no mesmo tópico, para examinar esses timestamps sem entregá-los. Uma assinatura
  com um dia de pedidos antigos esperando começa, então, com uma marca d'água um dia no passado, e
  nada nela está atrasado só por ser antigo.
- **Uma mensagem publicada tarde continua atrasada.** Se um celular publica um pedido feito há dez
  minutos, depois de o acúmulo ter sido consumido além desse horário, a marca d'água já andou e o
  pedido está atrás dela. A estimativa não enxerga uma mensagem que ainda não foi publicada, que é o
  elevador do vídeo de abertura, e nenhum runner enxerga.
- **Dois números na página do job medem a distância.** Data freshness é quanto a marca d'água está
  atrás do presente, e system latency é quanto um elemento espera no pipeline. Um data freshness
  que só cresce quer dizer que o job está ficando para trás da entrada, e que as janelas fecham cada
  vez mais tarde.

**Dado atrasado descartado é tão silencioso no Dataflow quanto foi aqui.** Nenhum passo falha e
nenhum erro vai para o log por um elemento atrás da marca d'água e além do atraso permitido. A conferência confiável é a que a aula 21 tornou
possível: as mesmas transformações, rodando em lote sobre a exportação da noite, calculam as mesmas
janelas a partir de dados completos. Um fluxo cujos totais sempre discordam dos da noite tem uma
marca d'água apressada demais ou um atraso permitido curto demais.

## O que atraso e painéis antecipados custam

**Toda janela é estado até a marca d'água passar o fim dela mais o atraso permitido.** Neste
pipeline, uma janela de cinco minutos com cinco minutos de atraso fica guardada uns dez, uma entrada
por bairro. Com Streaming Engine esse estado fica no serviço, e as duas formas de cobrança do
Streaming Engine da aula 21 crescem com ele: a legada conta os bytes guardados para as janelas, e a
por recurso conta o trabalho de guardá-los. Um atraso permitido de um dia numa janela deslizante de
uma hora a cada minuto são sessenta cópias de cada elemento, cada uma guardada por um dia.

Painéis antecipados custam no sentido oposto: cada painel é uma saída, gravada num destino e, no
Pub/Sub ou no BigQuery, paga como gravação. Um gatilho a cada minuto numa janela de uma hora são até
sessenta gravações por chave onde uma bastaria.

**Drenar um job é o último movimento da marca d'água.** O `gcloud dataflow jobs drain`, da aula 21,
para de ler, e a ajuda do próprio `gcloud` do laboratório diz que a marca d'água de entrada é então
levada ao infinito: toda janela aberta passa do fim de uma vez e dispara o que tem. Dados ainda a
caminho quando o drain começa não são esperados.
