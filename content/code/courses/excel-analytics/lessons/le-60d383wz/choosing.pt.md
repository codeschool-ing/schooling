---
title: Escolhendo o gráfico pela pergunta
version: 1
---

**Um gráfico se escolhe pela pergunta que ele responde, nunca pela galeria.** O **Inserir ›
Gráficos Recomendados** do Excel olha a forma do intervalo selecionado e oferece o que combina com
essa forma. Ele não tem como saber o que o leitor deve ver, e os mesmos seis números podem ser
desenhados de um jeito que mostra a resposta ou de um jeito que a esconde.

Cinco perguntas cobrem quase tudo o que se pede a um gráfico de negócio:

| a pergunta | a forma | na Café Serra |
|---|---|---|
| como estes valores se comparam? | barras ou colunas, ordenadas | receita por produto |
| como isto mudou com o tempo? | uma linha, ou colunas para poucos períodos | receita por mês |
| que parte do todo é cada pedaço? | uma barra só dividida em partes, ou uma pizza quando são duas ou três partes bem diferentes | receita por canal |
| duas medidas andam juntas? | uma dispersão, um ponto por registro | sacos contra preço, venda a venda |
| qual é o número? | gráfico nenhum: uma célula, escrita grande | receita total |

## A pizza, posta à prova

A receita dos seis produtos é a pizza clássica. Aqui está ela ao lado dos mesmos números em barras:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 760 330\" role=\"img\" data-fig=\"l12-pie-bar\" aria-label=\"A receita dos seis produtos desenhada duas vezes. À esquerda, uma pizza: as duas maiores fatias, CER1K com 41.5% e SUL1K com 40.9%, parecem do mesmo tamanho. À direita, os mesmos valores em barras ordenadas da maior para a menor, a partir do zero, com o valor na ponta de cada barra: CER1K 21356, SUL1K 21082, e os outros quatro bem abaixo.\"><text x=\"40.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">uma pizza: qual fatia é maior?</text><path d=\"M170 175 L170.0 60.0 A115 115 0 0 1 228.7 273.9 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--phosphor)\"></path><text x=\"298.3\" y=\"139.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">CER1K</text><path d=\"M170 175 L228.7 273.9 A115 115 0 0 1 67.3 123.3 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--amber)\"></path><text x=\"79.3\" y=\"272.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">SUL1K</text><path d=\"M170 175 L67.3 123.3 A115 115 0 0 1 99.2 84.4 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--wire)\"></path><path d=\"M170 175 L99.2 84.4 A115 115 0 0 1 141.1 63.7 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--wire)\"></path><path d=\"M170 175 L141.1 63.7 A115 115 0 0 1 158.3 60.6 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--wire)\"></path><path d=\"M170 175 L158.3 60.6 A115 115 0 0 1 170.0 60.0 Z\" stroke=\"var(--ink)\" stroke-width=\"2\" fill=\"var(--wire)\"></path><text x=\"40.0\" y=\"316.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">as quatro fatias pequenas juntas: 17,6%</text><text x=\"400.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">barras, ordenadas, a partir do zero</text><path d=\"M470.0 52.0 L470.0 280.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"462.0\" y=\"71.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CER1K</text><path d=\"M470.0 60.0 L666.0 60.0 Q670.0 60.0 670.0 64.0 L670.0 78.0 Q670.0 82.0 666.0 82.0 L470.0 82.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor)\"></path><text x=\"676.0\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">21.356</text><text x=\"462.0\" y=\"109.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SUL1K</text><path d=\"M470.0 98.0 L663.4 98.0 Q667.4 98.0 667.4 102.0 L667.4 116.0 Q667.4 120.0 663.4 120.0 L470.0 120.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--amber)\"></path><text x=\"673.4\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">21.082</text><text x=\"462.0\" y=\"147.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">DEC250</text><path d=\"M470.0 136.0 L499.9 136.0 Q503.9 136.0 503.9 140.0 L503.9 154.0 Q503.9 158.0 499.9 158.0 L470.0 158.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"509.9\" y=\"147.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3.622</text><text x=\"462.0\" y=\"185.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">MOG250</text><path d=\"M470.0 174.0 L497.4 174.0 Q501.4 174.0 501.4 178.0 L501.4 192.0 Q501.4 196.0 497.4 196.0 L470.0 196.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"507.4\" y=\"185.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">3.354</text><text x=\"462.0\" y=\"223.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SUL250</text><path d=\"M470.0 212.0 L477.6 212.0 Q481.6 212.0 481.6 216.0 L481.6 230.0 Q481.6 234.0 477.6 234.0 L470.0 234.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"487.6\" y=\"223.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">1.243</text><text x=\"462.0\" y=\"261.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">CER250</text><path d=\"M470.0 250.0 L473.9 250.0 Q477.8 250.0 477.8 253.9 L477.8 268.1 Q477.8 272.0 473.9 272.0 L470.0 272.0 Z\" stroke=\"none\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"483.8\" y=\"261.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">837</text><text x=\"400.0\" y=\"316.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CER1K passa SUL1K por R$ 274, o que a pizza não consegue mostrar</text></svg>", "caption": "Os mesmos seis números como pizza e como barras ordenadas. O olho compara comprimentos sobre uma mesma linha de base muito melhor que ângulos, então as barras mostram o que a pizza esconde: qual produto lidera, e por quão pouco."}
```

`CER1K` traz 41,5% da receita e `SUL1K`, 40,9%. Na pizza as duas fatias parecem iguais, e ninguém
consegue dizer qual é maior. Uma fórmula diz na hora:

```localised
=SOMASES(Sales[Revenue]; Sales[Product]; "CER1K")-SOMASES(Sales[Revenue]; Sales[Product]; "SUL1K")
```

Ela, com `SOMASES` (`SUMIFS` no Excel em inglês), responde 274: `CER1K` lidera por R$ 274 em
R$ 51.494. **O olho compara bem comprimentos sobre uma mesma linha de base e compara mal ângulos**,
então nas barras a vantagem aparece, ainda que pequena, e os quatro produtos pequenos ficam legíveis
em vez de quatro lascas. Ordenar as barras da maior para a menor faz por quem lê o primeiro trabalho
dele.

Uma pizza se defende com duas ou três partes bem diferentes. A receita por canal é uma: atacado
75,2%, online 21,6%, balcão 3,1%. Mesmo aí uma barra faz o serviço igualmente bem, e as próximas
seções usam barras.

## Barras, colunas e linhas

Barras correm na horizontal e colunas ficam em pé; mostram a mesma coisa. Use **barras** quando os
nomes das categorias são longos ou muitos, porque aí os nomes ficam cada um na sua linha, e
**colunas** quando as categorias são períodos de tempo, que o leitor espera ver correndo da esquerda
para a direita.

**Uma linha liga os pontos, e ligá-los afirma uma ordem e um caminho de um ao seguinte.** Os meses
vêm um depois do outro, então a receita por mês é uma linha. Os produtos não têm ordem nenhuma, e uma
linha passando pelos seis desenharia uma tendência de `CER1K` a `CER250` que não existe.

## Uma dispersão, para duas medidas de uma vez

Uma dispersão põe um ponto por registro: aqui, cada uma das 108 vendas, com os sacos na horizontal e
o preço na vertical. É a forma da pergunta "estas duas andam juntas?", e nos dados da Café Serra ela
mostra duas nuvens. Estas duas fórmulas medem onde elas se encontram:

```localised
=MÍNIMOSES(Sales[Bags]; Sales[Channel]; "Wholesale")
=MÁXIMOSES(Sales[Bags]; Sales[Channel]; "<>Wholesale")
```

Nenhuma venda de atacado tem menos de **4** sacos, e nenhuma venda online ou de balcão tem mais de
**5**. `MÍNIMOSES` e `MÁXIMOSES` são `MINIFS` e `MAXIFS` no Excel em inglês. Os dois grupos se tocam
em 4 e 5 sacos e em nenhum outro lugar.

## E às vezes gráfico nenhum

"Qual foi a receita?" tem uma resposta, R$ 51.494, e um gráfico de um número só é uma barra sem nada
com que se comparar. Escreva o número numa célula, grande, com o que ele é ao lado. A aula 17 monta
essas células para o painel.
