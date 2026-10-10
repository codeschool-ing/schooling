---
title: PROCV, e suas três armadilhas
version: 1
---

**`PROCV` (`VLOOKUP` no Excel em inglês) é a busca em que a maioria das pastas de trabalho existentes
se apoia, e ela falha em silêncio de três jeitos que o `PROCX` foi feito para eliminar.** Você vai
encontrá-la em todo arquivo com mais de alguns anos, e em arquivos de quem aprendeu Excel antes de
2021, então precisa saber lê-la e saber onde ela quebra, mesmo que prefira não escrevê-la.

## Como se escreve

O `PROCV` recebe a chave, uma tabela inteira cuja **primeira coluna** é onde se procura, o **número**
da coluna a trazer, contado a partir da esquerda dessa tabela, e um quarto argumento sobre a
correspondência. O preço de tabela da S1001:

```localised
=PROCV(D2;Products!$A$2:$G$7;6;FALSO)
```

A resposta é **118**, a mesma do `PROCX`. O 6 é `List price`, contando de A a G: `Code` 1, `Product`
2, `Origin` 3, `Roast` 4, `Grams` 5, `List price` 6. O `FALSO` pede uma correspondência exata.

## Armadilha 1: a coluna é um número

O 6 não é uma referência. É uma contagem, digitada uma vez, e nada a atualiza. Suponha que alguém
insira uma coluna em `Products` à esquerda de `List price`, digamos uma coluna `Supplier` depois de
`Grams`. A referência da tabela acompanha a inserção e vira `$A$2:$H$7`, mas o 6 continua 6, e a
coluna 6 agora é a nova `Supplier`, vazia. Todo preço de tabela trazido pela fórmula vira **0**.
Nenhum erro: zero é um número, e uma coluna de zeros soma sem reclamar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l04-shifted\" aria-label=\"Duas cópias da linha de cabeçalho de Products, contadas a partir de 1 embaixo de cada coluna. Antes: Code, Product, Origin, Roast, Grams, List price, Unit cost, e o número de coluna 6 do PROCV aponta para List price. Depois que uma coluna Supplier é inserida depois de Grams, o número 6 aponta para a nova coluna Supplier, vazia, e List price virou a coluna 7.\"><text x=\"12.0\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">antes</text><rect x=\"60.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"66.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Code</text><rect x=\"134.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"140.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Product</text><rect x=\"208.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"214.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Origin</text><rect x=\"282.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Roast</text><rect x=\"356.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"362.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Grams</text><rect x=\"430.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"436.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">List price</text><rect x=\"504.0\" y=\"50.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"510.0\" y=\"63.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Unit cost</text><text x=\"97.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"171.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><text x=\"245.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"319.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text><text x=\"393.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5</text><text x=\"467.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">6</text><text x=\"541.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7</text><text x=\"12.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">depois</text><rect x=\"60.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"66.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Code</text><rect x=\"134.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"140.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Product</text><rect x=\"208.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"214.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Origin</text><rect x=\"282.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"288.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Roast</text><rect x=\"356.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"362.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Grams</text><rect x=\"430.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"436.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">Supplier</text><rect x=\"504.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"510.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">List price</text><rect x=\"578.0\" y=\"150.0\" width=\"74.0\" height=\"26.0\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"584.0\" y=\"163.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Unit cost</text><text x=\"97.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">1</text><text x=\"171.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2</text><text x=\"245.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">3</text><text x=\"319.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">4</text><text x=\"393.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">5</text><text x=\"467.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">6</text><text x=\"541.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">7</text><text x=\"615.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">8</text><text x=\"60.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">PROCV(…; 6; FALSO) traz List price</text><text x=\"60.0\" y=\"220.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">o mesmo 6 agora traz a Supplier vazia: 0 em toda linha</text></svg>", "caption": "O número da coluna é uma contagem digitada uma vez. Insira uma coluna dentro da tabela e a contagem aponta para outro campo, sem erro nenhum."}
```

Uma fórmula de `PROCX` ou de `ÍNDICE` apontada para `Products!$F$2:$F$7` é uma referência, e inserir
uma coluna a move para `G`, para onde os preços foram. Experimente numa cópia, ou desfaça a inserção
na hora.

## Armadilha 2: o padrão é a correspondência errada

O quarto argumento é opcional, e quando fica de fora quer dizer `VERDADEIRO`: uma correspondência
**aproximada**. A correspondência aproximada supõe que a primeira coluna está em ordem crescente e
devolve a linha da maior chave que não passa da que você pediu. Os códigos de produto não estão em
ordem. Em chaves fora de ordem, uma correspondência aproximada pode cair numa linha que só está perto
na ordem alfabética: algumas linhas saem certas, outras levam o preço de um vizinho, e não há erro
nenhum dizendo qual é qual.

Então o `PROCV` para um código sempre se escreve com `FALSO` no fim. A seção 06 mostra onde a
correspondência aproximada é exatamente o que você quer, numa tabela feita para ela.

## Armadilha 3: ela não olha para a esquerda

A coluna em que se procura é sempre a primeira da tabela, então o valor trazido está sempre à direita
dela. Perguntado qual código pertence a `Decaf 250 g`, o `PROCV` teria de procurar na coluna B e
trazer a coluna A, e não consegue. O remendo de sempre era copiar a coluna de códigos para a direita
dos nomes, uma segunda cópia dos dados que se afasta da primeira. O `PROCX` e o `ÍNDICE` com
`CORRESP` procuram em qualquer coluna e trazem qualquer outra.

## Quando ainda se escreve

Escreva `PROCV` quando a pasta de trabalho for aberta num Excel anterior a 2021, onde o `PROCX` dá
`#NOME?`, ou quando estiver ampliando um arquivo já construído sobre ela e a consistência importar
mais. Nos dois casos, escreva os quatro argumentos, e prefira `ÍNDICE` e `CORRESP`, a próxima seção,
que funcionam em qualquer versão e não têm nenhuma das três armadilhas.

O `PROCH` (`HLOOKUP`) é a mesma função deitada: procura na primeira **linha** de uma tabela e traz um
valor de uma linha abaixo. Tem as mesmas três armadilhas, e numa planilha de uma linha por registro
você raramente vai precisar dela.
