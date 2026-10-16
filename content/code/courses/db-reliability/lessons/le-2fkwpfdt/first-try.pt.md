---
title: A primeira tentativa, e o segmento que não estava lá
version: 1
---

A restauração é a da lição 5, com mais três opções: **`--type=xid --target=742`** nomeia a
transação, **`--target-exclusive`** diz para parar antes dela em vez de depois, e
**`--target-action=pause`** diz o que fazer ao chegar, o que a próxima seção explica. Restaure no
segundo servidor, como antes, e suba-o:

```
ana@vm:~$ sudo pg_ctlcluster 16 restore stop
ana@vm:~$ sudo rm -rf /var/lib/postgresql/16/restore
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main --pg1-path=/var/lib/postgresql/16/restore --archive-mode=off --type=xid --target=742 --target-exclusive --target-action=pause restore
ana@vm:~$ sudo tail -n 4 /var/lib/postgresql/16/restore/postgresql.auto.conf
archive_mode = 'off'
restore_command = 'pgbackrest --pg1-path=/var/lib/postgresql/16/restore --stanza=main archive-get %f "%p"'
recovery_target_xid = '742'
recovery_target_inclusive = 'false'
ana@vm:~$ sudo pg_ctlcluster 16 restore start 2>&1 | grep -E "FATAL|could not start"
2026-10-10 16:36:15.295 -03 [4460] FATAL:  recovery ended before configured recovery target was reached
pg_ctl: could not start server
```

O pgBackRest escreveu o alvo nas configurações da cópia, `recovery_target_xid` e
`recovery_target_inclusive = 'false'`, e o servidor se recusou a subir: **recovery ended before
configured recovery target was reached**, a recuperação terminou antes de chegar ao alvo configurado.
Ele reaplicou todo segmento que conseguiu buscar e nunca encontrou a transação 742.

A pergunta é quais segmentos ele conseguia buscar:

```
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info | grep "wal archive"
        wal archive min/max (16): 000000010000000000000002/000000010000000000000003
shop=# SELECT pg_switch_wal();
 pg_switch_wal 
---------------
 0/4165F08
(1 row)
ana@vm:~$ sudo -u postgres pgbackrest --stanza=main info | grep "wal archive"
        wal archive min/max (16): 000000010000000000000002/000000010000000000000004
```

O arquivo terminava no `…03`. A transação 742 está no `…04`, **o segmento que o servidor ainda está
escrevendo**, e um segmento só é arquivado quando termina: o problema da hora tranquila da lição 4,
chegando no pior momento possível. O `pg_switch_wal()` no servidor de produção o termina, o
`archive-push` o envia, e o `info` agora termina no `…04`.

Essa falha é o jeito mais comum de uma primeira recuperação para um ponto no tempo dar errado, e vale
dois hábitos:

- **Antes de restaurar para um momento recente, termine o segmento atual** no servidor de produção, se
  ele ainda estiver rodando, e confira se o arquivo o tem.
- **Leia a recusa como boa notícia.** O PostgreSQL parou em vez de abrir um banco que não está no
  momento que você pediu. Uma cópia que tivesse terminado em silêncio no `…03` e se dissesse
  recuperada estaria sem os cinco pedidos bons, e alguém só descobriria depois.
