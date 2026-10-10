---
title: fsync, synchronous_commit e a diferença entre eles
version: 1
---

Duas configurações deixam uma carga de escrita mais rápida enfraquecendo a garantia que você acabou
de ver valer, e elas parecem duas intensidades do mesmo botão. **Não são. O `synchronous_commit =
off` pode perder o último instante de trabalho e deixa o banco correto; o `fsync = off` pode deixá-lo
corrompido.** Uma é uma decisão que uma aplicação pode tomar por si; a outra é uma configuração que
ninguém deveria afrouxar num banco que quer manter.

```
shop=# SHOW fsync;
 fsync 
-------
 on
(1 row)

shop=# SHOW synchronous_commit;
 synchronous_commit 
--------------------
 on
(1 row)

shop=# SHOW wal_writer_delay;
 wal_writer_delay 
------------------
 200ms
(1 row)
```

## O que um commit espera

`fsync` é a chamada de sistema que pede ao sistema operacional para pôr os dados de um arquivo no
disco e só voltar quando tiver posto. **Um commit com `synchronous_commit = on` espera essa chamada
sobre o log**: a linha no `acked.txt` só foi impressa depois de o disco ter confirmado o registro do
commit. Essa espera é a maior parte do tempo que uma transação de escrita pequena leva.

Com `synchronous_commit = off`, o `COMMIT` responde assim que o registro está nos buffers de WAL na
memória. O walwriter, o processo de fundo da lição 7, os grava a cada `wal_writer_delay`, então o
log no disco fica uma fração de segundo atrás dos commits; no pior caso, cerca de três vezes esse
intervalo. Meça quanto a espera custa. O `PGOPTIONS` passa uma configuração ao servidor só para
estas conexões, então nada no servidor muda e nada precisa ser desfeito:

```
ana@db:~$ pgbench -n -c 4 -T 30 bench | grep -E 'processed|latency|tps'
number of transactions actually processed: 61073
latency average = 1.964 ms
tps = 2036.258559 (without initial connection time)
ana@db:~$ PGOPTIONS='-c synchronous_commit=off' pgbench -n -c 4 -T 30 bench | grep -E 'processed|latency|tps'
number of transactions actually processed: 127610
latency average = 0.940 ms
tps = 4254.118454 (without initial connection time)
```

O `-T 30` roda por trinta segundos em vez de uma contagem fixa. **Não esperar pelo disco mais ou
menos dobrou o trabalho feito no mesmo tempo** na máquina da gravação, e cortou pela metade a
latência de cada transação. Fique com a razão, não com os números: as duas execuções dividiram
quatro processadores e um disco com outro trabalho, e o próximo par mediria diferente. A razão
depende de quanto o disco demora para confirmar uma gravação. Uma confirmação lenta — um disco
giratório, um volume de rede — aumenta a distância, e um disco com cache protegido por bateria a
diminui. A lição 9 mede a confirmação do seu disco com o `pg_test_fsync`.

O que isso custa é exato. Depois de uma queda, os commits do último instante que não tinham sido
gravados somem, embora os clientes deles tenham ouvido que deram certo. **O que sobra continua
sendo um banco consistente**: essas transações estão ausentes por inteiro, como se a queda tivesse
vindo uma fração de segundo antes, e a recuperação roda como na seção anterior. Isso faz dela uma
troca justa para trabalho que pode ser perdido, como um contador de visualizações ou a hora do
último acesso de uma sessão. E a configuração pode valer para uma transação só:

```sql
BEGIN;
SET LOCAL synchronous_commit = off;
UPDATE ... ;
COMMIT;
```

O `SET LOCAL` dura até o fim da transação, então os pagamentos confirmados pela próxima sessão
continuam esperando o disco.

## Por que fsync = off corrompe

O `fsync = off` diz ao servidor para nunca fazer aquela chamada, nem para o log nem para os arquivos
das tabelas. Tudo continua indo para o sistema operacional, que grava no disco quando e na ordem que
quiser. A regra da lição 7 era que **nenhuma página chega a um arquivo de tabela antes de a
descrição dela chegar ao log**; com o `fsync` desligado, nada mais garante essa ordem. Depois de uma
queda de energia, o disco pode ter uma página cujo registro de log nunca chegou, ou o log de um
checkpoint cujas páginas nunca chegaram. A recuperação então refaz a partir de um ponto de redo que
prometia páginas gravadas, em cima de páginas que não foram, e o resultado é um estrago que nada
denuncia até uma consulta lê-lo.

Isso não foi demonstrado aqui, e o motivo vale saber: **um `kill -9` não consegue mostrar isso**. O
sistema operacional sobrevive ao kill com todas as escritas ainda no cache, grava tudo depois, e o
banco volta bem. É assim que o `fsync = off` passa em todo teste que não seja uma falta de energia
de verdade ou uma queda do próprio kernel. O único uso defensável é num banco que você está disposto
a jogar fora e construir de novo do zero, como a primeira carga de uma cópia que você descarta se
algo der errado.

| configuração, quando desligada | o que uma queda pode custar | consistente depois |
| --- | --- | --- |
| `synchronous_commit` | a última fração de segundo de commits confirmados | sim |
| `fsync` | qualquer coisa, inclusive dados confirmados muito antes | não |

As duas estão como começaram: o `synchronous_commit` só mudou para as conexões do `pgbench`, e o
`fsync` nunca foi tocado. Limpe o que esta lição criou:

```
shop=# DROP TABLE acks;
DROP TABLE

shop=# DROP TABLE notes;
DROP TABLE
ana@db:~$ dropdb bench
ana@db:~$ rm acked.txt acked.err bench.out
```
