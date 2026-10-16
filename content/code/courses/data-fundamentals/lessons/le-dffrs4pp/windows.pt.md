---
title: Janelas, os totais que um fluxo consegue dar
version: 1
---

**Um fluxo ilimitado não tem total, então um processador de fluxo conta por janela.** Uma janela é um
trecho de tempo com começo e fim. Cada evento cai em uma ou mais janelas pelo seu horário, e cada janela
ganha a sua própria resposta: viagens iniciadas entre 08:00 e 08:15, entre 08:15 e 08:30, e assim por
diante. O job em lote desta aula também usou uma janela, de um dia. Um fluxo só tem muito mais delas, e
precisa decidir quando cada uma terminou.

Três formatos cobrem quase todos os casos:

| janela | o que é | na Roda Livre |
|---|---|---|
| **fixa** (*tumbling*) | tamanho fixo, uma colada na outra, sem sobreposição: cada evento está em exatamente uma | viagens por quarto de hora |
| **deslizante** (*sliding*) | tamanho fixo, começando a um passo fixo menor que o tamanho, então as janelas se sobrepõem e um evento está em várias | viagens nos últimos 30 minutos, atualizadas a cada 5 |
| **de sessão** (*session*) | sem tamanho fixo: abre com um evento e fecha depois de um intervalo sem nenhum | o uso do aplicativo por um cliente, encerrado após 10 minutos parado |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um eixo de tempo das 08:00 às 09:00 com viagens marcadas como pontos. Fixa: quatro caixas de quinze minutos lado a lado. Deslizante: caixas de trinta minutos começando a cada quinze, sobrepostas. Sessão: os toques de um cliente em três grupos, cada grupo numa caixa, separados por intervalos de mais de dez minutos.\" data-fig=\"windows\"><defs><marker id=\"windows-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"150\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:00</text><line x1=\"150\" y1=\"28\" x2=\"150\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"285\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:15</text><line x1=\"285\" y1=\"28\" x2=\"285\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"420\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:30</text><line x1=\"420\" y1=\"28\" x2=\"420\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"555\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">08:45</text><line x1=\"555\" y1=\"28\" x2=\"555\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"690\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">09:00</text><line x1=\"690\" y1=\"28\" x2=\"690\" y2=\"262\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 4\"></line><text x=\"14\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">viagens</text><line x1=\"150\" y1=\"46\" x2=\"690\" y2=\"46\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><circle cx=\"168\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"195\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"213\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"231\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"258\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"294\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"303\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"330\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"348\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"357\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"384\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"411\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"429\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"447\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"474\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"492\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"519\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"546\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"573\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"618\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"645\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><circle cx=\"672\" cy=\"46\" r=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--phosphor)\" stroke-width=\"1\"></circle><text x=\"14\" y=\"88\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">fixa</text><rect x=\"152\" y=\"72\" width=\"131\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"217.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 min</text><rect x=\"287\" y=\"72\" width=\"131\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"352.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 min</text><rect x=\"422\" y=\"72\" width=\"131\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"487.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 min</text><rect x=\"557\" y=\"72\" width=\"131\" height=\"32\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"622.5\" y=\"88.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">15 min</text><text x=\"14\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">deslizante</text><rect x=\"152\" y=\"122\" width=\"266\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"285.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">08:00–08:30</text><rect x=\"422\" y=\"122\" width=\"266\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"555.0\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">08:30–09:00</text><rect x=\"287\" y=\"154\" width=\"266\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"420.0\" y=\"167.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">08:15–08:45</text><text x=\"14\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\" font-weight=\"600\">sessão</text><text x=\"14\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um cliente</text><rect x=\"169\" y=\"212\" width=\"88\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"177\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"195\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"204\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"231\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"249\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><rect x=\"376\" y=\"212\" width=\"43\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"384\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"393\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"411\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><rect x=\"538\" y=\"212\" width=\"124\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><circle cx=\"546\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"573\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"591\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"627\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><circle cx=\"654\" cy=\"229\" r=\"3\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></circle><text x=\"316.5\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um intervalo de 15 min</text><text x=\"478.5\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um intervalo de 15 min</text><text x=\"420\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma sessão fecha depois de 10 minutos sem toque</text></svg>", "caption": "A mesma hora cortada de três jeitos. Janelas fixas não dividem nenhum evento; as deslizantes se sobrepõem, então um evento é contado em duas; as sessões são cortadas onde um cliente fica parado."}
```

Uma janela fixa responde "quantos em cada período", e as suas contagens somam o total. Uma janela
deslizante responde "quantos recentemente" e suaviza os saltos de um quarto de hora para o outro; as suas
contagens não somam, porque cada evento é contado uma vez por janela em que está. Uma janela de sessão
segue os dados e não o relógio, então duas sessões de um mesmo cliente podem durar três minutos ou três
horas.

## Contando pelo relógio errado

É nas janelas que os dois relógios da seção anterior deixam de ser uma ideia. Salve
`stream/windows.py`, que conta as viagens de segunda das 08:00 às 09:00 em janelas fixas de quinze
minutos, uma vez pelo tempo do evento e outra pela chegada:

```python
# stream/windows.py
import json
from collections import Counter


def window(ts):                                  # '2025-10-06 08:37:12' -> '08:30'
    return f'{ts[11:13]}:{int(ts[14:16]) // 15 * 15:02}'


by_event, by_arrival = Counter(), Counter()
with open('docks.jsonl') as f:
    for line in f:
        e = json.loads(line)
        if e['kind'] != 'undock':
            continue
        if e['event_time'].startswith('2025-10-06 08'):
            by_event[window(e['event_time'])] += 1
        if e['arrived'].startswith('2025-10-06 08'):
            by_arrival[window(e['arrived'])] += 1
print('window  by event time  by arrival time')
for w in ('08:00', '08:15', '08:30', '08:45'):
    print(f'{w}   {by_event[w]:>13}  {by_arrival[w]:>15}')
print('total   ', f'{sum(by_event.values()):>12}  {sum(by_arrival.values()):>15}')
```

A função `window` é tudo o que uma janela fixa é: ela arredonda um horário para baixo, até o quarto de
hora em que ele cai.

```
ana@lab:~/roda/stream$ python windows.py
window  by event time  by arrival time
08:00              19               19
08:15              21               20
08:30              16               14
08:45               8               11
total              64               64
```

As duas colunas concordam às 08:00 e discordam depois disso. Contando pela chegada, 08:15 e 08:30 perdem
viagens e 08:45 ganha três: as viagens do Parque Barigui que aconteceram antes e chegaram às 08:51:30.
**O total é o mesmo nas duas colunas**, 64, então um relatório que mostrasse só a hora nunca revelaria o
problema. O erro está na janela em que cada viagem é arquivada, e um gráfico de viagens por quarto de
hora feito com a segunda coluna mostra às 08:45 um pico que não aconteceu.

A primeira coluna é a certa, e foi calculada sobre um arquivo que já tinha terminado de chegar. Um
processador de fluxo que conta, às 08:31, a janela das 08:15 não tem esse arquivo. Ele precisa decidir
quando enviar a resposta, e essa decisão é a próxima seção.
