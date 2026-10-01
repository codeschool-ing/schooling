---
title: O que o proxy recusa antes que a aplicação veja
version: 1
---

A proteção mais barata que um proxy oferece é **recusar as requisições de que a aplicação nunca
precisa**. Cada recusa é uma linha de configuração e uma classe de problema que deixa de chegar ao
código por trás dele.

Antes de qualquer mudança, o proxy anuncia seu software e sua versão a quem perguntar:

```
ana@remote:~$ curl -sI https://www.example.com/ | grep -iE "^server|^HTTP"
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
```

Um número de versão diz a um desconhecido quais vulnerabilidades publicadas tentar primeiro.
Escondê-lo não é uma defesa, já que um servidor atualizado está seguro diga ele o que disser, mas
não há motivo para oferecê-lo de graça. A configuração do site depois das mudanças desta seção:

```schooling-example
{"language": "conf", "file": "/etc/nginx/sites-enabled/shop", "parts": [{"code": "server_tokens off;", "note": "Dizer `nginx` no cabeçalho `Server`, sem versão."}, {"code": "server {\n    listen 192.0.2.80:80;\n    server_name www.example.com;\n    return 301 https://$host$request_uri;\n}", "note": "O HTTP em claro só responde com um redirecionamento para HTTPS. A aula 13 explica por que o redirecionamento sozinho não basta."}, {"code": "server {\n    listen 192.0.2.80:443 ssl;\n    server_name www.example.com;\n    ssl_certificate     /etc/ssl/private/www.crt;\n    ssl_certificate_key /etc/ssl/private/www.key;\n    ssl_protocols TLSv1.2 TLSv1.3;", "note": "O TLS termina aqui, e só as duas versões atuais são oferecidas."}, {"code": "    client_max_body_size 16k;", "note": "Um corpo de requisição maior que 16 KiB é recusado com `413`. Os formulários da loja são pequenos; um endpoint de upload teria um limite maior só dele."}, {"code": "    location /admin/ {\n        allow 192.168.10.0/24;\n        deny all;\n        proxy_pass http://192.168.20.10:8080;\n    }", "note": "As páginas de administração existem, e só a LAN da equipe pode alcançá-las através do proxy. Todos os outros recebem `403`."}, {"code": "    location / {\n        limit_except GET POST { deny all; }\n        proxy_pass http://192.168.20.10:8080;\n        proxy_set_header Host $host;\n        proxy_set_header X-Forwarded-For $remote_addr;\n    }\n}", "note": "Todo o resto é repassado à aplicação, mas só como `GET` ou `POST`. `HEAD` é permitido junto com `GET`; qualquer outro método é recusado."}]}
```

Cada recusa, testada de fora e, onde importa, de dentro:

```
ana@remote:~$ curl -sI https://www.example.com/ | grep -iE "^server|^HTTP"
HTTP/1.1 200 OK
Server: nginx
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" https://www.example.com/admin/
403
ana@laptop:~$ curl -s https://www.example.com/admin/
admin console
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" -X DELETE https://www.example.com/orders/17
403
ana@remote:~$ head -c 20000 /dev/zero | curl -s -o /dev/null -w "%{http_code}\n" --data-binary @- https://www.example.com/
413
ana@remote:~$ curl -s -o /dev/null -w "%{http_code}\n" http://www.example.com/
301
```

O cabeçalho `Server` agora diz `nginx` e nada mais. A página de administração dá `403` a partir da
internet e funciona a partir do `laptop`. `DELETE` é recusado antes de chegar a qualquer código que
pudesse tratá-lo sem cuidado. Vinte mil bytes de corpo foram recusados na porta com `413`, e o HTTP
em claro respondeu com um redirecionamento.

**Nada disso precisou saber como é um ataque.** Cada regra descreve o que a aplicação recebe
legitimamente e recusa o resto, que é a mesma postura do `policy drop` do firewall. As duas
próximas seções acrescentam controles que precisam, sim, reconhecer o mau uso, e eles são mais
difíceis de acertar.
