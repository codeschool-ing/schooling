---
title: Uma figura, e os eixos dentro dela
version: 1
---

**O matplotlib desenha numa `Figure`, a imagem inteira, que contém um ou mais `Axes`, cada um um
gráfico com a própria área de dados, os dois eixos, o título e a legenda.** Quase todo momento confuso
com o matplotlib vem de não saber com qual dos dois um comando fala. Esta aula sempre dá nome a eles:
`fig` para a figura, `ax` para um axes.

O notebook lê as viagens e monta a série diária da aula 16:

```python
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

fmt = "%Y-%m-%d %H:%M:%S"
trips = pd.read_csv("trips.csv")
trips["started_at"] = pd.to_datetime(trips["started_at"], format=fmt)
stations = pd.read_csv("stations.csv")
daily = trips.set_index("started_at").resample("D").size()
```

O `plt.subplots()` cria uma figura com um axes dentro e devolve os dois:

```python
fig, ax = plt.subplots(figsize=(8, 3.5))
ax.plot(daily.index, daily.to_numpy())
type(fig).__name__, type(ax).__name__, len(fig.axes)
```

```
('Figure', 'Axes', 1)
```

Um gráfico aparece embaixo da célula, e o texto acima dele é o valor da última linha. O `figsize` é
em polegadas, largura primeiro; no padrão do matplotlib de 100 pontos por polegada, esta figura tem
800 por 350 pixels. `ax.plot(x, y)` desenha uma linha pelos pontos, aqui um por dia.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Uma Figure, a imagem inteira, contém um Axes. O Axes contém a área de dados com a linha, um título acima, um eixo x e um eixo y com os rótulos, e uma legenda. Métodos de fig agem na imagem; métodos de ax agem no gráfico.\" data-fig=\"anatomy\"><defs><marker id=\"anatomy-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"260\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"34\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">fig</text><text x=\"66\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Figure: tamanho, layout, savefig</text><rect x=\"90\" y=\"56\" width=\"420\" height=\"190\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"104\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">ax</text><text x=\"350\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ax.set_title</text><line x1=\"210\" y1=\"210\" x2=\"490\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><line x1=\"210\" y1=\"90\" x2=\"210\" y2=\"210\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><path d=\"M210 180 L245 150 L280 165 L315 120 L350 140 L385 110 L420 130 L455 100 L490 115\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"2\"></path><text x=\"350\" y=\"232\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ax.set_xlabel</text><text x=\"104\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">ax.set_ylabel</text><rect x=\"400\" y=\"170\" width=\"80\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"440\" y=\"185\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">ax.legend</text><text x=\"600\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um gráfico:</text><text x=\"600\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seus dados, eixos,</text><text x=\"600\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">título e legenda</text><line x1=\"560\" y1=\"120\" x2=\"514\" y2=\"120\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#anatomy-ah)\"></line></svg>", "caption": "fig é a imagem; ax é um gráfico dentro dela, com tudo o que pertence a esse gráfico."}
```

**Tudo sobre um gráfico é método do seu `ax`**: `ax.set_title`, `ax.set_xlabel`, `ax.set_ylim`,
`ax.legend`. Tudo sobre a imagem como um todo pertence à `fig`: o tamanho, o layout, salvá-la num
arquivo. Com vários gráficos numa figura, essa é a diferença entre pôr o título no gráfico certo e no
errado.

## Dois jeitos de falar com o matplotlib

Muitos exemplos que você vai achar escrevem `plt.plot(...)`, `plt.title(...)`, sem `fig` nem `ax`.
Essa é a **interface pyplot**: o `plt` guarda uma figura e um axes "atuais" e manda cada comando para
lá. É mais curta para um gráfico digitado no prompt, e vira adivinhação assim que há dois. Este curso
usa a forma explícita, `fig, ax = plt.subplots()` e métodos neles, em todo lugar; traduzir um exemplo
é quase só trocar `plt.title` por `ax.set_title`.

## O que o axes guarda

O axes sabe o intervalo que escolheu para cada eixo:

```python
ax.get_xlim()
```

```
(np.float64(20070.8), np.float64(20471.2))
```

Números perto de vinte mil para um ano de datas. O matplotlib guarda uma data como **o número de dias
desde 1º de janeiro de 1970**, então 2025 está uns 20.089 dias depois, e o eixo os mostra como datas só
porque o pandas disse que eram. Quando um eixo de datas mostra números estranhos no lugar de datas, é
isto que está embaixo.

O gráfico apareceu embaixo da célula porque o JupyterLab exibe qualquer figura que uma célula criou, no
fim da célula, e depois a fecha. Um script não tem célula que termine, e a aula 21 é sobre o que ele
precisa no lugar disso.
