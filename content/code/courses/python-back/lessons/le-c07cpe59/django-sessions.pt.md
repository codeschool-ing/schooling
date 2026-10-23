---
title: Sessões: o padrão do Django
version: 1
---

Uma **sessão** é uma linha no servidor e uma chave aleatória num cookie. A aula 5 entrou com o curl;
desta vez, olhe o arquivo de cookies entre os passos. Suba o servidor de desenvolvimento e busque o
formulário de login:

```
ana@vm:~/agenda$ curl -s -c jar.txt http://127.0.0.1:8000/admin/login/ -o /dev/null -w "%{http_code}\n"
200
ana@vm:~/agenda$ grep -vE '^(# |$)' jar.txt | cut -f1,6
127.0.0.1	csrftoken
```

Só o `csrftoken` por enquanto: o cookie de CSRF da aula 3. Envie o formulário, como a aula 5 fez:

```
ana@vm:~/agenda$ curl -s -b jar.txt -c jar.txt http://127.0.0.1:8000/admin/login/ -d "csrfmiddlewaretoken=$(grep csrftoken jar.txt | cut -f7)" -d username=bruno -d password=m4-orchard-copper-17 -d next=/admin/ -o /dev/null -w "%{http_code} %{redirect_url}\n"
302 http://127.0.0.1:8000/admin/
ana@vm:~/agenda$ grep -vE '^(# |$)' jar.txt | cut -f1,6
#HttpOnly_127.0.0.1	sessionid
127.0.0.1	csrftoken
```

**O `sessionid` chegou, e o curl o marca como `#HttpOnly_`**: o navegador guarda o cookie mas nunca o
entrega ao JavaScript, então um script injetado numa página não consegue lê-lo. A chave é o
`session_key` de uma linha nova:

```
ana@vm:~/agenda$ psql agenda -c "select session_key, expire_date from django_session order by expire_date"
           session_key            |          expire_date          
----------------------------------+-------------------------------
 5v7savbx916xvx3uasda8levshotmjw2 | 2026-10-30 20:25:05.226206-03
 0smz9pjrmznxj5jzt7e7dw02jgns0g48 | 2026-10-30 20:25:17.61332-03
 auryossackfeqd6yi973yefmoqo32ahz | 2026-11-05 20:35:16.152252-03
(3 rows)
```

As duas linhas mais antigas são os logins da aula 5, ainda válidos por duas semanas a partir daquele
dia, que é a duração padrão do Django. A cada requisição, o `AuthenticationMiddleware` do Django lê o
cookie, procura a linha e põe o usuário em `request.user`, como a tabela da aula 2 prometeu.

## Uma sessão e a API

O DRF aceita a mesma sessão. A aula 6 disse quanto isso custa: **uma requisição autenticada por um
cookie precisa levar o token de CSRF**, porque um navegador anexa cookies a requisições que outros
sites o fazem mandar:

```
ana@vm:~/agenda$ curl -s -b jar.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -d '{"capacity": 22}'; echo
{"detail":"CSRF Failed: CSRF token missing."}
ana@vm:~/agenda$ curl -s -b jar.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -H "X-CSRFToken: $(grep csrftoken jar.txt | cut -f7)" -d '{"capacity": 22}'; echo
{"slug":"testing-dojo","title":"Testing dojo","starts_at":"2026-11-26T19:00:00-03:00","venue":"Community Centre, room 3","capacity":22,"description":"","taken":3}
```

## Tomando de volta

Sair apaga a linha. Guarde uma cópia do arquivo de cookies, saia, e tente a cópia antiga:

```
ana@vm:~/agenda$ cp jar.txt before-logout.txt
ana@vm:~/agenda$ curl -s -b jar.txt -c jar.txt -X POST http://127.0.0.1:8000/admin/logout/ -H "X-CSRFToken: $(grep csrftoken jar.txt | cut -f7)" -o /dev/null -w "%{http_code}\n"
200
ana@vm:~/agenda$ curl -s -b before-logout.txt -X PATCH http://127.0.0.1:8000/api/events/testing-dojo/ -H 'Content-Type: application/json' -H "X-CSRFToken: $(grep csrftoken before-logout.txt | cut -f7)" -d '{"capacity": 24}'; echo
{"detail":"Authentication credentials were not provided."}
```

**O cookie ainda guarda a chave antiga, e a chave agora não leva a lugar nenhum.** Essa é a força de
uma sessão: o servidor pode encerrar uma a qualquer momento, para uma pessoa ou para todo mundo,
apagando linhas.
