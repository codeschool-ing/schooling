---
title: Onde os arquivos moram
version: 1
---

A lição 3 perguntou ao servidor onde estão os dados dele, e ele respondeu `/var/lib/postgresql/16/main`.
Esse diretório é o **cluster**: todo banco, toda tabela e todo índice que o servidor guarda é um
arquivo em algum lugar abaixo dele, e nada de que o servidor precisa para subir mora em outro
lugar, a não ser a configuração. Só o usuário `postgres` consegue abri-lo, então olhe com `sudo`:

```
ana@db:~$ sudo ls -l /var/lib/postgresql/16/main
total 84
-rw------- 1 postgres postgres    3 Oct 10 03:18 PG_VERSION
drwx------ 8 postgres postgres 4096 Oct 10 04:11 base
drwx------ 2 postgres postgres 4096 Oct 10 04:11 global
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_commit_ts
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_dynshmem
drwx------ 4 postgres postgres 4096 Oct 10 03:18 pg_logical
drwx------ 4 postgres postgres 4096 Oct 10 03:18 pg_multixact
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_notify
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_replslot
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_serial
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_snapshots
drwx------ 2 postgres postgres 4096 Oct 10 04:11 pg_stat
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_stat_tmp
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_subtrans
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_tblspc
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_twophase
drwx------ 3 postgres postgres 4096 Oct 10 04:11 pg_wal
drwx------ 2 postgres postgres 4096 Oct 10 03:18 pg_xact
-rw------- 1 postgres postgres   88 Oct 10 03:18 postgresql.auto.conf
-rw------- 1 postgres postgres  130 Oct 10 04:11 postmaster.opts
-rw------- 1 postgres postgres  107 Oct 10 04:11 postmaster.pid
```

A maioria desses nomes é contabilidade interna que você nunca vai abrir, e o servidor teria razão
em reclamar se abrisse. Cinco valem conhecer pelo nome:

| entrada | o que guarda |
|---|---|
| `base/` | **os bancos**: um subdiretório por banco, e dentro dele um ou mais arquivos por tabela e índice |
| `global/` | as poucas tabelas que todos os bancos compartilham, como a lista de papéis e a lista de bancos |
| `pg_wal/` | o **write-ahead log**, toda mudança anotada antes de chegar a uma tabela; lições 7 e 8 |
| `pg_xact/` | um par de bits por transação dizendo se ela fez commit — minúsculo, e sem ele nada em `base/` pode ser lido corretamente |
| `PG_VERSION` | a versão maior que criou este diretório: `16`. Um servidor de outra versão maior se recusa a subir nele |

O `postmaster.pid` só existe enquanto o servidor roda. É ele que impede um segundo servidor de subir
no mesmo diretório, e é por ele que as ferramentas acham o que está rodando:

```
ana@db:~$ sudo cat /var/lib/postgresql/16/main/postmaster.pid
101
/var/lib/postgresql/16/main
1791616272
5432
/var/run/postgresql
localhost
   860661         0
ready   
```

A primeira linha é o id do processo do postmaster, depois o diretório de dados, a hora de início em
segundos desde 1970, a porta, onde fica o socket e em que endereço ele escuta. **Um servidor morto à
força deixa esse arquivo para trás**, e a próxima subida verifica se aquele processo ainda está vivo
antes de acreditar nele.

## Quanto pesa cada parte

```
ana@db:~$ sudo du -h -d1 /var/lib/postgresql/16/main | sort -h
4.0K	/var/lib/postgresql/16/main/pg_commit_ts
4.0K	/var/lib/postgresql/16/main/pg_dynshmem
4.0K	/var/lib/postgresql/16/main/pg_notify
4.0K	/var/lib/postgresql/16/main/pg_replslot
4.0K	/var/lib/postgresql/16/main/pg_serial
4.0K	/var/lib/postgresql/16/main/pg_snapshots
4.0K	/var/lib/postgresql/16/main/pg_stat
4.0K	/var/lib/postgresql/16/main/pg_stat_tmp
4.0K	/var/lib/postgresql/16/main/pg_tblspc
4.0K	/var/lib/postgresql/16/main/pg_twophase
12K	/var/lib/postgresql/16/main/pg_subtrans
12K	/var/lib/postgresql/16/main/pg_xact
16K	/var/lib/postgresql/16/main/pg_logical
28K	/var/lib/postgresql/16/main/pg_multixact
600K	/var/lib/postgresql/16/main/global
153M	/var/lib/postgresql/16/main/base
337M	/var/lib/postgresql/16/main/pg_wal
490M	/var/lib/postgresql/16/main
```

Duas linhas carregam quase tudo: `base` com 153M, que é o `shop` e os bancos pequenos ao lado dele,
e **`pg_wal` com 337M — mais que os próprios dados**. Carregar um milhão de linhas em poucos comandos
grandes escreve todas elas no log antes, e o servidor mantém os segmentos do log até ter motivo para
reciclá-los. Isso é normal, é limitado, e a lição 7 diz pelo quê. Na sua máquina o segundo número
pode ser outro; o primeiro não deve ser.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"O diretório de dados /var/lib/postgresql/16/main guarda base, com um diretório por banco cujo nome é o oid; dentro de base/16386, o banco shop, a tabela orders é o arquivo 16398, com o mapa de espaço livre 16398_fsm e o mapa de visibilidade 16398_vm. Ao lado de base ficam global, pg_wal e pg_xact. O Ubuntu guarda a configuração em /etc/postgresql/16/main e o log em /var/log/postgresql, fora do diretório de dados.\"><rect x=\"10\" y=\"10\" width=\"470\" height=\"300\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"24\" y=\"30\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">/var/lib/postgresql/16/main</text><text x=\"24\" y=\"48\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o diretório de dados: um cluster</text><rect x=\"24\" y=\"62\" width=\"442\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"38\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">base/</text><text x=\"90\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um diretório por banco, com o oid como nome</text><rect x=\"38\" y=\"94\" width=\"414\" height=\"108\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"52\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--phosphor)\">16386/</text><text x=\"112\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">shop</text><text x=\"52\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders: um arquivo por fork</text><rect x=\"52\" y=\"144\" width=\"126\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"115\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">16398</text><text x=\"115\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">as linhas</text><rect x=\"186\" y=\"144\" width=\"126\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"249\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">16398_fsm</text><text x=\"249\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mapa de espaço livre</text><rect x=\"320\" y=\"144\" width=\"126\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></rect><text x=\"383\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\">16398_vm</text><text x=\"383\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">mapa de visibilidade</text><text x=\"38\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">global/</text><text x=\"112\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tabelas comuns a todos os bancos: papéis, a lista de bancos</text><text x=\"38\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">pg_wal/</text><text x=\"112\" y=\"256\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o write-ahead log (lição 7)</text><text x=\"38\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">pg_xact/</text><text x=\"112\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">se cada transação fez commit</text><rect x=\"496\" y=\"10\" width=\"214\" height=\"300\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"603\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">guardados em outro lugar pelo Ubuntu</text><rect x=\"510\" y=\"62\" width=\"186\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"603\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/etc/postgresql/16/main</text><text x=\"603\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">configuração (lição 5)</text><rect x=\"510\" y=\"150\" width=\"186\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"603\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">/var/log/postgresql</text><text x=\"603\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">o log (lição 19)</text></svg>", "caption": "Um cluster é um diretório. Uma tabela é alguns arquivos dentro dele, com números no lugar do nome da tabela.", "same": ["shop"]}
```

A figura mostra o resto desta lição numa imagem só: dentro de `base/`, um diretório para o `shop`, e
dentro dele os arquivos que são a tabela `orders`. As duas caixas da direita nem estão no diretório
de dados, e a seção depois da próxima explica por quê.
