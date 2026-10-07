---
title: Medindo uma cor você mesmo
version: 1
---

O brilho real de uma cor se calcula em poucas linhas, e fazer isso uma vez torna concretas as duas
seções anteriores.

```schooling-example
{"language": "python", "file": "colours.py", "parts": [{"code": "import colorsys\nimport sys\n"}, {"code": "\ndef channels(hex_colour):\n    return [int(hex_colour[i:i + 2], 16) / 255 for i in (1, 3, 5)]\n", "note": "Transforma uma cor escrita como `#rrggbb` em três números entre 0 e 1."}, {"code": "\ndef linear(c):\n    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4\n", "note": "As telas guardam a cor com uma curva aplicada, chamada gama. O `linear` desfaz isso, porque o brilho só se soma em luz linear."}, {"code": "\ndef oklab_lightness(rgb):\n    r, g, b = (linear(c) for c in rgb)\n    l = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)\n    m = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)\n    s = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)\n    return 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s\n", "note": "A luminosidade do OKLab, pelas matrizes publicadas por Björn Ottosson: luz linear, depois uma matriz, depois uma raiz cúbica, depois a soma ponderada que é o L."}, {"code": "\nprint(\"colour     hue  sat  light(HSL)  luminance  OKLab L\")\nfor hex_colour in sys.argv[1:]:\n    rgb = channels(hex_colour)\n    h, l, s = colorsys.rgb_to_hls(*rgb)\n    r, g, b = (linear(c) for c in rgb)\n    luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b\n    print(f\"{hex_colour}  {h * 360:4.0f} {s:4.0%}  {l:9.0%}  {luminance:9.3f}  {oklab_lightness(rgb):7.3f}\")\n", "note": "Para cada cor dada na linha de comando, imprime os valores HSL pelo `colorsys` do próprio Python, a luminância relativa pelos pesos da WCAG e a luminosidade do OKLab."}]}
```

```
ana@vm:~/viz$ .venv/bin/python colours.py "#ff0000" "#ffff00" "#00ff00" "#00ffff" "#0000ff" "#ff00ff"
colour     hue  sat  light(HSL)  luminance  OKLab L
#ff0000     0 100%        50%      0.213    0.628
#ffff00    60 100%        50%      0.928    0.968
#00ff00   120 100%        50%      0.715    0.866
#00ffff   180 100%        50%      0.787    0.905
#0000ff   240 100%        50%      0.072    0.452
#ff00ff   300 100%        50%      0.285    0.702
```

Leia as colunas da esquerda para a direita:

- o **matiz** dá a volta em passos de 60 graus, como deve;
- a **saturação** e a **luminosidade HSL** são 100% e 50% para as seis, então pelo HSL elas são
  igualmente vivas e igualmente claras;
- a **luminância** vai de 0,072 no azul a 0,928 no amarelo, a diferença de treze vezes da figura;
- a **luminosidade do OKLab** concorda com a ordem, o azul mais escuro e o amarelo mais claro, e
  comprime a faixa, de 0,452 a 0,968, porque a luminosidade percebida cresce mais devagar que o brilho
  físico.

## Duas conferências rápidas sem código

**Deixe o gráfico em cinza.** A maioria dos editores de imagem e dos sistemas operacionais tem um modo
em escala de cinza, e as ferramentas de desenvolvedor de alguns navegadores conseguem simulá-lo. Um
gráfico cujo significado sobrevive em cinza tem uma paleta que funciona pela luminosidade; um que vira
cinzas idênticos dependia só do matiz.

**Aperte os olhos.** Desfocar a vista tira o detalhe e deixa a luminosidade. O que se destaca quando
você aperta os olhos é o que se destaca para um leitor com pressa.

## Numa planilha

As planilhas não informam a luminância, mas toda janela de cor mostra os valores RGB, e a fórmula de
cima pode ser digitada em células: uma coluna por canal, a conversão linear e a soma ponderada. Vale
fazer uma vez para as cores da marca da sua organização, que muitas vezes são escolhidas para logos e
não para gráficos.
