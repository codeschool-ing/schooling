---
title: O slot, e o que ele guarda para um standby que se foi
version: 1
---

Sem um slot, o primário recicla os segmentos antigos no seu próprio ritmo, e um standby que fica para
trás o bastante (uma queda de rede, uma manutenção longa, um disco lento) pede um segmento que não
existe mais e nunca consegue alcançar o primário. Um **slot de replicação** evita isso: o primário
guarda todo segmento a partir do `restart_lsn` do slot, até o standby confirmar que já o tem.

```
shop=# SELECT slot_name, slot_type, active, restart_lsn, wal_status FROM pg_replication_slots;
 slot_name | slot_type | active | restart_lsn | wal_status 
-----------+-----------+--------+-------------+------------
 standby1  | physical  | t      | 0/4006608   | reserved
(1 row)
```

Um slot físico, `active` porque o standby está conectado, e `wal_status: reserved`: o log de que ele
precisa está dentro do que o primário guardaria de qualquer jeito.

## Um standby que para

A promessa não tem prazo de validade. Pare o standby e deixe o primário continuar trabalhando:

```
ana@vm:~$ sudo pg_ctlcluster 16 standby stop
shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# UPDATE orders SET total_cents = total_cents + 1;
UPDATE 50001

shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT slot_name, active, wal_status, pg_size_pretty(pg_current_wal_lsn() - restart_lsn) AS held FROM pg_replication_slots;
 slot_name | active | wal_status | held  
-----------+--------+------------+-------
 standby1  | f      | reserved   | 49 MB
(1 row)
ana@vm:~$ sudo du -sh /var/lib/postgresql/16/main/pg_wal
81M	/var/lib/postgresql/16/main/pg_wal
```

O slot não está mais ativo, e segura **49 MB** de log que o primário não pode reciclar, porque o
standby pode voltar para buscá-lo. Um primário de verdade escreve gigabytes por hora; um standby que
morreu na sexta, com o slot ainda no primário, segura o log do fim de semana inteiro até segunda. É o
archive command quebrado da lição 4 de novo, e o slot do `pg_receivewal` da lição 4: a mesma pilha,
com o mesmo final, **um disco cheio e um primário que para**.

As duas defesas são as da lição 4, aplicadas aos slots:

- **Vigie-os.** Um `pg_replication_slots` com `active = f`, ou com `pg_current_wal_lsn() -
  restart_lsn` crescendo, é um alerta, e um slot que ninguém sabe explicar é removido com
  `pg_drop_replication_slot`.
- **Ponha um limite neles**, que é o que a próxima seção faz.
