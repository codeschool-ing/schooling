---
title: Os totais digitados, achados pela coerência
version: 1
---

**A checagem mais forte de um valor errado é um segundo registro do mesmo fato.** O total de todo
pedido pode ser calculado pelos itens: quantidade vezes preço, somados, menos o desconto, mais o
frete. A aula 7 montou esse cálculo para testar as suas conversões e achou 28.519 pedidos que batem
ao centavo e 7 que não. Aqui estão os sete:

```schooling-example
{
  "language": "python",
  "file": "typos.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom lines import lines\nfrom orders import orders\n\n",
      "note": "Os itens da aula 7, convertidos, e os pedidos."
    },
    {
      "code": "cents = lambda col: (pd.to_numeric(orders[col].fillna(\"0\")) * 100).round().astype(int)\n",
      "note": "Uma coluna em reais como centavos inteiros, vazios contados como zero."
    },
    {
      "code": "orders[\"expected\"] = (orders[\"order_id\"].map(lines.groupby(\"order_id\")[\"line_cents\"].sum())\n                      - cents(\"discount\") + cents(\"delivery_fee\")) / 100\n",
      "note": "**Quanto cada total deveria ser**: os itens, menos o desconto, mais o frete."
    },
    {
      "code": "wrong = orders[(orders[\"total\"] - orders[\"expected\"]).abs() > 0.005].copy()\nwrong[\"ratio\"] = (wrong[\"total\"] / wrong[\"expected\"]).round(2)\n\n",
      "note": "Todo pedido cujo total discorda dos itens por mais de meio centavo, e por que fator."
    },
    {
      "code": "if __name__ == \"__main__\":\n    print(wrong[[\"order_id\", \"total\", \"expected\", \"ratio\", \"status\"]].to_string(index=False))\n"
    }
  ]
}
```

```
ana@lab:~/clean$ python typos.py
order_id  total  expected  ratio    status
  100592 2516.0    251.60   10.0 delivered
  106842  458.5     45.85   10.0 delivered
  111955 2721.5    272.15   10.0 delivered
  118299 1807.0    180.70   10.0 delivered
  121020  336.5     33.65   10.0 delivered
  122133  118.5     11.85   10.0 delivered
  125535 1370.0    137.00   10.0 delivered
```

**Cada um é exatamente dez vezes os seus itens.** O atendimento corrigiu esses pedidos à mão e digitou
um zero a mais, o deslize mais comum que existe com dinheiro. A razão diz o que aconteceu; os itens
dizem quanto o total deveria ser.

Olhe o pedido 122133: R$ 118,50 contra R$ 11,85. Um total de R$ 118,50 é um pedido comum, bem dentro
de todas as regras da seção anterior — **nenhum teste de valor atípico o marcaria**, e ele está errado
pelo mesmo fator que o de R$ 2.721,50. A checagem de coerência acha os dois, porque não liga para quão
longe um valor está dos outros, só para se ele concorda consigo mesmo.

A correção aqui não é julgamento, e é isso que a torna segura: o total é trocado pelo valor que os
próprios itens dão, a linha é marcada para a mudança ficar visível, e o valor digitado original fica
no arquivo bruto. Quando existe um segundo registro, **confie no mais detalhado** — sete itens com
quantidades e preços são mais difíceis de errar de forma coerente do que um número.
