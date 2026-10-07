---
title: Duas cópias da aplicação
version: 1
---

Uma cópia da loja é um processo, e um processo é um ponto único de falha além de um teto para o
trabalho que dá para fazer. A loja roda como duas, nas portas 8001 e 8002, e um bloco **upstream** as
nomeia como um grupo para o qual o `proxy_pass` pode apontar:

```conf
upstream shop {
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}

server {
    listen 80;
    server_name ipelivros.example www.ipelivros.example;

    root /var/www/ipe;
    index index.html;

    location /api/ {
        proxy_pass http://shop;
        proxy_http_version 1.1;
        proxy_set_header Connection        "";
        proxy_set_header Host              $host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    access_log /var/log/nginx/ipelivros.access.log;
    error_log  /var/log/nginx/ipelivros.error.log;
}
```

`proxy_pass http://shop` agora nomeia o grupo em vez de um endereço. O jeito padrão de dividir as
requisições entre os membros é o **round robin**: cada um na sua vez. Seis requisições, então:

```
ana@web:~$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -D - http://ipelivros.example/api/books/1 | grep X-Served-By; done
X-Served-By: shop1
X-Served-By: shop1
X-Served-By: shop1
X-Served-By: shop1
X-Served-By: shop2
X-Served-By: shop1
```

Isso não é cada um na sua vez, e vale entender por quê antes de confiar em qualquer coisa que esta
aula mede. **Cada worker do Nginx guarda a própria posição do round robin.** Cada `curl` abre uma
conexão nova, o kernel a entrega ao worker que estiver livre entre os quatro, e cada worker começa a
própria contagem pelo `shop1`. Em muitas requisições a conta se equilibra:

```
ana@web:~$ for i in $(seq 100); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c
     50 shop1
     50 shop2
```

Cinquenta e cinquenta em cem. Em seis parecia quebrado. A correção é o `zone`, que põe o estado do
grupo numa memória compartilhada por todos os workers, então há uma posição de round robin em vez de
quatro:

```
ana@web:~$ sudo sed -i 's/^upstream shop {/upstream shop {\n    zone shop 64k;/' /etc/nginx/sites-available/ipelivros && sed -n '1,6p' /etc/nginx/sites-available/ipelivros
upstream shop {
    zone shop 64k;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}
ana@web:~$ for i in 1 2 3 4 5 6; do curl -s -o /dev/null -D - http://ipelivros.example/api/books/1 | grep X-Served-By; done
X-Served-By: shop1
X-Served-By: shop2
X-Served-By: shop1
X-Served-By: shop2
X-Served-By: shop1
X-Served-By: shop2
```

**O `zone` deve estar em todo bloco upstream que você escrever.** Sem ele, todo contador por membro é
contado quatro vezes: a vez, as falhas da seção depois da próxima e as conexões que o `least_conn`
equilibra. Nada avisa da diferença. Ela aparece como um comportamento que parece quase certo.

## Mantendo conexões com a aplicação abertas

As três linhas novas no location tratam de uma coisa só. Por padrão o Nginx abre uma conexão nova com
a aplicação para cada requisição e a fecha depois, o que para uma resposta JSON pequena pode custar
mais do que a própria resposta. `keepalive 16` deixa cada worker guardar até dezesseis conexões
ociosas com o grupo, e elas só são reaproveitadas em HTTP/1.1 com o cabeçalho `Connection` limpo, daí
`proxy_http_version 1.1` e `proxy_set_header Connection ""`. Depois das cem requisições acima, as
conexões continuam lá, esperando:

```
ana@web:~$ sudo ss -Htn state established '( dport = :8001 or dport = :8002 )' | wc -l
8
```

Oito conexões abertas do Nginx para as duas lojas, entre quatro workers. Sem `keepalive`, o Nginx
fecha cada uma quando a requisição termina, e toda requisição nova paga antes um handshake TCP.
