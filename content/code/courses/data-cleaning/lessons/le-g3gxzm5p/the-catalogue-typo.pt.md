---
title: O erro do catálogo que chegou aos clientes
version: 1
---

**A aula 5 achou o açúcar listado duas vezes no catálogo, a R$ 12,90 e a R$ 134,90**, e suspeitou de
um erro de digitação. Os itens dos pedidos dizem o que aconteceu depois. Todo item desse produto, por
mês e preço:

```
ana@lab:~/clean$ python -c "from lines import lines as l; s = l[l['code'] == '00343'].copy(); s['month'] = s['order_id'].astype(int); import pandas as pd; o = pd.read_csv('raw/orders.csv', dtype=str).drop_duplicates(); s = s.merge(o[['order_id', 'ordered_at']], on='order_id'); s['month'] = s['ordered_at'].str[:7]; print(s.groupby(['month', 'unit_price']).size().to_string())"
month    unit_price
2025-01  12.9           49
2025-02  12.9           43
2025-03  12.9           60
2025-04  12.9           75
2025-05  12.9           84
2025-06  12.9           86
2025-07  12.9            1
         134.9          83
2025-08  134.9          91
2025-09  134.9          81
2025-10  134.9          75
2025-11  134.9          75
2025-12  134.9         105
```

Até junho, R$ 12,90. A partir de julho, R$ 134,90 em todos os itens menos um. **O preço novo foi
cobrado.** Os pedidos são coerentes por dentro — a checagem da aula 7 os aprova, porque itens e totais
concordam — e é exatamente por isso que nenhuma checagem de coerência o achou: o erro está antes dos
dois.

O tamanho dele:

```
ana@lab:~/clean$ python -c "from lines import lines as l; s = l[(l['code'] == '00343') & (l['unit_price'] > 100)]; print(len(s), s['order_id'].nunique(), round(s['line_cents'].sum() / 100, 2), round((s['quantity'] * (134.90 - 12.90)).sum(), 2))"
510 510 127615.4 115412.0
```

510 itens em 510 pedidos, R$ 127.615,40 de açúcar vendido no preço errado, e R$ 115.412,00 a mais do que
o preço antigo teria cobrado.

**Isso não é uma decisão de limpeza.** Corrigir o preço na análise faria a receita descrever dinheiro
que a empresa não recebeu; deixá-lo faria descrever dinheiro que ela não deveria ter cobrado. O que a
analista faz é o mesmo que com os reembolsos: informar, com os números, a quem decide — aqui os
compradores, donos do catálogo, e o financeiro, que vai querer reembolsar 510 clientes. A análise
então diz com clareza qual número usa.

A lição geral é sobre onde olhar. Um erro dentro de um registro é pego pelos outros campos do
registro; **um erro numa tabela de referência é copiado para todo registro que a usa**, de forma
coerente, e só uma comparação no tempo ou com um preço de fora o mostra. Um preço que sobe dez vezes
de um dia para o outro é o tipo de mudança que um gráfico mensal de preços torna óbvia, e a aula 15
desenha um.
