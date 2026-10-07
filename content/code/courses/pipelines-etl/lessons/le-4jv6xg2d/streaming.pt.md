---
title: Streaming: um evento por vez
version: 1
---

**A ingestão em streaming trata cada registro quando ele chega**, sem um período para esperar. A
origem é algo que nunca fecha — um site gravando um clique a cada vez que alguém clica, um caixa
gravando uma venda, um sensor gravando uma leitura — e o consumidor acompanha, um evento ou um
punhado de cada vez.

O site do laboratório escreve os seus eventos num arquivo, um objeto JSON por linha, e durante o
dia o arquivo cresce. O `shop day` entrega o arquivo do dia inteiro, como um batch o receberia, então
para ver um arquivo crescer é preciso algo que o escreva uma linha por vez. Salve isto como
`~/pontofinal/replay.py`:

```python
"""Replay a day of the website's events as if it were happening now.

    python3 replay.py EVENTS.jsonl OUT.jsonl [SPEED]

appends each event of EVENTS.jsonl to OUT.jsonl when its moment comes, with
`occurred_at` moved to today, SPEED times faster than the day it came from (60
by default: a minute of the shop's day each second). It is the lab's stand-in
for a website that is open: what a streaming consumer reads is a file that
keeps growing. Written for the course; standard library only.
"""
import datetime as dt
import json
import sys
import time

src, out = sys.argv[1], sys.argv[2]
speed = float(sys.argv[3]) if len(sys.argv) > 3 else 60.0
events = [json.loads(line) for line in open(src, encoding="utf-8")]
first = dt.datetime.fromisoformat(events[0]["occurred_at"])
start = time.time()
now0 = dt.datetime.now().astimezone()
with open(out, "a", encoding="utf-8") as f:
    for ev in events:
        due = (dt.datetime.fromisoformat(ev["occurred_at"]) - first).total_seconds() / speed
        wait = start + due - time.time()
        if wait > 0:
            time.sleep(wait)
        ev["occurred_at"] = (now0 + dt.timedelta(seconds=due)).isoformat(timespec="seconds")
        f.write(json.dumps(ev, separators=(",", ":")) + "\n")
        f.flush()
```

A Ana o inicia em segundo plano, `python ~/pontofinal/replay.py landing/events/2026-03-01.jsonl
landing/stream.jsonl 600 &`, e ele acrescenta cada evento do dia a `landing/stream.jsonl` quando
chega a hora dele, seiscentas vezes mais rápido que o dia de onde veio. O consumidor dela lê o
arquivo enquanto ele cresce:

```schooling-example
{
  "language": "python",
  "file": "consume.py",
  "parts": [
    {
      "code": "\"\"\"Read the website's events as they land, and say how far behind it is.\"\"\"\nimport datetime as dt\nimport json\nimport os\nimport sys\nimport time\n\n"
    },
    {
      "code": "path, offset_file, seconds = sys.argv[1], sys.argv[2], float(sys.argv[3])\npos = int(open(offset_file).read()) if os.path.exists(offset_file) else 0\nprint(f\"starting at byte {pos}\")\nstop = time.time() + seconds\nseen, purchases, worst, report = 0, 0, 0.0, time.time() + 2\n",
      "note": "Onde começar: o deslocamento em bytes salvo pela última execução, ou o início do arquivo. **O deslocamento é a memória do consumidor**, e ele mora fora do programa para que um reinício não comece de novo do zero."
    },
    {
      "code": "with open(path, encoding=\"utf-8\") as f:\n    f.seek(pos)\n    while time.time() < stop:\n",
      "note": "Ele roda por um número fixo de segundos para a lição poder mostrá-lo parando. Um consumidor de verdade roda até alguém pará-lo."
    },
    {
      "code": "        line = f.readline()\n        if not line.endswith(\"\\n\"):        # nothing new yet, or half a line\n            f.seek(pos)\n            time.sleep(0.1)\n            continue\n",
      "note": "Uma linha sem a quebra de linha no fim é uma que o escritor ainda não terminou. Lê-la seria interpretar meio evento, então o consumidor volta e espera."
    },
    {
      "code": "        pos = f.tell()\n        event = json.loads(line)\n        seen += 1\n        purchases += event[\"type\"] == \"purchase\"\n        happened = dt.datetime.fromisoformat(event[\"occurred_at\"])\n        lag = (dt.datetime.now().astimezone() - happened).total_seconds()\n        worst = max(worst, lag)\n",
      "note": "**O atraso é agora menos o momento em que o evento aconteceu.** É o número pelo qual um pipeline de streaming é julgado, como um batch é julgado por quanto tempo faz desde a última execução."
    },
    {
      "code": "        with open(offset_file, \"w\") as o:\n            o.write(str(pos))\n",
      "note": "O deslocamento é gravado depois de cada evento ser tratado, nunca antes. Gravado antes, uma queda no meio pularia um evento; gravado depois, uma queda faz a próxima execução ler um evento duas vezes."
    },
    {
      "code": "        if time.time() >= report:\n            print(f\"{time.strftime('%H:%M:%S')}  {seen} events, \"\n                  f\"{purchases} purchases, at most {worst:.1f} s behind\")\n            worst, report = 0.0, report + 2\n",
      "note": "A cada dois segundos, uma linha: quantos eventos até agora, e o pior atraso naquela janela."
    },
    {
      "code": "print(f\"stopped at byte {pos}\")"
    }
  ]
}
```

Ela o inicia por sete segundos, para, espera três, e inicia de novo:

```
ana@vm:~/etl$ python consume.py landing/stream.jsonl stream.offset 7
starting at byte 0
05:24:42  74 events, 5 purchases, at most 1.3 s behind
05:24:44  117 events, 5 purchases, at most 1.1 s behind
05:24:46  152 events, 6 purchases, at most 1.0 s behind
stopped at byte 19649
ana@vm:~/etl$ python consume.py landing/stream.jsonl stream.offset 5
starting at byte 19649
05:24:52  97 events, 4 purchases, at most 3.4 s behind
05:24:54  130 events, 6 purchases, at most 1.0 s behind
stopped at byte 36377
```

Os horários são os da gravação, e uma execução sua vai mostrar os seus. Duas coisas nela importam:

- **O atraso é de cerca de um segundo.** Uma compra chega ao pipeline um segundo depois de
  acontecer, não na manhã seguinte. O piso de um segundo é obra da reprodução: ela escreve
  `occurred_at` em segundos inteiros, então um evento pode parecer até um segundo mais velho do que
  é.
- **O reinício não começou de novo.** A segunda execução começou no byte 19649, onde a primeira
  tinha parado, e a sua primeira janela estava 3,4 segundos atrasada: os três segundos de eventos que
  chegaram enquanto nada lia, alcançados de uma vez.

## O que o streaming custa

**Nada nunca termina.** Um batch pode dizer "o dia 2 de março está carregado". Um stream só pode
dizer "isto é tudo até o último evento que vi", e um evento atrasado no celular de alguém pode
chegar depois de eventos que aconteceram mais tarde. O arquivo do dia que este laboratório
reproduz traz alguns desses de propósito, e alguns eventos escritos duas vezes, do jeito que um
coletor que tentou de novo os escreve.

**E o programa nunca para.** Um batch que cai é rodado de novo de manhã. Um consumidor que cai é um
buraco nos dados a partir daquele momento, crescendo até alguém perceber, então ele precisa de algo
que o reinicie e de algo que vigie o atraso. O arquivo de deslocamento é a versão pequena da
contabilidade que uma plataforma de streaming de verdade faz por você: o Kafka guarda um
deslocamento por grupo de consumidores, e a lição 3 fala mais disso. O Kafka não está instalado
neste laboratório e nada aqui rodou nele.
