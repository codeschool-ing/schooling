---
title: Recebendo o log por streaming em vez de copiá-lo
version: 1
---

O `archive_command` só vê um segmento quando ele termina. O que estiver no segmento atual, ainda
não terminado, está só no servidor, e o `archive_timeout` apenas encurta essa janela. Existe um
segundo jeito de coletar o log que não espera um segmento acabar: recebê-lo **à medida que é
escrito**, pelo mesmo protocolo de replicação que o `pg_basebackup -X stream` usou.

O `pg_receivewal` é um cliente que faz exatamente isso e escreve o que recebe num diretório, como
segmentos. Ele deveria rodar em outra máquina, para ser uma cópia em outro lugar; aqui ele roda ao
lado do servidor, o que basta para mostrar o mecanismo.

Antes de começar, peça ao servidor um **slot de replicação**. Um slot é a promessa do servidor de
guardar todo segmento que o cliente ainda não recebeu, mesmo enquanto o cliente está desconectado,
para que um restart do `pg_receivewal` retome de onde parou em vez de encontrar já reciclado o log
de que precisava. Depois inicie-o em segundo plano, com o `&` no fim. O seu shell responde com um
número de job e um id de processo, que esta transcrição não mostra:

```
ana@vm:~$ mkdir walstream
ana@vm:~$ pg_receivewal --create-slot --slot=walstream
ana@vm:~$ pg_receivewal -D walstream --slot=walstream > walstream.log 2>&1 &
shop=# INSERT INTO orders (customer_id, total_cents, placed_at) VALUES (9, 4400, now());
INSERT 0 1

shop=# SELECT pg_walfile_name(pg_current_wal_lsn());
     pg_walfile_name      
--------------------------
 00000001000000000000000F
(1 row)
ana@vm:~$ ls -l walstream
total 16384
-rw------- 1 ana ana 16777216 Oct 10 04:37 00000001000000000000000F.partial
```

O pedido foi para o segmento `0F`, e o `pg_receivewal` já o tem: o arquivo se chama `…0F.partial`
porque o segmento ainda está sendo escrito, e ele contém todo registro até o último que o servidor
mandou. Quando o servidor termina o segmento, o receptor o renomeia sem o sufixo. **O que falta ao
arquivo é no máximo o que a rede ainda não entregou**, uma fração de segundo, em vez de até um
segmento inteiro ou um `archive_timeout` inteiro.

## A promessa do slot tem um custo

Pare o receptor, e veja o slot que ele deixa para trás:

```
shop=# SELECT slot_name, active, restart_lsn FROM pg_replication_slots;
 slot_name | active | restart_lsn 
-----------+--------+-------------
 walstream | f      | 0/F000000
(1 row)
ana@vm:~$ pg_receivewal --drop-slot --slot=walstream
```

O `active` é `f`: ninguém está conectado a ele. O slot continua lá, e o `restart_lsn` dele diz que
o servidor tem que guardar todo segmento do `0F` em diante para ele, **enquanto ele existir**. Um
receptor que morreu na sexta e um slot que ninguém removeu são a mesma pilha de segmentos que um
comando de arquivamento quebrado, sem nenhum contador de falhas para avisar. O último comando
remove o slot, que é o que tem que acontecer sempre que um receptor é aposentado. A lição 11
reencontra os slots, como o que guarda o log de uma réplica, e põe um limite em quanto eles podem
segurar.

## Qual usar

Muitas instalações usam os dois. O comando de arquivamento (ou a ferramenta da lição 5, que o
substitui) é a espinha dorsal do backup: todo segmento, verificado, comprimido, guardado pelo tempo
que a retenção mandar. Um receptor por streaming é como uma instalação que não pode perder nem o
último minuto chega perto de zero, e com `--synchronous` ele confirma cada pedaço de log só quando
está no seu próprio disco. Mesmo assim, **o servidor não espera por ele** a menos que mandem: um
commit retorna antes de o receptor ter o registro, então a perda é pequena e não é zero. Fazer o
servidor esperar é replicação síncrona, lição 12.
