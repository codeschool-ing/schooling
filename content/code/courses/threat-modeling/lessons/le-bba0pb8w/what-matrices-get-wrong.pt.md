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
