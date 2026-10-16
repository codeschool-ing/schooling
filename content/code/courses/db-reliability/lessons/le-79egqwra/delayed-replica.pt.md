---
title: Uma réplica atrasada de propósito
version: 1
---

Todo standby até aqui copia um erro tão fielmente quanto todo o resto; a lição 11 chamou isso de
`DELETE` replicado. Uma **réplica atrasada** mantém uma janela aberta: o `recovery_min_apply_delay`
faz ela receber o log na hora e aplicar cada transação só depois que o atraso tiver passado. Dois
minutos aqui, para que a lição não espere muito; uma hora ou mais na prática. Na figura da primeira
seção a réplica atrasada pende sozinha do primário; este lab tem dois standbys, então o atraso vai no
`standby1`, que também alimenta o `standby2`, e essa diferença aparece daqui a pouco. Configure:

```
ana@vm:~$ sudo -u postgres psql -p 5434 -c "ALTER SYSTEM SET recovery_min_apply_delay = '2min'" -c 'SELECT pg_reload_conf()'
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)
```

Agora o erro: uma limpeza de pedidos feita para os pedidos de teste de um cliente roda contra os
pedidos reais do cliente 7 no primário. Segundos depois, conte os pedidos do cliente 7 nos dois
standbys:

```
shop=# SELECT now();
              now              
-------------------------------
 2026-10-16 02:32:18.565434-03
(1 row)

shop=# DELETE FROM orders WHERE customer_id = 7;
DELETE 50
shop=# SELECT count(*) FROM orders WHERE customer_id = 7;
 count 
-------
    50
(1 row)
shop=# SELECT count(*) FROM orders WHERE customer_id = 7;
 count 
-------
     0
(1 row)
```

No `standby1` os **50 pedidos ainda estão lá**; o delete está no `pg_wal` dele, esperando os dois
minutos passarem. No `standby2` eles **sumiram**: uma cascata repassa o log conforme ele chega, e o
`standby2` não tem atraso próprio. Uma réplica atrasada protege só a si mesma, e qualquer servidor que
precise do atraso tem de estar pendurado no primário ou ter a configuração ele mesmo.

Pause o replay da réplica atrasada antes que os dois minutos acabem, copie as 50 linhas para fora dela
e copie-as de volta para o primário:

```
shop=# SELECT pg_wal_replay_pause();
 pg_wal_replay_pause 
---------------------
 
(1 row)
ana@vm:~$ psql -p 5434 shop -c "\copy (SELECT * FROM orders WHERE customer_id = 7) TO 'orders-7.csv' CSV"
COPY 50
ana@vm:~$ psql shop -c "\copy orders FROM 'orders-7.csv' CSV"
COPY 50
ana@vm:~$ psql -XAt shop -c "SELECT count(*) FROM orders WHERE customer_id = 7"
50
shop=# SELECT pg_wal_replay_resume();
 pg_wal_replay_resume 
----------------------
 
(1 row)
```

Cinquenta pedidos de volta no primário, com os ids originais, dois minutos depois de terem sido
apagados, e sem restauração. O `\copy` é o `psql` lendo ou gravando um arquivo do seu lado da conexão;
um `COPY` numa tabela com coluna identity mantém os ids que recebe. Retomar o replay deixa o `standby1`
aplicar o delete e depois a reinserção, e chegar às mesmas linhas que o primário.

## O que custa, e o que não cobre

- A réplica atrasada é **inútil para failover**: promovê-la significa esperar o atraso inteiro até ela
  alcançar, ou abrir mão da última hora. Ela é um standby a mais, nunca o que um failover usa.
- Ela retém uma hora de log, no disco dela e, através do seu slot, no do primário.
- Ela cobre um erro percebido **dentro do atraso**. Um percebido amanhã precisa da recuperação para um
  ponto no tempo da lição 6, a partir do arquivo, que continua sendo a última rede de proteção debaixo
  de tudo.
