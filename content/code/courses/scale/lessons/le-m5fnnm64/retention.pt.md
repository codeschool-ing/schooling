---
title: Jogando dados velhos fora
version: 1
---

A segunda coisa em que as partições são boas é apagar. Uma tabela de vendas que guarda dezoito
meses precisa perder um mês de linhas por mês, e há dois jeitos de fazer isso.

Numa tabela única, é um `DELETE` com uma data no `WHERE`. Numa tabela particionada, a partição mais
antiga pode ser desanexada e descartada. Este script cronometra os dois, na tabela da última seção;
o `DELETE` roda dentro de uma transação desfeita no fim, para que as linhas continuem lá para o
segundo jeito:

```sql
-- retention.sql
\timing on
BEGIN;
DELETE FROM sales WHERE sold_at < '2026-02-01';
ROLLBACK;
ALTER TABLE sales DETACH PARTITION sales_2026_01;
DROP TABLE sales_2026_01;
```

```
ana@lab:~/tickets$ docker compose cp retention.sql db:/tmp/retention.sql
 tickets-db-1 Copying retention.sql to tickets-db-1:/tmp/retention.sql
 tickets-db-1 Copied retention.sql to tickets-db-1:/tmp/retention.sql
ana@lab:~/tickets$ docker compose exec db psql -U tickets -f /tmp/retention.sql
Timing is on.
BEGIN
Time: 0.225 ms
DELETE 205529
Time: 198.865 ms
ROLLBACK
Time: 0.189 ms
ALTER TABLE
Time: 6.859 ms
DROP TABLE
Time: 3.539 ms
```

O `DELETE` levou **199 ms** para 205 529 linhas, e desanexar e descartar **menos de 11 ms
juntos**. Os números são pequenos porque a tabela é pequena, e o que cresce é a proporção: o custo
de um `DELETE` é proporcional às linhas que ele remove, enquanto descartar uma partição custa mais
ou menos o mesmo para mil linhas ou um bilhão, porque remove arquivos e não linhas.

O que o cronômetro não mostra é pior para o `DELETE`:

- **Toda linha apagada é uma mudança no log.** Ela é gravada no WAL, enviada a toda réplica e
  aplicada lá também, então um delete grande é uma rajada de atraso de replicação em todas as
  réplicas ao mesmo tempo.
- **Linhas apagadas não somem.** O PostgreSQL as marca como mortas e as deixa no lugar até o
  `VACUUM` recuperar o espaço, então a tabela continua do mesmo tamanho no disco por um tempo e os
  índices continuam com as entradas delas.
- **Ele segura travas em toda linha que apaga** até confirmar, e um demorado disputa com as vendas
  que continuam chegando.

`DETACH PARTITION` tira a filha da pai, e depois disso ela é uma tabela comum que as consultas em
`sales` não veem mais. É um bom momento para uma pausa: o mês antigo pode ser copiado para um
armazenamento mais barato, ou guardado por um tempo caso alguém pergunte, antes de o `DROP TABLE`
removê-lo. Numa tabela movimentada, `DETACH PARTITION … CONCURRENTLY` faz o mesmo sem bloquear as
consultas na pai, ao preço de ser mais lento e não rodar dentro de uma transação.
