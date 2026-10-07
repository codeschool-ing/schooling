---
title: O que as matrizes erram
version: 1
---

Em 2008 o analista de risco Louis Anthony Cox publicou um artigo com um título sem ambiguidade, *What's
wrong with risk matrices?*, e mostrou matematicamente o que a seção anterior mostrou com nove riscos.
Quatro achados do artigo explicam cada estranheza da tabela da Vereda.

| problema | o que significa | na Vereda |
|---|---|---|
| **compressão de faixa** | valores muito diferentes caem na mesma faixa | R$ 60.000 e R$ 200.000 são os dois impacto 4; um evento por ano e três são os dois probabilidade 4 |
| **empates** | riscos diferentes recebem a mesma nota e parecem iguais | T14, T08 e T11 têm todas nota 4, com perdas esperadas de R$ 2.400 a R$ 9.000 |
| **inversão** | um risco menor recebe nota maior que um risco maior | a T01 tem nota 9 com R$ 6.000 por ano; a T13 tem nota 5 com R$ 15.000 |
| **aritmética ordinal** | posições de faixa são multiplicadas como se fossem quantidades | "3 × 3 = 9 > 1 × 5 = 5" trata o passo da faixa 1 para a 2 como o passo da 4 para a 5, embora as faixas cubram valores muito diferentes |

A conclusão de Cox foi que uma matriz pode ordenar riscos **pior que o acaso** em alguns casos, o
que soa exagerado e se vê em inversões como a da T01. Uma ordenação que põe o risco mais barato
acima do mais caro é pior que uma moeda para esse par.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" data-fig=\"l10-compression\" aria-label=\"As faixas de impacto do matrix.py numa escala de reais, com as bordas em R$ 2.000, 10.000, 50.000 e 200.000. R$ 60.000 e R$ 200.000 caem os dois na faixa 4, embora um seja mais de três vezes o outro.\"><defs><marker id=\"l10-compression-tm-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"40.0\" y=\"60.0\" width=\"114.7\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"98.4\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">faixa 1</text><rect x=\"156.7\" y=\"60.0\" width=\"133.5\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"224.5\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">faixa 2</text><rect x=\"292.2\" y=\"60.0\" width=\"133.5\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">faixa 3</text><rect x=\"427.8\" y=\"60.0\" width=\"114.7\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"486.1\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">faixa 4</text><rect x=\"544.5\" y=\"60.0\" width=\"133.5\" height=\"50.0\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"612.2\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">faixa 5</text><text x=\"156.7\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">2.000</text><text x=\"292.2\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10.000</text><text x=\"427.8\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50.000</text><text x=\"544.5\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">200.000</text><path d=\"M442.1 40.0 L442.1 60.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-compression-tm-ah-amber)\"></path><text x=\"442.1\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">R$ 60.000</text><path d=\"M543.5 40.0 L543.5 60.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l10-compression-tm-ah-amber)\"></path><text x=\"543.5\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">R$ 200.000</text><text x=\"360.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a mesma faixa, a mesma nota: uma matriz não enxerga um fator de três dentro de uma célula</text></svg>", "caption": "Compressão de faixa: tudo entre duas bordas vira um número, por mais longe que os valores estejam."}
```

### Por que as matrizes estão em toda parte mesmo assim

São rápidas, parecem análise, e não precisam de estimativas que alguém tenha de defender. Esses são
também os motivos de elas falharem: **uma matriz deixa a equipe pular o passo em que os números são
discutidos**, e a discussão é onde está a maior parte do valor de uma análise de risco. Duas pessoas
que concordam que um risco é "provável" podem querer dizer uma vez por ano e uma vez por mês, e a
matriz nunca vai mostrar isso.

### Quando uma matriz basta

Há usos honestos:

- **Triagem.** Separar cinquenta ameaças em "olhar estas primeiro" e "depois" em uma hora, antes de
  existir qualquer número. Uma ordenação grosseira é o que a matriz faz bem.
- **Quando um framework exige.** Alguns padrões e auditores pedem uma matriz. Produza-a a partir das
  estimativas quantitativas, para que as faixas sejam preenchidas com números e não com adjetivos, e
  mantenha os números ao lado.
- **Quando os números seriam pura invenção.** Para um sistema sem histórico e sem classe de
  referência, uma equipe pode honestamente não conseguir dar uma faixa. Uma matriz pelo menos não
  finge precisão.

### O que fazer no lugar, por padrão

Para os poucos riscos que mais importam, faça o que as aulas 9 e 10 fizeram: estime frequência e
perda como faixas, simule, e mostre a curva. Para o resto, uma matriz preenchida a partir dessas
mesmas estimativas serve, desde que ninguém leia os empates e as inversões dela como achados. A
Vereda mantém as duas: a matriz no slide que o conselho do daniel vê a cada trimestre, montada pelo
`matrix.py` a partir do `risks.csv`, e a curva na página seguinte.
