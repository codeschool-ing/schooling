---
title: Na prática: o mesmo dado, duas vezes
version: 1
---

Desenhe você mesmo a comparação da segunda seção, na ferramenta que você montou na aula 1.

## Numa planilha

Abra o `categories.csv`, selecione as duas colunas e insira um **gráfico de pizza**. Depois, com a
mesma seleção, insira um **gráfico de barras**, ordenando antes o dado do maior para o menor (no
LibreOffice, *Dados ▸ Ordenar*; no Excel, *Dados ▸ Classificar do Maior para o Menor*). Ponha os dois
lado a lado.

Antes de olhar os números, anote qual fatia você acha que é a terceira maior, e por quanto a maior
passa a menor. Depois confira nas barras.

## Em Python

Salve isto como `pie.py` na pasta do curso:

```schooling-example
{"language": "python", "file": "pie.py", "parts": [{"code": "import csv\nimport matplotlib.pyplot as plt\n", "note": "Lê as seis categorias e as ordena da maior receita para a menor, para que os dois gráficos comecem da mesma ordem."}, {"code": "with open(\"categories.csv\") as f:\n    rows = sorted(csv.DictReader(f), key=lambda r: int(r[\"revenue\"]), reverse=True)\nnames = [r[\"category\"] for r in rows]\nrevenue = [int(r[\"revenue\"]) for r in rows]\n", "note": "Imprime a fração do total de cada categoria. Esses são os números que a pizza deveria tornar visíveis; mantenha-os ao lado enquanto olha para ela."}, {"code": "total = sum(revenue)\nfor name, value in zip(names, revenue):\n    print(f\"{name:11} {value:4}  {100 * value / total:5.1f}%\")\n", "note": "Uma figura com dois pares de eixos lado a lado. A pizza começa no meio-dia e vai no sentido horário, a convenção que torna uma pizza ordenada minimamente legível."}, {"code": "fig, (left, right) = plt.subplots(1, 2, figsize=(9, 3.5))\nleft.pie(revenue, labels=names, startangle=90, counterclock=False)\nright.barh(names[::-1], revenue[::-1])\nright.set_xlabel(\"revenue in 2025 (R$ thousands)\")\nfig.savefig(\"pie.png\", dpi=150, bbox_inches=\"tight\")\nprint(\"saved pie.png\")\n", "note": "As barras são invertidas para que a maior fique em cima, e o arquivo é gravado."}], "output": "Vegetables   412   21.0%\nFruit        386   19.7%\nDairy        351   17.9%\nBakery       298   15.2%\nDrinks       274   14.0%\nPantry       239   12.2%\nsaved pie.png"}
```

```
ana@vm:~/viz$ .venv/bin/python pie.py
Vegetables   412   21.0%
Fruit        386   19.7%
Dairy        351   17.9%
Bakery       298   15.2%
Drinks       274   14.0%
Pantry       239   12.2%
saved pie.png
```

Abra o `pie.png`. O matplotlib dá a cada fatia um matiz diferente por padrão, e as cores fazem parte
do trabalho que os ângulos não conseguem: pelo menos dá para achar cada categoria. **Repare no que
você usa para responder "Laticínios é maior que Padaria?"** Na pizza, a maioria das pessoas acaba
lendo a tabela impressa acima dela. Nas barras, ninguém precisa.

## Uma pergunta para guardar

Da próxima vez que vir uma pizza no trabalho, pergunte que pergunta ela foi desenhada para
responder. Se a resposta for "que fração é esta parte", a pizza pode ser o gráfico certo. Se for
"qual é maior" ou "como mudaram", é um gráfico de barras que foi entortado num círculo.
