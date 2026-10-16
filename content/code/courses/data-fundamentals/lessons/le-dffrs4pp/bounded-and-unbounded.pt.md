---
title: Dados limitados e ilimitados
version: 1
---

**Lote e fluxo não são um jeito lento e um jeito rápido de fazer a mesma coisa. Antes de tudo, eles
respondem a uma pergunta diferente: o dado termina?**

A imagem comum separa os dois pela velocidade. O lote seria o velho job da madrugada, o fluxo seria o
moderno, em tempo real, e um fluxo seria o que se constrói quando o lote é lento demais. A velocidade
decorre da diferença, mas não é a diferença. Um job que roda a cada cinco minutos sobre os últimos
cinco minutos de dados continua sendo lote, e um processador de fluxo pode ser configurado para esperar
uma hora antes de responder qualquer coisa.

A diferença está na entrada:

- dados **limitados** (*bounded*) têm fim. As viagens de ontem, a exportação de setembro, um arquivo que
  alguém enviou: dá para esperar até que tudo esteja lá, ler da primeira à última linha e dar uma
  resposta que não vai mudar;
- dados **ilimitados** (*unbounded*) não têm. Os sensores das docas da Roda Livre informam cada
  bicicleta que sai ou volta, e vão continuar fazendo isso enquanto a empresa existir. Não existe um
  "tudo" pelo qual esperar, então toda resposta é uma resposta sobre os dados até agora.

O **processamento em lote** (*batch*) trabalha com dados limitados. Ele espera um pedaço ficar completo
e então processa tudo de uma vez. O **processamento de fluxo** (*stream*) trabalha com dados
ilimitados. Ele trata cada evento quando chega e mantém a resposta sempre atualizada.

A maior parte dos dados que uma empresa produz é ilimitada: os sensores, os toques no aplicativo, os
pagamentos. O lote torna esses dados limitados cortando-os em pedaços, um dia ou uma hora, e
processando cada pedaço depois que ele fecha. Quase tudo nesta aula decorre desse corte: onde ele cai,
quando é feito, e o que acontece com um evento que aparece depois dele.

## Três manhãs de eventos das docas

Todos os programas desta aula trabalham num diretório próprio, `~/roda/stream`, na máquina que a aula 1
montou:

```sh
mkdir -p ~/roda/stream
cd ~/roda/stream
```

Os dados vêm de um programa, como tudo neste curso. Salve-o como `stream/sensors.py`. Ele escreve três
manhãs de eventos das docas, de segunda, 6, a quarta, 8 de outubro de 2025, num arquivo só,
`docks.jsonl`, com um objeto JSON por linha.

```schooling-example
{"language": "python", "file": "stream/sensors.py", "parts": [
{"code": "# stream/sensors.py\nimport json\nimport random\nfrom datetime import datetime, timedelta\n\nrandom.seed(8)\nSTATIONS = [f'ST{i:02}' for i in range(1, 13)]\nevents = []\nfor day in ('2025-10-06', '2025-10-07', '2025-10-08'):\n    opening = datetime.fromisoformat(day + ' 07:00:00')\n    for _ in range(120):                          # 120 rides a morning\n        start = opening + timedelta(seconds=int(random.triangular(0, 10800, 5400)))\n        end = start + timedelta(minutes=random.randint(4, 40))\n        bike = f'B{random.randint(1, 90):03}'\n        events.append((start, random.choice(STATIONS), bike, 'undock'))\n        events.append((end, random.choice(STATIONS), bike, 'dock'))\nevents.sort()\n", "note": "Três manhãs, das 07:00 às 10:00, com 120 viagens cada. Uma viagem são dois eventos: um `undock` onde ela começa e um `dock` onde termina, numa estação sorteada. O `triangular` concentra as saídas perto das 08:30, o meio da manhã, e a semente fixa faz o seu arquivo sair igual ao desta aula."},
{"code": "\n\ndef arrival(t, station):\n    \"\"\"When the reading reached the server: seconds later, unless a link was down.\"\"\"\n    s = str(t)\n    if station == 'ST08' and '2025-10-06 08:20' <= s < '2025-10-06 08:51:30':\n        return datetime.fromisoformat('2025-10-06 08:51:30')\n    if station == 'ST04' and '2025-10-06 09:20' <= s < '2025-10-07 07:02':\n        return datetime.fromisoformat('2025-10-07 07:02:00')\n    return t + timedelta(seconds=random.randint(1, 4))\n", "note": "Quando cada evento chegou ao servidor: de um a quatro segundos depois de acontecer, a não ser que um link estivesse fora. Há duas quedas plantadas. O Parque Barigui (`ST08`) perde o link na segunda às 08:20 e manda o que guardou às 08:51:30; o Passeio Público (`ST04`) perde o link às 09:20 e manda tudo às 07:02 da manhã seguinte."},
{"code": "\n\nrows = [{'id': f'EV{n:05}', 'station': st, 'bike': bike, 'kind': kind,\n         'event_time': str(t), 'arrived': str(arrival(t, st))}\n        for n, (t, st, bike, kind) in enumerate(events, 1)]\nrows.sort(key=lambda r: (r['arrived'], r['id']))  # the log is in order of arrival\nwith open('docks.jsonl', 'w') as f:\n    for r in rows:\n        f.write(json.dumps(r) + '\\n')\nprint(len(rows), 'events written to docks.jsonl')\n", "note": "Cada evento recebe um id na ordem em que os eventos aconteceram, de `EV00001` em diante. Depois o arquivo é ordenado pela chegada, porque é nessa ordem que um servidor recebe os eventos: a posição de uma linha diz quando ela chegou, não quando aconteceu."}
]}
```

```
ana@lab:~/roda/stream$ python sensors.py
720 events written to docks.jsonl
ana@lab:~/roda/stream$ head -3 docks.jsonl
{"id": "EV00001", "station": "ST10", "bike": "B058", "kind": "undock", "event_time": "2025-10-06 07:15:18", "arrived": "2025-10-06 07:15:20"}
{"id": "EV00002", "station": "ST05", "bike": "B088", "kind": "undock", "event_time": "2025-10-06 07:18:55", "arrived": "2025-10-06 07:18:59"}
{"id": "EV00003", "station": "ST05", "bike": "B065", "kind": "undock", "event_time": "2025-10-06 07:22:47", "arrived": "2025-10-06 07:22:48"}
```

Cada linha é um evento, e **cada evento carrega dois horários**: `event_time`, quando a bicicleta saiu
da doca ou chegou a ela, e `arrived`, quando a leitura chegou ao servidor. Na primeira linha eles estão
a dois segundos de distância. Duas quedas foram escritas no programa de propósito, do tipo que um link
móvel tem, e o resto da aula as encontra do jeito que uma equipe de dados encontraria.

O arquivo é limitado, porque o programa parou de escrever. O resto da aula o lê de dois jeitos. O job em
lote da próxima seção o trata como um arquivo terminado. O consumidor da seção seguinte o trata como um
log que ainda poderia estar crescendo, e o lê uma linha depois da outra.
