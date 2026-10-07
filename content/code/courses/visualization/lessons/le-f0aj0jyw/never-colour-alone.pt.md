---
title: Nunca só a cor
version: 1
---

Uma regra resolve quase toda esta aula, e é o critério de sucesso **1.4.1, Uso de Cor**, da WCAG: **a
cor não pode ser o único jeito de transmitir uma informação.** Se um leitor que não vê cor, ou vê as
cores erradas, não consegue entender a mensagem, o gráfico falhou, por melhor que seja a paleta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 460 230\" role=\"img\" data-fig=\"l14-redundant\" aria-label=\"O gráfico de Sul e Nordeste redesenhado para todos e mostrado como a deuteranopia o vê. O Sul é uma linha contínua e o Nordeste uma linha tracejada com pontos; o Nordeste é azul e não verde, então os dois ainda diferem no matiz; e cada linha tem o nome na ponta direita, então nenhuma legenda é necessária.\"><rect x=\"20.0\" y=\"20.0\" width=\"420.0\" height=\"190.0\" rx=\"4\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><path d=\"M40.0 164.2 L52.6 168.0 L65.2 159.2 L77.8 163.7 L90.4 159.7 L103.0 156.0 L115.7 170.5 L128.3 155.1 L140.9 149.6 L153.5 153.8 L166.1 151.8 L178.7 122.6 L191.3 151.3 L203.9 143.2 L216.5 145.4 L229.1 136.0 L241.7 146.2 L254.3 132.2 L267.0 139.6 L279.6 134.3 L292.2 129.0 L304.8 134.6 L317.4 132.2 L330.0 87.8\" stroke=\"#8b7c1f\" stroke-width=\"2.2\" fill=\"none\" stroke-linejoin=\"round\"></path><path d=\"M40.0 174.8 L52.6 176.7 L65.2 171.4 L77.8 169.0 L90.4 167.2 L103.0 160.9 L115.7 159.9 L128.3 159.8 L140.9 151.2 L153.5 149.7 L166.1 143.2 L178.7 118.8 L191.3 146.3 L203.9 136.6 L216.5 138.6 L229.1 129.6 L241.7 127.4 L254.3 121.8 L267.0 122.1 L279.6 114.2 L292.2 113.5 L304.8 102.0 L317.4 106.5 L330.0 56.0\" stroke=\"#456cb3\" stroke-width=\"2.2\" fill=\"none\" stroke-dasharray=\"6 4\" stroke-linejoin=\"round\"></path><circle cx=\"40.0\" cy=\"174.8\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"77.8\" cy=\"169.0\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"115.7\" cy=\"159.9\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"153.5\" cy=\"149.7\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"191.3\" cy=\"146.3\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"229.1\" cy=\"129.6\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"267.0\" cy=\"122.1\" r=\"3.2\" fill=\"#456cb3\"></circle><circle cx=\"304.8\" cy=\"102.0\" r=\"3.2\" fill=\"#456cb3\"></circle><text x=\"338.0\" y=\"93.8\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"#20263c\">Sul</text><text x=\"338.0\" y=\"52.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"#20263c\">Nordeste</text></svg>", "caption": "Três pistas em vez de uma: o matiz difere, o estilo da linha difere, e o nome fica na linha. Qualquer uma pode falhar e o gráfico ainda se lê."}
```

O gráfico é mostrado como a deuteranopia o vê, e ainda se lê, porque **três pistas carregam a
diferença** e qualquer uma delas basta:

- **o matiz difere**: o Nordeste é azul em vez de verde, e o azul sobrevive à deficiência
  vermelho-verde;
- **o estilo da linha difere**: o Sul é contínuo; o Nordeste é tracejado com pontos;
- **o nome está na linha**: cada série tem o rótulo na ponta direita, então nenhuma legenda precisa ser
  casada pela cor.

## Jeitos de acrescentar uma segunda pista

| gráfico | segunda pista |
|---|---|
| linhas | rótulos diretos nas pontas; tracejado, pontilhado; marcadores de formas diferentes |
| barras | rótulos sobre ou ao lado das barras; uma textura ou hachura numa série |
| dispersão | formas de marcador diferentes por grupo, como a aula 1 sugeriu |
| mapa | valores escritos nas áreas que importam; um segundo mapa em cinza |
| situação (bom, ruim) | um símbolo ou uma palavra: setas para cima e para baixo, "na meta", "atrasado" |

**Rótulos diretos são a mais forte delas**, porque tiram de vez a consulta pela cor: o leitor não
precisa distinguir duas cores se a linha diz o que ela é.

## O que isso não quer dizer

Não quer dizer que os gráficos devam ser cinza. A cor é o canal mais rápido que existe para a maioria
dos leitores, e as aulas 12 e 13 a usam de propósito. A regra pede **cor mais alguma coisa**, para que
a cor acelere a leitura de quem a vê e ninguém fique de fora quando ela falha.
