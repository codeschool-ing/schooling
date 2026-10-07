---
title: Medindo o contraste
version: 1
---

O **contraste** entre duas cores é medido como uma razão entre as luminâncias relativas delas, a
quantidade que a aula 11 calculou:

```localised
contraste = (luminância mais clara + 0,05) ÷ (luminância mais escura + 0,05)
```

Ele vai de **1:1**, duas cores idênticas, a **21:1**, preto no branco. As Diretrizes de Acessibilidade
para Conteúdo Web, **WCAG 2.2**, fixam os limites que a maioria das organizações e muitas leis adotam:

| o quê | critério da WCAG 2.2 | o nível AA pede |
|---|---|---|
| texto, inclusive rótulos e números num gráfico | 1.4.3 Contraste (Mínimo) | **4,5:1**, ou 3:1 para texto grande |
| as partes de um gráfico de que o leitor precisa: linhas, barras, pontos, contornos | 1.4.11 Contraste Não Textual | **3:1** contra o que está ao lado |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 600 250\" role=\"img\" data-fig=\"l14-contrast\" aria-label=\"Quatro pares de cores com as suas razões de contraste, contra dois limites marcados numa escala: 3 para 1 para gráficos e 4,5 para 1 para texto. Cinza médio no branco, 4,54, passa nos dois. Cinza claro no branco, 1,61, falha nos dois. O azul deste curso no branco, 6,66, passa nos dois. Vermelho contra verde, 1,48, falha nos dois.\"><rect x=\"30.0\" y=\"40.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"46.0\" y=\"48.0\" width=\"28.0\" height=\"18.0\" rx=\"1\" fill=\"#767676\" stroke=\"#767676\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#767676 / #ffffff</text><path d=\"M250.0 47.0 h167.0 v20.0 h-167.0 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"423.0\" y=\"57.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">4,54</text><rect x=\"30.0\" y=\"86.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"46.0\" y=\"94.0\" width=\"28.0\" height=\"18.0\" rx=\"1\" fill=\"#c8ccd4\" stroke=\"#c8ccd4\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#c8ccd4 / #ffffff</text><path d=\"M250.0 93.0 h28.8 v20.0 h-28.8 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"284.8\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1,61</text><rect x=\"30.0\" y=\"132.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"#ffffff\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"46.0\" y=\"140.0\" width=\"28.0\" height=\"18.0\" rx=\"1\" fill=\"#2b52c9\" stroke=\"#2b52c9\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"149.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#2b52c9 / #ffffff</text><path d=\"M250.0 139.0 h266.8 v20.0 h-266.8 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"522.8\" y=\"149.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">6,66</text><rect x=\"30.0\" y=\"178.0\" width=\"60.0\" height=\"34.0\" rx=\"2\" fill=\"#2ca02c\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"46.0\" y=\"186.0\" width=\"28.0\" height=\"18.0\" rx=\"1\" fill=\"#d62728\" stroke=\"#d62728\" stroke-width=\"1\"></rect><text x=\"110.0\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">#d62728 / #2ca02c</text><path d=\"M250.0 185.0 h22.5 v20.0 h-22.5 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"278.5\" y=\"195.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1,48</text><path d=\"M344.3 34.0 L344.3 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"348.3\" y=\"236.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">gráficos pedem 3:1</text><path d=\"M415.0 34.0 L415.0 226.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"419.0\" y=\"224.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">texto pede 4,5:1</text></svg>", "caption": "Contraste é uma razão de luminâncias, de 1:1 para cores idênticas a 21:1 para preto no branco. A WCAG 2.2 pede 4,5:1 para texto e 3:1 para as partes de um gráfico de que o leitor precisa."}
```

## Medindo

```schooling-example
{"language": "python", "file": "access.py", "parts": [{"code": "import sys\n"}, {"code": "# Machado, Oliveira and Fernandes (2009): full deuteranopia, applied to linear RGB.\nDEUTAN = [[0.367322, 0.860646, -0.227968],\n          [0.280085, 0.672501, 0.047413],\n          [-0.011820, 0.042940, 0.968881]]\n\n", "note": "A matriz de simulação da deuteranopia completa, de Machado, Oliveira e Fernandes, aplicada à luz linear."}, {"code": "def to_linear(hex_colour):\n    out = []\n    for i in (1, 3, 5):\n        c = int(hex_colour[i:i + 2], 16) / 255\n        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)\n    return out\n\n", "note": "Converte uma cor hex para luz linear. Toda conta abaixo é feita em luz linear, como na aula 11."}, {"code": "def to_hex(linear):\n    out = \"\"\n    for c in linear:\n        c = min(1.0, max(0.0, c))\n        c = 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055\n        out += f\"{round(c * 255):02x}\"\n    return \"#\" + out\n\n", "note": "E de volta, cortando no que uma tela consegue mostrar."}, {"code": "def luminance(hex_colour):\n    r, g, b = to_linear(hex_colour)\n    return 0.2126 * r + 0.7152 * g + 0.0722 * b\n\n", "note": "A luminância relativa, pelos pesos da WCAG."}, {"code": "def contrast(a, b):\n    la, lb = sorted([luminance(a), luminance(b)], reverse=True)\n    return (la + 0.05) / (lb + 0.05)\n\n", "note": "A razão de contraste da WCAG: a luminância mais clara mais 0,05, dividida pela mais escura mais 0,05."}, {"code": "def deutan(hex_colour):\n    rgb = to_linear(hex_colour)\n    return to_hex([sum(m * c for m, c in zip(row, rgb)) for row in DEUTAN])\n\n", "note": "Aplica a matriz a uma cor: o que uma pessoa com deuteranopia percebe, como cor hex."}, {"code": "for pair in sys.argv[1:]:\n    a, b = pair.split(\":\")\n    print(f\"{a} on {b}: {contrast(a, b):5.2f} : 1   \"\n          f\"as deuteranopia sees them, {deutan(a)} and {deutan(b)}: \"\n          f\"{contrast(deutan(a), deutan(b)):5.2f} : 1\")\n", "note": "Para cada par dado como `frente:fundo`, imprime o contraste como a maioria das pessoas o vê e como a deuteranopia o vê."}]}
```

```
ana@vm:~/viz$ .venv/bin/python access.py "#d62728:#2ca02c" "#d62728:#1f77b4" "#c8ccd4:#ffffff" "#767676:#ffffff" "#5a6274:#ffffff"
#d62728 on #2ca02c:  1.48 : 1   as deuteranopia sees them, #8b7c1f and #968838:  1.17 : 1
#d62728 on #1f77b4:  1.04 : 1   as deuteranopia sees them, #8b7c1f and #456cb3:  1.24 : 1
#c8ccd4 on #ffffff:  1.61 : 1   as deuteranopia sees them, #c9cbd4 and #ffffff:  1.62 : 1
#767676 on #ffffff:  4.54 : 1   as deuteranopia sees them, #767676 and #ffffff:  4.54 : 1
#5a6274 on #ffffff:  6.12 : 1   as deuteranopia sees them, #5a6174 and #ffffff:  6.18 : 1
```

Cinco pares, cinco lições:

- **Vermelho e verde**, o `tab:red` e o `tab:green` do matplotlib, têm contraste de só 1,48:1, e para a
  deuteranopia viram `#8b7c1f` e `#968838`, dois tons de oliva a 1,17:1. Nada os separa.
- **Vermelho e azul** têm ainda menos contraste, 1,04:1, e mesmo assim funcionam como duas séries,
  porque para a deuteranopia viram oliva e azul: **os matizes continuam diferentes**. O contraste mede
  a luminosidade; separar duas séries também pode vir do matiz, desde que os matizes sobrevivam.
- **`#c8ccd4` no branco, 1,61:1, falha nos 3:1 que uma barra necessária pede.** É o cinza que o
  `highlight.py` da aula 13 usou nas barras de contexto, escolhido de olho porque parecia discreto.
  Medido, ele é discreto demais: um leitor com baixa visão, ou qualquer um diante de um projetor
  desbotado, perde o contexto de que o destaque depende.
- **`#767676` no branco, 4,54:1**, é o cinza mais claro que passa para texto. É um número útil de
  guardar.
- **`#5a6274`, 6,12:1**, a cor do texto apagado do tema claro deste curso, passa com folga.

## O que medir num gráfico

- **Todo texto**: títulos, rótulos, valores do eixo, anotações, contra o fundo atrás deles. 4,5:1.
- **Toda marca de que o leitor precisa**: barras, linhas, pontos, contra o fundo, e contra as vizinhas
  quando se tocam, como os segmentos de uma barra empilhada. 3:1, ou uma borda visível entre elas.
- **Linhas de grade não contam**, desde que o gráfico se leia sem elas. Elas são feitas para ser
  discretas.
