---
title: O mesmo gráfico, duas vezes
version: 1
---

O argumento mais forte para desenhar gráficos com código é que o mesmo programa desenha o mesmo
gráfico. Vale conferir quão ao pé da letra isso é verdade. Aqui está um programa parecido com o da
aula 1, salvo como `plain.py`, gravando um SVG. Ele roda duas vezes, e o `sha256sum` imprime uma
impressão digital do arquivo depois de cada vez:

```
ana@vm:~/viz$ .venv/bin/python plain.py && sha256sum chart.svg
matplotlib 3.11.2
de53177756e09cf0b461472932f805508a41db89abad20b8a2d33796eaf823eb  chart.svg
ana@vm:~/viz$ .venv/bin/python plain.py && sha256sum chart.svg
matplotlib 3.11.2
f70c0124395ebca8df0c2679b268cb8a0bf740658980fb4a25dd88840951409e  chart.svg
```

As impressões digitais diferem. A imagem é a mesma, mas o arquivo não: o matplotlib escreve a data e
a hora em cada SVG que salva, e dá às formas dentro dele identificadores inventados ao acaso. Para uma
imagem isso não faz mal. Para um gráfico guardado em controle de versão, quer dizer que cada execução
parece uma mudança, e uma mudança de verdade se esconde entre as falsas.

Dois ajustes tiram as duas coisas. Este é o `plain.py` com eles acrescentados, salvo como `chart.py`:

```schooling-example
{"language": "python", "file": "chart.py", "parts": [{"code": "import csv\nimport matplotlib\nimport matplotlib.pyplot as plt\n"}, {"code": "matplotlib.rcParams[\"svg.hashsalt\"] = \"horta\"\n", "note": "Dá uma semente fixa aos identificadores dentro do SVG, para eles saírem iguais em toda execução. Qualquer texto serve; o que importa é que ele não mude."}, {"code": "totals = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        if row[\"month\"].startswith(\"2025\"):\n            totals[row[\"region\"]] = totals.get(row[\"region\"], 0) + int(row[\"orders\"])\n", "note": "Soma os pedidos de cada região em 2025."}, {"code": "regions = sorted(totals, key=totals.get)\nfig, ax = plt.subplots(figsize=(6, 3))\nax.barh(regions, [totals[r] for r in regions], color=\"#2b52c9\")\nax.set_title(\"Southeast takes more orders than the next two regions together\", loc=\"left\")\nax.spines[[\"top\", \"right\"]].set_visible(False)\nfig.savefig(\"chart.svg\", metadata={\"Date\": None})\nprint(\"matplotlib\", matplotlib.__version__)\n", "note": "Desenha as barras ordenadas com uma afirmação no título, e salva o SVG sem a data. Depois imprime a versão da biblioteca, porque uma versão nova do matplotlib também pode mudar o arquivo, e essa é uma mudança que vale saber."}]}
```

```
ana@vm:~/viz$ .venv/bin/python chart.py && sha256sum chart.svg
matplotlib 3.11.2
5bf2b40165fc69c02dc3f39614961009781d0ac2415a0a7e3dcb6822b9318a8b  chart.svg
ana@vm:~/viz$ .venv/bin/python chart.py && sha256sum chart.svg
matplotlib 3.11.2
5bf2b40165fc69c02dc3f39614961009781d0ac2415a0a7e3dcb6822b9318a8b  chart.svg
```

Agora as duas execuções produzem arquivos idênticos, byte a byte. Uma impressão digital diferente quer
dizer que o gráfico mudou: o dado, o código ou a biblioteca. É essa propriedade que deixa um gráfico
ser revisado como qualquer outro trabalho.

## O que toda ferramenta consegue fazer

Nem toda ferramenta promete arquivos idênticos, mas qualquer uma delas consegue aplicar as mudanças que
este curso defendeu. Seja o que for que desenhou o gráfico, estas são as edições que valem a pena antes
de alguém vê-lo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 620 270\" role=\"img\" data-fig=\"l20-fixes\" aria-label=\"Um gráfico de barras da receita por categoria com cinco mudanças numeradas marcadas nele, as mudanças que este curso faria em qualquer ferramenta: 1, um título que diz o achado; 2, as barras ordenadas da maior para a menor; 3, o eixo começando no zero; 4, valores nas barras em vez de grade; 5, uma cor, com a barra que importa destacada.\"><text x=\"110.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Verduras e frutas trazem dois quintos da receita</text><path d=\"M110.0 40.0 L110.0 252.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M110.0 50.0 h265.5 v22.0 h-265.5 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"61.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Verduras</text><text x=\"381.5\" y=\"61.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">412</text><path d=\"M110.0 84.0 h248.8 v22.0 h-248.8 Z\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"95.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Frutas</text><text x=\"364.8\" y=\"95.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">386</text><path d=\"M110.0 118.0 h226.2 v22.0 h-226.2 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"129.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Laticínios</text><text x=\"342.2\" y=\"129.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">351</text><path d=\"M110.0 152.0 h192.0 v22.0 h-192.0 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"163.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Padaria</text><text x=\"308.0\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">298</text><path d=\"M110.0 186.0 h176.6 v22.0 h-176.6 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"197.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Bebidas</text><text x=\"292.6\" y=\"197.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">274</text><path d=\"M110.0 220.0 h154.0 v22.0 h-154.0 Z\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"102.0\" y=\"231.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Mercearia</text><text x=\"270.0\" y=\"231.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">239</text><circle cx=\"92.0\" cy=\"20.0\" r=\"9.0\" fill=\"var(--amber)\"></circle><text x=\"92.0\" y=\"20.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"#ffffff\">1</text><circle cx=\"30.0\" cy=\"150.0\" r=\"9.0\" fill=\"var(--amber)\"></circle><text x=\"30.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"#ffffff\">2</text><circle cx=\"110.0\" cy=\"262.0\" r=\"9.0\" fill=\"var(--amber)\"></circle><text x=\"110.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"#ffffff\">3</text><circle cx=\"415.5\" cy=\"61.0\" r=\"9.0\" fill=\"var(--amber)\"></circle><text x=\"415.5\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"#ffffff\">4</text><circle cx=\"398.8\" cy=\"95.0\" r=\"9.0\" fill=\"var(--amber)\"></circle><text x=\"398.8\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"#ffffff\">5</text><text x=\"470.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">1  uma afirmação no título</text><text x=\"470.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">2  ordenado</text><text x=\"470.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3  a partir do zero</text><text x=\"470.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4  valores, sem grade</text><text x=\"470.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5  uma cor, um destaque</text></svg>", "caption": "Cinco mudanças que toda ferramenta desta aula consegue fazer, num menu ou numa linha de código. Os padrões mudam de ferramenta para ferramenta; a lista não."}
```

Os menus mudam entre versões e os nomes das funções mudam entre bibliotecas. A lista de mudanças fica
a mesma, e o motivo de cada uma também: o leitor deve ver o ponto do gráfico, com precisão, sem ter de
trabalhar para isso.
