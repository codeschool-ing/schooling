---
title: Montando uma página que reflui
version: 1
---

Um gráfico salvo como imagem não reflui: é uma forma num tamanho. Uma **página web** reflui, porque o
navegador a monta de novo para cada tela. Três peças de HTML e CSS fazem o trabalho, e este programa
escreve as três, com duas versões do gráfico de tendência, uma larga e uma estreita:

```schooling-example
{"language": "python", "file": "responsive.py", "parts": [{"code": "import csv\nimport os\nimport matplotlib.pyplot as plt\n"}, {"code": "total = {}\nwith open(\"monthly.csv\") as f:\n    for row in csv.DictReader(f):\n        total[row[\"month\"]] = total.get(row[\"month\"], 0) + int(row[\"orders\"])\nmonths = sorted(total)\nvalues = [total[m] for m in months]\ny24, y25 = sum(values[:12]), sum(values[12:])\n", "note": "Soma os pedidos de cada mês somando as regiões, e os dois totais anuais para os cartões."}, {"code": "def trend(name, size, ticks):\n    fig, ax = plt.subplots(figsize=size)\n    ax.plot(range(len(months)), values, color=\"#2b52c9\", linewidth=2)\n    ax.set_xticks(ticks, [months[i] for i in ticks])\n    ax.set_title(\"Orders per month\", loc=\"left\")\n    ax.spines[[\"top\", \"right\"]].set_visible(False)\n    fig.savefig(name, bbox_inches=\"tight\")\n    plt.close(fig)\n", "note": "Uma função desenha a tendência num tamanho dado com um conjunto dado de meses rotulados, então o gráfico largo e o estreito só diferem nessas duas coisas."}, {"code": "trend(\"trend-wide.svg\", (9, 3.5), [0, 6, 12, 18, 23])\ntrend(\"trend-narrow.svg\", (3.6, 3.2), [0, 23])\n", "note": "O gráfico largo rotula cinco meses; o estreito, menor e quase quadrado, só rotula o primeiro e o último."}, {"code": "page = f\"\"\"<!doctype html>\n<html lang=\"en\">\n<meta charset=\"utf-8\">\n<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n<title>Horta</title>\n<style>\n  body {{ font-family: sans-serif; margin: 16px; max-width: 960px; }}\n  .cards {{ display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }}\n  .card {{ border: 1px solid #ccd4e3; border-radius: 6px; padding: 12px; }}\n  .card b {{ display: block; font-size: 2rem; }}\n  img {{ width: 100%; height: auto; margin-top: 16px; }}\n  @media (max-width: 600px) {{\n    .cards {{ grid-template-columns: 1fr; }}\n  }}\n</style>\n<div class=\"cards\">\n  <div class=\"card\">orders in 2025 <b>{y25:,}</b> {y25 / y24 - 1:+.1%} on 2024</div>\n  <div class=\"card\">orders in December <b>{values[-1]:,}</b> {values[-1] / values[11] - 1:+.1%} on Dec 2024</div>\n</div>\n<picture>\n  <source media=\"(max-width: 600px)\" srcset=\"trend-narrow.svg\">\n  <img src=\"trend-wide.svg\" alt=\"Orders per month, January 2024 to December 2025, rising from {values[0]:,} to {values[-1]:,} with a spike every December.\">\n</picture>\n\"\"\"\nwith open(\"dashboard.html\", \"w\") as f:\n    f.write(page)\n", "note": "A página. A linha do viewport faz o celular montá-la na própria largura; a grade põe os cartões em duas colunas; a regra de media os transforma em uma com 600 pixels ou menos; e o elemento picture entrega os dois gráficos ao navegador com a regra para escolher. As chaves dobradas são como uma f-string escreve uma chave literal. Depois grava tudo em dashboard.html."}, {"code": "for name in (\"dashboard.html\", \"trend-wide.svg\", \"trend-narrow.svg\"):\n    print(f\"{name:16} {os.path.getsize(name):7,} bytes\")\n", "note": "Imprime o tamanho de cada arquivo gravado, como conferência de que os três existem."}]}
```

```
ana@vm:~/viz$ .venv/bin/python responsive.py
dashboard.html       965 bytes
trend-wide.svg    20,517 bytes
trend-narrow.svg  17,846 bytes
```

## As três peças

- **A linha do viewport**, `<meta name="viewport" content="width=device-width, initial-scale=1">`.
  Sem ela, o navegador do celular finge ter uns 980 pixels de largura e encolhe a página para caber,
  que é o celular da esquerda na primeira figura desta aula. Com ela, a página é montada na largura
  real do celular.
- **Uma grade que muda numa largura.** Os cartões ficam numa grade CSS de duas colunas. A regra
  `@media (max-width: 600px)` a transforma em uma coluna quando a tela tem 600 pixels de largura ou
  menos. O número é um **ponto de quebra**, e ele pertence ao lugar onde o layout para de funcionar,
  não à largura de um celular específico.
- **Um gráfico por forma.** O elemento `<picture>` oferece dois arquivos ao navegador e uma regra
  para escolher: o SVG estreito, com dois rótulos de data e uma forma mais alta, com 600 pixels ou
  menos; o largo nos outros casos. Os dois têm o mesmo texto `alt`, que diz o que o gráfico mostra
  (aula 14).

## Olhando para ela

Abrir o `dashboard.html` direto da pasta serve para uma primeira olhada. Servi-lo é mais parecido com
o jeito como se chega a um painel de verdade, e é o único jeito de um celular abri-lo. O Python vem
com um pequeno servidor web:

```
ana@vm:~/viz$ timeout 3 python3 -u -m http.server 8000 --bind 127.0.0.1
Serving HTTP on 127.0.0.1 port 8000 (http://127.0.0.1:8000/) ...
```

Abra `http://127.0.0.1:8000/dashboard.html` num navegador no mesmo computador, depois ligue o **modo
de dispositivo** dele: Ctrl+Shift+M nas ferramentas de desenvolvedor do Chrome ou no Firefox
(Cmd+Opt+M no Mac). Ele mostra a página na largura de um celular escolhido, e arrastar a borda mostra
o ponto de quebra em ação.

`--bind 127.0.0.1` deixa o servidor visível só para este computador. Para testar a página num celular
de verdade, os dois precisam estar na mesma rede e o servidor precisa escutar nela, com
`--bind 0.0.0.0`, o que mostra a pasta para **todo mundo nessa rede**. Faça isso só numa rede em que
você confia, sirva uma pasta que não guarde mais nada, e pare o servidor com Ctrl+C quando terminar.

## O que o modo de dispositivo não mostra

Um navegador de computador fingindo ser estreito acerta o layout e erra a mão: não mostra quão
pequeno um alvo fica sob o polegar, nem como a tela se lê ao sol. A última conferência é o celular de
verdade, seguro do jeito que a diretora o segura.
