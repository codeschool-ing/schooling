---
title: Limites para rápido demais e devagar demais
version: 1
---

Um servidor que responde a tudo tão rápido quanto lhe pedem pode ser levado a gastar toda a
capacidade com um cliente. Dois tipos de limite o protegem: quanto à **frequência** com que um cliente
pode pedir, e quanto à **lentidão** com que um cliente pode falar.

## Limite de taxa

```conf
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_status 429;
client_header_timeout 5s;
client_body_timeout   5s;
```

A primeira linha declara uma zona: dez megabytes de memória compartilhada que contam requisições por
endereço de cliente, a dez por segundo. Ela é declarada em `http { }` e usada num location, com quanto
de rajada tolerar:

```
ana@web:~$ sudo sed -i 's|        limit_except GET HEAD PUT { deny all; }|        limit_except GET HEAD PUT { deny all; }\n        limit_req zone=api burst=20 nodelay;|' /etc/nginx/sites-available/ipelivros && grep -n 'limit_' /etc/nginx/sites-available/ipelivros
27:        limit_except GET HEAD PUT { deny all; }
28:        limit_req zone=api burst=20 nodelay;
ana@web:~$ for i in $(seq 60); do curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/api/echo; done | sort | uniq -c
     42 200
     18 429
```

Sessenta requisições mandadas tão rápido quanto um `curl` atrás do outro consegue: 42 atendidas, 18
recusadas com `429 Too Many Requests`. A conta é a do **balde de fichas** (*token bucket*): o balde
guarda 20 requisições extras (`burst=20`), o `nodelay` atende essas na hora em vez de espaçá-las, e
ele se reabastece a dez por segundo enquanto o laço roda. O Nginx registra cada recusa:

```
ana@web:~$ grep -c "limiting requests" /var/log/nginx/ipelivros.error.log; grep "limiting requests" /var/log/nginx/ipelivros.error.log | tail -n 1 | cut -c 1-130
18
2026/10/07 00:50:18 [error] 1648#1648: *108 limiting requests, excess: 20.340 by zone "api", client: 127.0.0.1, server: ipelivros.
ana@web:~$ sleep 2; curl -s -o /dev/null -w '%{http_code}\n' https://ipelivros.example/api/echo
200
```

e dois segundos depois o balde se encheu de novo e o mesmo cliente é atendido. O padrão do próprio
Nginx para uma recusa é `503`; `limit_req_status 429` a torna o código que quer dizer "você, vá mais
devagar", que clientes bem-comportados e a lógica de nova tentativa deles entendem.

**Escolha a taxa pelo que um cliente de verdade faz, não pelo que o servidor aguenta.** Uma pessoa
navegando na livraria faz no máximo algumas chamadas à API por segundo; um script copiando o catálogo
inteiro faz centenas. Um limite num endpoint de login é o caso mais forte, medido em poucas por minuto,
porque é o que torna lento adivinhar senhas.

## Clientes lentos

O ataque oposto é abrir muitas conexões e mandar cada requisição um byte por vez, segurando uma conexão
por minutos sem mandar quase nada. O laço de eventos do Nginx torna cada conexão dessas barata, mas não
de graça. `client_header_timeout` e `client_body_timeout` decidem quanto o Nginx espera entre dois
pedaços de uma requisição; o padrão é sessenta segundos, e as linhas acima o tornam cinco. Uma
requisição cuja última linha de cabeçalho nunca é mandada:

```
ana@web:~$ time (exec 3<>/dev/tcp/127.0.0.1/80; printf 'GET / HTTP/1.1\r\nHost: ipelivros.example\r\n' >&3; cat <&3)

real	0m5.006s
user	0m0.002s
sys	0m0.000s
ana@web:~$ sudo grep -h '" 408 ' /var/log/nginx/*.log | tail -n 1
127.0.0.1 - - [07/Oct/2026:00:50:25 -0300] "GET / HTTP/1.1" 408 0 "-" "-"
```

Cinco segundos e a conexão é fechada, com `408 Request Timeout` escrito no log e nada mandado de volta.
