---
title: Uma dimensão muda, e os fatos não
version: 1
---

Um fato não muda depois que aconteceu. A venda de 8 de janeiro de 2024 vendeu um livro, a um preço,
numa loja, e isso continua verdade para sempre. **Uma dimensão descreve algo que continua existindo**,
e muda: um cliente se muda, sobe de nível no programa de fidelidade, tem o nome corrigido. O registro
dessas mudanças na rede, para o cliente número um:

```
ana@lab:~/wh$ duckdb wh.duckdb -c "SELECT changed_at, field, old_value, new_value FROM staging.customer_changes WHERE customer_id = 1 ORDER BY changed_at"
┌──────────────────────────┬─────────┬───────────┬───────────┐
│        changed_at        │  field  │ old_value │ new_value │
│ timestamp with time zone │ varchar │  varchar  │  varchar  │
├──────────────────────────┼─────────┼───────────┼───────────┤
│ 2024-01-08 17:21:54-03   │ tier    │ reader    │ regular   │
│ 2025-01-30 14:20:27-03   │ tier    │ regular   │ patron    │
└──────────────────────────┴─────────┴───────────┴───────────┘
```

Reader até 8 de janeiro de 2024, regular até 30 de janeiro de 2025, e patron desde então. Três
descrições de uma pessoa, cada uma verdadeira por um tempo.

A lição 1 mediu o que acontece quando o warehouse guarda só a última: 1.404 pedidos de 2024 contados
num estado para onde os compradores ainda não tinham se mudado. O mesmo acontece com o nível, e o
nível é um caso mais nítido, porque ele *existe* para ser analisado: o programa de fidelidade serve
para transformar readers em regulars e regulars em patrons, e o gerente quer saber o que cada nível
compra.

Kimball chamou isso de **dimensões de mudança lenta** (slowly changing dimensions), SCD: dimensões cujos
atributos mudam de vez em quando, não a cada transação. As mudanças são lentas; decidir o que fazer com
elas não é, e a decisão é tomada **por atributo**. O nível, a cidade e o nome de um cliente recebem
cada um a sua resposta, e as respostas são numeradas:

| tipo | o que acontece numa mudança | o passado |
|---|---|---|
| 0 | nada: o valor original fica | congelado no começo |
| 1 | o valor é sobrescrito | reescrito para parecer hoje |
| 2 | uma linha nova é acrescentada para a nova versão | guardado, versão a versão |
| 3 | o valor antigo vai para uma coluna "anterior" | um passo dele guardado |

Os tipos 4 e 6, que a seção 10 cobre, combinam esses. O resto desta lição constrói cada um sobre os
clientes da rede e faz a todos a mesma pergunta.
