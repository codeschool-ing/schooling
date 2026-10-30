---
title: Captura de mudanças de verdade, do próprio log do PostgreSQL
version: 1
---

**O Datastream lê mudanças do PostgreSQL por decodificação lógica**, e a decodificação lógica faz
parte do próprio PostgreSQL, então dá para rodá-la no seu computador e assistir. Esta seção faz isso
com um servidor PostgreSQL 16 de verdade e mudanças de verdade. Nada aqui imita o Datastream: o que
as transcrições mostram é o que qualquer leitor de uma origem PostgreSQL recebe, o Datastream
incluído, antes de transformar as mudanças em linhas no BigQuery ou em arquivos num bucket.

**Quatro peças fazem isso funcionar.** O **write-ahead log**, WAL, é onde o PostgreSQL escreve cada
mudança antes de aplicá-la, e com `wal_level=logical` ele escreve o bastante para reconstruir cada
linha alterada. Uma **publicação** nomeia as tabelas cujas mudanças podem ser publicadas, e é assim
que uma origem diz "estas e nenhuma outra". Um **slot de replicação** é um marcador com nome no log,
mantido pelo servidor para um leitor: ele lembra até onde o leitor confirmou, e faz o servidor
guardar todo pedaço de log que o leitor ainda não leu. Um **plugin de saída** transforma o log entre
o marcador e agora em algo que um leitor entende. A configuração de origem do Datastream nomeia um
slot e uma publicação, os dois campos que a ajuda da seção anterior imprimiu, e o slot que ele lê usa
o `pgoutput`, o plugin que a própria replicação do PostgreSQL fala.

## Um servidor descartável

Se o `sql-databases` instalou o PostgreSQL na sua máquina, já está tudo aqui; se não, o pacote do
Ubuntu é um comando:

```sh
sudo apt-get install -y postgresql-16
```

O servidor dele roda na porta 5432, e esta seção o deixa em paz: ela inicia um segundo servidor,
descartável e seu, na porta 5433, em `~/gcp/cdc`, sem escutar endereço de rede nenhum, só um arquivo
de socket naquele diretório. Você não precisa de `sudo` para isso, porque o servidor roda como você:

```sh
PG=/usr/lib/postgresql/16/bin
mkdir -p ~/gcp/cdc
$PG/initdb -D ~/gcp/cdc/data -U postgres -A trust > ~/gcp/cdc/initdb.log
$PG/pg_ctl -D ~/gcp/cdc/data -l ~/gcp/cdc/server.log -w start \
  -o "-c wal_level=logical -c port=5433 -c listen_addresses='' -c unix_socket_directories=$HOME/gcp/cdc"
export PGHOST=$HOME/gcp/cdc PGPORT=5433 PGUSER=postgres
```

O `initdb` cria o diretório de dados com um superusuário chamado `postgres` que não precisa de senha,
o que só é seguro porque nada além de um socket no seu próprio diretório pessoal o alcança. O
`pg_ctl` inicia o servidor com quatro configurações na linha de comando: WAL lógico, a porta, nada de
TCP e onde fica o socket. A última linha aponta o `psql` para ele pelo resto deste terminal.

## Uma tabela, uma publicação, dois slots

```
ana@laptop:~/gcp$ psql -c "SHOW wal_level"
 wal_level 
-----------
 logical
(1 row)

ana@laptop:~/gcp$ psql -c "CREATE TABLE orders (order_id text PRIMARY KEY, customer_id text NOT NULL, total_cents integer NOT NULL)" -c "INSERT INTO orders VALUES ('ord-1', 'c-17', 4590)"
CREATE TABLE
INSERT 0 1
ana@laptop:~/gcp$ psql -c "CREATE PUBLICATION datastream_pub FOR TABLE orders"
CREATE PUBLICATION
ana@laptop:~/gcp$ psql -c "SELECT slot_name, lsn FROM pg_create_logical_replication_slot('datastream_orders', 'pgoutput')" -c "SELECT slot_name, lsn FROM pg_create_logical_replication_slot('look', 'test_decoding')"
     slot_name     |    lsn    
-------------------+-----------
 datastream_orders | 0/151AB00
(1 row)

 slot_name |    lsn    
-----------+-----------
 look      | 0/151AB38
(1 row)
```

**Dois slots no mesmo log, para dois leitores.** O `datastream_orders` usa `pgoutput`, como o do
Datastream. O `look` usa `test_decoding`, um plugin que vem com o PostgreSQL e transforma as mudanças
em linhas de texto, o que serve para ler a olho. **Cada slot foi criado numa posição do log**, o
`lsn`, um log sequence number: o deslocamento em bytes no WAL, escrito como duas metades
hexadecimais. O pedido inserido antes de os slots existirem, `ord-1`, nunca vai ser informado por
nenhum deles. Essa posição é o ponto de partida que um stream anota antes do backfill, da primeira
seção desta aula. Agora mude a tabela de três jeitos e pergunte ao slot de texto o que ele viu, sem
consumir nada:

```
ana@laptop:~/gcp$ psql -c "INSERT INTO orders VALUES ('ord-2', 'c-03', 12800)" -c "UPDATE orders SET total_cents = 4990 WHERE order_id = 'ord-1'" -c "DELETE FROM orders WHERE order_id = 'ord-2'"
INSERT 0 1
UPDATE 1
DELETE 1
ana@laptop:~/gcp$ psql -Atc "SELECT lsn, xid, data FROM pg_logical_slot_peek_changes('look', NULL, NULL)"
0/151AB38|733|BEGIN 733
0/151AB38|733|table public.orders: INSERT: order_id[text]:'ord-2' customer_id[text]:'c-03' total_cents[integer]:12800
0/151ABF0|733|COMMIT 733
0/151ABF0|734|BEGIN 734
0/151ABF0|734|table public.orders: UPDATE: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990
0/151AC78|734|COMMIT 734
0/151AC78|735|BEGIN 735
0/151AC78|735|table public.orders: DELETE: order_id[text]:'ord-2'
0/151ACF0|735|COMMIT 735
```

**Cada mudança confirmada, na ordem dos commits, cada uma dentro da sua transação.** O insert traz a
linha nova inteira com os tipos. O update traz a linha como ela está agora. O delete traz só a chave
primária, porque por padrão é só isso que o PostgreSQL escreve no log sobre uma linha apagada, e é o
bastante para achar a linha no destino e apagá-la lá. Cada mudança fica entre um `BEGIN` e um
`COMMIT` com o id da transação, `xid`, e é assim que um leitor sabe quais mudanças valem ou caem
juntas. Uma transação desfeita com rollback nem aparece.

## O que o slot do Datastream guarda

**O slot `pgoutput` viu as mesmas três transações, como mensagens binárias.** As mudanças dele são
lidas com a forma binária da mesma função, recebendo a versão do protocolo e a publicação, e o
primeiro byte de cada mensagem diz o que ela é:

```
ana@laptop:~/gcp$ psql -c "SELECT lsn, xid, chr(get_byte(data, 0)) AS kind, length(data) AS bytes FROM pg_logical_slot_peek_binary_changes('datastream_orders', NULL, NULL, 'proto_version', '1', 'publication_names', 'datastream_pub')"
    lsn    | xid | kind | bytes 
-----------+-----+------+-------
 0/151AB38 | 733 | B    |    21
 0/151AB38 | 733 | R    |    82
 0/151AB38 | 733 | I    |    37
 0/151ABF0 | 733 | C    |    26
 0/151ABF0 | 734 | B    |    21
 0/151ABF0 | 734 | U    |    36
 0/151AC78 | 734 | C    |    26
 0/151AC78 | 735 | B    |    21
 0/151AC78 | 735 | D    |    20
 0/151ACF0 | 735 | C    |    26
(10 rows)
```

**`B` começa uma transação, `C` a confirma, e `I`, `U` e `D` são o insert, o update e o delete**,
nas mesmas posições e com os mesmos ids de transação que o slot de texto imprimiu. O `R`, uma
mensagem de relação, descreve as colunas da tabela uma vez antes da primeira mudança dela, para que
um leitor decodifique as linhas seguintes sem perguntar ao banco. Este é o fluxo de bytes que o
Datastream lê, e é por isso que a configuração de origem precisa de uma publicação: o `pgoutput` só
publica as tabelas que a publicação nomeia.

## Ler move o marcador

**O `peek` leu as mudanças e as deixou lá; o `get` as lê e move o marcador.** Leia o slot de texto
com `get`, e depois de novo:

```
ana@laptop:~/gcp$ psql -Atc "SELECT data FROM pg_logical_slot_get_changes('look', NULL, NULL)"
BEGIN 733
table public.orders: INSERT: order_id[text]:'ord-2' customer_id[text]:'c-03' total_cents[integer]:12800
COMMIT 733
BEGIN 734
table public.orders: UPDATE: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990
COMMIT 734
BEGIN 735
table public.orders: DELETE: order_id[text]:'ord-2'
COMMIT 735
ana@laptop:~/gcp$ psql -Atc "SELECT count(*) FROM pg_logical_slot_get_changes('look', NULL, NULL)"
0
```

**A segunda leitura veio vazia, e esse é o contrato**: depois que um leitor pega as mudanças, o
servidor as esquece para aquele slot e pode reciclar aquela parte do log. O Datastream lê pelo slot
dele numa conexão de replicação e confirma o que já escreveu no destino, mas o marcador se move do
mesmo jeito. O slot `pgoutput`, que ninguém leu, ainda guarda as três transações.

## Como era a linha antiga

**Um update que traz só a linha nova não consegue dizer ao destino o que mudou**, e um destino que
guarda histórico não recebe nada sobre os valores antigos. `REPLICA IDENTITY` é a configuração da
tabela que diz quanto da linha antiga vai para o log:

```
ana@laptop:~/gcp$ psql -c "ALTER TABLE orders REPLICA IDENTITY FULL" -c "UPDATE orders SET total_cents = 5190 WHERE order_id = 'ord-1'"
ALTER TABLE
UPDATE 1
ana@laptop:~/gcp$ psql -Atc "SELECT xid, data FROM pg_logical_slot_get_changes('look', NULL, NULL)"
736|BEGIN 736
736|COMMIT 736
737|BEGIN 737
737|table public.orders: UPDATE: old-key: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990 new-tuple: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:5190
737|COMMIT 737
```

**Agora o update traz `old-key` e `new-tuple`**: 4990 antes, 5190 depois. A primeira transação,
vazia, é o próprio `ALTER TABLE`, e não traz mudança nenhuma, porque a decodificação lógica não
informa mudanças na estrutura de uma tabela; o Datastream descobre as colunas novas de uma tabela do
jeito dele, o que é mais um motivo para uma migração evitar mudar as colunas de uma tabela enquanto
roda. `FULL` escreve mais WAL a cada update e delete da tabela, e esse é o preço, e uma tabela sem
chave primária precisa dele, ou de algo parecido, antes que os updates e deletes dela possam ser
replicados.

## O slot que ninguém lê

```
ana@laptop:~/gcp$ psql -c "INSERT INTO orders SELECT 'bulk-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 20000) g"
INSERT 0 20000
ana@laptop:~/gcp$ psql -c "SELECT slot_name, plugin, active, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
     slot_name     |    plugin     | active | wal_status | retained 
-------------------+---------------+--------+------------+----------
 datastream_orders | pgoutput      | f      | reserved   | 3431 kB
 look              | test_decoding | f      | reserved   | 3431 kB
(2 rows)

ana@laptop:~/gcp$ psql -Atc "SELECT pg_drop_replication_slot('look')"
```

**Vinte mil linhas inseridas e ninguém lendo: cada slot segura o log desde o próprio marcador.** Esse
é o perigo do CDC no PostgreSQL que importa, e ele não está no Datastream. Um slot guarda o WAL que o
leitor não confirmou, sem limite por padrão. Então um stream pausado num fim de semana, ou apagado
deixando o slot para trás, faz o banco da loja guardar cada mudança que faz até o disco encher, e um
disco cheio para a loja. **A regra é apagar um slot quando o leitor dele se foi**, o que o último
comando fez com o `look`, e acompanhar o tamanho retido de cada slot enquanto ele existir.

**O PostgreSQL também consegue pôr um teto nisso.** O `max_slot_wal_keep_size` é o máximo de WAL que
um slot pode segurar, e um slot que fica mais para trás do que isso é abandonado, em vez de poder
encher o disco. Ponha um valor baixo, escreva mais do que ele permite e observe:

```
ana@laptop:~/gcp$ psql -c "ALTER SYSTEM SET max_slot_wal_keep_size = '32MB'" -c "SELECT pg_reload_conf()"
ALTER SYSTEM
 pg_reload_conf 
----------------
 t
(1 row)

ana@laptop:~/gcp$ psql -c "INSERT INTO orders SELECT 'more-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 400000) g"
INSERT 0 400000
ana@laptop:~/gcp$ psql -c "SELECT slot_name, wal_status, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained, pg_size_pretty(safe_wal_size) AS safe FROM pg_replication_slots"
     slot_name     | wal_status | retained |  safe  
-------------------+------------+----------+--------
 datastream_orders | unreserved | 71 MB    | -28 MB
(1 row)

ana@laptop:~/gcp$ psql -c "CHECKPOINT" -c "SELECT slot_name, wal_status FROM pg_replication_slots"
CHECKPOINT
     slot_name     | wal_status 
-------------------+------------
 datastream_orders | lost
(1 row)

ana@laptop:~/gcp$ psql -c "SELECT count(*) FROM pg_logical_slot_peek_binary_changes('datastream_orders', NULL, NULL, 'proto_version', '1', 'publication_names', 'datastream_pub')"
ERROR:  can no longer get changes from replication slot "datastream_orders"
DETAIL:  This slot has been invalidated because it exceeded the maximum reserved size.
ana@laptop:~/gcp$ psql -Atc "SELECT pg_drop_replication_slot('datastream_orders')" -c "SELECT count(*) FROM pg_replication_slots"

0
```

**`unreserved`, depois `lost`.** Com 71 MB para segurar e 32 MB permitidos, o status do slot virou
`unreserved` e o tamanho seguro ficou negativo: o servidor avisava a quem estivesse olhando que o
próximo checkpoint removeria log de que o slot ainda precisava. O checkpoint removeu, o slot virou
`lost`, e lê-lo agora é um erro. **O disco foi salvo e o stream não**: um stream do Datastream num
slot como este não consegue continuar, e a volta é um slot novo e um backfill novo. Essa é a troca
que a configuração faz, e num banco que não pode parar é a certa, com um alerta sobre o `wal_status`
muito antes de acontecer.

Quando terminar, pare o servidor descartável e apague-o; nada mais na sua máquina o usava:

```sh
$PG/pg_ctl -D ~/gcp/cdc/data stop
rm -rf ~/gcp/cdc
```
