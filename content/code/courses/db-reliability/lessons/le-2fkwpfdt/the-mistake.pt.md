---
title: Um dia de trabalho, e o DELETE no meio dele
version: 1
---

A lição 2 reparou um erro a partir de um dump e terminou no limite dele: o dump era mais antigo que o
erro, então toda mudança feita entre os dois se perdeu ou teve que ser reparada à mão. Esta lição
reaplica o log até **o momento antes do erro**, e não perde nada do que foi escrito antes dele.

O cenário é o da lição 5: o pgBackRest arquivando cada segmento, e um backup full tirado no começo
do dia.

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info
stanza: main
    status: ok
    cipher: none

    db (current)
        wal archive min/max (16): 000000010000000000000002/000000010000000000000003

        full backup: 20261010-163600F
            timestamp start/stop: 2026-10-10 16:36:00-03 / 2026-10-10 16:36:03-03
            wal start/stop: 000000010000000000000003 / 000000010000000000000003
            database size: 33.8MB, database backup size: 33.8MB
            repo1: backup set size: 4.4MB, backup size: 4.4MB
```

## O dia

Os pedidos chegam, um por segundo. No meio deles, alguém roda uma limpeza que era para uma cópia do
banco, contra o banco de verdade:

```
ana@vm:~$ for i in 1 2 3 4 5; do psql -q shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES ($i, 1000 + $i, now())"; sleep 1; done
ana@vm:~$ psql shop -c "DELETE FROM orders WHERE placed_at < '2026-03-01'"
DELETE 12059
ana@vm:~$ for i in 6 7 8; do psql -q shop -c "INSERT INTO orders (customer_id, total_cents, placed_at) VALUES ($i, 1000 + $i, now())"; sleep 1; done
```

Cinco pedidos, o `DELETE`, mais três pedidos. **Doze mil e cinquenta e nove pedidos de janeiro e
fevereiro sumiram**, e os oito novos são vendas reais que não podem se perder no reparo. Esse é o
formato de quase toda recuperação para um ponto no tempo: uma transação ruim, com transações boas dos
dois lados dela.

## Alguém percebe

Alguém olha o shop alguns segundos depois e vê:

```
shop=# SELECT count(*), min(placed_at) FROM orders;
 count |          min           
-------+------------------------
 37949 | 2026-03-01 00:00:00-03
(1 row)

shop=# SELECT pg_walfile_name(pg_current_wal_lsn());
     pg_walfile_name      
--------------------------
 000000010000000000000004
(1 row)
```

O pedido mais antigo agora é de 1º de março, e a contagem é 37949 onde deveria ser 50008. A segunda
consulta é a primeira coisa que vale perguntar num incidente assim: **qual segmento do log está sendo
escrito agora**. O erro aconteceu nos últimos segundos, então está nesse segmento, o `…04`, e é ali
que a próxima seção vai procurá-lo.

Uma coisa a fazer logo, antes de qualquer outra, é não fazer nada que escreva. Cada transação daqui em
diante é mais uma coisa que ou vai ter que ser reaplicada na cópia restaurada ou vai se perder, e
quanto menos houver, mais simples fica o reparo.
