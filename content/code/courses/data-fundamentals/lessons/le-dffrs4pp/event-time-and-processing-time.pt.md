---
title: Tempo do evento e tempo de processamento
version: 1
---

**Todo evento tem dois horários, quando aconteceu e quando foi processado, e os dois discordam.** O
primeiro é o **tempo do evento** (*event time*), escrito no evento por quem o produziu: o sensor da doca
carimba o segundo em que a bicicleta saiu. O segundo é o **tempo de processamento** (*processing time*),
o relógio da máquina que trata o evento quando ele chega. No `docks.jsonl`, o campo `arrived` faz esse
papel.

A imagem errada é a de uma esteira: os eventos saem das docas em ordem e chegam ao servidor na mesma
ordem, um instante depois. Numa manhã boa isso é quase verdade. Aí a rede de celular cai por meia
hora, e um sensor guarda o que registra e manda quando o link volta. Meia hora de eventos de uma
estação chega junta, depois de eventos que aconteceram mais tarde em todas as outras estações.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Dois eixos de tempo das 08:15 às 09:00, o tempo do evento em cima e a chegada embaixo. As linhas das outras estações são quase verticais. Dez linhas do Parque Barigui começam entre 08:20 e 08:48 no eixo de cima e todas terminam às 08:51:30 no de baixo.\" data-fig=\"two-clocks\"><defs><marker id=\"two-clocks-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"14\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">quando aconteceu: tempo do evento</text><text x=\"14\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">quando chegou: tempo de processamento</text><line x1=\"96.0\" y1=\"92\" x2=\"681.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"96.0\" y1=\"206\" x2=\"681.0\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"96.0\" y1=\"87\" x2=\"96.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"96.0\" y1=\"206\" x2=\"96.0\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"96.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:15</text><text x=\"96.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:15</text><line x1=\"291.0\" y1=\"87\" x2=\"291.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"291.0\" y1=\"206\" x2=\"291.0\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"291.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:30</text><text x=\"291.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:30</text><line x1=\"486.0\" y1=\"87\" x2=\"486.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"486.0\" y1=\"206\" x2=\"486.0\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"486.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:45</text><text x=\"486.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:45</text><line x1=\"681.0\" y1=\"87\" x2=\"681.0\" y2=\"92\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><line x1=\"681.0\" y1=\"206\" x2=\"681.0\" y2=\"211\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></line><text x=\"681.0\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:00</text><text x=\"681.0\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"101.8\" y1=\"92\" x2=\"102.5\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"140.0\" y1=\"92\" x2=\"140.8\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"161.9\" y1=\"92\" x2=\"162.5\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"203.9\" y1=\"92\" x2=\"204.6\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"222.3\" y1=\"92\" x2=\"222.8\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"243.1\" y1=\"92\" x2=\"244.0\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"272.8\" y1=\"92\" x2=\"273.2\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"295.8\" y1=\"92\" x2=\"296.4\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"324.6\" y1=\"92\" x2=\"325.0\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"368.3\" y1=\"92\" x2=\"368.6\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"395.7\" y1=\"92\" x2=\"396.5\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"443.3\" y1=\"92\" x2=\"444.2\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"479.1\" y1=\"92\" x2=\"479.9\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"505.9\" y1=\"92\" x2=\"506.2\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"534.5\" y1=\"92\" x2=\"534.8\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"578.3\" y1=\"92\" x2=\"579.2\" y2=\"206\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"116.6\" y1=\"92\" x2=\"117.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"116.6\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"117.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"145.0\" y1=\"92\" x2=\"145.2\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"145.0\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"145.2\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"168.4\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"168.4\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"233.4\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"233.4\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"272.4\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"272.4\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"302.5\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"302.5\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"328.5\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"328.5\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"344.3\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"344.3\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"416.4\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"416.4\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"423.2\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"423.2\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"452.8\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"452.8\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"522.2\" y1=\"92\" x2=\"570.5\" y2=\"206\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><circle cx=\"522.2\" cy=\"92\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"570.5\" cy=\"206\" r=\"2.6\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><line x1=\"161.0\" y1=\"60\" x2=\"570.5\" y2=\"60\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></line><line x1=\"161.0\" y1=\"56\" x2=\"161.0\" y2=\"64\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><line x1=\"570.5\" y1=\"56\" x2=\"570.5\" y2=\"64\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><text x=\"369.0\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">link do Parque Barigui fora</text><line x1=\"452\" y1=\"246\" x2=\"476\" y2=\"246\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></line><text x=\"482\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Parque Barigui (ST08)</text><line x1=\"610\" y1=\"246\" x2=\"634\" y2=\"246\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"640\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">outras</text><text x=\"598.0\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">as dez enviadas</text><text x=\"598.0\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">às 08:51:30</text></svg>", "caption": "Cada linha liga os dois horários de um evento. A maioria cai reta: poucos segundos entre acontecer e chegar. As do Parque Barigui se abrem até 08:51:30, quando o link voltou, e cruzam os eventos que aconteceram depois delas.", "same": ["Parque Barigui (ST08)"]}
```

Foi isso que o gerador plantou, e um programa curto encontra sem que ninguém diga onde procurar. Salve-o
como `stream/lateness.py`:

```python
# stream/lateness.py
import json
from collections import Counter
from datetime import datetime

newest = None                  # the latest event time seen so far
behind = 0                     # events older than one that arrived before them
delay = Counter()
over_a_minute = Counter()
with open('docks.jsonl') as f:
    for line in f:
        e = json.loads(line)
        happened = datetime.fromisoformat(e['event_time'])
        arrived = datetime.fromisoformat(e['arrived'])
        if newest and happened < newest:
            behind += 1
        newest = max(newest or happened, happened)
        seconds = (arrived - happened).total_seconds()
        if seconds < 5:
            delay['under 5 s'] += 1
        elif seconds < 60:
            delay['5 s to 1 min'] += 1
        else:
            delay['over 1 min'] += 1
            over_a_minute[e['station']] += 1
print(behind, 'events arrived after a later one')
for band in ('under 5 s', '5 s to 1 min', 'over 1 min'):
    print(f'{band:>12}: {delay[band]}')
print('over a minute late, by station:', dict(over_a_minute))
```

Ele lê o log na ordem em que foi escrito, que é a ordem de chegada, e conta todo evento que aconteceu
antes de algum que ele já viu:

```
ana@lab:~/roda/stream$ python lateness.py
21 events arrived after a later one
   under 5 s: 704
5 s to 1 min: 0
  over 1 min: 16
over a minute late, by station: {'ST08': 10, 'ST04': 6}
```

Quase todos os eventos chegaram em menos de cinco segundos. Mesmo assim, **fora de ordem não é o mesmo
que atrasado**: alguns dos eventos que vieram depois de um mais recente estão só alguns segundos atrás,
dois sensores cujas leituras se cruzaram no caminho. Os dezesseis com mais de um minuto são as duas
quedas: os dez do Parque Barigui, retidos a partir das 08:20 e enviados às 08:51:30, e os seis do Passeio
Público, que chegaram na manhã seguinte.

## Qual relógio cada pergunta pede

**Uma pergunta sobre o mundo pede o tempo do evento.** "Quantas viagens começaram entre 08:15 e 08:30?" é
sobre quando as bicicletas saíram das docas, e uma resposta que conta pela chegada põe as viagens do
Parque Barigui no quarto de hora errado. O tempo de processamento é o relógio certo para perguntas sobre
o próprio sistema: quão atrasado está o consumidor, quantos eventos chegaram ao servidor num minuto.

O tempo de processamento é fácil, porque é o relógio da parede, e todo evento ganha um no momento em que
chega. O tempo do evento é o correto, e traz dois custos. O processador precisa esperar, porque um
evento das 08:20 ainda pode estar a caminho às 08:50. E o tempo do evento só é tão bom quanto o relógio
que o escreveu: um sensor com o relógio desregulado carimba o segundo errado com toda a confiança, que é o
problema dos dispositivos da aula 4 e não tem cura mais adiante.

Os dois relógios aqui são os de Curitiba, o `TZ` que a aula 1 configurou. Um sistema de verdade levaria
no horário a diferença para o UTC, e a quarta-feira de 27 horas da aula 1 mostra o que acontece quando
dois sistemas discordam sobre qual relógio usaram.
