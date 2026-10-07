---
title: Contando à aplicação quem perguntou
version: 1
---

O Nginx sabe tudo o que a aplicação perdeu: o endereço do cliente, o nome que ele pediu e se chegou
por HTTP ou HTTPS. `proxy_set_header` repassa isso como cabeçalhos da requisição, que a aplicação
pode ler:

```
ana@web:~$ grep -A6 'location /api/' /etc/nginx/sites-available/ipelivros
    location /api/ {
        proxy_pass http://127.0.0.1:8001;
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
ana@web:~$ curl -s http://ipelivros.example/api/echo
{"server": "shop1", "peer": "127.0.0.1", "host": "ipelivros.example", "x_real_ip": "127.0.0.1", "x_forwarded_for": "127.0.0.1", "x_forwarded_proto": "http"}
```

| cabeçalho | o que carrega | vem de |
|---|---|---|
| `Host` | o nome que o cliente pediu | `$host` |
| `X-Real-IP` | o endereço do cliente, um valor | `$remote_addr` |
| `X-Forwarded-For` | todo endereço por onde a requisição passou, o cliente primeiro | `$proxy_add_x_forwarded_for` |
| `X-Forwarded-Proto` | `http` ou `https`, como o cliente viu | `$scheme` |

Nenhum deles é padrão no sentido estrito. `X-Forwarded-For` e os irmãos são uma convenção que todo
proxy e todo framework seguem, e a RFC 7239 define um cabeçalho `Forwarded` feito para substituí-los,
que poucas aplicações leem. O Ubuntu traz as quatro linhas acima como `/etc/nginx/proxy_params`, então
`include proxy_params;` as escreve numa linha só:

```
ana@web:~$ cat /etc/nginx/proxy_params
proxy_set_header Host $http_host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $scheme;
```

A única diferença é `$http_host` contra `$host`: o primeiro é o cabeçalho `Host` exatamente como o
cliente mandou, com a porta, e o segundo é o nome sem a porta, ou o nome do próprio servidor se o
cliente não mandou nenhum.

## Um cabeçalho que qualquer um escreve

`X-Forwarded-For` é uma lista, e `$proxy_add_x_forwarded_for` **acrescenta** ao que o cliente já
mandou. Então um cliente pode começar a lista com o que quiser:

```
ana@web:~$ curl -s -H 'X-Forwarded-For: 198.51.100.7' http://ipelivros.example/api/echo
{"server": "shop1", "peer": "127.0.0.1", "host": "ipelivros.example", "x_real_ip": "127.0.0.1", "x_forwarded_for": "198.51.100.7, 127.0.0.1", "x_forwarded_proto": "http"}
```

`198.51.100.7` não é um endereço que participou desta requisição. Foi o cliente que o escreveu, e o
Nginx o manteve fielmente no começo da lista. Uma aplicação que lê a **primeira** entrada e a chama de
"o IP do cliente" acabou de deixar o cliente escolher o próprio endereço, e é assim que se contorna um
limite de taxa ou uma lista de permissões.

**A regra: confie nas entradas acrescentadas por proxies que você opera, e em nada à esquerda
delas.** Com um Nginx na frente, é a última entrada, que é também o que o `X-Real-IP` carrega. Com um
balanceador na frente do Nginx, é a penúltima, e tanto o Nginx (o módulo `realip`) quanto todo
framework web têm uma configuração que diz em quantos proxies confiar exatamente por isso.
