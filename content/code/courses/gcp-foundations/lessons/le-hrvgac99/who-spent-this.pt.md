---
title: Quem gastou isto?
version: 1
---

**Três perguntas aparecem todo mês, e cada uma é uma consulta**: qual é de fato a fatura depois de subtrair os
créditos, que equipe a gastou, e o que foi gasto por ninguém em particular. As três rodam contra o mês que a
seção anterior fez, em `~/gcp/export`.

## O que a fatura é de fato

`credits` é uma lista em cada linha, então os créditos de uma linha são somados primeiro dentro dela, com uma
pequena consulta sobre a sua própria lista, e só depois somados entre as linhas. Salve como `net.sql`:

```sql
SELECT service.description AS service,
       round(sum(cost), 2) AS gross,
       round(sum((SELECT coalesce(sum(c.amount), 0) FROM unnest(credits) AS t(c))), 2) AS credits,
       round(sum(cost) + sum((SELECT coalesce(sum(c.amount), 0) FROM unnest(credits) AS t(c))), 2) AS net
FROM export
GROUP BY service
ORDER BY net DESC
```

```
ana@laptop:~/gcp/export$ python3 ask.py net.sql
┌────────────────┬────────┬─────────┬────────┐
│    service     │ gross  │ credits │  net   │
│    varchar     │ double │ double  │ double │
├────────────────┼────────┼─────────┼────────┤
│ Compute Engine │ 430.01 │  -66.53 │ 363.48 │
│ Cloud Pub/Sub  │  38.01 │   -1.15 │  36.86 │
│ Networking     │   1.03 │     0.0 │   1.03 │
└────────────────┴────────┴─────────┴────────┘
```

**O líquido é o que a fatura cobra; o bruto é o que o uso teria custado pelo preço de tabela.** Os créditos do
Compute Engine são o desconto por uso contínuo da lição 13, os do Pub/Sub o nível gratuito. Um relatório que
soma só o `cost` exagera a fatura em cada desconto que a conta ganhou, e o tamanho desse erro muda de mês para
mês conforme descontos começam e param.

## Que equipe gastou

Um rótulo é uma entrada numa lista, então o rótulo `team` é lido da lista com o mesmo tipo de pequena consulta,
e uma linha sem ele ganha um nome que diz isso em vez de uma célula vazia. Salve como `teams.sql`:

```sql
SELECT coalesce((SELECT l.value FROM unnest(labels) AS t(l) WHERE l.key = 'team'), '(no team)') AS team,
       project.id AS project,
       round(sum(cost), 2) AS gross
FROM export
GROUP BY team, project
ORDER BY gross DESC
```

```
ana@laptop:~/gcp/export$ python3 ask.py teams.sql
┌───────────┬─────────────────┬────────┐
│   team    │     project     │ gross  │
│  varchar  │     varchar     │ double │
├───────────┼─────────────────┼────────┤
│ planner   │ planner-prod    │ 380.19 │
│ data      │ planner-dev     │  38.01 │
│ planner   │ planner-staging │  33.37 │
│ (no team) │ planner-dev     │  16.45 │
│ network   │ planner-network │   1.03 │
└───────────┴─────────────────┴────────┘
```

São os rótulos da lição 3 se pagando. Os dois projetos da equipe planner se separam por `project`, e o Pub/Sub
da equipe de dados fica no `planner-dev` ao lado de uma linha sem equipe nenhuma.

## O que ninguém gastou

**Custo sem rótulo é a primeira coisa a ler**, porque é o custo pelo qual ninguém vai responder. Salve como
`forgotten.sql`:

```sql
SELECT project.id AS project,
       sku.description AS sku,
       round(sum(usage.amount)) AS hours,
       round(sum(cost), 2) AS gross
FROM export
WHERE len(labels) = 0
GROUP BY project, sku
```

```
ana@laptop:~/gcp/export$ python3 ask.py forgotten.sql
┌─────────────┬───────────────────────────────────────┬────────┬────────┐
│   project   │                  sku                  │ hours  │ gross  │
│   varchar   │                varchar                │ double │ double │
├─────────────┼───────────────────────────────────────┼────────┼────────┤
│ planner-dev │ N2 Instance Core running in Sao Paulo │  366.0 │  16.45 │
└─────────────┴───────────────────────────────────────┴────────┴────────┘
```

Cerca de doze horas de vCPU por dia, o mês todo, no projeto de desenvolvimento, numa máquina sem rótulo: o
primeiro item da lista da lição 13, *algo está rodando de que ninguém se lembra*. A consulta não diz que
máquina é, porque a exportação padrão não tem nomes de recursos; a detalhada tem, e olhar no `planner-dev`
atrás de uma instância sem rótulo `team` também resolve. Dezesseis dólares é pouco. A mesma consulta contra
uma conta real com quarenta projetos é como os grandes são achados.

## As mesmas perguntas no BigQuery

DuckDB e BigQuery falam os dois SQL com linhas aninhadas, e diferem em algumas grafias. Contra uma exportação
real, o `net.sql` fica assim, com o nome da tabela levando o id da conta de faturamento. **Isto não rodou**: não
há BigQuery no laboratório.

```sql
SELECT service.description AS service,
       ROUND(SUM(cost), 2) AS gross,
       ROUND(SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) AS c), 0)), 2) AS credits,
       ROUND(SUM(cost) + SUM(IFNULL((SELECT SUM(c.amount) FROM UNNEST(credits) AS c), 0)), 2) AS net
FROM `planner-logs.billing_export.gcp_billing_export_v1_012345_6789AB_CDEF01`
WHERE invoice.month = '202610'
GROUP BY service
ORDER BY net DESC
```

Três diferenças: `UNNEST(credits) AS c` nomeia o elemento direto, onde o DuckDB nomeia uma tabela e uma coluna,
`IFNULL` é a palavra do BigQuery para `coalesce` (que ele também aceita), e `len(labels)` seria
`ARRAY_LENGTH(labels)`. O `WHERE` em `invoice.month` é o acréscimo que importa com dados reais: **a exportação
guarda todo mês**, e uma consulta sem um mês nela soma todos. E como o BigQuery cobra consultas pelos bytes que
leem, o pessoal de finanças do planner roda estas contra um mês de cada vez também pelo segundo motivo.
