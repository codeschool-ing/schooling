---
title: Escopos e autoridades, e a diferença entre 401 e 403
version: 1
---

Uma **autoridade** (*authority*) é a palavra do Spring Security para uma coisa que um usuário
autenticado pode fazer, e ela é só um texto. O `SecurityConfig` dá à ana `orders` e ao clerk `orders` e
`catalogue:write`; o `TokenController` copia isso para o claim `scope` do token. Em toda requisição
seguinte, o filtro bearer confere a assinatura e a validade do token e então transforma cada palavra do
`scope` numa autoridade com o prefixo `SCOPE_`. O token da ana vira `SCOPE_orders`, e as regras do
`apiChain` são escritas com esses nomes:

| requisição | regra | quem passa |
|---|---|---|
| `GET /books`, `GET /books/**` | `permitAll()` | todo mundo, sem token nenhum |
| `POST /books` | `hasAuthority("SCOPE_catalogue:write")` | o clerk |
| `/orders`, `/orders/**` | `hasAuthority("SCOPE_orders")` | a ana e o clerk |
| todo o resto | `authenticated()` | qualquer um com um token válido |

**As regras são lidas de cima para baixo, e a primeira que casa decide.** Uma regra geral acima de uma
estreita a esconderia, e por isso o `anyRequest()` vem por último; o Spring se recusa a subir se houver
algo escrito depois dele.

## Quatro respostas

Eis a tabela funcionando. O token do clerk é pego do mesmo jeito que o da ana, e o payload dele leva os
dois escopos:

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/books/1
200
ana@vm:~/bookshop$ curl -si localhost:8080/orders/1
HTTP/1.1 401 
WWW-Authenticate: Bearer resource_metadata="http://localhost:8080/.well-known/oauth-protected-resource"
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Length: 0
Date: Thu, 22 Oct 2026 22:48:30 GMT

ana@vm:~/bookshop$ curl -s -u clerk:clerk-adds-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > clerk.token
ana@vm:~/bookshop$ cut -d. -f2 clerk.token | basenc -d --base64url; echo
{"iss":"bookshop","sub":"clerk","exp":1792710210,"iat":1792709310,"scope":"catalogue:write orders"}
ana@vm:~/bookshop$ curl -si -H "Authorization: Bearer $(cat ana.token)" -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
HTTP/1.1 403 
WWW-Authenticate: Bearer error="insufficient_scope", error_description="The request requires higher privileges than provided by the access token.", error_uri="https://tools.ietf.org/html/rfc6750#section-3.1"
X-Content-Type-Options: nosniff
X-XSS-Protection: 0
Cache-Control: no-cache, no-store, max-age=0, must-revalidate
Pragma: no-cache
Expires: 0
X-Frame-Options: DENY
Content-Length: 0
Date: Thu, 22 Oct 2026 22:48:30 GMT

ana@vm:~/bookshop$ curl -s -w '\n' -H "Authorization: Bearer $(cat clerk.token)" -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
{"id":7,"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}
```

Um livro público não precisa de token: 200. Um pedido consultado sem token recebe **401**, e o
`WWW-Authenticate: Bearer` diz que tipo de credencial serviria; o `resource_metadata` é o endereço do
documento que o filtro de metadados serve, que este curso não usa. O token da ana é válido, então o
servidor sabe quem pede, e a regra de `POST /books` pede uma autoridade que ela não tem: **403**, com
`insufficient_scope` no cabeçalho. A mesma requisição do clerk é aceita, e o livro volta com o seu id
novo, 7.

**As duas recusas vêm com corpo vazio**, e não com o problem detail da aula 7. Quem as escreve é o
`ExceptionTranslationFilter`, dentro da cadeia, e o `ApiErrorHandler` pertence ao Spring MVC, aonde
essas requisições nunca chegaram. Uma API que quer `application/problem+json` aqui dá à cadeia o seu
próprio `AuthenticationEntryPoint` e o seu `AccessDeniedHandler`; a livraria fica com os padrões do
Spring.

## A autoridade que fica de fora

O Spring Security 7 acrescenta a toda autenticação algo que a lista de usuários nunca menciona. O
controller do token filtra isso. Como desvio, apague a linha com `FACTOR_` no `TokenController`,
compile e suba de novo, e peça um token; depois ponha a linha de volta:

```
ana@vm:~/bookshop$ curl -s -u ana:ana-reads-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' | cut -d. -f2 | basenc -d --base64url; echo
{"iss":"bookshop","sub":"ana","exp":1792710291,"iat":1792709391,"scope":"FACTOR_PASSWORD orders"}basenc: invalid input
```

**`FACTOR_PASSWORD`.** O Spring Security 7 registra, ao lado das autoridades de um usuário, como ele
provou quem é: uma autoridade `FACTOR_` por fator, para que uma regra possa pedir dois deles, como uma
senha e um código de uso único. Na requisição a `/auth/token` isso é verdade e útil. No token seria
errado. O claim `scope` diz o que o portador pode fazer, e como a ana entrou é um fato sobre uma
requisição anterior. Copiado para o token, ele viraria a autoridade `SCOPE_FACTOR_PASSWORD` em toda
requisição por quinze minutos: uma palavra que parece permissão, que nenhuma regra confere, e que uma
regra escrita como `hasAuthority("FACTOR_PASSWORD")` nunca casaria, por causa do prefixo. Por isso o
`TokenController` descarta o que começa com `FACTOR_`.
