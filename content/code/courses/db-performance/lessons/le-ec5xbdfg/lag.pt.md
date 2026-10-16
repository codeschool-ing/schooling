---
title: O atraso, medido pelas duas pontas
version: 1
---

O **atraso de replicação** é o quanto uma réplica está atrás do primário. Parece um número só e são
três, medidos em três passos da cópia, e pode ser contado em bytes ou em segundos, pelo primário ou
pela réplica. Cada leitura responde uma pergunta diferente, e o erro mais comum é ler uma delas como
se respondesse outra.

## Os passos por que uma mudança passa

Um commit no primário grava o seu WAL e volta para o cliente. Depois o WAL é **enviado** à réplica,
que o **grava** no próprio disco, o **descarrega** para que sobreviva a uma queda e, por fim, o
**reaplica**, aplicando a mudança às tabelas. Só depois da reaplicação uma consulta na réplica
enxerga a mudança. O `pg_stat_replication` tem uma posição para cada passo e um tempo para cada
intervalo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"Um commit viaja da esquerda para a direita por cinco passos: confirmado no primário, enviado, gravado na réplica, descarregado na réplica e reaplicado. Três chaves medem a partir do commit: write_lag termina em gravado, flush_lag em descarregado e replay_lag em reaplicado, o único ponto em que uma consulta na réplica enxerga a mudança.\"><text x=\"14\" y=\"16\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no primário</text><text x=\"298\" y=\"16\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">na réplica</text><rect x=\"14\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"76\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">confirmado</text><path d=\"M138 48 L156 48\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M156.0 48.0 L150.0 52.0 L150.0 44.0 Z\" fill=\"var(--wire)\"></path><rect x=\"156\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"218\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">enviado</text><path d=\"M280 48 L298 48\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M298.0 48.0 L292.0 52.0 L292.0 44.0 Z\" fill=\"var(--wire)\"></path><rect x=\"298\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"360\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">gravado</text><path d=\"M422 48 L440 48\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M440.0 48.0 L434.0 52.0 L434.0 44.0 Z\" fill=\"var(--wire)\"></path><rect x=\"440\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"502\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">descarregado</text><path d=\"M564 48 L582 48\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></path><path d=\"M582.0 48.0 L576.0 52.0 L576.0 44.0 Z\" fill=\"var(--wire)\"></path><rect x=\"582\" y=\"28\" width=\"124\" height=\"40\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"644\" y=\"48\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" text-anchor=\"middle\" fill=\"var(--paper)\">reaplicado</text><text x=\"644\" y=\"84\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" text-anchor=\"middle\" fill=\"var(--amber)\">visível para consultas</text><path d=\"M76 102 L76 110 L360 110 L360 102\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"354\" y=\"122\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">write_lag</text><path d=\"M76 132 L76 140 L502 140 L502 132\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></path><text x=\"496\" y=\"152\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--phosphor)\">flush_lag</text><path d=\"M76 162 L76 170 L644 170 L644 162\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></path><text x=\"638\" y=\"182\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" text-anchor=\"end\" fill=\"var(--amber)\">replay_lag</text><text x=\"14\" y=\"204\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">recovery_min_apply_delay segura a mudança entre descarregado e reaplicado.</text></svg>", "caption": "Os três atrasos do pg_stat_replication são três distâncias a partir do mesmo commit. Só o último decide o que uma leitura na réplica enxerga."}
```

Numa réplica saudável numa rede rápida os três atrasos são milissegundos e quase iguais. Quando se
separam, o lugar onde se separam diz o que está lento. Um `write_lag` grande é a rede, e um
`flush_lag` bem acima dele é o disco da réplica. Um `replay_lag` bem acima disso é a própria
reaplicação, que roda num único processo e pode ficar para trás de um primário que escreve com
muitos.

## Sob uma carga de escritas

Rode sozinho o script de compra da aula 2 por vinte segundos, com quatro clientes, e depois pergunte
ao primário:

```
ana@vm:~$ cd ~/workload && pgbench -n -c 4 -T 20 -P 10 -f place-order.sql market
pgbench (16.15 (Ubuntu 16.15-0ubuntu0.24.04.1))
progress: 10.0 s, 1487.1 tps, lat 2.675 ms stddev 1.722, 0 failed
progress: 20.0 s, 1665.4 tps, lat 2.393 ms stddev 1.102, 0 failed
transaction type: place-order.sql
scaling factor: 1
query mode: simple
number of clients: 4
number of threads: 1
maximum number of tries: 1
duration: 20 s
number of transactions actually processed: 31529
number of failed transactions: 0 (0.000%)
latency average = 2.527 ms
latency stddev = 1.438 ms
initial connection time = 18.863 ms
tps = 1576.710078 (without initial connection time)
market=# SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication;
    write_lag    |    flush_lag    |   replay_lag    | bytes_behind 
-----------------+-----------------+-----------------+--------------
 00:00:00.000098 | 00:00:00.000689 | 00:00:00.000771 |            0
(1 row)

Time: 2.759 ms
```

**31529 pedidos em vinte segundos**, cerca de 1577 por segundo, e quando acabou a réplica estava
**0 bytes** atrás, com todo atraso abaixo de um milissegundo. A reaplicação acompanha isso com
folga, e numa máquina só a rede é um socket. Entre duas máquinas em dois prédios, o piso é a ida e
volta entre elas, e uma rajada de escritas, um `UPDATE` grande ou a criação de um índice no primário
empurram o atraso para cima pelo tempo que a reaplicação leva para digerir.

## Do lado da réplica, e a armadilha dele

Uma réplica não enxerga o `pg_stat_replication`. O que ela tem é a hora do commit da última
transação que reaplicou, `pg_last_xact_replay_timestamp()`, e "agora menos isso" é o jeito óbvio de
dizer o quanto ela está atrás. Pergunte duas vezes, com dez segundos de intervalo, sem nada sendo
escrito:

```
market=# SELECT now() - pg_last_xact_replay_timestamp() AS behind;
     behind      
-----------------
 00:00:01.201852
(1 row)

Time: 1.040 ms
market=# SELECT now() - pg_last_xact_replay_timestamp() AS behind;
     behind      
-----------------
 00:00:11.929953
(1 row)

Time: 0.722 ms
```

**1,2 segundo, depois 11,9**, e a réplica não está atrás de nada: simplesmente não há nada novo
para reaplicar, então o último commit reaplicado envelhece a cada segundo. Um monitor construído só
com esse número acorda alguém toda noite às três, quando a loja está quieta. Ele só mede atraso
**enquanto o primário está escrevendo**; quando não está, compare posições, que é o que a próxima
leitura faz.

## Tornando o atraso visível de propósito

Numa máquina só o atraso é pequeno demais para ver uma leitura velha acontecer, então deixe-o grande
e previsível. O **`recovery_min_apply_delay`** manda a réplica esperar, antes de reaplicar cada
commit, até que esse tempo tenha passado desde que o primário o fez. É uma ferramenta de verdade,
usada para manter uma réplica um tempo fixo atrás, de modo que um `DROP TABLE` por engano possa ser
pego antes de chegar à cópia; a aula 20 de `db-reliability` a usa para isso. Aqui ela faz o papel
de uma rede ocupada. Ponha dez segundos na réplica, escreva por cinco e leia as duas pontas. Os
dois prompts `market=#` são iguais: o `ALTER SYSTEM` e a última consulta rodam em
`psql -p 5433 market`, na réplica, e a consulta ao `pg_stat_replication` roda no primário:

```
market=# ALTER SYSTEM SET recovery_min_apply_delay = '10s';
ALTER SYSTEM
Time: 1.828 ms

market=# SELECT pg_reload_conf();
 pg_reload_conf 
----------------
 t
(1 row)

Time: 0.735 ms
ana@vm:~$ cd ~/workload && pgbench -n -c 4 -T 5 -f place-order.sql market | grep -E "^(number of transactions|tps)"
number of transactions actually processed: 9232
tps = 1843.688671 (without initial connection time)
market=# SELECT write_lag, flush_lag, replay_lag, pg_wal_lsn_diff(sent_lsn, replay_lsn) AS bytes_behind FROM pg_stat_replication;
   write_lag    |    flush_lag    |   replay_lag    | bytes_behind 
----------------+-----------------+-----------------+--------------
 00:00:00.00035 | 00:00:00.005032 | 00:00:04.996743 |      8637096
(1 row)

Time: 2.127 ms
market=# SELECT pg_last_wal_receive_lsn(), pg_last_wal_replay_lsn(), now() - pg_last_xact_replay_timestamp() AS behind;
 pg_last_wal_receive_lsn | pg_last_wal_replay_lsn |     behind      
-------------------------+------------------------+-----------------
 1A/70039A0              | 1A/67C6EF8             | 00:00:19.539915
(1 row)

Time: 0.764 ms
```

A visão do primário: `write_lag` e `flush_lag` continuam **abaixo de 6 milissegundos**, porque o WAL
chega e é salvo na hora; o atraso está na reaplicação, e o `replay_lag` marca **5,0 segundos**, com
**8637096 bytes** de WAL recebidos e ainda não aplicados. A visão da réplica diz o mesmo em
posições: ela recebeu até `1A/70039A0` e reaplicou só até `1A/67C6EF8`. A leitura pelo horário,
**19,5 segundos**, mistura os dois problemas desta seção: a réplica ainda não reaplicou nenhum
commit desta rodada, então o último que reaplicou é da rodada anterior, que terminou quase vinte
segundos antes.

Então, ao vigiar uma réplica:

- **Pelo primário**, o `replay_lag` e a diferença em bytes entre `sent_lsn` e `replay_lsn`. Bytes
  nunca crescem num servidor parado.
- **Pela réplica**, `pg_last_wal_receive_lsn()` contra `pg_last_wal_replay_lsn()` para o que ela
  tem e ainda não aplicou, e o horário de reaplicação só enquanto há escritas chegando.
- **Como um usuário faria**, escrevendo e medindo quanto tempo leva até uma leitura na réplica
  enxergar a escrita, que é o que a próxima seção faz.

O atraso de dez segundos fica ligado para a seção 04.
