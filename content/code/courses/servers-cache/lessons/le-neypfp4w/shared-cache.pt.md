---
title: Um cache compartilhado na frente da aplicação
version: 1
---

O frescor deixa um navegador pular uma requisição. Para poupar a aplicação das requisições de **todos**
os visitantes, a cópia precisa ficar num lugar por onde todos passam, e o Nginx já está nesse lugar.
Duas peças de configuração o tornam um cache: onde guardar as cópias, no nível `http`, e qual location
as usa.

```
ana@web:~$ cat /etc/nginx/conf.d/cache.conf
proxy_cache_path /var/cache/nginx/shop levels=1:2 keys_zone=api_cache:10m
                 max_size=100m inactive=10m use_temp_path=off;
ana@web:~$ sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
2026/10/07 01:00:48 [emerg] 1445#1445: mkdir() "/var/cache/nginx/shop" failed (2: No such file or directory)
nginx: configuration file /etc/nginx/nginx.conf test failed
ana@web:~$ sudo mkdir -p /var/cache/nginx && sudo nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

O teste pegou algo antes de qualquer requisição: o Nginx cria o diretório do próprio cache e não os
diretórios acima dele, e o Ubuntu não tem `/var/cache/nginx`. `levels=1:2` espalha os arquivos por dois
níveis de subdiretórios, para nenhum diretório acabar com um milhão de arquivos.
`keys_zone=api_cache:10m` é memória compartilhada para o índice do que está guardado, cerca de oito mil
chaves por megabyte; `max_size` limita o disco, e `inactive=10m` descarta o que ninguém pediu em dez
minutos, fresco ou não. A zona precisa de um nome próprio: `shop` já era do upstream.

No location, `proxy_cache` liga o cache, e um cabeçalho extra informa o que ele fez em cada requisição,
o único jeito de ver um cache funcionando de fora:

```
ana@web:~$ sudo sed -i 's|        proxy_pass http://shop;|        proxy_pass http://shop;\n        proxy_cache api_cache;\n        add_header X-Cache-Status $upstream_cache_status always;|' /etc/nginx/sites-available/ipelivros && grep -n -A2 'proxy_pass' /etc/nginx/sites-available/ipelivros
26:        proxy_pass http://shop;
27-        proxy_cache api_cache;
28-        add_header X-Cache-Status $upstream_cache_status always;
ana@web:~$ for i in 1 2 3; do curl -s -o /dev/null -D - -w 'took %{time_total} s\n' https://ipelivros.example/api/books/2 | grep -iE '^x-cache-status|^took'; done
X-Cache-Status: MISS
took 0.151113 s
X-Cache-Status: HIT
took 0.041534 s
X-Cache-Status: HIT
took 0.030108 s
ana@web:~$ for p in 8001 8002; do curl -s localhost:$p/api/stats; done
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 0}
```

**`MISS`, depois `HIT`, `HIT`, e as lojas contaram uma consulta ao banco entre as duas**, onde três
requisições sem o cache fizeram três. A primeira requisição pagou os 120 ms do banco; as duas seguintes
levaram 42 e 30 milissegundos, e quase tudo isso é o `curl` abrindo uma conexão TLS nova a cada vez, já
que a cópia em si saiu do disco do Nginx.

O Nginx tirou o tempo de vida do próprio `Cache-Control: max-age=60` da loja, então nada na
configuração do Nginx diz por quanto tempo: **a origem decide, e todo cache no caminho obedece à mesma
linha**. A cópia é um arquivo, e a primeira linha dele é a **chave** sob a qual está guardado:

```
ana@web:~$ sudo find /var/cache/nginx/shop -type f
/var/cache/nginx/shop/9/67/e8fb3bb9dc4188361a54f7d7c9036679
ana@web:~$ sudo find /var/cache/nginx/shop -type f -exec grep -a -m1 '^KEY' {} \;
KEY: http://shop/api/books/2
```

`http://shop/api/books/2`: a chave padrão é o esquema e o nome **do upstream**, seguidos do caminho e da
query da requisição. Dois sites fazendo proxy para o mesmo grupo upstream dividiriam as cópias, o que
está certo para um site com dois nomes e errado para dois sites diferentes; uma chave escrita como
`$scheme$host$request_uri` os mantém separados.

## Quando a cópia acaba

Com um tempo de vida de cinco segundos:

```
ana@web:~$ grep SHOP /etc/shop/shop.env
SHOP_CACHE_CONTROL=max-age=5
ana@web:~$ curl -s -o /dev/null -D - https://ipelivros.example/api/books/3 | grep -i x-cache-status
X-Cache-Status: MISS
ana@web:~$ curl -s -o /dev/null -D - https://ipelivros.example/api/books/3 | grep -i x-cache-status
X-Cache-Status: HIT
ana@web:~$ sleep 6; curl -s -o /dev/null -D - https://ipelivros.example/api/books/3 | grep -i x-cache-status
X-Cache-Status: EXPIRED
ana@web:~$ curl -s -o /dev/null -D - https://ipelivros.example/api/books/3 | grep -i x-cache-status
X-Cache-Status: HIT
ana@web:~$ for p in 8001 8002; do curl -s localhost:$p/api/stats; done
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 1}
```

`MISS` guarda, `HIT` entrega, e seis segundos depois `EXPIRED`: a cópia estava velha, então o Nginx foi
à loja buscar uma nova e a guardou. Duas consultas ao banco para quatro requisições. O Nginx também
poderia ter **revalidado** a cópia velha com uma requisição condicional, mandando à loja o `ETag` que
tinha, acrescentando `proxy_cache_revalidate on`; com o `304` da loja custando o mesmo que um `200`,
isso não pouparia nada aqui, e a aula 6 tem um uso melhor para uma cópia velha.

## O que ele não guarda

```
ana@web:~$ grep SHOP /etc/shop/shop.env
SHOP_CACHE_CONTROL=private, max-age=60
ana@web:~$ for i in 1 2 3; do curl -s -o /dev/null -D - https://ipelivros.example/api/books/4 | grep -iE '^(cache-control|x-cache-status)'; done
Cache-Control: private, max-age=60
X-Cache-Status: MISS
Cache-Control: private, max-age=60
X-Cache-Status: MISS
Cache-Control: private, max-age=60
X-Cache-Status: MISS
ana@web:~$ for p in 8001 8002; do curl -s localhost:$p/api/stats; done
{"server": "shop1", "db_queries": 1}
{"server": "shop2", "db_queries": 2}
```

`private` quer dizer que nenhum cache compartilhado pode guardar, e o Nginx obedeceu: `MISS` três vezes,
porque olhou, não achou nada e não guardou nada, e três consultas ao banco para três requisições. A
próxima seção explica por que essa recusa importa mais que qualquer taxa de acerto.
