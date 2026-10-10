---
title: Um watermark em ação
version: 1
---

**Este programa passa as vendas da lição 10 por janelas tumbling de cinco minutos que só fecham
quando um watermark passa do fim delas.** Ele imprime uma linha por venda conforme ela chega, com o
watermark depois dela, e uma linha para cada janela que emite. Duas vendas se juntam às dez da lição
10: uma das 09:04:30 que chega em décimo primeiro lugar, atrasada demais, e uma das 09:23:10 que faz
o tempo andar.

Salve como `~/work/watermark.py`:

```schooling-example
{
  "language": "python",
  "file": "watermark.py",
  "parts": [
    {
      "code": "\"\"\"watermark.py: five-minute windows that close when a watermark says so.\n\n    python watermark.py [--bound MIN] [--lateness MIN] [--partitions N] [--idle K]\n                        [--late-topic TOPIC]\n\nThe watermark is the latest event time seen, minus --bound minutes. A window\nis emitted when the watermark passes its end, kept --lateness minutes more for\nlate sales, and then forgotten. With --partitions, each shop's sales come from\none of N partitions and the watermark is the lowest of theirs; --idle K leaves\nout a partition that has had nothing for the last K sales. --late-topic sends\nsales too late to count to that Kafka topic instead of dropping them.\n\"\"\"\nimport argparse\nimport json\n\nSALES = [  # (when it happened, shop, cents), in the order they arrived\n    (\"09:00:40\", \"recife\", 3990), (\"09:02:10\", \"natal\", 5490),\n    (\"09:03:55\", \"olinda\", 2990), (\"09:05:00\", \"recife\", 7900),\n    (\"09:06:20\", \"natal\", 4490), (\"09:12:30\", \"caruaru\", 6200),\n    (\"09:13:05\", \"recife\", 3500), (\"09:08:50\", \"natal\", 8990),\n    (\"09:14:10\", \"olinda\", 2990), (\"09:21:00\", \"recife\", 5490),\n    (\"09:04:30\", \"natal\", 4490), (\"09:23:10\", \"olinda\", 3990),\n]",
      "note": "O uso, e doze vendas na ordem em que chegaram: as dez da lição 10, depois **uma venda das 09:04:30 que chega em décimo primeiro lugar**, e mais uma às 09:23:10."
    },
    {
      "code": "PARTITION = {\"recife\": 0, \"olinda\": 0, \"natal\": 1, \"caruaru\": 1, \"joao-pessoa\": 2}\nSIZE = 300\n\nargs = argparse.ArgumentParser()\nargs.add_argument(\"--bound\", type=float, default=2)\nargs.add_argument(\"--lateness\", type=float, default=0)\nargs.add_argument(\"--partitions\", type=int, default=1)\nargs.add_argument(\"--idle\", type=int, default=0)\nargs.add_argument(\"--late-topic\")\nargs = args.parse_args()\nbound, lateness = int(args.bound * 60), int(args.lateness * 60)\n\n",
      "note": "De qual partição vêm as vendas de cada loja quando `--partitions` pede mais de uma, o tamanho da janela em segundos, e as opções em minutos."
    },
    {
      "code": "def secs(when):\n    h, m, s = map(int, when.split(\":\"))\n    return h * 3600 + m * 60 + s\n\n\ndef clock(t):\n    return \"--:--:--\" if t is None else f\"{t // 3600:02d}:{t % 3600 // 60:02d}:{t % 60:02d}\"\n\n",
      "note": "Os mesmos dois auxiliares do `windows.py`; um horário que ainda não existe aparece como traços."
    },
    {
      "code": "latest = {p: None for p in range(args.partitions)}   # latest event time per partition\nquiet = {p: 0 for p in range(args.partitions)}       # sales since each partition's last\nwindows, emitted, watermark = {}, set(), None\nproducer = None\nif args.late_topic:\n    from confluent_kafka import Producer\n    producer = Producer({\"bootstrap.servers\": \"localhost:9092\"})\n\n",
      "note": "O estado: o tempo de evento mais recente por partição, quantas vendas cada partição passou sem nada, as janelas abertas, as já emitidas e o watermark. Um produtor só se `--late-topic` foi dado."
    },
    {
      "code": "def advance():\n    live = [p for p in latest if not (args.idle and quiet[p] >= args.idle)]\n    seen = [latest[p] for p in live]\n    if not seen or None in seen:\n        return None\n    return min(seen) - bound\n\n",
      "note": "**O watermark: o menor dos tempos mais recentes das partições, menos o limite.** Uma partição ainda sem nada o segura por completo, a não ser que `--idle` a tenha deixado de fora."
    },
    {
      "code": "def say(n, t, shop, what):\n    print(f\"{n:2d}  {clock(t)}  {shop:8}  {clock(watermark)}  {what}\")\n\n",
      "note": "Uma linha por venda: o número, quando aconteceu, a loja, o watermark depois que ela chegou e o que aconteceu com ela."
    },
    {
      "code": "print(\" #  happened  shop      watermark  what happened\")\nfor n, (when, shop, cents) in enumerate(SALES, 1):\n    t, p = secs(when), PARTITION[shop] % args.partitions\n    for q in quiet:\n        quiet[q] = 0 if q == p else quiet[q] + 1\n    start = t // SIZE * SIZE",
      "note": "O laço. Cada venda é atividade para a própria partição e mais uma venda de silêncio para cada outra, e pertence à janela de cinco minutos em que cai o horário dela."
    },
    {
      "code": "    window = f\"{clock(start)}-{clock(start + SIZE)}\"\n    if watermark is not None and start + SIZE + lateness <= watermark:\n        if producer:\n            producer.produce(args.late_topic, key=shop, value=json.dumps(\n                {\"at\": when, \"shop\": shop, \"cents\": cents, \"watermark\": clock(watermark)}))\n            say(n, t, shop, f\"too late for {window}: sent to {args.late_topic}\")\n        else:\n            say(n, t, shop, f\"too late for {window}: dropped\")\n        continue",
      "note": "**Se o watermark já passou do fim da janela mais o atraso permitido, a janela não existe mais**: a venda é descartada, ou mandada para o tópico de atrasadas."
    },
    {
      "code": "    count, total = windows.get(start, (0, 0))\n    windows[start] = (count + 1, total + cents)\n    if latest[p] is None or t > latest[p]:\n        latest[p] = t\n    new = advance()\n    if new is not None and (watermark is None or new > watermark):\n        watermark = new\n    if start in emitted:\n        say(n, t, shop, f\"late, {window} now {count + 1} sales, {total + cents}\")\n    else:\n        say(n, t, shop, \"\")",
      "note": "Senão ela é contada, o tempo mais recente da partição dela anda, e **o watermark anda para a frente, nunca para trás**. Uma venda para uma janela já emitida é informada como atualização atrasada."
    },
    {
      "code": "    for s in sorted(windows):\n        if s not in emitted and s + SIZE <= (watermark or 0):\n            emitted.add(s)\n            print(f\"{'':30}emit {clock(s)}-{clock(s + SIZE)}: {windows[s][0]} sales, {windows[s][1]}\")\n    for s in [s for s in windows if s + SIZE + lateness <= (watermark or 0)]:\n        del windows[s]\n",
      "note": "Toda janela cujo fim o watermark passou é emitida uma vez; toda janela cujo fim mais o atraso permitido ele passou é esquecida."
    },
    {
      "code": "if producer:\n    producer.flush()\nprint(\"still open: \" + (\", \".join(f\"{clock(s)} ({windows[s][0]})\" for s in sorted(windows)\n                                  if s not in emitted) or \"nothing\"))",
      "note": "No fim, o que continua aberto. Um motor lendo um stream nunca chega aqui; um que lesse uma entrada já terminada emitiria essas também."
    }
  ]
}
```

Com o limite padrão de dois minutos e nenhum atraso permitido:

```
ubuntu@stream:~/work$ python watermark.py
```

Leia uma linha de cada vez, porque cada linha é uma decisão.

**As vendas 1 a 5** levam o watermark dois minutos atrás delas: 08:58:40, 09:00:10, até 09:04:20
depois da venda 5. Nenhuma janela termina antes das 09:05, então nada é emitido, embora as vendas 1 a
3 estejam todas na janela das 09:00 e o relógio dos eventos já tenha passado das 09:05.

**A venda 6, das 09:12:30**, leva o watermark para 09:10:30, que passa do fim de duas janelas. As
duas são emitidas de uma vez: 09:00 às 09:05 com três vendas e 12.470 centavos, e 09:05 às 09:10 com
duas vendas e 12.390. **Esse é o momento em que o processador se compromete com uma resposta**, e ele
se compromete com duas de uma vez porque uma venda fez o tempo andar seis minutos.

**A venda 8, das 09:08:50**, chega com o watermark em 09:11:05. A janela dela terminou às 09:10, antes
do watermark, e sem atraso permitido a janela já não existe: a venda é descartada. A janela das 09:05
continua informada como duas vendas, onde a lição 10, que viu tudo, contou três. **O watermark perdeu
a aposta na venda 8 por 1 minuto e 5 segundos**, a distância entre o fim da janela dela e o watermark
quando ela chegou.

**A venda 10, das 09:21:00**, leva o watermark para 09:19:00 e fecha 09:10 às 09:15. **A venda 11,
das 09:04:30**, também é descartada; o watermark já estava catorze minutos além do fim da janela dela.
A venda 12 leva o watermark para 09:21:10, que não chega a 09:25, então a última janela ainda está
aberta quando a lista acaba.

## O que ele acertou e errou

Três janelas foram emitidas, cada uma uma vez, e cada uma num momento definido só por tempos de
evento: rode de novo e elas saem nas mesmas linhas. Duas das doze vendas se perderam, 13.480 centavos
que nunca chegaram a nenhum total. Se isso é aceitável não é uma propriedade do programa. Depende de
para que servem os totais e do que mais pega essas duas vendas, que é o assunto das próximas três
seções: manter as janelas abertas um pouco mais, mandar as vendas atrasadas para algum lugar em vez de
lugar nenhum, e escolher o limite por medição em vez de hábito.
