---
title: Atrás quanto, e medido como
version: 1
---

A lição 11 deixou o `pg_stat_replication` com quatro posições para cada standby: até onde o log foi
**enviado**, **escrito**, **com flush** e **reaplicado**. O atraso de replicação é a distância da
posição atual do próprio primário até cada uma delas, e pode ser medido de dois jeitos: **em bytes**,
como uma distância no log, e **em tempo**, como quanto uma mudança levou para chegar lá.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 200\" role=\"img\" aria-label=\"Uma linha horizontal é o write-ahead log, mais antigo à esquerda e mais novo à direita. Cinco marcas nela, da esquerda para a direita: replay_lsn, flush_lsn, write_lsn, sent_lsn e a posição atual do primário, pg_current_wal_lsn(). Um colchete de replay_lsn até a posição atual tem o rótulo bytes de atraso; replay_lag é o tempo que uma mudança levou para atravessar essa distância.\"><defs><marker id=\"l13p-wi\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><path d=\"M30 90 L700 90\" stroke=\"var(--wire)\" stroke-width=\"2\" fill=\"none\" marker-end=\"url(#l13p-wi)\"></path><text x=\"40\" y=\"72\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais antigo</text><text x=\"690\" y=\"72\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais novo</text><path d=\"M150 80 L150 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"150\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">replay_lsn</text><text x=\"150\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">nos dados do standby</text><path d=\"M290 80 L290 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"290\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">flush_lsn</text><text x=\"290\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no disco do standby</text><path d=\"M400 80 L400 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"400\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">write_lsn</text><path d=\"M500 80 L500 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"500\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">sent_lsn</text><text x=\"500\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">enviado pelo primário</text><path d=\"M630 80 L630 100\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"630\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">pg_current_wal_lsn()</text><text x=\"630\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o primário, agora</text><path d=\"M150 160 L150 168 L630 168 L630 160\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"390\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">bytes de atraso: pg_wal_lsn_diff(atual, replay_lsn)</text></svg>", "caption": "As quatro posições que o pg_stat_replication informa para um standby, comparadas com a do próprio primário. Bytes de atraso é a distância nesta linha; as colunas _lag são quanto tempo uma mudança levou para percorrê-la."}
```

O `pg_wal_lsn_diff` subtrai duas posições e dá bytes, e o `pg_size_pretty` os torna legíveis. As três
colunas `_lag` são as medidas de tempo: para commits recentes, quanto tempo depois de o primário ter
feito o flush deles o standby informou que os tinha escrito, feito o flush e reaplicado. Meça as duas
coisas enquanto o `pgbench` mantém o primário ocupado por vinte segundos em segundo plano:

```
ana@vm:~$ pgbench -c 4 -T 20 -n bench > /dev/null 2>&1 &
shop=# \x
Expanded display is on.

shop=# SELECT application_name, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)) AS behind, write_lag, flush_lag, replay_lag FROM pg_stat_replication;
-[ RECORD 1 ]----+----------------
application_name | standby1
behind           | 400 bytes
write_lag        | 00:00:00.000071
flush_lag        | 00:00:00.000359
replay_lag       | 00:00:00.000359
```

**400 bytes e um terço de milissegundo**: numa máquina só, sob carga, o standby está uma fração de
transação atrás. Os dois tipos de número respondem a perguntas diferentes, e um alerta precisa dos
dois:

| | responde | cresce quando |
|---|---|---|
| bytes de atraso (`replay_lsn`) | quanto log seria perdido, ou tem que ser reaplicado antes de uma promoção | o primário escreve mais rápido do que o standby acompanha |
| `replay_lag` | quão antiga pode ser uma leitura no standby | o standby está lento, pausado ou bloqueado |
| `write_lag`, `flush_lag` | quão lentos são a rede e o disco do standby | o link ou o disco está lento |

Um `replay_lag` grande com `write_lag` e `flush_lag` pequenos quer dizer que o log está chegando e
ficando parado no disco do standby sem ser reaplicado: a rede vai bem, e o problema está no standby.
Essa leitura das três colunas é o primeiro passo da maioria das investigações de atraso.
