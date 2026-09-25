---
title: HTTP à mão
version: 1
---

O HTTP/1.1 é texto, e uma pessoa consegue falar HTTP. O `nc` abre uma conexão TCP com a porta 80 e
manda o que receber; o `printf` dá a ele um pedido, cada linha terminada com `\r\n` e o pedido
inteiro terminado com uma linha vazia:

```
ana@laptop:~$ printf 'GET / HTTP/1.1\r\nHost: www.example.com\r\nConnection: close\r\n\r\n' | nc -w 3 192.0.2.80 80
HTTP/1.1 301 Moved Permanently
Server: nginx/1.24.0 (Ubuntu)
Date: Fri, 25 Sep 2026 16:57:45 GMT
Content-Type: text/html
Content-Length: 178
Connection: close
Location: https://www.example.com/

<html>
<head><title>301 Moved Permanently</title></head>
<body>
<center><h1>301 Moved Permanently</h1></center>
<hr><center>nginx/1.24.0 (Ubuntu)</center>
</body>
</html>
```

Um pedido é uma **linha de pedido**, `GET / HTTP/1.1`, e depois **cabeçalhos**, um por linha. O
`Host:` é o que mais importa: um servidor web, num endereço, pode servir muitos sites, e o `Host:` diz
qual. É assim que `example.com`, `www.example.com` e `shop.example.com` moram todos em `192.0.2.80`.

A resposta tem a mesma forma: uma **linha de status**, `HTTP/1.1 301 Moved Permanently`, cabeçalhos,
uma linha vazia e um corpo. O status diz que isto não é a página; o **`Location:`** diz onde ela está,
e o corpo é uma pagininha para quem ler mesmo assim. Este servidor manda todo pedido HTTP puro para o
mesmo endereço por HTTPS, e faz isso para todo caminho, como o `curl -v` mostra, com `>` para o que
foi enviado e `<` para o que voltou:

```
ana@laptop:~$ curl -sv -o /dev/null http://www.example.com/prices.txt 2>&1 | grep "^[<>]"
> GET /prices.txt HTTP/1.1
> Host: www.example.com
> User-Agent: curl/8.5.0
> Accept: */*
> 
< HTTP/1.1 301 Moved Permanently
< Server: nginx/1.24.0 (Ubuntu)
< Date: Fri, 25 Sep 2026 16:57:45 GMT
< Content-Type: text/html
< Content-Length: 178
< Connection: keep-alive
< Location: https://www.example.com/prices.txt
< 
```

`/prices.txt` por HTTP recebe um redirecionamento para `/prices.txt` por HTTPS. Nenhuma página é
servida em texto puro. A próxima aula trata do que torna a resposta por HTTPS confiável; esta trata de
como ela aparece no fio.
