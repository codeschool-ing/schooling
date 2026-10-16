---
title: Dimensionando o pool a partir de uma medida
version: 1
---

`default_pool_size = 8` foi um palpite. O tamanho do pool é o número de transações em que o servidor
trabalha ao mesmo tempo, então ele é o botão de que tratava a curva da seção 03, levado da aplicação
para o PgBouncer. Pequeno demais, e o servidor fica parado enquanto os clientes esperam no pool;
grande demais, e os clientes esperam dentro do servidor, nas filas dele, a um preço mais alto. O
tamanho certo é a dobra da curva, e o jeito de achá-lo é medir.

## Mudando sem reiniciar

O console do PgBouncer, o pseudobanco `pgbouncer` em que o `admin_users` deixou você entrar, aceita
`SET` para a maioria das configurações e aplica na hora. Duzentos clientes, a mistura da aula 2,
vinte segundos, em cinco tamanhos de pool:

```
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 2"
SET default_pool_size=2
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 241.050 ms
tps = 829.703130 (without initial connection time)
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 4"
SET default_pool_size=4
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 179.263 ms
tps = 1115.679412 (without initial connection time)
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 8"
SET default_pool_size=8
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 161.900 ms
tps = 1235.333375 (without initial connection time)
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 16"
SET default_pool_size=16
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 154.251 ms
tps = 1296.591974 (without initial connection time)
ana@vm:~/workload$ psql -h 127.0.0.1 -p 6432 pgbouncer -c "SET default_pool_size = 32"
SET default_pool_size=32
ana@vm:~/workload$ pgbench -h 127.0.0.1 -p 6432 -n -c 200 -j 4 -T 20 -f customer-orders.sql@50 -f order-page.sql@25 -f tag-search.sql@10 -f place-order.sql@10 -f seller-dashboard.sql@4 -f pending-count.sql@1 market | grep -E '^(latency average|tps)'
latency average = 147.839 ms
tps = 1352.819242 (without initial connection time)
```

## Lendo

| tamanho do pool | tps | latência média |
|---|---|---|
| 2 | 830 | 241 ms |
| 4 | 1116 | 179 ms |
| 8 | 1235 | 162 ms |
| 16 | 1297 | 154 ms |
| 32 | 1353 | 148 ms |

Duas conexões com o servidor são claramente poucas: **830 transações por segundo**, com 198 clientes
esperando por duas conexões. Quatro são um terço melhores, 1116. Depois disso a linha se achata: 1235
com oito, 1297 com dezesseis, 1353 com trinta e duas, cada vez que dobra comprando menos que a
anterior.

Quanto menos importa, porque a regra da aula 1 vale aqui: **uma diferença menor que o ruído não é uma
diferença.** O mesmo pool de oito, rodado duas vezes nesta aula, deu 1235 aqui e 1342 na seção 04.
São 107 transações de distância sem mudança nenhuma. Todo passo de oito para cima é menor que isso. Então
a leitura honesta é que a dobra fica **entre quatro e oito**, como a curva da seção 03 a pôs, por
volta do número de processadores, e que acima dela esta máquina não consegue distinguir os tamanhos.

Quando as medidas não distinguem dois tamanhos, **fique com o menor.** Ele faz o mesmo trabalho com
menos processos no servidor, deixa mais do `max_connections` para todo o resto, e quando uma transação
fica lenta ela segura uma parte menor do servidor. Um pool de trinta e duas conexões em quatro
processadores é a disputa de noventa clientes levada de volta para dentro do servidor.

## Uma regra prática, e por que ela é só um começo

Um ponto de partida comum é um pool de **mais ou menos o dobro do número de processadores**, mais um
pouco para conexões que esperam o disco. Em quatro processadores isso dá oito a dez, perto do que a
medida achou. Trate isso como o primeiro número a medir, nunca como a resposta: uma carga que espera
o disco ou travas quer mais, uma que é só cálculo quer menos, e o único jeito de saber qual é a sua é
a execução acima.

Três outras coisas decidem o número real em produção, e vale nomeá-las aqui, embora esta máquina só
tenha um de cada:

- **Todo pool se soma.** O `default_pool_size` vale por banco e papel. Três servidores de aplicação,
  cada um com o seu PgBouncer e um pool de 20, são 60 conexões no banco. A soma é que precisa ficar
  abaixo da dobra, e abaixo do `max_connections`.
- **Deixe espaço para as pessoas.** Migrações, um `psql` durante um incidente, monitoramento, um
  backup: eles se conectam direto, e o limite precisa ter espaço para eles quando os pools estão
  cheios. As três vagas de superusuário são para o último recurso, não para isso.
- **O pool limita o trabalho, então vigie a espera.** Com o pool cheio, uma consulta lenta não deixa o
  servidor lento, deixa a fila lenta: `cl_waiting` e `maxwait` no `SHOW POOLS` são os números para
  colocar em gráfico e em alerta. A aula 18 de `db-reliability` trata de operar o PgBouncer assim: a
  disponibilidade dele, os logs e o lugar dele num failover.

## Pondo a máquina de volta

Tudo o que esta aula mudou fora de `market` é desfeito do jeito que foi feito: pare o PgBouncer e
impeça que ele suba no boot, ponha a configuração original de volta, esvazie a lista de usuários,
remova o arquivo de senha e a senha:

```
ana@vm:~$ sudo systemctl disable --now pgbouncer
Synchronizing state of pgbouncer.service with SysV service script with /usr/lib/systemd/systemd-sysv-install.
Executing: /usr/lib/systemd/systemd-sysv-install disable pgbouncer
ana@vm:~$ sudo mv /etc/pgbouncer/pgbouncer.ini.orig /etc/pgbouncer/pgbouncer.ini
ana@vm:~$ sudo truncate -s 0 /etc/pgbouncer/userlist.txt
ana@vm:~$ rm ~/.pgpass
market=# ALTER ROLE ana PASSWORD NULL;
ALTER ROLE
Time: 1.440 ms
```

A carga gravou pedidos, então termine com `market` como a aula 17 começa:

```
ana@vm:~$ ~/reset-market.sh
CREATE EXTENSION
Time: 10.848 ms
CREATE INDEX
Time: 700.261 ms
```
