---
title: O pipeline, e uma execução noturna sobre um arquivo
version: 1
---

**O pipeline é um programa com duas pontas e um meio.** O meio lê linhas de JSON, fica com os
pedidos que foram feitos e soma por bairro. Uma ponta lê um arquivo e grava arquivos; a outra lê uma
assinatura do Pub/Sub e publica num tópico. Esta seção roda a ponta do arquivo, que é o job da
noite, e a próxima roda a ponta do fluxo sobre os mesmos eventos.

## Os eventos da noite

A exportação da Quitanda é um evento por linha, cada um sobre um pedido: quando foi feito,
embalado, entregue ou cancelado. Este programa grava uma noite deles, das 19:00 às 20:00 de 15 de
outubro, sempre os mesmos 2.000 porque o gerador aleatório tem semente, e depois mais uma linha
cortada no meio, como termina uma exportação interrompida por um disco cheio. Salve como
`~/gcp/events.py`:

`events.py`:

```python
"""events.py: one evening of Quitanda's order events, one JSON object a line.

    python3 events.py           writes events.jsonl
"""
import json
import random
from datetime import datetime, timedelta, timezone

random.seed(21)
SP = timezone(timedelta(hours=-3))
START = datetime(2026, 10, 15, 19, 0, tzinfo=SP)
NEIGHBOURHOODS = ['Butantã', 'Moema', 'Pinheiros', 'Santana', 'Tatuapé']
KINDS, WEIGHTS = ['placed', 'packed', 'delivered', 'cancelled'], [5, 4, 4, 1]

with open('events.jsonl', 'w', encoding='utf-8') as f:
    for i in range(2000):
        event = {'order_id': f'o-{10000 + i}',
                 'event': random.choices(KINDS, WEIGHTS)[0],
                 'neighbourhood': random.choice(NEIGHBOURHOODS),
                 'total_cents': random.randrange(1500, 30000),
                 'at': (START + timedelta(seconds=random.randrange(3600))).isoformat()}
        f.write(json.dumps(event, ensure_ascii=False) + '\n')
    f.write('{"order_id": "o-12000", "event": "placed", "total_cents": \n')
print('2,001 lines written to events.jsonl, the last one cut short')
```

```
ana@laptop:~/gcp$ python3 events.py
2,001 lines written to events.jsonl, the last one cut short
ana@laptop:~/gcp$ head -2 events.jsonl
{"order_id": "o-10000", "event": "placed", "neighbourhood": "Santana", "total_cents": 22307, "at": "2026-10-15T19:19:12-03:00"}
{"order_id": "o-10001", "event": "packed", "neighbourhood": "Moema", "total_cents": 27473, "at": "2026-10-15T19:32:24-03:00"}
```

**O campo `at` é quando o evento aconteceu**, e esta aula ainda não usa: um arquivo é somado como
uma única janela global, e o fluxo da próxima seção é cortado em janelas pelo horário em que o
Pub/Sub recebeu cada mensagem. A aula 22 põe o `at` para trabalhar.

## O programa

Salve como `~/gcp/orders_beam.py`:

```schooling-example
{"language": "python", "file": "orders_beam.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"orders_beam.py: the placed orders of Quitanda's events, totalled per neighbourhood.\n\n    python3 orders_beam.py --input events.jsonl --output out/\n    python3 orders_beam.py --subscription order-events-beam --topic order-totals --streaming\n\nTHE SAME TRANSFORMS RUN IN BOTH. Only the ends differ: where the lines come\nfrom, and where the totals and the unreadable lines go. A stream is cut into\nwindows of --window seconds, by the time Pub/Sub received each message.\n\"\"\"\nimport argparse\nimport json\nfrom datetime import datetime, timedelta, timezone\n\nimport apache_beam as beam\nfrom apache_beam.options.pipeline_options import PipelineOptions\nfrom apache_beam.transforms.window import FixedWindows, GlobalWindow\n\nPROJECT = 'planner-dev'\nSP = timezone(timedelta(hours=-3))\n\n\n", "note": "**A docstring diz a única coisa a lembrar: as mesmas transformações rodam nos dois.** As duas formas de rodar são as primeiras linhas dela. O Beam em si são três imports: a biblioteca, as opções e dois tipos de janela, um deles a janela em que o lote vive sem pedir."}, {"code": "def parse(line):\n    try:\n        e = json.loads(line)\n        yield {'event': e['event'], 'neighbourhood': e['neighbourhood'],\n               'cents': int(e['total_cents'])}\n    except (ValueError, KeyError, TypeError):\n        yield beam.pvalue.TaggedOutput('unreadable', line)\n\n\n", "note": "`parse` é uma função de `FlatMap`: produz um evento limpo para uma linha boa e **uma saída marcada** para uma ruim. Uma linha que não é JSON, ou à qual falta um campo, vai para `unreadable` em vez de parar o pipeline, e às duas da manhã essa é a diferença entre uma linha ruim e nenhum total."}, {"code": "def add(pairs):\n    orders = cents = 0\n    for n, c in pairs:\n        orders, cents = orders + n, cents + c\n    return orders, cents\n\n\n", "note": "**A função de combinação.** Recebe uma lista de pares `(orders, cents)`, ou de resultados anteriores dela mesma, e soma. O Beam pode chamá-la sobre partes dos valores de uma chave em workers diferentes e depois sobre os resultados das partes, então ela tem de dar a mesma resposta em qualquer agrupamento, e a soma dá."}, {"code": "class Format(beam.DoFn):\n    def process(self, total, window=beam.DoFn.WindowParam):\n        neighbourhood, (orders, cents) = total\n        if window == GlobalWindow():\n            when = 'all'\n        else:\n            when = datetime.fromtimestamp(float(window.start), SP).strftime('%H:%M:%S')\n        yield json.dumps({'window': when, 'neighbourhood': neighbourhood, 'orders': orders,\n                          'reais': f'{cents / 100:.2f}'}, ensure_ascii=False)\n\n\n", "note": "`Format` transforma um total em uma linha de JSON. Pergunta ao Beam a **janela** a que o total pertence: em lote é a janela global, escrita `all`, e em fluxo o início do minuto, no horário de São Paulo."}, {"code": "class PlacedTotals(beam.PTransform):\n    def expand(self, lines):\n        parsed = lines | 'Parse' >> beam.FlatMap(parse).with_outputs('unreadable', main='events')\n        totals = (parsed.events\n                  | 'Placed' >> beam.Filter(lambda e: e['event'] == 'placed')\n                  | 'Key' >> beam.Map(lambda e: (e['neighbourhood'], (1, e['cents'])))\n                  | 'Add' >> beam.CombinePerKey(add)\n                  | 'Format' >> beam.ParDo(Format()))\n        return totals, parsed.unreadable\n\n\n", "note": "**O pipeline propriamente dito, como uma transformação composta.** `expand` recebe uma coleção de linhas e devolve duas: os totais e as linhas ilegíveis. Não sabe nada de arquivos nem de Pub/Sub, e é isso que deixa os mesmos cinco passos rodarem sobre qualquer um dos dois."}, {"code": "def main():\n    ap = argparse.ArgumentParser()\n    ap.add_argument('--input')\n    ap.add_argument('--output')\n    ap.add_argument('--subscription')\n    ap.add_argument('--topic')\n    ap.add_argument('--window', type=int, default=60)\n    ap.add_argument('--runner', default='BundleBasedDirectRunner')\n    args, beam_args = ap.parse_known_args()\n    options = PipelineOptions(beam_args, runner=args.runner)\n\n", "note": "As opções. Tudo o que o programa não conhece, como `--streaming` ou `--project`, segue para o Beam. **O runner padrão é o `BundleBasedDirectRunner`**, o runner de dentro do Python, pelo motivo que a seção anterior deu; `--runner=DataflowRunner` passa por cima dele."}, {"code": "    with beam.Pipeline(options=options) as p:\n        if args.input:\n            lines = p | 'Read' >> beam.io.ReadFromText(args.input)\n        else:\n            lines = (p\n                     | 'Read' >> beam.io.ReadFromPubSub(\n                         subscription=f'projects/{PROJECT}/subscriptions/{args.subscription}')\n                     | 'Decode' >> beam.Map(lambda data: data.decode('utf-8')))\n            if args.window:\n                lines = lines | 'Window' >> beam.WindowInto(FixedWindows(args.window))\n\n", "note": "**A primeira ponta.** Um arquivo é lido com `ReadFromText`, um elemento por linha. O Pub/Sub é lido com `ReadFromPubSub`, um elemento por mensagem, em bytes; e o fluxo é cortado em janelas fixas de `--window` segundos. `--window 0` tira a janela, para ver por que ela está ali."}, {"code": "        totals, unreadable = lines | 'Totals' >> PlacedTotals()\n\n        if args.input:\n            totals | 'WriteTotals' >> beam.io.WriteToText(\n                args.output + 'totals', file_name_suffix='.jsonl')\n            unreadable | 'WriteUnreadable' >> beam.io.WriteToText(\n                args.output + 'unreadable', file_name_suffix='.txt')\n        else:\n            (totals | 'EncodeTotals' >> beam.Map(lambda s: s.encode('utf-8'))\n                    | 'WriteTotals' >> beam.io.WriteToPubSub(\n                        f'projects/{PROJECT}/topics/{args.topic}'))\n            (unreadable | 'EncodeUnreadable' >> beam.Map(lambda s: s.encode('utf-8'))\n                        | 'WriteUnreadable' >> beam.io.WriteToPubSub(\n                            f'projects/{PROJECT}/topics/{args.topic}-unreadable'))\n\n\nif __name__ == '__main__':\n    main()\n", "note": "**A outra ponta.** As mesmas duas coleções vão para arquivos em lote, por `WriteToText`, e para dois tópicos do Pub/Sub em fluxo, por `WriteToPubSub`. Sair do bloco `with` roda o pipeline e espera que ele termine, o que um fluxo nunca faz."}]}
```

**Cinco passos, e só um deles junta elementos.** `Parse`, `Placed`, `Key` e `Format` olham cada um
um elemento e não sabem nada dos outros, então um runner dá a cada worker qualquer fatia da entrada.
`Add` é o que precisa de todos os pedidos feitos de Moema num lugar só, e no Beam isso é um
`CombinePerKey`: um `GroupByKey` que também soma pelo caminho. **No Dataflow esse passo é o
shuffle**, onde os elementos passam de um worker a outro pela chave, e é o passo com uma linha
própria na conta da última seção. Uma combinação sai mais barata que um agrupamento simples pelo
mesmo motivo que um `GROUP BY` sai mais barato que buscar todas as linhas: cada worker soma a
própria fatia primeiro, e só as somas parciais viajam.

## A execução da noite

```
ana@laptop:~/gcp$ time python3 orders_beam.py --input events.jsonl --output out/

real	0m5.666s
user	0m1.645s
sys	0m0.163s
ana@laptop:~/gcp$ ls out/
totals-00000-of-00001.jsonl
unreadable-00000-of-00001.txt
ana@laptop:~/gcp$ sort out/totals-*
{"window": "all", "neighbourhood": "Butantã", "orders": 150, "reais": "23835.54"}
{"window": "all", "neighbourhood": "Moema", "orders": 138, "reais": "22737.55"}
{"window": "all", "neighbourhood": "Pinheiros", "orders": 161, "reais": "24949.60"}
{"window": "all", "neighbourhood": "Santana", "orders": 140, "reais": "22367.32"}
{"window": "all", "neighbourhood": "Tatuapé", "orders": 152, "reais": "26061.58"}
ana@laptop:~/gcp$ cat out/unreadable-*
{"order_id": "o-12000", "event": "placed", "total_cents": 
```

**Cinco totais, uma linha ruim posta de lado, em poucos segundos.** 741 dos 2.000 eventos
eram `placed`, e as cinco contagens somam esse número. A linha cortada não parou a execução: foi
pela segunda saída e foi gravada, inteira, num arquivo próprio, onde alguém consegue ver o que a
loja mandou. Um pipeline que quebrasse nela não teria produzido total nenhum, e um que a pulasse em
silêncio teria produzido totais com um pedido a menos e nada avisando.

**Os nomes dos arquivos são do Beam: `-00000-of-00001` é o shard 0 de 1.** Um destino no Beam grava
tantos arquivos quantos gravadores em paralelo tiver, e dá nomes que deixam quem lê saber se tem
todos. Aqui um processo gravou um shard de cada. O Dataflow, com dez workers, gravaria vários, e o
número depois de `of` diria quantos esperar. Para um caminho no Cloud Storage o programa não muda:
`--output gs://quitanda-curated-prod/orders/totals/` é um argumento válido para o `WriteToText`, com
o extra `gcp` instalado.

**E a janela é `all`.** Uma coleção limitada que ninguém cortou em janelas vive na janela global, e
`Format` escreve essa palavra. Os totais são do arquivo inteiro, que numa exportação da noite é o
dia inteiro e é para isso que serve o job.
