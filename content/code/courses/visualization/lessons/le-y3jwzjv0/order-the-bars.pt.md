---
title: A ordem das barras
version: 1
---

Um gráfico de barras tem um canal livre que as pessoas esquecem que é canal: **a ordem das barras**.
O programa o preenche por padrão, quase sempre em ordem alfabética ou na ordem do dado, e o padrão
quase nunca combina com a pergunta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 660 230\" role=\"img\" data-fig=\"l03-sorted\" aria-label=\"Dois gráficos de barras dos totais regionais de 2025. À esquerda as regiões estão em ordem alfabética, Centro-Oeste, Nordeste, Norte, Sudeste, Sul, e o olho ziguezagueia para ordená-las. À direita estão ordenadas do Sudeste, o maior, ao Norte, o menor, e o ranking é a própria figura.\"><text x=\"20.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ordem alfabética</text><rect x=\"110.0\" y=\"40.0\" width=\"39.0\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"50.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Centro-Oeste</text><rect x=\"110.0\" y=\"71.0\" width=\"94.8\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"81.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Nordeste</text><rect x=\"110.0\" y=\"102.0\" width=\"28.1\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"112.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Norte</text><rect x=\"110.0\" y=\"133.0\" width=\"184.2\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"143.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Sudeste</text><rect x=\"110.0\" y=\"164.0\" width=\"82.9\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"102.0\" y=\"174.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Sul</text><path d=\"M110.0 36.0 L110.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"350.0\" y=\"16.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ordenado pelo valor</text><rect x=\"440.0\" y=\"40.0\" width=\"184.2\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"50.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Sudeste</text><rect x=\"440.0\" y=\"71.0\" width=\"94.8\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"81.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Nordeste</text><rect x=\"440.0\" y=\"102.0\" width=\"82.9\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"112.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Sul</text><rect x=\"440.0\" y=\"133.0\" width=\"39.0\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"143.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Centro-Oeste</text><rect x=\"440.0\" y=\"164.0\" width=\"28.1\" height=\"21.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"432.0\" y=\"174.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Norte</text><path d=\"M440.0 36.0 L440.0 196.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path></svg>", "caption": "A ordem alfabética ajuda quem procura um nome e não ajuda ninguém a comparar. Ordenado pelo valor, o gráfico responde \"qual é o maior, qual é o segundo\" antes da pergunta."}
```

Na ordem alfabética o olho tem de pular: o Sudeste é o quarto, o Nordeste é o segundo, e achar a
segunda maior região exige comparar cada barra com todas as outras. **Ordenado pelo valor, o
ranking é a própria figura.** O Sudeste vem primeiro, o Nordeste em segundo, e a distância entre
eles, que é o tamanho da vantagem do Sudeste, aparece como o degrau entre as duas primeiras barras.

## Em que sentido ordenar

- **A maior no alto** nas barras, porque as pessoas leem para baixo e a primeira coisa lida deve
  ser a primeira do ranking.
- **A maior à esquerda** nas colunas, pelo mesmo motivo na outra direção.
- **Mantenha a mesma ordem em gráficos relacionados.** Se um gráfico põe o Sudeste primeiro, o
  próximo gráfico sobre as mesmas regiões também deve pôr, mesmo que os números dele ordenassem de
  outro jeito; senão o leitor tem de achar cada região de novo.

## Quando não ordenar pelo valor

**Algumas categorias têm uma ordem própria, e ela ganha.** Meses, horas do dia, faixas de idade, a
satisfação de "muito insatisfeito" a "muito satisfeito", as etapas de um funil: ordenar essas pelo
valor destrói a sequência de que o leitor precisa. Um gráfico de colunas de pedidos por mês ordenado
pelo tamanho é um quebra-cabeça, e não um gráfico.

Uma ordem própria é o caso de *pequeno, médio, grande* da aula 1: categorias ordenadas, entre um
nome e uma quantidade. A regra é **manter a ordem que as categorias já têm**, e ordenar pelo valor só
quando não têm nenhuma.

## E o "outros"

Quando uma cauda longa de categorias pequenas é juntada em "Outros", ponha Outros **por último**,
seja qual for o tamanho. Não é uma categoria como as outras, e um leitor que o veja em segundo lugar
vai achar que é.
