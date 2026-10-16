---
title: Por que antes e depois não responde
version: 1
---

O jeito mais natural de julgar uma mudança é comparar as semanas depois dela com as semanas antes.
**É também o menos confiável**, e as seis primeiras aulas deste curso são o motivo: uma série se
mexe com a tendência, as sazonalidades e os feriados, tenha alguém mudado alguma coisa ou não.

```schooling-example
{"language": "python", "file": "before_after.py", "parts": [{"code": "import pandas as pd\n\norders = pd.read_csv(\"daily_orders.csv\", parse_dates=[\"date\"], index_col=\"date\")[\"orders\"]\nlaunch = pd.Timestamp(\"2024-02-26\")", "note": "Suponha que uma página de checkout nova entrou no ar na segunda, 26 de fevereiro de 2024. Nada nos dados da Panela mudou naquele dia; é esse o ponto."}, {"code": "before = orders[launch - pd.Timedelta(days=28):launch - pd.Timedelta(days=1)]\nafter = orders[launch:launch + pd.Timedelta(days=27)]\nprint(f\"28 days before {launch.date()}: {before.mean():7.1f} orders a day\")\nprint(f\"28 days from   {launch.date()}: {after.mean():7.1f} orders a day\")\nprint(f\"change: {after.mean() / before.mean() - 1:+.1%}\")", "note": "Quatro semanas antes e quatro semanas a partir do lançamento: a comparação que um relatório de lançamento faz."}, {"code": "before_2023 = orders[launch - pd.Timedelta(days=392):launch - pd.Timedelta(days=365)]\nafter_2023 = orders[launch - pd.Timedelta(days=364):launch - pd.Timedelta(days=337)]\nprint(f\"\\nthe same two stretches of 2023, with no new page: {after_2023.mean() / before_2023.mean() - 1:+.1%}\")", "note": "Os mesmos 56 dias um ano antes, 364 dias para trás para os dias da semana se alinharem. Nenhuma página foi lançada em 2023."}], "output": "28 days before 2024-02-26:   957.0 orders a day\n28 days from   2024-02-26:  1063.0 orders a day\nchange: +11.1%\n\nthe same two stretches of 2023, with no new page: +10.2%"}
```

O lançamento "aumentou os pedidos em 11,1%". Os mesmos dois trechos do ano anterior, sem nada
lançado, subiram 10,2%. Quase todo o efeito aparente é o calendário: as semanas antes do lançamento
tinham Carnaval nos dois anos, as semanas depois eram o começo da temporada mais movimentada, e o
negócio crescia o tempo todo. O que quer que a página tenha feito está em algum lugar na distância
entre os dois números, e dois números de dois anos diferentes não dizem onde.

**Antes e depois compara dois momentos diferentes, então tudo o mais que difere entre esses momentos
se mistura na resposta.** A estatística chama essas outras coisas de **variáveis de confusão**, e a
aula 18 de `statistics` é sobre elas. Algumas podem ser ajustadas, como a aula 6 ajustou o Carnaval,
mas só as que alguém lembrou.

## O que um experimento faz no lugar

Um **teste A/B** mostra duas versões ao mesmo tempo, e decide por sorteio que visitante vê qual. A
versão A é o **controle**, normalmente o que já existe; a versão B é o **tratamento**, a mudança.
Como a divisão é aleatória e simultânea:

- a sazonalidade, a tendência e os feriados caem nos dois grupos igualmente, então se anulam na
  comparação;
- os tipos de visitante, animado ou distraído, no celular ou no notebook, se espalham por igual
  entre os grupos, em média, sem ninguém precisar listá-los;
- o que sobra como diferença é a própria mudança, mais o acaso, e o acaso é exatamente o que os
  testes das aulas 13 a 15 de `statistics` medem.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 250\" role=\"img\" data-fig=\"l07-split\" aria-label=\"Um diagrama de um teste A/B. Os visitantes chegam pela esquerda e uma moeda decide, para cada um, se ele vê o checkout antigo, A, ou o novo, B. Os dois grupos ficam dentro de uma faixa rotulada as mesmas semanas, feriados e tendência. À direita, a diferença entre os dois grupos é a mudança mais o acaso.\"><defs><marker id=\"st-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"170.0\" y=\"30.0\" width=\"280.0\" height=\"180.0\" rx=\"6\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"310.0\" y=\"196.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as mesmas semanas, os mesmos feriados, a mesma tendência</text><rect x=\"20.0\" y=\"95.0\" width=\"100.0\" height=\"40.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"70.0\" y=\"115.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">visitantes</text><text x=\"70.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um sorteio</text><path d=\"M120 108 C150 108 160 70 196 70\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M120 122 C150 122 160 150 196 150\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"200.0\" y=\"50.0\" width=\"220.0\" height=\"40.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">A: o checkout antigo</text><rect x=\"200.0\" y=\"130.0\" width=\"220.0\" height=\"40.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"310.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">B: o checkout novo</text><path d=\"M420 70 C450 70 460 108 486 108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><path d=\"M420 150 C450 150 460 122 486 122\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-paper-dim)\"></path><rect x=\"490.0\" y=\"92.0\" width=\"136.0\" height=\"46.0\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"558.0\" y=\"107.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a diferença</text><text x=\"558.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">= a mudança + o acaso</text></svg>", "caption": "Antes e depois compara dois momentos. Um experimento compara dois grupos num mesmo momento, então tudo o que o momento carrega cai nos dois e se anula."}
```

É por isso que experimentos aleatorizados são o padrão de evidência para uma decisão como esta, e
por isso que as próximas cinco aulas valem o tamanho que têm. Eles também não são de graça: um
experimento precisa de tráfego, de tempo e da disciplina de decidir antes de olhar, que é o que o
resto desta aula escreve.
