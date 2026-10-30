---
title: Smart tuning, e a consulta que lê a view no lugar
version: 1
---

**Uma visão materializada só economiza dinheiro se as consultas a lerem, e o BigQuery consegue fazê-las
lê-la sem que ninguém peça.** A documentação do Google chama isso de **smart tuning**: quando uma consulta
na tabela base pode ser respondida por uma visão materializada, o BigQuery reescreve a consulta para ler a
view, e o painel que ainda diz `FROM quitanda.orders` é servido por `daily_sales_mv`. Ninguém precisa
mudar um relatório, e quem escreve um novo não precisa saber que a view existe. Nada disso pode rodar aqui;
a medição abaixo é dos bytes que cada versão seria cobrada, calculados com o `bqbill.py` da aula 16.

## Quando uma consulta pode ser reescrita

**Uma consulta pode ser respondida pela view quando tudo de que ela precisa está na view.** A pergunta do
painel, vendas por bairro em setembro, agrupa por colunas pelas quais a view agrupa, filtra por uma coluna
que a view tem e soma uma coluna que a view já soma. Uma consulta que pede vendas por loja não pode ser
reescrita: a view não tem `store_id`, e um agregado não pode ser desmontado de novo. Uma consulta que pede
o valor médio dos pedidos pode, em princípio, já que uma média é uma soma sobre uma contagem e a view tem
as duas; a documentação lista quais agregados e filtros a reescrita trata, e a regra dela é a que qualquer
leitor consegue aplicar: a view tem de ter toda coluna que a consulta toca, num grão não mais grosso do que
a consulta pede.

## As duas contas, lado a lado

**Sem a view, o painel lê três colunas de todo pedido; com ela, três colunas de 480 linhas.** O
`bqbill.py` funciona em qualquer pasta dentro de `warehouse/` com um `dt`, e `daily_sales` é uma:

```
ana@laptop:~/gcp$ python3 bqbill.py orders dt,district,total_cents
3 columns of orders, 0001-01-01 to 9999-12-31
  bytes processed      31,443,638
  bytes billed         31,457,280   0.000322 USD
ana@laptop:~/gcp$ python3 bqbill.py daily_sales dt,district,sales
3 columns of daily_sales, 0001-01-01 to 9999-12-31
  bytes processed          12,120
  bytes billed         10,485,760   0.000107 USD
```

**31.443.638 bytes processados contra 12.120.** Na tabela da Quitanda as duas são cobradas pelo menos pelo
mínimo de 10 MB, e a consulta da tabela base custa três vezes a da view. Os 12.120 bytes são 480 linhas de
`dt`, `sales` e o nome do bairro, que é o agregado inteiro; os 31 MB da tabela base são `dt`, `district` e
`total_cents` de todo pedido. **A mil vezes o tamanho da Quitanda, a consulta da tabela base seria cerca de
30 GB por execução e a da view cerca de 12 MB**, porque a view cresce com o número de dias e bairros e não
com o número de pedidos. Um painel atualizando de hora em hora lê a view 720 vezes por mês pelo custo de um
punhado de varreduras da tabela base.

**Esse também é o limite honesto da comparação.** A consulta na view, no BigQuery, leria também o delta, as
linhas da base que chegaram desde a última atualização; uma atualização de hora em hora depois de uma carga
de hora em hora mantém esse delta em cerca de uma hora de pedidos. E as próprias atualizações são
consultas: a uma por noite, cada uma lendo um dia de pedidos, elas somam ao mês os bytes de um dia para
cada dia dele.

## O que quebra a reescrita

**Uma consulta que a view não responde roda na tabela base, em silêncio, e é cobrada como tal.** Não há
erro nem aviso na conta: a consulta só custa o que custaria sem a view. Então o hábito da aula 16 vale aqui
também: leia o que o job de fato fez. No BigQuery as estatísticas do job dizem se uma visão materializada
foi usada, e o grafo de execução lê da view em vez da tabela quando foi. Um painel que acrescenta uma
coluna que a view não tem voltou, sem alarde, a varrer todo pedido.
