---
title: Eventos: pelo menos uma vez, mais ou menos em ordem
version: 1
---

O coletor do site escreve uma linha por clique, visualização e compra, e o laboratório deixa um dia
deles em `landing/events/`. Um evento é um fato sobre um momento: ele nunca é atualizado nem
apagado, o que faz dele a origem mais fácil de ler e a mais fácil de contar errado.

```
ana@vm:~/etl$ wc -l landing/events/2026-03-05.jsonl
2438 landing/events/2026-03-05.jsonl
ana@vm:~/etl$ python -c "import json,collections; ids=collections.Counter(json.loads(l)['event_id'] for l in open('landing/events/2026-03-05.jsonl')); print(sum(1 for c in ids.values() if c > 1), 'event ids appear twice')"
23 event ids appear twice
ana@vm:~/etl$ python -c "import json; ev=[json.loads(l) for l in open('landing/events/2026-03-05.jsonl')]; late=[e for e in ev if not e['occurred_at'].startswith('2026-03-05')]; print(len(late), 'events from another day'); print(late[0])"
3 events from another day
{'event_id': 'e0010088', 'occurred_at': '2026-03-04T23:01:17-03:00', 'session': 's283220', 'type': 'view', 'book_id': 65}
```

Dois dos três números são a razão de os eventos precisarem de um tratamento próprio.

## Duas vezes

**Vinte e três ids de evento aparecem duas vezes.** Ninguém clicou duas vezes: o coletor mandou um
evento, não ouviu resposta a tempo e mandou de novo, e as duas cópias chegaram. Esse comportamento tem
nome, *entrega pelo menos uma vez*, e é o que quase todo sistema de eventos garante, porque a
alternativa — no máximo uma vez — perde eventos sempre que a rede soluça, e um evento perdido não
deixa rastro para achar.

Então o pipeline fica com o trabalho de transformar "pelo menos uma vez" em "exatamente uma vez", e
só consegue fazer isso com um identificador que o produtor deu ao evento. **O `event_id` é o campo
mais importante do arquivo**: sem ele, dois cliques idênticos com um segundo de diferença e um clique
mandado duas vezes são indistinguíveis. A lição 15 o usa para carregar eventos de modo que uma
duplicata não faça mal.

## Atrasados

**Três eventos do arquivo de 5 de março aconteceram no dia 4.** Um celular num trem mandou os seus
cliques quando achou sinal; o coletor os escreveu quando chegaram, no arquivo do dia em que
chegaram. Isso dá dois horários a cada evento:

- **horário do evento**, `occurred_at`, quando aconteceu;
- **horário de processamento**, quando o pipeline o viu — aqui, em que arquivo ele caiu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l03-late\" aria-label=\"Duas linhas do tempo, uma acima da outra. A de cima é quando os eventos aconteceram, a de baixo é em que arquivo eles caíram. A maioria dos eventos desce reto para o arquivo do próprio dia. Um evento que aconteceu às 23:01 de 4 de março cruza a meia-noite na diagonal e cai no arquivo de 5 de março.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"st-ah-phosphor-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor-dim)\"></path></marker></defs><path d=\"M60.0 60.0 L690.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"60.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">horário do evento: quando aconteceu</text><path d=\"M60.0 190.0 L690.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\"></path><text x=\"60.0\" y=\"212.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">horário de processamento: o arquivo onde caiu</text><path d=\"M380.0 40.0 L380.0 210.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"220.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">4 de março</text><text x=\"535.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">5 de março</text><path d=\"M110.0 66.0 L110.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"110.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M170.0 66.0 L170.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"170.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M240.0 66.0 L240.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"240.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M300.0 66.0 L300.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"300.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M430.0 66.0 L430.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"430.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M500.0 66.0 L500.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"500.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M560.0 66.0 L560.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"560.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><path d=\"M630.0 66.0 L630.0 182.0\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#st-ah-phosphor-dim)\"></path><circle cx=\"630.0\" cy=\"60.0\" r=\"4\" fill=\"var(--phosphor)\"></circle><circle cx=\"350.0\" cy=\"60.0\" r=\"5\" fill=\"var(--amber)\"></circle><path d=\"M350.0 66.0 L455.0 182.0\" stroke=\"var(--amber)\" stroke-width=\"1.8\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"350.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">23:01, mandado de um trem</text></svg>", "caption": "Agrupe por quando aconteceu, não por onde caiu, ou um evento atrasado conta no dia errado."}
```


Um relatório de visualizações por dia precisa agrupar pelo horário do evento, ou um evento atrasado
conta no dia errado. E aí o dia 4 nunca termina de verdade: um evento sobre ele ainda pode chegar
amanhã. Sistemas de streaming fecham um período depois de um atraso fixo que chamam de *watermark*
e descartam ou tratam à parte o que chega depois; um batch noturno pode fazer o mais simples e
recarregar os últimos dias toda noite. **De um jeito ou de outro, a decisão é quão atrasado é
atrasado demais**, e ela precisa ficar escrita.

## Em ordem, mais ou menos

Os eventos dentro de um arquivo estão na ordem em que foram escritos, que é perto da ordem em que
aconteceram e não é a mesma. Um pipeline que supõe que "o último evento de uma sessão é o seu estado
mais recente" um dia vai errar por um evento. Ordene pelo horário do evento quando a ordem importa; é
barato, e nunca está errado.

Kafka, Kinesis e Pub/Sub são o que carrega eventos entre sistemas em escala, com partições,
deslocamentos de consumidor e retenção em vez de um arquivo. Por padrão, eles mantêm as mesmas três
propriedades — pelo menos uma vez, atrasados, mais ou menos em ordem — e o arquivo do laboratório
mostra as três sem nenhuma dessas máquinas. Nenhum deles está instalado aqui, e nada neste curso
rodou neles.
