---
title: Ler o banco dos outros com educação
version: 1
---

O banco da loja existe para registrar vendas. **Cada consulta que um pipeline manda para ele é carga
que os caixas não pediram**, e a pessoa responsável por ele vai julgar o pipeline por uma coisa só:
se os caixas ficaram lentos. Quatro hábitos evitam isso.

## Um papel que só lê

O pipeline não deve se conectar como dono da loja. Ele recebe um papel próprio, com permissão para
ler e nada mais:

```
ana@vm:~/etl$ psql -q -c "CREATE ROLE etl_reader LOGIN; GRANT SELECT ON ALL TABLES IN SCHEMA public TO etl_reader"
ana@vm:~/etl$ psql -U etl_reader -c "SELECT count(*) FROM orders"
 count 
-------
 18020
(1 row)

ana@vm:~/etl$ psql -U etl_reader -c "UPDATE orders SET status = 'cancelled' WHERE order_id = 100001"
ERROR:  permission denied for table orders
```

O que importa é o segundo comando. Um bug no pipeline, um `UPDATE` colado no terminal errado, uma
biblioteca que "ajuda" criando uma tabela: nenhum deles toca a loja por esse papel. E no
`pg_stat_activity`, que lista cada sessão aberta, as conexões do pipeline agora têm um nome próprio,
que é como o responsável pela origem encontra você antes de encontrar o problema.

## Outro lugar para ler

O lugar de uma leitura grande é uma **réplica de leitura**: uma cópia do banco que o PostgreSQL mantém
atualizada a partir do log de escrita antecipada do primário, um segundo ou pouco mais atrás dele, e
que não registra vendas. Os caixas nunca percebem uma extração que roda lá. O laboratório não tem
réplica, e o curso lê o primário; em produção, essa é uma decisão que alguém deveria tomar em voz
alta.

## Uma hora para ler

As extrações noturnas rodam nas horas em que a loja está fechada, e o agendamento do laboratório a
partir da lição 9 diz isso. A loja online nunca fecha, o que é mais uma razão para a réplica ser a
resposta normal.

## Menos para ler

A consulta mais barata é a que lê só o que mudou. Toda extração das lições 1 e 2 leu um dia ou uma
semana inteira de novo; a lição 4 lê só as linhas modificadas desde a última execução, e a lição 5
lê as mudanças a partir do próprio log do banco, sem consultar as tabelas.
