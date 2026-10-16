---
title: O que a aplicação vê durante uma troca
version: 1
---

Um substituto para uma aplicação: um pedido por segundo, cada um numa conexão nova pela porta 5000 do
HAProxy, durante quarenta segundos. Salve como `orders.sh` e torne-o executável:

```schooling-example
{"language": "sh", "file": "orders.sh", "parts": [{"code": "#!/bin/sh\n# orders.sh: one order a second through HAProxy, for 40 seconds\nfor i in $(seq 1 40); do\n  if port=$(psql -h 127.0.0.1 -p 5000 -U postgres -XAtq shop -c \"\n      INSERT INTO orders (customer_id, total_cents, placed_at)\n      VALUES ($i, 1000 + $i, now()) RETURNING inet_server_port()\" 2>/dev/null)\n  then\n    echo \"$(date +%T) ok on $port\"\n  else\n    echo \"$(date +%T) FAILED\"\n  fi\n  sleep 1\ndone", "note": "Um substituto para uma aplicação: um pedido por segundo, cada um numa conexão nova pela porta 5000, durante quarenta segundos. Cada linha diz se funcionou, quando, e qual servidor recebeu o pedido."}]}
```

Inicie duas coisas em background: uma conexão de longa duração pela porta 5000 que pergunta em qual
servidor está, dorme trinta segundos e pergunta de novo, e o `orders.sh`. Então, com as duas rodando,
mude o líder do `pg1` para o `pg2`:

```
ana@vm:~$ psql -h 127.0.0.1 -p 5000 -U postgres -XAt shop -c 'SELECT inet_server_port()' -c 'SELECT pg_sleep(30)' -c 'SELECT inet_server_port()' > held.log 2>&1 &
ana@vm:~$ ./orders.sh > orders.log 2>&1 &
ana@vm:~$ patronictl -c ~/patroni/pg1.yml switchover --leader pg1 --candidate pg2 --force > /dev/null 2>&1
```

Quando tudo terminar, os pedidos:

```
ana@vm:~$ cat orders.log
02:17:30 ok on 5441
02:17:31 ok on 5441
02:17:32 ok on 5441
02:17:33 ok on 5441
02:17:34 ok on 5441
02:17:35 ok on 5441
02:17:36 ok on 5441
02:17:37 ok on 5441
02:17:38 ok on 5441
02:17:42 FAILED
02:17:43 FAILED
02:17:44 ok on 5442
02:17:45 ok on 5442
02:17:46 ok on 5442
02:17:47 ok on 5442
02:17:49 ok on 5442
02:17:50 ok on 5442
02:17:51 ok on 5442
02:17:52 ok on 5442
02:17:53 ok on 5442
02:17:54 ok on 5442
02:17:55 ok on 5442
02:17:56 ok on 5442
02:17:57 ok on 5442
02:17:58 ok on 5442
02:17:59 ok on 5442
02:18:00 ok on 5442
02:18:01 ok on 5442
02:18:02 ok on 5442
02:18:03 ok on 5442
02:18:04 ok on 5442
02:18:05 ok on 5442
02:18:07 ok on 5442
02:18:08 ok on 5442
02:18:09 ok on 5442
02:18:10 ok on 5442
02:18:11 ok on 5442
02:18:12 ok on 5442
02:18:13 ok on 5442
02:18:14 ok on 5442
```

Nove pedidos no `pg1`, depois **duas falhas**, depois pedidos no `pg2` até o fim. Entre o último pedido
na 5441, às 02:17:38, e o primeiro na 5442, às 02:17:44, o shop não recebeu nada por cerca de **seis
segundos**: o Patroni parando o `pg1` de forma limpa, promovendo o `pg2`, e as checagens do HAProxy
precisando de duas respostas boas seguidas, com dois segundos entre elas, antes de mandar alguém para
ele. A tentativa depois de 02:17:38 travou no meio da troca e falhou às 02:17:42. Isso é um
**switchover**, o tipo suave; um failover soma o `ttl` da lição 16 por cima.

E a conexão de longa duração:

```
ana@vm:~$ cat held.log
5441
FATAL:  terminating connection due to administrator command
server closed the connection unexpectedly
	This probably means the server terminated abnormally
	before or while processing the request.
connection to server was lost
```

Ela respondeu `5441` e depois foi **encerrada**, `pg_sleep` e tudo, quando o `pg1` foi parado para a
troca. O terceiro comando nunca rodou. Nenhum proxy, endereço ou string de conexão consegue levar uma
conexão aberta de um servidor para outro, porque a própria sessão, com a sua transação e as suas
configurações, vivia num processo no primário antigo.

## O que a aplicação precisa fazer

O proxy fez a parte dele: as conexões novas foram para o lugar certo em poucos segundos. Todo o resto
está na aplicação:

- **Trate uma conexão quebrada como algo esperado**, durante um failover ou um switchover, e reconecte
  em vez de cair ou mostrar uma página de erro.
- **Repita a transação, não o comando**, e só se for seguro: um pedido que falhou com "connection
  lost" pode ter sido commitado ou não, como a lição 12 mostrou. Uma tabela de pedidos com
  uma chave única fornecida pela aplicação (um número de pedido gerado antes do insert) torna a
  repetição incapaz de duplicar qualquer coisa.
- **Espere um pouco entre as tentativas**, porque os primeiros segundos depois de uma troca são quando
  o novo primário está menos pronto e todos os clientes estão se reconectando ao mesmo tempo.

As duas falhas acima são o que o `orders.sh` faz sem nada disso: ele as informa e segue em frente. Um
shop que faz o mesmo perde esses dois pedidos.

Depois disso, o HAProxy e a string de conexão apontam os dois para o `pg2`:

```
ana@vm:~$ curl -s 'http://127.0.0.1:7000/;csv' | cut -d, -f1,2,18 | grep -E '^primary,pg'
primary,pg1,DOWN
primary,pg2,UP
primary,pg3,DOWN
ana@vm:~$ psql 'host=127.0.0.1,127.0.0.1,127.0.0.1 port=5441,5442,5443 user=postgres dbname=shop target_session_attrs=read-write' -XAt -c 'SELECT inet_server_port()'
5442
```
