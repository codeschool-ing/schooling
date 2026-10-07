---
title: Bibliotecas de código
version: 1
---

Uma biblioteca de gráficos é um conjunto de funções que desenham gráficos quando um programa as chama.
Você usou uma por dezenove aulas. A maioria das linguagens usadas para dados tem várias:

| biblioteca | linguagem | conhecida por |
| --- | --- | --- |
| matplotlib | Python | a base; cada parte de um gráfico pode ser ajustada |
| seaborn | Python | gráficos estatísticos sobre o matplotlib, com padrões melhores |
| plotly | Python, R, JavaScript | gráficos interativos que abrem num navegador |
| Altair | Python | uma descrição curta de um gráfico que vira um gráfico Vega-Lite |
| ggplot2 | R | gráficos montados em camadas, a partir da *Grammar of Graphics* de Leland Wilkinson |
| D3.js | JavaScript | desenhar qualquer coisa no navegador, do zero |

Elas diferem no estilo. O **matplotlib** pede que você diga como desenhar: esta barra aqui, este
rótulo ali. O **ggplot2** e o **Altair** pedem que você diga o que o gráfico é: esta coluna no x,
aquela no y, esta como cor, e a biblioteca resolve o desenho. O segundo estilo é mais rápido para
gráficos comuns; o primeiro dá os últimos por cento de controle de que um gráfico publicado às vezes
precisa.

A diferença que mais importa nem está no desenho. Está em onde os passos ficam guardados:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 230\" role=\"img\" data-fig=\"l20-reproducible\" aria-label=\"Dois caminhos de um arquivo de dados até um gráfico. Em cima, por cliques numa planilha: os passos ficam na memória de alguém, e o gráfico do mês que vem é feito repetindo-os. Embaixo, por um script: os passos estão escritos num arquivo, e o gráfico do mês que vem é feito rodando-o de novo sobre o dado novo.\"><defs><marker id=\"vz-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"80.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monthly.csv</text><rect x=\"230.0\" y=\"40.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">doze cliques, de memória</text><rect x=\"480.0\" y=\"40.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"540.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gráfico</text><path d=\"M140.0 60.0 L228.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-paper-dim)\"></path><path d=\"M390.0 60.0 L478.0 60.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-paper-dim)\"></path><text x=\"310.0\" y=\"98.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">mês que vem: repetir os cliques</text><rect x=\"20.0\" y=\"150.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"80.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">monthly.csv</text><rect x=\"230.0\" y=\"150.0\" width=\"160.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">chart.py, salvo</text><rect x=\"480.0\" y=\"150.0\" width=\"120.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"540.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">gráfico</text><path d=\"M140.0 170.0 L228.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-paper-dim)\"></path><path d=\"M390.0 170.0 L478.0 170.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#vz-ah-paper-dim)\"></path><text x=\"310.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">mês que vem: rodar de novo</text></svg>", "caption": "A pergunta não é que ferramenta desenha melhor, mas onde os passos moram. Um passo escrito pode ser lido, revisado e rodado de novo; um passo lembrado sai um pouco diferente a cada vez."}
```

## O que o código dá

- **Os passos ficam escritos.** O programa é o registro completo de como o gráfico foi feito. Um
  colega pode lê-lo, questioná-lo e rodá-lo.
- **O gráfico pode ser feito de novo.** No mês que vem, rode o mesmo arquivo sobre o dado novo. A
  próxima seção mostra até onde vai "o mesmo".
- **Muitos gráficos são tão fáceis quanto um.** Um laço desenha doze pequenos múltiplos com uma escala
  comum.
- **Controle de versão.** Um script pode morar no Git, com cada mudança no gráfico registrada e
  reversível.

## O que ele custa

- **O primeiro gráfico demora mais.** Saber que função chamar e que argumento ajusta a cor exige um
  aprendizado que uma planilha não exige.
- **Interação dá trabalho.** Uma imagem estática é fácil; um painel com filtros precisa de um
  framework web por cima da biblioteca, e nesse ponto uma ferramenta de BI pode ser a escolha melhor.
- **Alguém precisa manter.** Um script que mais ninguém consegue ler é o mesmo problema de um painel
  numa ferramenta que mais ninguém tem.
