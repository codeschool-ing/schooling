---
title: Medindo o que o cache faz
version: 1
---

Um cache que ninguém mede é um cache que ninguém consegue defender, ajustar ou perceber falhando. O
número que importa é a **taxa de acerto** (*hit ratio*): a fração das requisições respondidas pelo
cache. O Nginx a conhece para cada requisição em `$upstream_cache_status`, e um formato de log próprio
a registra:

```
ana@web:~$ cat /etc/nginx/conf.d/cache-log.conf
log_format cache '$remote_addr [$time_local] "$request" $status '
                 'cache=$upstream_cache_status upstream_time=$upstream_response_time';
ana@web:~$ sudo sed -i 's|    access_log /var/log/nginx/ipelivros.access.log;|    access_log /var/log/nginx/ipelivros.access.log;\n    access_log /var/log/nginx/ipelivros.cache.log cache;|' /etc/nginx/sites-available/ipelivros
```

O mesmo site pode escrever dois logs, um no formato comum e outro para o cache. Duzentas requisições,
espalhadas por dez livros, depois de esvaziar o cache:

```
ana@web:~$ for i in $(seq 200); do curl -s -o /dev/null https://ipelivros.example/api/books/$(( (i % 10) + 1 )); done; tail -n 3 /var/log/nginx/ipelivros.cache.log
127.0.0.1 [07/Oct/2026:01:01:12 -0300] "GET /api/books/9 HTTP/1.1" 200 cache=HIT upstream_time=-
127.0.0.1 [07/Oct/2026:01:01:12 -0300] "GET /api/books/10 HTTP/1.1" 200 cache=HIT upstream_time=-
127.0.0.1 [07/Oct/2026:01:01:12 -0300] "GET /api/books/1 HTTP/1.1" 200 cache=HIT upstream_time=-
ana@web:~$ awk '{print $8}' /var/log/nginx/ipelivros.cache.log | sort | uniq -c
    190 cache=HIT
     10 cache=MISS
ana@web:~$ for p in 8001 8002; do curl -s localhost:$p/api/stats; done
{"server": "shop1", "db_queries": 5}
{"server": "shop2", "db_queries": 5}
```

**190 acertos e 10 erros: uma taxa de acerto de 95 por cento**, e as lojas fizeram uma consulta ao banco
por livro, dez no total, onde duzentas requisições sem o cache teriam feito duzentas. Um acerto mostra
`upstream_time=-`, porque nenhum upstream foi consultado.

Duas coisas mexem nesse número, e nenhuma está na configuração do Nginx. **Quantas coisas diferentes
são pedidas**: dez livros guardados por um minuto é fácil; cem mil livros, cada um pedido uma vez por
dia, quase nunca acertariam, seja qual for o tamanho do cache. E **quanto tempo uma cópia pode viver**:
um tempo de vida menor que o intervalo entre dois pedidos da mesma coisa transforma toda requisição num
erro. Uma taxa de acerto baixa é um fato sobre o tráfego e os tempos de vida antes de ser um fato sobre
o cache.

## E o que ele compra

O `ab`, dez de cada vez, duzentas requisições por um livro: primeiro direto na loja, depois pelo Nginx
com a cópia no cache.

```
ana@web:~$ ab -q -n 200 -c 10 http://localhost:8001/api/books/6 | grep -E 'Requests per second|Time per request.*mean\)$'
Requests per second:    68.51 [#/sec] (mean)
Time per request:       145.967 [ms] (mean)
ana@web:~$ ab -q -n 200 -c 10 https://ipelivros.example/api/books/6 | grep -E 'Requests per second|Time per request.*mean\)$'
Requests per second:    1184.88 [#/sec] (mean)
Time per request:       8.440 [ms] (mean)
```

68,51 requisições por segundo contra 1.184,88. O número da loja é o do banco: cada requisição espera
120 ms pela consulta, e dez de cada vez dão o teto de cerca de 80 por segundo, menos o custo extra. O
número do cache é o do Nginx, incluindo um handshake TLS por requisição, já que o `ab` não reaproveita
conexões. A razão entre os dois, cerca de dezessete vezes nesta máquina, é para que serve um cache na
frente de uma aplicação lenta, e é também por que a próxima aula existe: cada uma dessas respostas
rápidas só é tão atual quanto a cópia de onde saiu.
