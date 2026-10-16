---
title: Captura de mudanças de verdade, a partir do log do próprio PostgreSQL
version: 1
---

**O DMS lê mudanças do PostgreSQL por decodificação lógica**, e a decodificação lógica faz parte do
próprio PostgreSQL, então dá para rodá-la no seu computador e assistir. É isso que esta seção faz,
com um servidor PostgreSQL 16 de verdade e mudanças de verdade. Nada aqui imita coisa nenhuma: o que
as transcrições mostram é o que o DMS recebe de uma origem PostgreSQL, antes de o DMS transformar
isso em linhas no destino.

**Três peças fazem isso funcionar.** O **write-ahead log**, WAL, é onde o PostgreSQL escreve toda
mudança antes de aplicá-la, e com `wal_level=logical` ele escreve o bastante para reconstruir cada
linha alterada. Um **slot de replicação** é um marcador com nome nesse log, mantido pelo servidor
para um leitor: ele lembra até onde o leitor confirmou, e faz o servidor guardar todo pedaço do log
que o leitor ainda não leu. Um **plugin de saída** transforma o log entre o marcador e o agora em algo
que um leitor entenda; o `test_decoding`, que vem com o PostgreSQL, o transforma em linhas de texto, e
é um dos dois plugins que o DMS pode usar, o `PluginName` do endpoint de duas seções atrás.

## Um servidor descartável

Se a lição 1 de `sql-databases` instalou o PostgreSQL na sua máquina, está tudo aqui; se não, a seção
daquela lição sobre a instalação é um comando, `sudo apt install -y postgresql`. O servidor dele roda
na porta 5432 com `wal_level=replica`, e esta seção não mexe nele: ela liga um segundo servidor,
descartável e seu, na porta 5433, em `~/aws/cdc`, sem escutar endereço de rede nenhum, só um arquivo
de socket nesse diretório. Você não precisa de `sudo` para ele, porque o servidor roda como você.

```sh
PG=/usr/lib/postgresql/16/bin
mkdir -p ~/aws/cdc
$PG/initdb -D ~/aws/cdc/data -U postgres -A trust > ~/aws/cdc/initdb.log
$PG/pg_ctl -D ~/aws/cdc/data -l ~/aws/cdc/server.log -w start \
  -o "-c wal_level=logical -c port=5433 -c listen_addresses='' -c unix_socket_directories=$HOME/aws/cdc"
export PGHOST=$HOME/aws/cdc PGPORT=5433 PGUSER=postgres
```

O `initdb` cria o diretório de dados com um superusuário chamado `postgres` que não precisa de senha,
o que só é seguro porque nada além de um socket no seu próprio diretório pessoal alcança esse
servidor. O `pg_ctl` liga o servidor com três configurações dadas na linha de comando: WAL lógico, a
porta, e nenhum TCP. A última linha aponta o `psql` para ele pelo resto deste terminal.

## Uma tabela, um slot, três mudanças

```
ana@laptop:~/aws$ psql -c "SHOW wal_level"
 wal_level 
-----------
 logical
(1 row)

ana@laptop:~/aws$ psql -c "CREATE TABLE orders (order_id text PRIMARY KEY, customer_id text NOT NULL, total_cents integer NOT NULL)" -c "INSERT INTO orders VALUES ('ord-1', 'c-17', 4590)"
CREATE TABLE
INSERT 0 1
ana@laptop:~/aws$ psql -c "SELECT slot_name, lsn FROM pg_create_logical_replication_slot('dms_orders', 'test_decoding')"
 slot_name  |    lsn    
------------+-----------
 dms_orders | 0/15183B0
(1 row)
```

**O slot foi criado numa posição do log**, o `lsn`, um log sequence number: o deslocamento em bytes no
WAL, escrito como duas metades hexadecimais. O pedido inserido antes de o slot existir, `ord-1`, nunca
vai ser informado por ele. Esse é o ponto de partida que uma tarefa full-load-and-cdc anota antes de
copiar uma tabela, da primeira seção desta lição. Agora mude a tabela de três jeitos, e pergunte ao
slot o que ele viu, primeiro sem consumir nada:

```
ana@laptop:~/aws$ psql -c "INSERT INTO orders VALUES ('ord-2', 'c-03', 12800)" -c "UPDATE orders SET total_cents = 4990 WHERE order_id = 'ord-1'" -c "DELETE FROM orders WHERE order_id = 'ord-2'"
INSERT 0 1
UPDATE 1
DELETE 1
ana@laptop:~/aws$ psql -Atc "SELECT lsn, xid, data FROM pg_logical_slot_peek_changes('dms_orders', NULL, NULL)"
0/15183B0|732|BEGIN 732
0/15183B0|732|table public.orders: INSERT: order_id[text]:'ord-2' customer_id[text]:'c-03' total_cents[integer]:12800
0/1518468|732|COMMIT 732
0/1518468|733|BEGIN 733
0/1518468|733|table public.orders: UPDATE: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990
0/15184F0|733|COMMIT 733
0/15184F0|734|BEGIN 734
0/15184F0|734|table public.orders: DELETE: order_id[text]:'ord-2'
0/1518568|734|COMMIT 734
```

**Toda mudança confirmada, na ordem dos commits, cada uma dentro da sua transação.** A inserção traz
a linha nova inteira com os tipos. A alteração traz a linha como ela está agora. A exclusão traz só a
chave primária, porque por padrão é tudo o que o PostgreSQL escreve no log sobre uma linha apagada, e
isso basta para achar a linha no destino e apagá-la lá. Cada mudança fica entre um `BEGIN` e um
`COMMIT` com o id da transação, `xid`, e é assim que um leitor sabe quais mudanças valem ou caem
juntas. Uma transação desfeita com rollback nem aparece.

**`peek` leu as mudanças e as deixou; `get` as lê e move o marcador.** Leia as mesmas mudanças com
`get`, e depois de novo:

```
ana@laptop:~/aws$ psql -Atc "SELECT data FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)"
BEGIN 732
table public.orders: INSERT: order_id[text]:'ord-2' customer_id[text]:'c-03' total_cents[integer]:12800
COMMIT 732
BEGIN 733
table public.orders: UPDATE: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990
COMMIT 733
BEGIN 734
table public.orders: DELETE: order_id[text]:'ord-2'
COMMIT 734
ana@laptop:~/aws$ psql -Atc "SELECT count(*) FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)"
0
```

**A segunda leitura vem vazia, e esse é o contrato**: depois que um leitor pegou as mudanças, o
servidor as esquece, e fica livre para reciclar aquela parte do log. O DMS lê por um slot do mesmo
tipo, e só confirma o que já aplicou no destino, mas o marcador anda do mesmo jeito.

## Como era a linha antiga

**Uma alteração que traz só a linha nova não consegue dizer ao destino o que mudou**, e um destino que
precisa dos valores antigos, uma tabela de auditoria ou um lake que guarda histórico, fica sem nada.
`REPLICA IDENTITY` é a configuração da tabela que diz quanto da linha antiga vai para o log:

```
ana@laptop:~/aws$ psql -c "ALTER TABLE orders REPLICA IDENTITY FULL" -c "UPDATE orders SET total_cents = 5190 WHERE order_id = 'ord-1'"
ALTER TABLE
UPDATE 1
ana@laptop:~/aws$ psql -Atc "SELECT xid, data FROM pg_logical_slot_get_changes('dms_orders', NULL, NULL)"
735|BEGIN 735
735|COMMIT 735
736|BEGIN 736
736|table public.orders: UPDATE: old-key: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:4990 new-tuple: order_id[text]:'ord-1' customer_id[text]:'c-17' total_cents[integer]:5190
736|COMMIT 736
```

**Agora a alteração traz `old-key` e `new-tuple`**: 4990 antes, 5190 depois. A primeira transação,
vazia, é o próprio `ALTER TABLE`, e ela não traz mudança nenhuma, porque a decodificação lógica não
informa mudanças na estrutura de uma tabela. O DMS cuida delas à parte, e esse é mais um motivo para
uma migração evitar mudar as colunas de uma tabela enquanto roda. `FULL` escreve mais WAL a cada
alteração e exclusão da tabela, e esse é o preço, e uma tabela sem chave primária precisa dele, ou de
algo parecido, antes que as suas alterações e exclusões possam ser replicadas.

## O slot que ninguém lê

```
ana@laptop:~/aws$ psql -c "INSERT INTO orders SELECT 'bulk-' || g, 'c-' || (g % 50), 1000 FROM generate_series(1, 20000) g"
INSERT 0 20000
ana@laptop:~/aws$ psql -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
 slot_name  | active | retained 
------------+--------+----------
 dms_orders | f      | 3431 kB
(1 row)

ana@laptop:~/aws$ psql -Atc "SELECT pg_drop_replication_slot('dms_orders')" -c "SELECT count(*) FROM pg_replication_slots"

0
```

**Vinte mil linhas inseridas e ninguém lendo: o slot está segurando 3431 kB de log** que o servidor,
sem ele, já teria reciclado. Esse é o perigo do CDC no PostgreSQL que importa, e ele nem está no DMS.
Um slot guarda o WAL que o leitor não confirmou, sem limite por padrão, então uma tarefa parada por um
fim de semana, ou apagada com o slot esquecido para trás, faz o banco antigo guardar toda mudança que
faz até o disco encher, e um disco cheio para a loja. **A regra é apagar o slot quando o leitor não
existe mais**, que é o que o último comando fez, e acompanhar o tamanho retido de todo slot enquanto
ele existir. Desde a versão 13 o PostgreSQL também consegue limitar isso com
`max_slot_wal_keep_size`, que desiste de um slot que fica atrasado demais em vez de encher o disco; o
leitor então precisa recomeçar com uma carga completa nova.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Duas faixas de dez segmentos de WAL, o mais antigo à esquerda. Quando o leitor está em dia, os seis segmentos mais antigos são reciclados pelo servidor e só os que vão do restart_lsn do slot até agora ficam guardados até o leitor confirmá-los. Quando o leitor parou, o restart_lsn fica perto do começo e todo segmento desde então fica guardado, até o disco encher.\" data-fig=\"l26-slot\"><defs><marker id=\"ah-l26-slot\" viewBox=\"0 0 10 10\" refX=\"9\" refY=\"5\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L10,5 L0,10 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">leitor em dia</text><rect x=\"120\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"176\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"232\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"288\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"344\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"400\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"456\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"568\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"624\" y=\"60\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"453\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">restart_lsn</text><text x=\"674\" y=\"50\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">agora</text><text x=\"285\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reciclado pelo servidor</text><text x=\"593.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">guardado até confirmar</text><text x=\"20\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">leitor parado</text><rect x=\"120\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"176\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><rect x=\"232\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"288\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"344\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"400\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"456\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"512\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"568\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"624\" y=\"150\" width=\"50\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"229\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">restart_lsn</text><text x=\"453\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">todo segmento desde então fica guardado, até o disco encher</text><text x=\"397\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">segmentos de WAL, o mais antigo à esquerda</text></svg>", "caption": "Um slot faz o servidor guardar todo pedaço do log que o leitor não confirmou, sem limite a menos que um seja definido."}
```

Quando terminar, pare o servidor descartável e apague-o; nada mais na sua máquina o usava:

```sh
$PG/pg_ctl -D ~/aws/cdc/data stop
rm -rf ~/aws/cdc
```
