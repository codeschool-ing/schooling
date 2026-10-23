---
title: Inscrever-se pela API, e os códigos de status certos
version: 1
---

A inscrição é um POST em `/api/events/<slug>/registrations/`, aberto a qualquer um, tratado pelo
`register_for_event` de `events/api.py`:

```
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"name":"Elisa","email":"elisa@example.org","created_at":"2026-10-22T19:13:36.419630-03:00"}
201
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Elisa\", \"email\": \"elisa@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"detail":"This address is already registered."}
409
```

**201, depois 409.** A segunda requisição estava perfeitamente bem formada; o que a recusou foi o
estado dos dados, uma inscrição que já existe, e **409 Conflict** é exatamente o código para isso. A
mensagem é a do próprio serviço. As outras recusas ganham cada uma o código que as descreve:

```
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\", \"email\": \"not-an-address\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"email":["Enter a valid email address."]}
400
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\", \"email\": \"fabio@example.org\"}" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/async-workshop/registrations/
{"detail":"This event is full."}
409
ana@vm:~/agenda$ curl -s -H "Content-Type: application/json" -d "{\"name\": \"Fábio\"" -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"detail":"JSON parse error - Expecting ',' delimiter: line 1 column 17 (char 16)"}
400
ana@vm:~/agenda$ curl -s -X GET -w "\n%{http_code}\n" http://127.0.0.1:8000/api/events/testing-dojo/registrations/
{"detail":"Method \"GET\" not allowed."}
405
```

| resposta | por quê | quem decidiu |
|---|---|---|
| **400** `email` | os dados não têm o formato certo | o serializer |
| **409** cheio | os dados estão certos; o evento não tem lugares | o `register`, sob a trava |
| **400** `JSON parse error` | o corpo nem é JSON | o parser do DRF, antes da view |
| **405** `GET` | a view só aceita POST | `@api_view(["POST"])` |

## Por que nenhum token CSRF desta vez

A aula 2 prometeu uma resposta aqui. Esses POSTs não levavam cookie nem token, e foram aceitos. **O
DRF só confere CSRF em requisições autenticadas por um cookie de sessão**, porque CSRF é um ataque a
cookies: o navegador os anexa sozinho a uma requisição que outro site o fez mandar. Uma requisição sem
cookie, ou que se autentica com um cabeçalho que o navegador nunca acrescenta por conta própria, não
pode ser forjada desse jeito. Então o endpoint de inscrição, anônimo, não precisa de token; um
navegador logado usando o mesmo endpoint pela sessão precisaria; e a autenticação por token da aula 11
não precisa.
