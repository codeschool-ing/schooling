---
title: Uma busca, não uma linha
version: 1
---

A cadeia de pensamento (lição 26) escreve um caminho da pergunta até a resposta. Se o primeiro
passo for ruim, tudo o que vem depois é construído sobre ele, e a cadeia não tem como voltar. A
autoconsistência (lição 27) roda vários caminhos inteiros e compara só onde eles terminam. **A
árvore de pensamentos (*tree of thoughts*) trata o problema como uma busca: a cada passo ela
propõe vários próximos passos possíveis, julga quão promissor é cada um, fica com os melhores e
abandona o resto**, e então repete a partir de cada passo que manteve. Os caminhos se ramificam
como uma árvore, e os galhos fracos são cortados antes que alguém pague para terminá-los.

## O quebra-cabeça

O jogo do 24: dados quatro números, combine-os com `+`, `-`, `*` e `/`, usando cada número uma
vez, para fazer 24. Ele combina bem com o método, porque todo estado intermediário pode ser
julgado. Depois de um passo sobram três números, e ou o 24 ainda pode ser alcançado a partir deles,
ou não pode.

O `tot` é um programa de verdade, impresso no `lab.sh`. **Um "pensamento" é um passo**: escolher
dois dos números que sobram, combiná-los e devolver o resultado. A cada nível o `tot` propõe todo
passo possível a partir de cada estado que manteve, julga cada estado novo como `sure` (o 24 ainda
é alcançável) ou `impossible`, e fica com os `--breadth` melhores, três por padrão:

```
ana@lab:~/pe$ tot 4 9 10 13
level 1: 36 proposed, 36 different, 7 sure, 29 impossible
  keep  [9 13 -6]  after  4 - 10 = -6
  keep  [4 13 19]  after  9 + 10 = 19
  keep  [4 10 -4]  after  9 - 13 = -4
level 2: 54 proposed, 47 different, 2 sure, 45 impossible
  keep  [-6 -4]  after  9 - 13 = -4
  keep  [4 6]  after  19 - 13 = 6
level 3: 12 proposed, 7 different, 1 sure, 6 impossible
  keep  [24]  after  -6 * -4 = 24
solved: 4 - 10 = -6; 9 - 13 = -4; -6 * -4 = 24
```

Leia um nível por vez. A partir de `4 9 10 13` há 36 primeiros passos possíveis. Só 7 deixam
números a partir dos quais o 24 ainda é alcançável; **29 são becos sem saída, e são descartados
antes que se gaste um segundo passo com qualquer um deles.** Três dos sete são mantidos. A partir
desses três, 54 segundos passos são propostos, 47 deles estados diferentes, e só 2 ainda chegam a
24. Um deles leva a `-6 * -4 = 24`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 800 340\" role=\"img\" aria-label=\"Uma árvore desenhada a partir da captura do tot. O início, 4 9 10 13, tem três filhos mantidos no nível 1: 9 13 -6 depois de 4 - 10, 4 13 19 depois de 9 + 10, e 4 10 -4 depois de 9 - 13; 36 estados foram propostos, 7 eram certos e 29 foram descartados. No nível 2, 54 foram propostos e 2 eram certos: -6 -4 abaixo de 9 13 -6, e 4 6 abaixo de 4 13 19; o terceiro ramo não manteve nada. No nível 3, -6 vezes -4 dá 24, e a busca está resolvida.\"><defs><marker id=\"tot-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"40\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">início</text><text x=\"40\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nível 1</text><text x=\"40\" y=\"220\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nível 2</text><text x=\"40\" y=\"305\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nível 3</text><rect x=\"265\" y=\"25\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[4 9 10 13]</text><path d=\"M320 55 L140 113\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"150\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4 - 10 = -6</text><rect x=\"85\" y=\"115\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[9 13 -6]</text><path d=\"M320 55 L320 113\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"328\" y=\"85\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9 + 10 = 19</text><rect x=\"265\" y=\"115\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[4 13 19]</text><path d=\"M320 55 L500 113\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"445\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9 - 13 = -4</text><rect x=\"445\" y=\"115\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"500\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[4 10 -4]</text><path d=\"M140 145 L140 203\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"148.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">9 - 13 = -4</text><rect x=\"85\" y=\"205\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[-6 -4]</text><path d=\"M320 145 L320 203\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"328.0\" y=\"175.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">19 - 13 = 6</text><rect x=\"265\" y=\"205\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"320\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">[4 6]</text><text x=\"500\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sem vaga</text><path d=\"M140 235 L140 288\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tot-ah)\"></path><text x=\"148.0\" y=\"262.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">-6 * -4 = 24</text><rect x=\"85\" y=\"290\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"140\" y=\"305\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">[24]</text><text x=\"600\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">36 propostos, 7 certos</text><text x=\"600\" y=\"139\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">3 mantidos, 29 descartados</text><text x=\"600\" y=\"212\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">54 propostos, 47 diferentes</text><text x=\"600\" y=\"229\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">2 certos, os dois mantidos</text><text x=\"600\" y=\"297\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">12 propostos, 7 diferentes</text><text x=\"600\" y=\"314\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">1 certo: resolvido</text></svg>", "caption": "A busca que o tot imprimiu para 4 9 10 13, nível por nível. Todo passo possível é proposto, cada estado novo é julgado, e só os três melhores ficam na árvore; a solução é o caminho pela esquerda."}
```

A resposta, `(4 - 10) * (9 - 13)`, usa números negativos, o que não é a primeira ideia que a maioria
das pessoas tenta. Uma cadeia que começasse por `9 + 10 = 19`, o movimento mais óbvio, teria de
achar `19 - 13 = 6` e depois `4 * 6 = 24`, que o `tot` também manteve no nível 2. Uma cadeia que
começasse por `4 * 10 = 40` não iria a lugar nenhum, e teria de admitir isso no fim.

## Quantos galhos manter

O `--breadth` é quantos estados sobrevivem a cada nível. Com 1, a busca mantém um caminho só:

```
ana@lab:~/pe$ tot 4 9 10 13 --breadth 1
level 1: 36 proposed, 36 different, 7 sure, 29 impossible
  keep  [9 13 -6]  after  4 - 10 = -6
level 2: 18 proposed, 18 different, 1 sure, 17 impossible
  keep  [-6 -4]  after  9 - 13 = -4
level 3: 6 proposed, 6 different, 1 sure, 5 impossible
  keep  [24]  after  -6 * -4 = 24
solved: 4 - 10 = -6; 9 - 13 = -4; -6 * -4 = 24
```

Ela resolveu o quebra-cabeça com 60 propostas em vez de 102 (36 + 18 + 6 contra 36 + 54 + 12).
Não foi sorte, e é a coisa mais importante a ler nesta captura: **o juiz do `tot` nunca erra.**
Ele decide `sure` tentando todas as combinações restantes, então um estado mantido sempre leva ao
24, e um galho basta.

O julgamento de um modelo não é assim. Ele lê três números e estima se o 24 ainda é alcançável, e
pode errar nas duas direções. Com largura 1, um `sure` errado manda a busca inteira para um beco
sem saída. **Uma largura maior é seguro contra um juiz falível**: os galhos extras custam propostas
e julgamentos, e são o que sobra quando o favorito se revela errado. O método também permite
voltar: quando todo filho de um estado mantido é julgado impossível, uma versão da busca em
profundidade retorna a um estado anterior e tenta o próximo galho dele. O `tot` busca nível por
nível e nunca precisa disso.

## Quando não há nada a achar

Alguns quebra-cabeças não têm resposta. Uma cadeia de pensamento a quem se pede uma tende a
produzir alguma coisa mesmo assim, já que uma resposta é o jeito provável de o texto dela terminar.
A busca relata a verdade:

```
ana@lab:~/pe$ tot 1 1 1 1
level 1: 36 proposed, 3 different, 0 sure, 3 impossible
no state left: 24 cannot be made from 1 1 1 1
```

Os 36 primeiros passos se reduzem a 3 estados diferentes (dois uns viram 2, 0 ou 1), nenhum deles
alcança o 24, e a busca para no primeiro nível. **Ficar sem galhos é uma resposta**: diz que nenhum
caminho foi encontrado, o que é mais útil que uma resposta fluente e errada.
