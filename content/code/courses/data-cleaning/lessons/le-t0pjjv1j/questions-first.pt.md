---
title: Perguntas primeiro
version: 1
---

**Análise exploratória de dados** é o primeiro olhar sobre dados em que você agora confia: resumos,
contagens e gráficos, escolhidos para descobrir o que os dados dizem antes que alguém decida o que
eles deveriam dizer. Não é uma atividade separada da limpeza. Toda aula até aqui explorou um pouco
para achar o próximo defeito; a diferença agora é que os defeitos estão tratados, então o que
aparece é sobre o negócio, não sobre os arquivos.

A exploração vai melhor com perguntas escritas antes, mesmo simples, porque uma pergunta decide o
que calcular e impede que uma tarde longa vire um passeio por todas as colunas:

- **O que é típico, e quanto varia?** Uma coluna de cada vez.
- **Quando acontece, e como muda?** As mesmas colunas ao longo do tempo.
- **O que se move junto?** Duas colunas de cada vez.
- **Onde está o dinheiro?** O total, decomposto.

As respostas partem de um arquivo pequeno que todo comando desta aula importa. Ele aplica as
decisões das aulas anteriores uma vez, para que nenhum gráfico saia de uma coluna que uma aula
anterior já corrigiu:

```schooling-example
{
  "language": "python",
  "file": "explore.py",
  "parts": [
    {
      "code": "from categorise import products  # lesson 8: one category and department per product\nfrom derive import orders  # lesson 12: decided totals, hour, weekday, items, corporate\nfrom lines import lines\n\n",
      "note": "Três aulas anteriores, importadas em vez de repetidas: categorias, pedidos decididos e itens convertidos."
    },
    {
      "code": "delivered = orders[orders[\"status\"] == \"delivered\"].copy()\n",
      "note": "**Só pedidos entregues**: um pedido cancelado ou reembolsado não é venda."
    },
    {
      "code": "delivered[\"month\"] = delivered[\"placed\"].dt.to_period(\"M\")\n",
      "note": "O mês de cada pedido, para tudo o que é ao longo do tempo."
    },
    {
      "code": "catalogue = products.drop_duplicates(\"product_code\").rename(columns={\"product_code\": \"code\"})\n",
      "note": "Uma linha por código de produto, como a aula 11 exigiu antes de juntar."
    },
    {
      "code": "sold = lines[lines[\"order_id\"].isin(delivered[\"order_id\"])].merge(\n    catalogue[[\"code\", \"category\", \"department\"]], on=\"code\", how=\"left\", validate=\"many_to_one\")\n",
      "note": "**Os itens dos pedidos entregues**, cada um com a sua categoria, juntados muitos para um."
    }
  ]
}
```

Duas escolhas nele moldam todo número que vem depois, e as duas estão ditas aqui para ninguém ter
de adivinhar. **Só pedidos entregues contam**, 26.510 deles, porque um pedido cancelado ou
reembolsado não é venda. **Os dezesseis pedidos corporativos ficam, marcados**, para que cada seção
possa mostrá-los ou deixá-los de lado de propósito.
