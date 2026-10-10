---
title: O que é um checkpoint
version: 1
---

A lição 7 deixou uma dívida. Todo commit está seguro no log, e os arquivos das tabelas ficam para
trás, então as páginas na memória que diferem dos seus arquivos vão se acumulando, e com elas o log
que seria necessário para reconstruí-las depois de uma queda. **Um checkpoint paga a dívida**: grava
cada página suja no seu arquivo, força esses arquivos para o disco e então escreve no log um
registro dizendo isso. A partir daí, a recuperação nunca precisa de nada mais antigo que o ponto
onde aquele checkpoint começou.

O processo que faz isso é o **checkpointer**, o que encabeça a lista que a lição 3 mostrou. Ele
começa um checkpoint a cada `checkpoint_timeout`, ou antes, quando o log cresceu o bastante, ou
quando alguém pede um com `CHECKPOINT`.

## A mesma linha, depois de um checkpoint

A lição 7 encontrou uma linha confirmada no log e não no arquivo da tabela. Faça isso de novo, e
conte as páginas sujas na memória com o `pg_buffercache`, a extensão que a lição 6 usou para olhar
dentro dos shared buffers (o `IF NOT EXISTS` torna a primeira linha inofensiva se ela já existir):

```
shop=# CREATE EXTENSION IF NOT EXISTS pg_buffercache;
CREATE EXTENSION

shop=# CREATE TABLE notes (id int PRIMARY KEY, body text);
CREATE TABLE

shop=# INSERT INTO notes VALUES (1, 'written down first');
INSERT 0 1

shop=# SELECT pg_relation_filepath('notes');
 pg_relation_filepath 
----------------------
 base/16386/16428
(1 row)

shop=# SELECT count(*) AS dirty FROM pg_buffercache WHERE isdirty;
 dirty 
-------
 15321
(1 row)
ana@db:~$ sudo grep -c 'written down first' /var/lib/postgresql/16/main/base/16386/16428
0
```

A linha não está no arquivo, como antes. **15321 páginas na memória diferem dos seus arquivos**: na
máquina da gravação o `shop` tinha acabado de ser carregado e nenhum checkpoint tinha rodado desde
então, e na sua a contagem é o que mudou desde o último. Agora peça um checkpoint e olhe de novo:

```
shop=# CHECKPOINT;
CHECKPOINT

shop=# SELECT count(*) AS dirty FROM pg_buffercache WHERE isdirty;
 dirty 
-------
     0
(1 row)
ana@db:~$ sudo grep -c 'written down first' /var/lib/postgresql/16/main/base/16386/16428
1
```

**Não sobrou nenhuma página suja, e a linha está no arquivo da tabela.** Nada mudou para a sessão
que a inseriu: o commit já era durável antes, por causa do log. O que mudou é que o log escrito
antes deste checkpoint deixou de ser necessário para isso.

## Onde o servidor guarda isso

Todo checkpoint é registrado num arquivo pequeno do diretório de dados, `global/pg_control`, que o
servidor lê primeiro em toda subida. O `pg_controldata` o imprime, e como o `pg_waldump` ele mora
com os programas do servidor e não no seu `PATH`:

```
ana@db:~$ sudo /usr/lib/postgresql/16/bin/pg_controldata /var/lib/postgresql/16/main | grep -E 'state|checkpoint location|REDO'
Database cluster state:               in production
Latest checkpoint location:           0/158532B8
Latest checkpoint's REDO location:    0/15853280
Latest checkpoint's REDO WAL file:    000000010000000000000015
```

Duas posições, e **a REDO location vem primeiro**. Um checkpoint anota onde o log está quando
começa, que é o seu ponto de redo, depois grava as páginas enquanto o log continua crescendo, e só
no fim escreve o seu próprio registro, na posição mais adiante. Uma alteração feita enquanto as
páginas estavam sendo gravadas pode ou não ter chegado ao arquivo, então a recuperação tem de
começar do ponto de redo, e não do registro. `in production` quer dizer que o servidor está rodando;
depois de uma parada limpa ele diz `shut down`, e essa diferença é a primeira coisa que o servidor
confere quando sobe.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"O write-ahead log como um fluxo da esquerda para a direita. Um checkpoint começa no ponto de redo, grava as páginas sujas enquanto o log continua e termina com um registro de checkpoint. Os segmentos antes do ponto de redo não servem mais e são reciclados. Depois de uma queda, a subida refaz tudo do ponto de redo até o fim do log.\"><defs><marker id=\"arr\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"20\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"133\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><rect x=\"246\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"359\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"472\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"585\" y=\"130\" width=\"113\" height=\"34\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"133\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">não servem mais: reciclados</text><text x=\"700\" y=\"147\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" fill=\"var(--paper-dim)\">→</text><text x=\"20\" y=\"182\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o write-ahead log, o mais antigo à esquerda</text><line x1=\"246\" y1=\"60\" x2=\"246\" y2=\"164\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"246\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">o checkpoint começa</text><text x=\"246\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">redo lsn</text><line x1=\"430\" y1=\"60\" x2=\"430\" y2=\"164\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"430\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">registro do checkpoint</text><text x=\"430\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">checkpoint location</text><text x=\"338.0\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">páginas sujas gravadas nos arquivos</text><text x=\"338.0\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">espalhadas pelo intervalo</text><line x1=\"640\" y1=\"60\" x2=\"640\" y2=\"164\" stroke=\"var(--amber)\" stroke-width=\"2\" stroke-dasharray=\"5 4\"></line><text x=\"640\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">queda</text><text x=\"640\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">kill -9</text><line x1=\"246\" y1=\"210\" x2=\"636\" y2=\"210\" stroke=\"var(--amber)\" stroke-width=\"1.5\" marker-end=\"url(#arr)\"></line><text x=\"443.0\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">na subida, tudo a partir do ponto de redo é refeito</text><text x=\"430\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o pg_control guarda onde está o último registro de checkpoint, e esse registro aponta o seu ponto de redo</text></svg>", "caption": "Um checkpoint move o ponto onde a recuperação começaria. Tudo o que é mais antigo pode ir embora."}
```

## A linha que ele deixa no log

O `log_checkpoints` vem ligado por padrão desde o PostgreSQL 15, então todo checkpoint escreve duas
linhas no log do servidor:

```
ana@db:~$ sudo tail -n 2 /var/log/postgresql/postgresql-16-main.log
2026-10-10 04:28:02.835 -03 [102] LOG:  checkpoint starting: immediate force wait
2026-10-10 04:28:03.116 -03 [102] LOG:  checkpoint complete: wrote 15324 buffers (93.5%); 0 WAL file(s) added, 0 removed, 20 recycled; write=0.109 s, sync=0.160 s, total=0.281 s; sync files=624, longest=0.072 s, average=0.001 s; distance=331151 kB, estimate=331151 kB; lsn=0/158532B8, redo lsn=0/15853280
```

A primeira linha diz **por que** ele começou. `immediate force wait` é o comando `CHECKPOINT`: faça
agora, na velocidade máxima, e faça quem pediu esperar. Um de rotina diz `time` ou `wal`, e a
próxima seção faz os dois acontecerem. A segunda linha é o relatório:

| parte | o que diz |
| --- | --- |
| `wrote 15324 buffers (93.5%)` | páginas gravadas, e que fração dos shared buffers isso é |
| `0 WAL file(s) added, 0 removed, 20 recycled` | o que aconteceu com os segmentos mais antigos que o ponto de redo, como a lição 7 mostrou |
| `write=`, `sync=`, `total=` | segundos gastos gravando as páginas, esperando o disco confirmá-las, e no total |
| `sync files=624` | quantos arquivos tiveram de ser forçados para o disco |
| `distance=331151 kB` | quanto log foi escrito desde o checkpoint anterior |
| `estimate=` | o palpite corrente do servidor para essa distância, que decide quantos segmentos ele recicla |
| `lsn=`, `redo lsn=` | as mesmas duas posições que o `pg_controldata` mostrou |

**`write` e `sync` são os números para acompanhar.** Um checkpoint de rotina deve espalhar a
gravação pela maior parte do intervalo, então um `write` longo é normal; um `sync` longo quer dizer
que o disco demorou isso tudo para confirmar o que tinha recebido, e a lição 9 é sobre discos.
