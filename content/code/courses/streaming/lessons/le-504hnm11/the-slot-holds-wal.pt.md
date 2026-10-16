---
title: O slot que segura o WAL
version: 1
---

**Um conector parado não perde dados; ele faz o banco guardá-los.** Essa é a promessa de um slot de
replicação, e é também o jeito mais comum de a CDC derrubar um banco de produção. O conector para —
um deploy que falhou, um broker fora do ar, credenciais que expiraram num fim de semana — e ninguém
percebe, porque nada está falhando: o site funciona, a tabela está bem, e o tópico simplesmente não
recebe nada. Enquanto isso o PostgreSQL guarda todo arquivo de WAL gravado desde a última posição
confirmada do slot, e o disco sob o banco enche.

Faça acontecer. No segundo shell, pare o Connect com Ctrl+C. De volta ao primeiro, esta consulta
mostra cada slot, se alguém o está lendo, e duas distâncias medidas em bytes de WAL: o quanto o
leitor está atrás do servidor agora, e quanto WAL o servidor está guardando por causa dele:

```
ubuntu@stream:~/work$ psql pontofinal -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
   slot_name    | active |  behind   |  retained  
----------------+--------+-----------+------------
 debezium_stock | f      | 656 bytes | 1160 bytes
(1 row)
```

O `active` é `f`: ninguém está conectado. Agora a loja continua trabalhando. Alguém monta uma tabela
de anotações que não tem nada a ver com CDC e não está na publicação, e depois uma entrega repõe o
estoque de toda loja com um exemplar de tudo:

```
ubuntu@stream:~/work$ psql pontofinal -c "CREATE TABLE notes AS SELECT g AS id, md5(g::text) AS body FROM generate_series(1, 200000) g"
SELECT 200000
ubuntu@stream:~/work$ psql pontofinal -c "UPDATE stock SET qty = qty + 1"
UPDATE 39
ubuntu@stream:~/work$ psql pontofinal -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
   slot_name    | active | behind | retained 
----------------+--------+--------+----------
 debezium_stock | f      | 18 MB  | 18 MB
(1 row)
```

O `retained` foi de 1160 bytes para 18 MB, quase tudo as 200.000 linhas de `notes`. **A tabela de anotações não está publicada, e o WAL dela fica guardado do mesmo jeito.** O WAL é um
fluxo só para o servidor inteiro; um slot segura todo ele a partir da sua posição, sejam de quais
tabelas forem os bytes. Um slot que lê duas tabelas pequenas num banco onde outra coisa escreve
gigabytes por hora segura esses gigabytes.

## Alcançando

Suba o Connect de novo no segundo shell, com o mesmo comando de antes. Ele acha a sua posição no
`connect.offsets`, pede ao slot tudo o que vem depois dela, e não tira um segundo snapshot. Depois,
no primeiro shell:

```
ubuntu@stream:~/work$ kafka-get-offsets.sh --bootstrap-server localhost:9092 --topic pf.public.stock
pf.public.stock:0:83
```

O offset final é 83: as 44 mensagens que já estavam lá, e os 39 updates feitos enquanto o Connect
estava parado — 39 e não 40, porque o `bk-08` de Natal foi removido na seção anterior. Nada se
perdeu, que é o slot fazendo o trabalho dele. Agora olhe o lado do banco, vinte segundos depois de o
conector alcançar:

```
ubuntu@stream:~/work$ psql pontofinal -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
   slot_name    | active | behind | retained 
----------------+--------+--------+----------
 debezium_stock | t      | 19 MB  | 19 MB
(1 row)
```

**O leitor voltou e o WAL continua retido.** Todas as 39 mudanças estão no Kafka, e o slot não se
mexeu, porque o Debezium só diz ao PostgreSQL até onde chegou quando trata mais uma mudança das
tabelas dele. Uma mudança numa tabela publicada o move:

```
ubuntu@stream:~/work$ psql pontofinal -c "UPDATE books SET cents = 4190 WHERE book = 'bk-01'"
UPDATE 1
ubuntu@stream:~/work$ psql pontofinal -c "SELECT slot_name, active, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), confirmed_flush_lsn)) AS behind, pg_size_pretty(pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn)) AS retained FROM pg_replication_slots"
   slot_name    | active | behind | retained 
----------------+--------+--------+----------
 debezium_stock | t      | 120 kB | 19 MB
(1 row)
```

O `behind` cai de 19 MB para 120 kB: o conector confirmou a posição dele. O `retained` continua em
19 MB, porque é medido a partir do `restart_lsn`, o ponto mais antigo de onde o PostgreSQL pode
precisar decodificar de novo, e ele acompanha a confirmação mais tarde; os arquivos de WAL atrás
dele são removidos quando ele anda e o servidor chega ao próximo checkpoint. **Observe as duas
colunas**: `behind` diz se o leitor está acompanhando, `retained` diz quanto o disco está pagando
por ele.

## O que observar, e o limite a definir

**O tamanho retido de cada slot é o número para alertar**, com a consulta acima ou o equivalente
dela no que monitora o banco, e `active = f` por mais tempo do que dura um deploy é o segundo. Um
slot sem leitor é ou um incidente a corrigir ou uma sobra a apagar com `pg_drop_replication_slot` —
e um conector que está sendo aposentado de vez deve ter o slot apagado no mesmo dia, porque nada
mais vai apagá-lo.

O PostgreSQL também tem um fusível, desligado por padrão:

```
ubuntu@stream:~/work$ psql pontofinal -c "SHOW max_slot_wal_keep_size"
 max_slot_wal_keep_size 
------------------------
 -1
(1 row)

EXIT 0
```

`-1` quer dizer sem limite. Com, digamos, `50GB`, o PostgreSQL para de guardar WAL para um slot
além desse tamanho e marca o slot como perdido. **Isso troca o disco do banco pela completude do
conector**: o banco sobrevive, e o conector precisa tirar um novo snapshot, porque as mudanças que
ele perdeu se foram. A maioria das equipes escolhe essa troca, de propósito, com o limite
dimensionado para a pane da qual conseguem se recuperar.

Mais uma configuração fecha a brecha que a recuperação mostrou. O slot só anda quando o conector
confirma uma mudança que leu, então se as tabelas publicadas estão quietas enquanto outras estão
movimentadas — a `stock` mudando uma vez por dia num banco que escreve a noite toda — o slot fica
parado e o WAL cresce com o Connect rodando e saudável. O `heartbeat.interval.ms` do Debezium faz o
conector confirmar a posição num intervalo de tempo, tenham as tabelas dele mudado ou não. Ele não
foi definido neste laboratório, e é por isso que o `UPDATE` acima foi necessário para mover o slot.

Antes de sair desta lição, pare o Connect com Ctrl+C no segundo shell. O PostgreSQL pode continuar
rodando; ele não faz nada até alguém escrever nele.
