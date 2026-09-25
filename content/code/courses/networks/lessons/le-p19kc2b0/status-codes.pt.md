---
title: Códigos de status que apontam para algum lugar
version: 1
---

O `curl -L` segue redirecionamentos, e o `-I` pede só os cabeçalhos:

```
ana@laptop:~$ curl -sIL http://example.com/ | grep -iE "^HTTP|^location"
HTTP/1.1 301 Moved Permanently
Location: https://example.com/
HTTP/2 200 
```

Duas respostas para um comando: o `301` do HTTP puro e o `200` do HTTPS, agora por **HTTP/2**. Um
navegador faz a mesma coisa sem mostrar. Depois, quatro caminhos no mesmo site, e o status de cada um:

```
ana@laptop:~$ for p in / /private/ /nothing /app/; do curl -so /dev/null -w "%{http_code} $p\n" https://www.example.com$p; done
200 /
403 /private/
404 /nothing
502 /app/
ana@www:~$ tail -2 /var/log/nginx/error.log
2026/09/25 13:57:45 [error] 76721#76721: *6 directory index of "/var/www/example/private/" is forbidden, client: 203.0.113.2, server: example.com, request: "GET /private/ HTTP/2.0", host: "www.example.com"
2026/09/25 13:57:45 [error] 76721#76721: *8 connect() failed (111: Connection refused) while connecting to upstream, client: 203.0.113.2, server: example.com, request: "GET /app/ HTTP/2.0", upstream: "http://127.0.0.1:9000/app/", host: "www.example.com"
```

**Cada um destes é uma conversa de rede bem-sucedida.** O DNS funcionou, o TCP conectou, o TLS
combinou, o pedido chegou e o servidor respondeu. O código diz o que o servidor decidiu, e cada um
manda a pergunta do suporte para um lugar diferente:

| código | quer dizer | pergunte a |
|---|---|---|
| `2xx` | funcionou | ninguém |
| `3xx` | está em outro lugar, veja o `Location:` | ninguém; siga |
| `403` | o servidor não vai mostrar isto | quem cuida do site: permissões |
| `404` | não há nada nesse caminho | quem fez o link |
| `500` | a aplicação quebrou | os desenvolvedores da aplicação |
| `502`, `504` | o servidor web não alcançou a aplicação por trás dele | quem cuida dessa aplicação |

**O log de erros diz qual.** As duas últimas linhas do log do nginx no `www` dão nome às duas falhas:
o `403` é `directory index … is forbidden`, uma pasta sem página dentro; o **`502` é `connect()
failed (111: Connection refused) while connecting to upstream`, `127.0.0.1:9000`**. O nginx está
saudável e repassou o pedido para a aplicação de reservas, que não estava rodando. É o `Connection
refused` da aula 3, um nível mais para dentro. Reiniciar o nginx não mudaria nada.
