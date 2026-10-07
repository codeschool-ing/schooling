---
title: Marcas e canais
version: 1
---

Uma tabela de números pede ao leitor que faça contas. Um gráfico pede que ele olhe. A **codificação
visual** é a tradução entre as duas coisas: cada número do dado vira uma propriedade de algo
desenhado, e o olho lê essa propriedade de volta como o número.

Duas palavras carregam a ideia toda, e o resto do curso usa as duas o tempo inteiro.

- Uma **marca** é o que se desenha para cada item do dado: um ponto, uma barra, uma linha, uma área,
  um símbolo num mapa.
- Um **canal** é a propriedade da marca que muda com o dado: onde ela fica, qual o comprimento, o
  tamanho, o ângulo, a cor, a forma.

As palavras vêm de *Visualization Analysis and Design* (2014), de Tamara Munzner, que as construiu
sobre a *Semiologia Gráfica* (1967) de Jacques Bertin. Bertin chamava os canais de *variáveis
visuais*. A ideia não mudou em sessenta anos porque não depende do programa.

## Um gráfico, desmontado

Estes são os pedidos da Horta em 2025, uma barra por região. A Horta é um mercado online inventado,
e todo número deste curso vem dos dados dela.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 640 300\" role=\"img\" data-fig=\"l01-anatomy\" aria-label=\"Um gráfico de barras dos pedidos da Horta em 2025 por região, do Sudeste com 77.567 até o Norte com 11.852, com três notas apontando para ele. Uma aponta para uma barra: a marca. Uma aponta ao longo do comprimento da barra: o canal que carrega o número. Uma aponta para a coluna de nomes das regiões: a posição que diz qual barra é qual região.\"><defs><marker id=\"vz-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"120.0\" y=\"50.0\" width=\"300.6\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"61.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Sudeste</text><rect x=\"120.0\" y=\"84.0\" width=\"154.7\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Nordeste</text><rect x=\"120.0\" y=\"118.0\" width=\"135.3\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"129.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Sul</text><rect x=\"120.0\" y=\"152.0\" width=\"63.6\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Centro-Oeste</text><rect x=\"120.0\" y=\"186.0\" width=\"45.9\" height=\"22.0\" rx=\"1\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"112.0\" y=\"197.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Norte</text><path d=\"M120.0 220.0 L430.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M120.0 220.0 L120.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"120.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0</text><path d=\"M197.5 220.0 L197.5 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"197.5\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20</text><path d=\"M275.0 220.0 L275.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"275.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40</text><path d=\"M352.5 220.0 L352.5 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"352.5\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">60</text><path d=\"M430.0 220.0 L430.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"430.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">80</text><text x=\"275.0\" y=\"251.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pedidos em 2025 (milhares)</text><path d=\"M120.0 44.0 L120.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M470.0 61.0 L424.6 61.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-amber)\"></path><text x=\"474.0\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">marca: uma barra por região</text><path d=\"M124.0 113.0 L270.7 113.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-amber)\"></path><text x=\"286.7\" y=\"113.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">canal: comprimento, lido contra o eixo</text><text x=\"20.0\" y=\"276.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">canal: a posição na vertical diz a região</text><path d=\"M80.0 266.0 L88.0 208.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-amber)\"></path></svg>", "caption": "Todo gráfico é marcas e canais. Aqui a marca é uma barra, o comprimento de cada barra carrega o número, e o lugar da barra na coluna diz a que região ela pertence."}
```

Três coisas acontecem nessa figura, e dar nome a elas é a primeira habilidade do curso:

- **A marca é uma barra.** Há uma por região, então uma barra *é* uma região.
- **O comprimento da barra carrega o número.** A barra do Sudeste tem mais ou menos o dobro do
  comprimento da do Nordeste porque o Sudeste teve mais ou menos o dobro dos pedidos: 77.567 contra
  39.924.
- **A posição da barra na vertical diz qual região ela é.** Aqui a posição separa categorias em vez
  de medir alguma coisa, e o nome ao lado da barra a torna legível.

## Por que a distinção importa

Um erro num gráfico é quase sempre um erro sobre um canal. Um gráfico de barras cujo eixo começa
em 70.000 quebrou a ligação entre comprimento e número (aula 3). Uma pizza com oito fatias pede ao
olho que compare ângulos, que ele lê mal (aula 2). Um mapa pintado do claro ao escuro pela
*contagem* de pedidos mostra, no fundo, onde as pessoas moram (aula 8).

**Cada um desses gráficos desenha certo e mesmo assim engana.** Aprender a ver marcas e canais é
como você os pega antes que alguém tome uma decisão com base num deles, seja o gráfico seu ou de
outra pessoa.
