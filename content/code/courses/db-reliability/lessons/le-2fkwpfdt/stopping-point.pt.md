---
title: O alvo, e parar ali para olhar
version: 1
---

Com o segmento no arquivo, a mesma restauração de novo:

```
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=xid --target=742 --target-exclusive --target-action=pause restore
ana@vm:~$ sudo pg_ctlcluster 16 restore start
ana@vm:~$ sudo grep -E "starting point-in-time|recovery stopping|pausing at|ready to accept" /var/log/postgresql/postgresql-16-restore.log | tail -n 4
2026-10-10 16:36:20.129 -03 [4524] LOG:  starting point-in-time recovery to XID 742
2026-10-10 16:36:20.320 -03 [4521] LOG:  database system is ready to accept read-only connections
2026-10-10 16:36:20.330 -03 [4524] LOG:  recovery stopping before commit of transaction 742, time 2026-10-10 16:36:08.563344-03
2026-10-10 16:36:20.330 -03 [4524] LOG:  pausing at the end of recovery
```

O log conta a recuperação em quatro linhas: partiu para a transação 742, abriu para conexões
**somente leitura** assim que a cópia ficou consistente, depois **parou antes do commit da transação
742**, citando o horário de commit que o dump mostrou, e pausou.

## Quatro jeitos de nomear o momento

| configuração | para em | quando usar |
|---|---|---|
| `recovery_target_xid` | uma transação | o log mostrou qual, como aqui |
| `recovery_target_time` | um ponto no relógio | você sabe mais ou menos quando, e nada mais preciso |
| `recovery_target_lsn` | uma posição no log | o dump deu um registro em vez de uma transação |
| `recovery_target_name` | um ponto com nome | alguém rodou `pg_create_restore_point('before-migration')` antes |

Cada um vem com `recovery_target_inclusive`, que decide se o próprio alvo é reaplicado. Para uma
transação que você quer desfeita, é `false`; foi isso que o `--target-exclusive` configurou. E o
último é o seguro mais barato que existe: **um ponto de restauração com nome antes de cada mudança
arriscada**, uma migração, um update em massa, uma limpeza, custa uma chamada de função e transforma
"lá pelas quatro" num alvo exato.

## Pause, e olhe antes de se comprometer

O `--target-action=pause` é o motivo de o servidor ainda estar em recuperação. Ele para no alvo e
espera, somente leitura, para você conferir que o alvo era o certo **antes** que qualquer coisa
irreversível aconteça:

```
shop=# SELECT pg_is_in_recovery(), pg_get_wal_replay_pause_state();
 pg_is_in_recovery | pg_get_wal_replay_pause_state 
-------------------+-------------------------------
 t                 | paused
(1 row)

shop=# SELECT count(*), min(placed_at), max(id) FROM orders;
 count |          min           |  max  
-------+------------------------+-------
 50005 | 2026-01-01 09:07:00-03 | 50005
(1 row)
```

**50005 pedidos**: os cinquenta mil de antes, mais os cinco que chegaram antes do `DELETE`, e o mais
antigo é de novo de 1º de janeiro. Os três pedidos depois do `DELETE` não estão aqui, porque vieram
depois do alvo; esse é um problema para o reparo, duas seções adiante.

Se a cópia estivesse errada (o alvo uma transação cedo demais, ou tarde demais), a cura neste ponto é
barata: pare o servidor e restaure de novo com outro alvo. Nada foi decidido ainda. Aqui ela está
certa, então encerre a recuperação:

```
shop=# SELECT pg_wal_replay_resume();
 pg_wal_replay_resume 
----------------------
 
(1 row)
shop=# SELECT pg_is_in_recovery();
 pg_is_in_recovery 
-------------------
 f
(1 row)

shop=# SELECT timeline_id FROM pg_control_checkpoint();
 timeline_id 
-------------
           2
(1 row)
```

O `pg_wal_replay_resume()` deixa a recuperação terminar, e o servidor vira um servidor comum, que
aceita escritas, **na timeline 2**. As outras duas ações pulam a olhada: `promote` faz isso
imediatamente ao chegar, e `shutdown` para o servidor no alvo, para uma restauração que vai ser
iniciada em outro lugar.
