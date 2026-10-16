---
title: Cinco jeitos de um benchmark mentir
version: 1
---

Um benchmark parecido com a sua carga ainda pode relatar um número que a sua produção nunca vai ver.
Os jeitos de dar errado são poucos e se repetem, e cada um tem um sintoma que dá para procurar na
própria execução. Nenhum deles faz o `pgbench` imprimir um erro.

## Curto demais

As linhas de progresso da seção anterior variaram 10% de um intervalo de dez segundos para o
seguinte. Um benchmark de dez segundos é um desses intervalos, então pode relatar qualquer um deles,
e uma mudança "medida" com uma execução de dez segundos antes e outra depois está medindo em que
intervalo caiu.

Execuções curtas também perdem o que só acontece de vez em quando. O PostgreSQL grava em disco as
páginas alteradas num **checkpoint**, a cada cinco minutos por padrão, e um checkpoint tira tempo de
disco das consultas que rodam ao lado. Uma execução de trinta segundos contém um ou não contém, e duas
execuções que só diferem nisso vão diferir nos números. As execuções deste curso têm trinta ou
sessenta segundos porque demonstram; uma execução cujo número vai decidir alguma coisa deve ser longa
o bastante para conter as interrupções comuns do servidor — vários minutos, e mais que o
`checkpoint_timeout`.

## Fria, ou quente

A aula 1 mediu uma consulta fria e quente e achou duas vezes e meia de diferença. Uma carga inteira se
comporta do mesmo jeito. Reinicie o servidor, descarte o cache do sistema operacional e rode com
progresso a cada cinco segundos:

```
ana@vm:~$ sudo systemctl restart postgresql
ana@vm:~$ sudo sh -c "sync; echo 3 > /proc/sys/vm/drop_caches"
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -P 5 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(progress|tps)'
progress: 5.0 s, 1133.6 tps, lat 6.989 ms stddev 21.523, 0 failed
progress: 10.0 s, 1292.2 tps, lat 6.193 ms stddev 19.075, 0 failed
progress: 15.0 s, 975.4 tps, lat 8.136 ms stddev 26.475, 0 failed
progress: 20.0 s, 1085.8 tps, lat 7.432 ms stddev 23.731, 0 failed
progress: 25.0 s, 1103.4 tps, lat 7.218 ms stddev 22.940, 0 failed
progress: 30.0 s, 864.4 tps, lat 9.280 ms stddev 29.638, 0 failed
tps = 1073.036412 (without initial connection time)
```

Nesta máquina a partida a frio quase não aparece: 1134 transações por segundo nos primeiros cinco
segundos contra 1292 nos cinco seguintes, e depois a execução vagou entre 864 e 1103 por motivos que
nada tinham a ver com o cache. O `market` inteiro tem 1,3 GB, e um disco rápido entrega isso em
poucos segundos. **Num banco de produção maior que a memória, o mesmo reinício se sente por horas**,
porque as páginas só esquentam quando as consultas as pedem. Decida qual das duas você está medindo —
o servidor logo depois de uma implantação, ou o servidor numa tarde comum — e, em qualquer caso, rode
uma vez e descarte antes das execuções que vai guardar. A primeira execução depois de uma cópia nova
do `market`, na seção de repetição, mostra como é essa execução descartada.

## O cliente na mesma máquina

O `pgbench` é um programa, e na sua máquina ele roda ao lado do servidor que mede, tirando tempo de
processador que o servidor teria. Quanto, é fácil descobrir:

```
ana@vm:~/workload$ time pgbench -n -c 8 -j 4 -T 30 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^tps'
tps = 1368.504074 (without initial connection time)

real	0m30.116s
user	0m0.711s
sys	0m0.384s
ana@vm:~$ nproc
4
```

Trinta segundos em quatro processadores são 120 segundos de processador, e o `pgbench` usou **1,1
deles** (`user` mais `sys`): menos de um por cento. Para esta carga, cujos comandos levam
milissegundos cada um, o cliente é barato. Quanto mais barato cada comando, maior a parte do cliente.
Para uma carga de comandos minúsculos a dezenas de milhares por segundo, confira esta linha antes de
confiar no número, e para qualquer coisa que importe, rode o cliente em outra máquina, como estão os
servidores de aplicação da produção.

A mesma máquina também esconde a rede. Aqui os clientes chegam ao servidor por um socket local; em
produção cada comando atravessa uma rede, e uma carga de muitos comandos curtos paga essa viagem em
cada um. Um benchmark rodado ao lado do banco relata latências que a aplicação não vai ver.

## Menos dados que a produção

```
market=# SELECT pg_size_pretty(pg_database_size('market'));
 pg_size_pretty 
----------------
 1352 MB
(1 row)

Time: 3.437 ms
ana@vm:~$ free -h
               total        used        free      shared  buff/cache   available
Mem:            15Gi       918Mi        13Gi       156Mi       1.5Gi        14Gi
Swap:             0B          0B          0B
```

**1352 MB de banco contra 14 GB de memória disponível**: toda página do `market` cabe no cache do
sistema operacional com folga, então, depois do primeiro minuto, os benchmarks deste curso medem um
banco que nunca toca o disco. Um banco de produção dez vezes maior que a memória do servidor se
comporta de outro jeito em tudo o que importa. As leituras vão ao disco, e um índice que cabia na
memória deixa de caber. O próprio plano pode mudar com o tamanho das tabelas: a aula 4 mostrou os
pontos de virada se mexendo com as contagens de linhas.

Um benchmark contra uma cópia pequena da produção diz como a cópia pequena se comporta. Para dizer
alguma coisa sobre a produção, rode contra uma cópia do tamanho da produção, ou ao menos do mesmo
tamanho em relação à memória.

## O laço que esconde a fila

Toda execução até aqui foi um **laço fechado**: cada um dos oito clientes envia a próxima transação só
quando a anterior voltou. Quando o servidor fica lento, os clientes ficam lentos com ele, e as
transações que teriam chegado durante o momento lento simplesmente não são enviadas. Usuários reais
não esperam uns pelos outros assim; chegam quando chegam.

O `-R` faz o `pgbench` se comportar como usuários: agenda transações a uma taxa fixa, quer o servidor
tenha alcançado ou não, e conta a espera da vez de uma transação como parte da latência dela:

```
ana@vm:~/workload$ pgbench -n -c 8 -j 4 -T 30 -R 900 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(tps|latency|rate)'
latency average = 17.136 ms
latency stddev = 36.235 ms
rate limit schedule lag: avg 12.970 (max 307.706) ms
tps = 900.173812 (without initial connection time)
```

A **900 por segundo**, menos que os 1234 do laço fechado, a latência média é de **17,1
milissegundos**, e não 6,5 — e 13,0 deles são `schedule lag`, o tempo que uma transação esperou atrás
das anteriores, até 308 milissegundos para a mais azarada. Os 6,5 do laço fechado não estavam errados
sobre as transações que ele enviou. Calavam sobre as que ele nunca enviou enquanto o servidor estava
ocupado. **Uma latência medida em laço fechado é a latência de um servidor a quem nunca se pede mais
do que ele pode dar**, e a produção não é assim.

A aula 23 usa o `-R` para achar como a latência cresce conforme a taxa se aproxima do máximo, e essa
curva é onde o planejamento de capacidade começa. Para um benchmark, a regra é mais curta: informe a
vazão de um laço fechado, se quiser, mas informe a latência a uma taxa fixa perto da real.
