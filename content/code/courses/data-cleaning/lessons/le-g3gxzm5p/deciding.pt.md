---
title: Decidir, e o que as decisões fizeram
version: 1
---

**Cada tipo de valor atípico desta aula recebeu uma decisão diferente, e cada decisão fica escrita no
dado como uma marca.** Reunidas num script:

```schooling-example
{
  "language": "python",
  "file": "decide.py",
  "parts": [
    {
      "code": "import pandas as pd\n\nfrom orders import orders\nfrom typos import wrong\n\n"
    },
    {
      "code": "decided = orders.copy()\ndecided[\"flag\"] = \"none\"\n",
      "note": "Uma coluna de marca, para toda decisão ficar visível no dado."
    },
    {
      "code": "fix = decided[\"order_id\"].isin(wrong[\"order_id\"])\ndecided.loc[fix, \"total\"] = decided.loc[fix, \"order_id\"].map(\n    wrong.set_index(\"order_id\")[\"expected\"])\ndecided.loc[fix, \"flag\"] = \"total recomputed from lines\"\n",
      "note": "**Totais digitados** recebem o valor dos próprios itens."
    },
    {
      "code": "negative = decided[\"total\"] < 0\ndecided.loc[negative, \"total\"] = 0.0\ndecided.loc[negative, \"flag\"] = \"coupon above basket: charged 0\"\n",
      "note": "**Totais negativos** viram o que foi cobrado, zero."
    },
    {
      "code": "corporate = decided[\"name\"].str.contains(\"Ltda|Escritório|Clínica|Colégio|Agência|Studio\", na=False)\ndecided.loc[corporate, \"flag\"] = \"corporate order\"\n",
      "note": "**Pedidos corporativos** mantêm os totais e ganham um rótulo. Os nomes são as seis empresas que as seções anteriores acharam."
    },
    {
      "code": "delivered = decided[\"status\"] == \"delivered\"\nfor label, frame in [(\"as exported\", orders[orders[\"status\"] == \"delivered\"]),\n                     (\"decided\", decided[delivered]),\n                     (\"decided, households only\", decided[delivered & ~corporate])]:\n    print(f\"{label:25} revenue {frame['total'].sum():12,.2f}  mean {frame['total'].mean():6.2f}  \"\n          f\"median {frame['total'].median():6.2f}\")\nprint(decided[\"flag\"].value_counts().to_string())\n",
      "note": "Receita, média e mediana dos pedidos entregues, como exportado e como decidido, e a contagem de cada marca."
    }
  ]
}
```

```
ana@lab:~/clean$ python decide.py
as exported               revenue 2,501,334.35  mean  94.35  median  57.60
decided                   revenue 2,493,548.15  mean  94.06  median  57.60
decided, households only  revenue 2,380,737.65  mean  89.86  median  57.50
flag
none                              28366
coupon above basket: charged 0      137
corporate order                      16
total recomputed from lines           7
```

As marcas, de baixo para cima: 7 totais recalculados pelos itens, 16 pedidos corporativos mantidos e
rotulados, 137 totais negativos levados a zero, e 28.366 pedidos intocados. A conta dos reembolsos e
o preço do açúcar não estão no script, porque nenhum dos dois é decisão de limpeza: os dois foram
para quem é dono deles, e o relatório diz isso.

O efeito nos números que um gerente lê:

- a **receita** dos pedidos entregues cai de R$ 2.501.334,35 para R$ 2.493.548,15, com os sete totais
  digitados voltando ao que os itens dizem;
- o **pedido médio** cai só de 94,35 para 94,06, e para 89,86 só nas famílias;
- a **mediana** não se mexe, R$ 57,60, e quase nada nas famílias, R$ 57,50.

Essa última linha repete a aula 4 do `statistics` num caso real: a mediana ignora o que acontece nas
pontas, o que a torna o resumo certo de um pedido típico e o lugar errado para procurar erros.

| o que se achou | decisão | marca |
|---|---|---|
| total dez vezes os itens | trocar pelo total dos itens | `total recomputed from lines` |
| pedidos corporativos de dezembro | manter, rotular | `corporate order` |
| cupom acima da cesta | levar a zero, como cobrado | `coupon above basket: charged 0` |
| 23 reembolsos de uma conta nova | informar ao time de fraude | nenhuma: não é decisão de limpeza |
| açúcar cobrado a R$ 134,90 | informar compradores e financeiro | nenhuma: não é decisão de limpeza |

**A tabela é a entrega.** Um arquivo limpo sem ela pede ao próximo leitor que confie em sete totais
mudados; com ela, toda mudança se confere, e os dois achados que não eram limpeza estão na mesa de
alguém em vez de numa nota de rodapé que ninguém escreve.
