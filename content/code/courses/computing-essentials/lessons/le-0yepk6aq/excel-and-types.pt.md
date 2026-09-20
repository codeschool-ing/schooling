---
title: O Excel, em que a dificuldade nunca é a aritmética
version: 1
---

O modelo do Excel são duas frases. **Uma célula guarda um valor.** **Uma fórmula é um valor
calculado a partir de outras células**, e ela recalcula sempre que uma delas muda.

Esse é o motor inteiro, e não é aí que está a dificuldade. A dificuldade é que **o Excel decide
que tipo de coisa você digitou no instante em que você aperta Enter**, pelo formato dos
caracteres, em silêncio, e às vezes ele erra.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro linhas, cada uma mostrando algo digitado numa célula, o que o programa decide que aquilo é, e o que a célula então mostra. Zero um dois três quatro vira um número e aparece como um dois três quatro. Três barra quatro vira uma data e aparece como data. Um E cinco vira um número e aparece como cem mil. Abaixo de um traço, a mesma primeira entrada precedida de um apóstrofo vira texto e aparece exatamente como foi digitada.\"><text x=\"24\" y=\"20\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">O que a célula decide, no instante em que você aperta Enter</text><text x=\"60\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que você digita</text><text x=\"290\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que ele decide que é</text><text x=\"520\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que a célula então mostra</text><rect x=\"48\" y=\"64\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"60\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">01234</text><path d=\"M206 80 L278 80 M270 75 L278 80 L270 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><text x=\"290\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um número</text><path d=\"M436 80 L508 80 M500 75 L508 80 L500 85\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><rect x=\"508\" y=\"64\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"520\" y=\"80\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">1234</text><rect x=\"48\" y=\"108\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"60\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">3/4</text><path d=\"M206 124 L278 124 M270 119 L278 124 L270 129\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><text x=\"290\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">uma data</text><path d=\"M436 124 L508 124 M500 119 L508 124 L500 129\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><rect x=\"508\" y=\"108\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"520\" y=\"124\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">3/abr</text><rect x=\"48\" y=\"152\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"60\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">1E5</text><path d=\"M206 168 L278 168 M270 163 L278 168 L270 173\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><text x=\"290\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um número</text><path d=\"M436 168 L508 168 M500 163 L508 168 L500 173\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><rect x=\"508\" y=\"152\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"520\" y=\"168\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--amber)\">100000</text><path d=\"M48 206 L672 206\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></path><rect x=\"48\" y=\"220\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.1\"></rect><text x=\"60\" y=\"236\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">'01234</text><path d=\"M206 236 L278 236 M270 231 L278 236 L270 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><text x=\"290\" y=\"236\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">texto</text><path d=\"M436 236 L508 236 M500 231 L508 236 L500 241\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.1\"></path><rect x=\"508\" y=\"220\" width=\"150\" height=\"32\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"520\" y=\"236\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">01234</text><text x=\"24\" y=\"282\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Nada avisa. A entrada é aceita, a célula parece razoável, e o valor não é o que você digitou.</text></svg>", "caption": "O apóstrofo é o conserto inteiro, e ele não aparece na célula. Formatar a coluna como texto antes faz o mesmo serviço para a coluna toda."}
```

## Os quatro tipos, e como distingui-los

| | o que é | como dá para saber |
|---|---|---|
| **número** | uma quantidade | encosta à direita da célula por padrão |
| **texto** | caracteres | encosta à esquerda |
| **data e hora** | um número de dias desde 1900, vestido | à direita, e faz aritmética que você não esperava |
| **booleano** | `VERDADEIRO` ou `FALSO` | centralizado |

**O alinhamento é o diagnóstico de graça.** Uma coluna de números com uma entrada grudada na
borda esquerda é uma coluna com um pedaço de texto dentro, e toda `SOMA` daquela coluna está
silenciosamente pulando uma linha.

## As duas que estragam trabalho de verdade

**Zeros à esquerda somem.** CEPs, códigos de produto, números de conta, qualquer coisa em que
`007` e `7` sejam coisas diferentes. O Excel vê um número, e um número não tem zeros à esquerda.

**Coisas com cara de data viram datas.** `3/4` vira abril. `1-2` vira uma data. Um gene chamado
`SEP2` vira setembro. Uma medida escrita `2-3` vira três de fevereiro e não dá para desfazer,
porque **os caracteres originais sumiram** — a célula agora guarda um número de dia.

A segunda metade dessa frase é a parte que importa. Converter a coluna de volta para texto depois
te dá `45016`, não `2-3`. **Não há como desfazer depois de o arquivo ser salvo**, e é por isso que
esta é uma aula sobre o que fazer antes.

## Fazendo antes

- **Formate a coluna como Texto antes de digitar qualquer coisa nela.** A coluna inteira, uma vez,
  e toda entrada é mantida como caracteres.
- **Um apóstrofo na frente** — `'01234` — faz o mesmo para uma célula. O apóstrofo não é guardado
  e não é mostrado.
- **Ao importar um CSV, use a caixa de importação em vez de dar dois cliques no arquivo.** Ela
  deixa você marcar o tipo de cada coluna, e o duplo clique não pergunta.

Essa última é a que poupa tardes inteiras. Um CSV aberto com dois cliques é um CSV em que cada
palpite já foi dado.

## E a que é genuinamente um número e parece errada

`0,1 + 0,2` não dá exatamente `0,3` em planilha nenhuma, porque a máquina guarda frações em
binário e um décimo não é exato em binário — a mesma razão de um terço não ser exato em decimal.

O Excel esconde isso arredondando a exibição, e aparece quando um total que deveria ser zero sai
como `-0,000000000000001`. Não é defeito e há um conserto: **`ARRED` no resultado**, no ponto em
que uma pessoa lê, em vez de confiar na comparação.
