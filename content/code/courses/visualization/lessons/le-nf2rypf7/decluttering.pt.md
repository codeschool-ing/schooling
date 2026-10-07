---
title: Medindo a poluição
version: 1
---

A razão dado-tinta foi definida para tinta impressa, mas uma tela é feita de pixels, e pixels se
contam. Este programa desenha o gráfico de categorias duas vezes, uma com fundo cinza, grade preta e
legenda, e outra limpa, e conta quantos pixels de cada imagem são tinta e quantos são o azul das
barras:

```schooling-example
{"language": "python", "file": "inkratio.py", "parts": [{"code": "import csv\nimport numpy as np\nimport matplotlib.pyplot as plt\n"}, {"code": "names, revenue = [], []\nwith open(\"categories.csv\") as f:\n    for row in csv.DictReader(f):\n        names.append(row[\"category\"])\n        revenue.append(int(row[\"revenue\"]))\n", "note": "Lê as seis categorias e a receita delas, em R$ mil."}, {"code": "BLUE = (0x2B, 0x52, 0xC9)\n"}, {"code": "def draw(clean):\n    fig, ax = plt.subplots(figsize=(5, 3), dpi=100)\n    ax.barh(names, revenue, color=\"#2b52c9\", label=\"revenue (R$ thousand)\")\n    ax.invert_yaxis()\n    if clean:\n        ax.spines[[\"top\", \"right\", \"bottom\"]].set_visible(False)\n        ax.tick_params(left=False, bottom=False, labelbottom=False)\n        ax.set_title(\"Revenue by category, R$ thousand\", loc=\"left\")\n        for y, v in enumerate(revenue):\n            ax.text(v + 5, y, f\"{v}\", va=\"center\")\n    else:\n        ax.set_facecolor(\"#d9d9d9\")\n        ax.grid(color=\"black\", linewidth=1)\n        ax.set_axisbelow(True)\n        ax.legend()\n    fig.canvas.draw()\n    rgb = np.asarray(fig.canvas.buffer_rgba())[:, :, :3].astype(int)\n    fig.savefig(\"clean.png\" if clean else \"cluttered.png\", bbox_inches=\"tight\")\n    plt.close(fig)\n    ink = (rgb < 250).any(axis=2).sum()\n    data = (np.abs(rgb - BLUE).sum(axis=2) < 30).sum()\n    return data, ink\n", "note": "Desenha o gráfico de um de dois jeitos. O poluído ganha o fundo cinza, a grade preta e uma legenda; o limpo perde três das quatro bordas e as marcas dos eixos, e ganha os valores escritos ao lado das barras e a unidade no título. Depois transforma a imagem pronta num array de valores de vermelho, verde e azul, um por pixel, e conta: tinta é qualquer pixel que não seja branco, e barra é qualquer pixel a uma pequena distância do azul das barras."}, {"code": "for clean in (False, True):\n    data, ink = draw(clean)\n    name = \"clean\" if clean else \"cluttered\"\n    print(f\"{name:9}  ink {ink:6} px  bars {data:6} px  data-ink ratio {data / ink:.2f}\")\n", "note": "Roda os dois e imprime as contagens e a razão."}], "output": "cluttered  ink  94134 px  bars  45936 px  data-ink ratio 0.49\nclean      ink  54780 px  bars  50295 px  data-ink ratio 0.92"}
```

```
ana@vm:~/viz$ .venv/bin/python inkratio.py
cluttered  ink  94134 px  bars  45936 px  data-ink ratio 0.49
clean      ink  54780 px  bars  50295 px  data-ink ratio 0.92
```

O gráfico poluído é metade barras e metade todo o resto, uma razão de 0,49. O limpo tem 0,92. Duas
coisas da saída merecem uma segunda olhada:

- **O gráfico limpo usa 42% menos tinta**, 54.780 pixels contra 94.134, e mostra os mesmos seis
  números e ainda os valores exatos.
- **O gráfico limpo tem mais azul, não menos**: 50.295 pixels de barra contra 45.936. Na versão
  poluída a caixa da legenda fica por cima da barra mais longa e esconde parte dela. O lixo não só
  cerca o dado; às vezes o cobre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 190\" role=\"img\" data-fig=\"l17-ratio\" aria-label=\"Duas barras empilhadas medindo os pixels de tinta do gráfico poluído e do limpo. Poluído: 94.134 pixels de tinta, dos quais 45.936 são barras, uma razão dado-tinta de 0,49. Limpo: 54.780 pixels, dos quais 50.295 são barras, uma razão de 0,92.\"><path d=\"M110.0 36.0 h188.3 v28.0 h-188.3 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M298.3 36.0 h197.6 v28.0 h-197.6 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">poluído</text><text x=\"501.9\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">0,49</text><path d=\"M110.0 82.0 h206.2 v28.0 h-206.2 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><path d=\"M316.2 82.0 h18.4 v28.0 h-18.4 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">limpo</text><text x=\"340.6\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">0,92</text><path d=\"M110.0 130.0 L520.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M110.0 130.0 L110.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"110.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><path d=\"M212.5 130.0 L212.5 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"212.5\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">25.000</text><path d=\"M315.0 130.0 L315.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"315.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">50.000</text><path d=\"M417.5 130.0 L417.5 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"417.5\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">75.000</text><path d=\"M520.0 130.0 L520.0 134.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"520.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">100.000</text><text x=\"315.0\" y=\"161.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pixels de tinta</text><path d=\"M110.0 172.0 h14.0 v10.0 h-14.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"130.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">barras</text><path d=\"M220.0 172.0 h14.0 v10.0 h-14.0 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"240.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">todo o resto</text></svg>", "caption": "Medido nos dois gráficos que o inkratio.py desenha. O limpo usa 42% menos tinta, e as barras dele têm mais pixels, não menos: a legenda não cobre mais a mais longa."}
```

## A ordem de trabalho

Despoluir um gráfico é mais rápido numa ordem fixa, das marcas maiores para as menores:

1. **Fundo e moldura.** Tire.
2. **Linhas de grade.** Deixe leves, ou tire se os valores estiverem escritos no dado.
3. **Linhas de eixo e marcas.** Mantenha aquela de onde as barras partem; as outras em geral podem
   sair.
4. **Legenda.** Troque por rótulos diretos (aula 15), ou apague numa série só.
5. **Rótulos.** Mantenha um jeito de ler cada valor, não três.

A contagem de pixels é uma conferência, não uma meta. Vale rodar uma vez, para ver quanto de um
gráfico padrão não é dado. Depois disso, o olho faz a conta.
