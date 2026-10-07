---
title: A matriz de correlação
version: 1
---

A aula 6 mediu o quanto duas quantidades andam juntas com a **correlação**, *r*, entre −1 e +1. Com
cinco quantidades há dez pares, e uma **matriz de correlação** mostra todos de uma vez: uma linha e
uma coluna por variável, e em cada célula a correlação daquele par.

```schooling-example
{"language": "python", "file": "corr.py", "parts": [{"code": "import csv\nimport numpy as np\n"}, {"code": "columns = [\"km\", \"items\", \"rain\", \"basket\", \"minutes\"]\nwith open(\"deliveries.csv\") as f:\n    rows = list(csv.DictReader(f))\ndata = np.array([[float(r[c]) for c in columns] for r in rows])\n", "note": "Lê as cinco colunas numéricas de toda entrega numa tabela de 400 linhas e 5 colunas."}, {"code": "matrix = np.corrcoef(data, rowvar=False)\nprint(\" \" * 8 + \"\".join(f\"{c:>8}\" for c in columns))\nfor name, values in zip(columns, matrix):\n    print(f\"{name:8}\" + \"\".join(f\"{v:8.2f}\" for v in values))\n", "note": "O `corrcoef` com `rowvar=False` trata cada coluna como uma variável e devolve a matriz 5 por 5 das correlações, impressa aqui como tabela."}], "output": "              km   items    rain  basket minutes\nkm          1.00    0.05    0.03    0.04    0.88\nitems       0.05    1.00    0.06    0.95    0.23\nrain        0.03    0.06    1.00    0.08    0.26\nbasket      0.04    0.95    0.08    1.00    0.21\nminutes     0.88    0.23    0.26    0.21    1.00"}
```

```
ana@vm:~/viz$ .venv/bin/python corr.py
              km   items    rain  basket minutes
km          1.00    0.05    0.03    0.04    0.88
items       0.05    1.00    0.06    0.95    0.23
rain        0.03    0.06    1.00    0.08    0.26
basket      0.04    0.95    0.08    1.00    0.21
minutes     0.88    0.23    0.26    0.21    1.00
```

Três características de toda matriz de correlação aparecem aqui. Os nomes das colunas são os do
arquivo: `items` são os itens, `rain` é a chuva, `basket` é o valor da cesta.

- **A diagonal é toda 1,00.** Toda variável tem correlação perfeita consigo mesma, e essas células
  não carregam informação.
- **Ela é simétrica.** A correlação de km com minutes, 0,88, aparece duas vezes, acima e abaixo da
  diagonal. Metade da matriz é espelho da outra.
- **Quase tudo é pequeno.** Dos dez pares distintos, dois são fortes: **items com basket, 0,95**,
  porque mais itens custam mais, e **km com minutes, 0,88**, da aula 6. A chuva e os itens somam um
  pouco aos minutos, 0,26 e 0,23. Todo o resto fica perto de zero.

## Lendo com cuidado

Uma correlação mede **só uma relação em linha reta**. Duas variáveis podem estar fortemente ligadas
ao longo de uma curva e ainda mostrar correlação perto de zero, então uma célula surpreendente é
motivo para desenhar o gráfico de dispersão daquele par, e não uma conclusão.

E o aviso da aula 6 vale célula por célula: **uma correlação forte não é uma causa**. Com muitas
variáveis, alguns pares vão se correlacionar por coincidência, e uma matriz de cinquenta variáveis tem
1.225 pares onde achar coincidências.
