---
title: Um público é um modelo com um filtro
version: 1
---

As telas dos produtos para o marketing giram em torno do **público**: uma lista de clientes escolhidos
por regras — clientes de escritório, em risco, que valem mais que certo valor —, mantida atualizada e
mandada a uma ferramenta. Num produto composable, um público é montado sobre um modelo que alguém de
dados escreveu, com filtros que um profissional de marketing escolhe em menus. Por baixo, é uma cláusula
`WHERE`.

Os clientes de escritório da Lantern, por saúde:

```
lantern=# SELECT health, count(*) AS customers, sum(net_revenue) AS net_revenue
lantern-# FROM activation.crm_contacts
lantern-# WHERE segment = 'office'
lantern-# GROUP BY health ORDER BY 2 DESC;
 health  | customers | net_revenue 
---------+-----------+-------------
 active  |       102 |   204917.62
 at risk |        43 |    87377.11
 lapsed  |        42 |    63526.32
(3 rows)
```

Quarenta e três clientes de escritório estão *at risk*: compraram nos últimos 120 dias e não nos últimos
45, e juntos gastaram R$ 87.377,11 em toda a vida da loja. Essa é a lista que quem liga para clientes de
escritório quer. Escrita, ela é uma view:

```sql
CREATE VIEW activation.office_win_back AS
SELECT external_id, net_revenue, last_order
FROM activation.crm_contacts
WHERE segment = 'office' AND health = 'at risk';
```

```
lantern=# CREATE VIEW activation.office_win_back AS
lantern-# SELECT external_id, net_revenue, last_order
lantern-# FROM activation.crm_contacts
lantern-# WHERE segment = 'office' AND health = 'at risk';
CREATE VIEW

lantern=# SELECT count(*) AS customers, sum(net_revenue) AS net_revenue,
lantern-#        min(last_order) AS earliest, max(last_order) AS latest
lantern-# FROM activation.office_win_back;
 customers | net_revenue |  earliest  |   latest   
-----------+-------------+------------+------------
        43 |    87377.11 | 2026-02-19 | 2026-05-02
(1 row)
```

Quarenta e três clientes, com últimos pedidos entre 19 de fevereiro e 2 de maio: exatamente a janela que
a definição desenha. Três propriedades fazem disso um público, e não uma exportação:

- **É uma definição, não uma lista.** Amanhã alguns desses 43 compram de novo e saem, e outros cruzam a
  linha dos 45 dias e entram, sem que ninguém refaça nada.
- **Herda as palavras.** *At risk* e *receita líquida* querem dizer o que a aula 2 e a aula 3 disseram,
  porque o público é montado sobre `crm_contacts`, que é montado sobre a camada semântica.
- **É mandado como qualquer modelo.** Pela sincronização da aula 7, para o CRM como uma lista ou como um
  campo em cada contato, com a mesma diferença, a mesma chave e o mesmo delete — um cliente que sai do
  público é uma linha que saiu do modelo.

O que os produtos acrescentam é o menu: um profissional de marketing monta
`segment = 'office' AND health = 'at risk'` sem escrevê-lo, e vê uma prévia de quantas pessoas o público
tem antes de mandá-lo a qualquer lugar. O que eles não conseguem acrescentar é a definição de *at risk*.
Se ela ainda não está num modelo, o menu oferece as colunas que existirem, e cada profissional de
marketing monta a sua.
