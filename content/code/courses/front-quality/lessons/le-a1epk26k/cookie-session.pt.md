---
title: Uma sessão num cookie, passo a passo
version: 1
---

**Com o servidor rodando num terminal, o `curl` em outro faz o que o navegador vai fazer, e mostra cada
cabeçalho no caminho.** O `-i` mostra os cabeçalhos da resposta antes do corpo; o `-c` e o `-b` fazem o
`curl` guardar os cookies num arquivo e mandá-los de volta, como um navegador os guarda no perfil.

Primeiro uma senha errada:

```
ana@dev:~/planner$ curl -s -i -X POST -H 'content-type: application/json' -d '{"name":"ana","password":"hunter2"}' http://localhost:5173/api/login
HTTP/1.1 401 Unauthorized
Vary: Origin
content-type: application/json
date: Fri, 23 Oct 2026 23:04:24 GMT
connection: close
Transfer-Encoding: chunked

{"error":"wrong name or password"}
```

**401, e a mesma frase qualquer que fosse a metade errada.** Uma mensagem dizendo "usuário inexistente"
contaria a qualquer um quais nomes têm conta. Depois a certa:

```
ana@dev:~/planner$ curl -s -i -c ~/cookies.txt -X POST -H 'content-type: application/json' -d '{"name":"ana","password":"correct horse battery staple"}' http://localhost:5173/api/login
HTTP/1.1 200 OK
Vary: Origin
content-type: application/json
set-cookie: sid=nWKvTbi-pkO0k2a_hq1FT-m6Nakf3rW1CWGzZF9ovIE; HttpOnly; SameSite=Lax; Path=/
date: Fri, 23 Oct 2026 23:04:24 GMT
connection: close
Transfer-Encoding: chunked

{"name":"ana"}
```

A resposta é `{"name":"ana"}`, e a parte que importa é o cabeçalho: **`Set-Cookie: sid=…`**, um valor de
43 caracteres feito de 32 bytes aleatórios, muito além do que se consegue adivinhar. O `HttpOnly` o
mantém longe dos scripts da própria página, o `SameSite=Lax` impede o navegador de mandá-lo junto com a
maioria das requisições começadas por outro site, e o `Path=/` o manda com todo endereço deste. A aula 6
é sobre cada uma dessas palavras.

Agora o plano, uma vez com o cookie e uma vez sem:

```
ana@dev:~/planner$ curl -s -b ~/cookies.txt http://localhost:5173/api/plan | head -c 150; echo
{"courses":[{"id":"html-css","title":"HTML and CSS"},{"id":"javascript","title":"JavaScript"},{"id":"git","title":"Git"}],"sessions":[{"id":1,"course"
ana@dev:~/planner$ curl -s -i http://localhost:5173/api/plan
HTTP/1.1 401 Unauthorized
Vary: Origin
content-type: application/json
date: Fri, 23 Oct 2026 23:04:24 GMT
connection: close
Transfer-Encoding: chunked

{"error":"sign in first"}
```

**O cookie é toda a prova.** Quem o manda é a ana, até onde o servidor sabe, e é por isso que ele nunca
pode ser legível, adivinhável ou mandado para outro lugar que não aqui. E sem ele não há nada além de um
401.

O servidor guarda este login no mapa `logins`, e é por essa propriedade que se escolhem sessões: o
servidor pode esquecer um login quando decidir, e o cookie para de funcionar no mesmo instante. O
próximo passo deveria mostrar isso, com o logout, e a aula 6 começa descobrindo que ele não mostra.
