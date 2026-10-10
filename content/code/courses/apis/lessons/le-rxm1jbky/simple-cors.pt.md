---
title: CORS numa requisição simples
version: 1
---

**O CORS, Cross-Origin Resource Sharing, é uma conversa em dois cabeçalhos.** O navegador põe a origem
da página num cabeçalho `Origin` na requisição. O servidor responde com
`Access-Control-Allow-Origin`, nomeando a origem por quem aceita ser lido. Se os dois batem, o script
recebe a resposta; se o cabeçalho falta ou nomeia outra coisa, não recebe.

A imagem tentadora é a de um servidor que recusa uma requisição de uma origem em que não confia. Veja
o que o `secure.py` faz de fato. O curl não manda `Origin` por conta própria, então o `-H` faz o papel
do navegador, uma vez como a página em `localhost:8080`, que está na lista, e outra como a mesma
página carregada de `127.0.0.1:8080`, que não está:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/1 -H 'Origin: http://localhost:8080'
HTTP/1.1 200 OK
Server: shelf
Date: Sat, 10 Oct 2026 04:23:14 GMT
Content-Type: application/json
Content-Length: 48
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Access-Control-Allow-Origin: http://localhost:8080
Vary: Origin

{"id": 1, "title": "Dom Casmurro", "stock": 12}
ana@api:~/shelf$ curl -si localhost:8000/v1/books/1 -H 'Origin: http://127.0.0.1:8080'
HTTP/1.1 200 OK
Server: shelf
Date: Sat, 10 Oct 2026 04:23:14 GMT
Content-Type: application/json
Content-Length: 48
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Vary: Origin

{"id": 1, "title": "Dom Casmurro", "stock": 12}
```

**As duas respostas são 200 e as duas trazem o livro.** A única diferença é um cabeçalho: a primeira
tem `Access-Control-Allow-Origin: http://localhost:8080` e a segunda não tem nenhum. O servidor não
recusa nada; ele declara quem pode ler, e quem recusa é o navegador.

## Num navegador

Carregada da origem que está na lista, a página imprimiu isto no console ao apertar "Read it":

```
GET 200 {"id": 1, "title": "Dom Casmurro", "stock": 12}
```

Carregada de `http://127.0.0.1:8080`, o mesmo botão imprimiu três linhas, as duas primeiras em
vermelho. Esta é a redação do próprio Chromium; outros navegadores escrevem de outro jeito e dizem a
mesma coisa:

```
Access to fetch at 'http://127.0.0.1:8000/v1/books/1' from origin 'http://127.0.0.1:8080' has been blocked by CORS policy: No 'Access-Control-Allow-Origin' header is present on the requested resource.
Failed to load resource: net::ERR_FAILED
GET failed: TypeError: Failed to fetch
```

O script ficou sabendo só de `TypeError: Failed to fetch`. É tudo o que ele chega a saber: o navegador
não dá à página nenhum jeito de distinguir uma recusa de CORS de um servidor fora do ar, porque essa
diferença já seria uma informação sobre a outra origem. A explicação vai para o console, para quem
desenvolve, e para nenhum lugar que o script consiga ler.

E o terminal do servidor imprimiu esta linha para esse mesmo clique:

```
127.0.0.1 - - [10/Oct/2026 01:23:16] "GET /v1/books/1 HTTP/1.1" 200 -
```

**A requisição chegou e foi respondida.** O livro foi lido do banco e enviado; o navegador o recebeu
e jogou fora. Esse é o custo de uma requisição simples, e é por isso que a regra da aula 1 importa
aqui: um GET nunca deve mudar nada, porque uma página de qualquer origem consegue fazer um navegador
mandar um para a sua API.

## Quais requisições são simples

O navegador manda uma requisição sem perguntar antes só quando um formulário HTML poderia ter mandado
a mesma coisa, porque os formulários são anteriores ao CORS e os servidores já precisavam lidar com
eles. As três condições valem juntas:

| | uma requisição simples pode usar |
|---|---|
| método | `GET`, `HEAD` ou `POST` |
| cabeçalhos definidos pelo script | só uma lista curta que a especificação chama de segura, como `Accept`, `Accept-Language` e `Content-Type` |
| `Content-Type` | só `text/plain`, `application/x-www-form-urlencoded` ou `multipart/form-data` |

Tudo o que fica de fora recebe um preflight antes, que é a próxima seção. Um corpo JSON fica de fora,
já que `application/json` não está na lista, e um cabeçalho `Authorization` também, o que quer dizer
que quase toda chamada a uma API de verdade feita por uma página passa por preflight.

## `*`, e quando ele está certo

`Access-Control-Allow-Origin` também pode ser `*`: qualquer origem pode ler. Para dados públicos que
não precisam de credenciais, um catálogo, uma grade de horários, cotações de câmbio, essa é a resposta
certa, e uma lista de permissões só acrescentaria uma lista para manter. O `secure.py` nomeia origens
porque o PATCH dele muda alguma coisa e, depois das aulas 7 a 9, as requisições de uma API levam
credenciais, e a seção sobre erros mostra o que o `*` faz nesse caso.
