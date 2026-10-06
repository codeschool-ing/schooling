---
title: Vinte testes sobre nada
version: 1
---

Um nível de significância de 5% significa que, quando a hipótese nula é verdadeira, 5% dos testes a rejeitam
mesmo assim. Um teste de cada vez, é um risco sensato. Muitos testes de uma vez, é quase certeza de ser
enganado.

## Vinte ajustes que não fazem nada

Imagine que a equipe de marketing da Horta experimenta vinte pequenas mudanças no site — uma cor de botão
nova, uma foto diferente, uma oferta reescrita — e para cada uma compara as cestas de 50 visitantes que
viram a mudança com as de 50 que não viram. Suponha que nenhuma das mudanças faça nada. Cada teste tem 5% de
chance de um resultado "significativo" por acidente.

A chance de **pelo menos um** dos vinte sair significativo é

```localised
1 − 0,95^20 = 0,64
```

Quase duas chances em três de uma "descoberta", com mudanças que não fazem nada.

Para ver isso, aqui estão 1.000 lotes simulados de 20 testes assim, cada teste comparando dois grupos de 50
cestas tirados das mesmas 400, para que toda nula seja verdadeira:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 270\" role=\"img\" data-fig=\"l14-batches\" aria-label=\"Um gráfico de barras de 1.000 lotes de 20 testes, cada teste comparando dois grupos que só diferem por acaso. 372 lotes não tiveram nenhum resultado significativo, 394 tiveram um, 174 tiveram dois, 47 tiveram três e 13 tiveram quatro ou mais. Pontos mostram o que a distribuição binomial prevê, e ficam perto das barras.\"><path d=\"M70.0 50.0 L70.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M66.0 210.0 L70.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"210.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M70.0 174.4 L570.0 174.4\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 174.4 L70.0 174.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"174.4\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">100</text><path d=\"M70.0 138.9 L570.0 138.9\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 138.9 L70.0 138.9\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"138.9\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">200</text><path d=\"M70.0 103.3 L570.0 103.3\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 103.3 L70.0 103.3\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"103.3\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">300</text><path d=\"M70.0 67.8 L570.0 67.8\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><path d=\"M66.0 67.8 L70.0 67.8\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"62.0\" y=\"67.8\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">400</text><text x=\"70.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">lotes</text><path d=\"M98.8 210.0 L98.8 77.7 L156.5 77.7 L156.5 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"127.7\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">0</text><circle cx=\"127.7\" cy=\"82.5\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M195.0 210.0 L195.0 69.9 L252.7 69.9 L252.7 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"223.8\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">1</text><circle cx=\"223.8\" cy=\"75.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M291.2 210.0 L291.2 148.1 L348.8 148.1 L348.8 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"320.0\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">2</text><circle cx=\"320.0\" cy=\"142.9\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M387.3 210.0 L387.3 193.3 L445.0 193.3 L445.0 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"416.2\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">3</text><circle cx=\"416.2\" cy=\"188.8\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M483.5 210.0 L483.5 205.4 L541.2 205.4 L541.2 210.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"512.3\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">4+</text><circle cx=\"512.3\" cy=\"204.3\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><path d=\"M70.0 210.0 L570.0 210.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"320.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">testes do lote com p abaixo de 0,05</text><path d=\"M380 30 L394 30 L394 42 L380 42 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"400.0\" y=\"36.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">lotes simulados</text><circle cx=\"387.0\" cy=\"56.0\" r=\"4.5\" fill=\"var(--amber)\" stroke=\"var(--paper)\" stroke-width=\"0.8\"></circle><text x=\"400.0\" y=\"56.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">binomial, 20 testes a 5%</text></svg>", "caption": "Rode vinte testes sobre nada, e na maior parte das vezes pelo menos um sai \"significativo\". Em 628 dos 1.000 lotes, alguém teria tido uma descoberta."}
```

Em **628 dos 1.000 lotes**, pelo menos um teste foi significativo. Nos 20.000 testes, 936 foram
significativos: 4,7%, perto dos 5% que o nível de significância promete. Todo teste se comportou
corretamente, e a equipe que rodasse vinte deles quase sempre teria um resultado para anunciar.

## Como acontece sem ninguém trapacear

Ninguém precisa falsificar nada. Basta:

- testar muitos resultados e informar o que saiu significativo;
- testar muitos subgrupos — por bairro, por dia, por aparelho — e informar o que funcionou;
- experimentar vários jeitos de tratar valores atípicos e ficar com o que dá o menor p;
- continuar coletando dados e testar depois de cada lote, parando quando p cair abaixo de 0,05.

Cada escolha parece razoável sozinha. Juntas, elas se chamam **p-hacking**, ou "jardim dos caminhos que se
bifurcam", e transformam uma taxa de alarmes falsos de 5% em algo muito maior.

## As defesas

**Decida antes.** Escreva a hipótese, o resultado, o teste e o tamanho da amostra antes de coletar os
dados. A aula 9 defendeu o mesmo sobre valores atípicos: uma decisão tomada antes do resultado não tem como
derivar na direção dele.

**Informe tudo o que testou.** "Um dos vinte ajustes chegou a p = 0,03" é uma descoberta muito diferente de
"o botão novo chegou a p = 0,03", e quem lê precisa saber qual das duas está lendo.

**Ajuste para testes múltiplos.** A correção mais simples, que leva o nome do matemático Carlo Emilio
**Bonferroni**, divide α pelo número de testes. Para 20 testes com 5% no total, cada teste precisa chegar a
p < 0,05 ÷ 20 = **0,0025**. É conservadora, e mantém a chance de qualquer alarme falso no lote perto de 5%.

**Replique.** Um efeito real aparece de novo em dados novos. Um alarme falso em geral não.
