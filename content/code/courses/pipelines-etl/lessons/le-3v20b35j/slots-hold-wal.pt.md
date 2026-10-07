---
title: O slot que ninguém lê
version: 1
---

Um slot promete ao seu leitor que nenhuma mudança vai se perder. **O PostgreSQL cumpre essa promessa
guardando cada byte de WAL que o slot ainda não consumiu** — no disco da origem, pelo tempo que for
preciso.

No começo desta lição a Ana também criou um segundo slot, `forgotten`, com
`psql -c "SELECT pg_create_logical_replication_slot('forgotten', 'test_decoding')"`, e nada
nunca o leu.
Catorze dias de vendas depois:

```
ana@vm:~/etl$ psql -q -c CHECKPOINT && python apply_cdc.py
0 changes read up to -: {'INSERT': 0, 'UPDATE': 0, 'DELETE': 0, 'other tables': 0}
ana@vm:~/etl$ psql -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained_wal FROM pg_replication_slots"
 slot_name | active | retained_wal 
-----------+--------+--------------
 wh_cdc    | f      | 176 bytes
 forgotten | f      | 6049 kB
(2 rows)

ana@vm:~/etl$ psql -c "SHOW max_slot_wal_keep_size"
 max_slot_wal_keep_size 
------------------------
 -1
(1 row)

ana@vm:~/etl$ psql -c "SELECT pg_drop_replication_slot('forgotten')"
 pg_drop_replication_slot 
--------------------------
 
(1 row)
```

O slot lido toda noite segura 176 bytes. O esquecido segura cada byte de WAL escrito desde que foi
criado, 6049 kB em catorze dias de uma loja pequena: pouco mais de 400 kB por dia aqui, e gigabytes
por dia num banco de produção movimentado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l05-slots\" aria-label=\"O log de escrita antecipada desenhado como uma faixa, o mais antigo à esquerda. O slot wh_cdc fica perto da ponta direita, então quase nada atrás dele é guardado. O slot forgotten fica na ponta esquerda, onde foi criado, e cada byte entre ele e o fim do log é guardado no disco da origem: 6049 kB depois de catorze dias.\"><defs><marker id=\"st-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"60.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o log de escrita antecipada, no disco da origem</text><rect x=\"61.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"86.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"111.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"136.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"161.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"186.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"211.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"236.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"261.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"286.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"311.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"336.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"361.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"386.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"411.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"436.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"461.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"486.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"511.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"536.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"561.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"586.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"611.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"636.0\" y=\"100.0\" width=\"23.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"60.0\" y=\"148.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mais antigo</text><text x=\"660.0\" y=\"148.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">agora</text><path d=\"M110.0 82.0 L110.0 134.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"110.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">forgotten</text><path d=\"M666.0 82.0 L666.0 134.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"666.0\" y=\"74.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">wh_cdc</text><path d=\"M110.0 170 L666.0 170\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#st-ah-amber)\"></path><text x=\"388.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">guardado para forgotten: 6049 kB</text><text x=\"666.0\" y=\"206.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">176 bytes (wh_cdc)</text></svg>", "caption": "O PostgreSQL guarda cada byte que um slot ainda não consumiu. Um slot que ninguém lê guarda todos, até o disco encher."}
```

**O WAL mora no mesmo disco que o banco.** Quando esse disco enche, o banco para de aceitar
escritas, e os caixas param junto.

Esse é o jeito mais comum de a captura de mudanças derrubar o sistema que ela lê, e o formato é
sempre o mesmo. Um pipeline é desativado, ou cai e não é reiniciado, ou o seu consumidor é pausado
para uma migração, e o slot dele fica para trás, segurando WAL, sem nada em tela nenhuma dizendo
isso.

## Três defesas

- **Um limite.** O `max_slot_wal_keep_size` limita quanto WAL um slot pode segurar; passado esse
  ponto, o PostgreSQL invalida o slot em vez de encher o disco. O valor do laboratório, `-1`, é o
  padrão: sem limite. Com um limite, a origem sobrevive e o pipeline perde o lugar, e precisa
  recomeçar de uma cópia nova — que é o jeito certo de as coisas acontecerem.
- **Vigiar o número.** O `pg_replication_slots` é uma view que qualquer um pode consultar, e o WAL
  segurado por slot é uma expressão. Um alerta sobre ele é assunto da lição 10; o número está aqui.
- **Apagar o que você não usa mais.** Um slot é removido pelo nome, e o WAL que ele segurava é
  liberado no próximo checkpoint. O laboratório apaga o `forgotten` na última linha acima, e o
  `sudo shop reset` apaga todos os slots do cluster.
