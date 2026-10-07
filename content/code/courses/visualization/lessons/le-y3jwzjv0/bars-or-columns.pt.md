---
title: Barras ou colunas
version: 1
---

As palavras são usadas de forma solta, e este curso as usa com precisão: uma **coluna** fica em pé
sobre uma base horizontal, e uma **barra** fica deitada ao longo de uma base vertical. As duas
codificam o número como comprimento a partir de um começo comum, então as duas ficam no segundo
degrau da escada da aula 2. A escolha entre elas depende de todo o resto do gráfico, e sobretudo dos
**rótulos**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 260\" role=\"img\" data-fig=\"l03-columns-vs-bars\" aria-label=\"Os mesmos cinco totais regionais desenhados como colunas e como barras. Nas colunas à esquerda, os nomes das regiões têm de ser inclinados para caber embaixo das colunas estreitas e são lidos de lado. Nas barras à direita, cada nome fica na horizontal ao lado da sua barra.\"><path d=\"M60.0 24.9 h28.0 v155.1 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"78.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 78.0 190.0)\" fill=\"var(--paper)\">Sudeste</text><path d=\"M102.0 100.2 h28.0 v79.8 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"120.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 120.0 190.0)\" fill=\"var(--paper)\">Nordeste</text><path d=\"M144.0 110.1 h28.0 v69.9 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"162.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 162.0 190.0)\" fill=\"var(--paper)\">Sul</text><path d=\"M186.0 147.2 h28.0 v32.8 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"204.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 204.0 190.0)\" fill=\"var(--paper)\">Centro-Oeste</text><path d=\"M228.0 156.3 h28.0 v23.7 h-28.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"246.0\" y=\"190.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" transform=\"rotate(-40 246.0 190.0)\" fill=\"var(--paper)\">Norte</text><path d=\"M50.0 180.0 L270.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"440.0\" y=\"30.0\" width=\"164.8\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"41.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Sudeste</text><rect x=\"440.0\" y=\"62.0\" width=\"84.8\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"73.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Nordeste</text><rect x=\"440.0\" y=\"94.0\" width=\"74.2\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"105.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Sul</text><rect x=\"440.0\" y=\"126.0\" width=\"34.9\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"137.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Centro-Oeste</text><rect x=\"440.0\" y=\"158.0\" width=\"25.2\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"169.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Norte</text><path d=\"M440.0 26.0 L440.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "As colunas deixam para os nomes a largura de uma coluna; as barras dão a eles a margem inteira. Com mais de um punhado de categorias, ou nomes longos, deite o gráfico."}
```

## Deite o gráfico quando os nomes forem longos

Uma coluna tem a largura do espaço dividido pelo número de categorias, e o rótulo tem de caber
nessa largura. Com cinco nomes curtos, cabe. Com "Centro-Oeste" já não cabe, e o salvamento de
sempre é inclinar os rótulos, o que deixa cada um deles mais lento de ler. Com vinte nomes de
produto, não tem jeito.

Uma barra dá a cada rótulo a margem esquerda inteira, na horizontal, na direção em que as pessoas
leem. Então:

- **muitas categorias** (mais de umas sete): barras;
- **nomes longos**: barras;
- **um ranking**: barras, porque uma lista de cima para baixo é como as pessoas já leem rankings.

## Quando as colunas acertam

**As colunas acertam quando as categorias são passos no tempo.** Meses, trimestres e anos correm da
esquerda para a direita em todas as culturas que este curso deve alcançar, e um gráfico de colunas
com os pedidos por mês é lido como sequência porque o eixo horizontal é onde o tempo mora. Um
gráfico de barras dos mesmos meses, com janeiro no alto, é lido como lista.

As colunas também servem quando há poucas categorias curtas e o gráfico fica num espaço largo e
baixo, como uma linha de um painel (aula 18).

## Uma nota sobre largura e espaços

**O espaço entre as barras diz que as categorias são separadas.** Um espaço de metade a dois terços
da largura da barra fica confortável. O histograma é o único gráfico parecido com barras que não tem
espaços, porque as barras dele são intervalos vizinhos de uma única quantidade contínua (aula 5).
Tirar os espaços de um gráfico de barras comum o faz parecer um histograma, e os leitores vão
procurar uma distribuição que não existe.
