---
title: Sobreposição
version: 2
---

Se o problema dos pedaços de tamanho fixo é que um corte cai dentro de uma frase, uma solução é
garantir que nenhuma frase viva só num corte. A **sobreposição** começa cada pedaço algumas palavras
antes do fim do anterior, para que o texto em volta de cada fronteira apareça duas vezes, uma no fim de
um pedaço e outra no começo do seguinte.

```
ana@vm:~/rag$ python boundaries.py 60 15
20 chunks of 60 words, 15 overlapping
chunk 3 starts: has no writing, no broken spine and no missing ...
chunk 3 ends:   ... an email explaining why. The statutory right of withdrawal
chunk 4 starts: to you at our cost with an email explaining ...
chunk 4 ends:   ... choose Return items. 2. Select the books you are
chunk 5 starts: the order in your account and choose Return items. ...
chunk 5 ends:   ... at the post office counter instead. 4. Pack the
```

**O pedaço 4 ainda termina no meio de *Select the books you are*, e o pedaço 5 começa quinze palavras
antes disso**, em *the order in your account*, então a instrução inteira está dentro do pedaço 5. O
corte continua lá. Ele deixa de importar, porque há uma segunda cópia do texto em volta dele, sem corte
nenhum.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 740 310\" role=\"img\" aria-label=\"Duas linhas de pedaços ao longo das palavras 130 a 340 do regulamento de devoluções. Sem sobreposição, pedaços de 60 palavras ficam encostados, e o corte entre o pedaço 3 e o pedaço 4, na palavra 240, cai dentro da frase Select the books you are sending back and a reason, então nenhum dos dois a tem inteira. Com 15 palavras de sobreposição, cada pedaço começa 15 palavras antes do fim do anterior, e o pedaço 5 tem essa frase inteira.\"><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">60 palavras, sem sobreposição: cada pedaço começa onde o anterior acabou</text><path d=\"M370.0 102 V108 H402.4 V102\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"30.0\" y=\"60\" width=\"159.9047619047619\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.95238095238095\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 2</text><rect x=\"191.9047619047619\" y=\"82\" width=\"192.2857142857143\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"289.04761904761904\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 3</text><rect x=\"386.1904761904762\" y=\"60\" width=\"192.28571428571428\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"483.33333333333337\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 4</text><rect x=\"580.4761904761905\" y=\"82\" width=\"127.52380952380952\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"645.2380952380952\" y=\"90\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 5</text><text x=\"30\" y=\"148\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">60 palavras, 15 sobrepostas: cada pedaço começa 15 palavras antes do fim do anterior</text><path d=\"M370.0 214 V220 H402.4 V214\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><rect x=\"30.0\" y=\"172\" width=\"62.76190476190476\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"62.38095238095238\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 2</text><rect x=\"46.19047619047619\" y=\"194\" width=\"192.28571428571428\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"143.33333333333334\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 3</text><rect x=\"191.9047619047619\" y=\"172\" width=\"192.2857142857143\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"289.04761904761904\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 4</text><rect x=\"337.6190476190476\" y=\"194\" width=\"192.28571428571433\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"434.76190476190476\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 5</text><rect x=\"483.3333333333333\" y=\"172\" width=\"192.28571428571428\" height=\"16\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"580.4761904761905\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pedaço 6</text><text x=\"94.76190476190476\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">palavra 150</text><text x=\"256.66666666666663\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">palavra 200</text><text x=\"418.57142857142856\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">palavra 250</text><text x=\"580.4761904761905\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">palavra 300</text><text x=\"386.1904761904762\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">\"Select the books you are sending back and a reason.\"</text></svg>", "caption": "Os mesmos pedaços de 60 palavras com e sem sobreposição. O colchete âmbar marca as palavras 235 a 244, uma frase: cortada em duas na palavra 240 quando os pedaços ficam encostados, inteira dentro do pedaço 5 quando cada pedaço começa 15 palavras antes. Os pedaços são numerados a partir de 0, como o boundaries.py os numera.", "same": ["\"Select the books you are sending back and a reason.\""]}
```

## O que custa

O mesmo regulamento agora rende 20 pedaços em vez de 15. Cada pedaço continua com 60 palavras, então um
quarto de cada pedaço repete o vizinho: o índice guarda um terço a mais de pedaços, a conta de
embeddings fica um terço maior, e a busca compara a pergunta com um terço a mais de vetores. Para um
regulamento isso não é nada; para um corpus de milhões de páginas é um terço a mais de armazenamento e
de tempo de reindexação, os custos que a aula 18 do `embeddings-vectors` mediu.

Também muda o que a recuperação devolve. Dois pedaços vizinhos têm quinze palavras em comum, então uma
pergunta cuja resposta está na sobreposição pode recuperar os dois, e o prompt passa a levar as mesmas
frases duas vezes. A aula 12 tira duplicatas assim antes de montar o prompt.

## O que compra

A tabela no fim desta aula mede cada estratégia contra as 26 perguntas com resposta do conjunto de
teste, contando uma pergunta como achada quando a frase que a responde está dentro de um dos três
pedaços recuperados. Duas linhas dela pertencem aqui:

| estratégia | pedaços | achadas |
| --- | --- | --- |
| fixo, 60 palavras | 116 | 19 de 26 |
| fixo, 60 palavras, 15 sobrepostas | 150 | 22 de 26 |

**A sobreposição achou quatro respostas a mais de 26**, por 34 pedaços a mais no corpus. É a melhoria mais
barata que o corte de tamanho fixo pode ter, e o conselho comum é uma sobreposição de 10 a 20 por cento
do tamanho do pedaço. Continua sendo um remendo num corte feito sem olhar. A próxima seção para de fazer
cortes assim.
