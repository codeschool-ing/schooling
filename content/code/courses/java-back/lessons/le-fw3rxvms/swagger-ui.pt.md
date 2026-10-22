---
title: O Swagger UI, e o que a produção não deve servir
version: 1
---

Um documento de quatrocentas linhas é o que um programa quer. Uma pessoa quer ver as operações,
abrir uma e enviá-la. O **Swagger UI** é uma página web que faz isso com qualquer documento OpenAPI,
e o starter `-ui` pôs uma cópia dela dentro do jar da livraria.

```
ana@vm:~/bookshop$ curl -si localhost:8080/swagger-ui.html | head -3
HTTP/1.1 302 
X-Request-Id: 9c9de462
Location: /swagger-ui/index.html
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/swagger-ui/index.html
200
```

`/swagger-ui.html` é um endereço curto que redireciona, com um 302, para a página em si. A página é
estática: HTML e JavaScript que pedem ao servidor uma pequena configuração e, por ela, o documento
que você vem lendo.

```
ana@vm:~/bookshop$ curl -s -w '\n' localhost:8080/v3/api-docs/swagger-config
{"configUrl":"/v3/api-docs/swagger-config","oauth2RedirectUrl":"http://localhost:8080/swagger-ui/oauth2-redirect.html","url":"/v3/api-docs","validatorUrl":""}
```

`"url":"/v3/api-docs"` é o documento que o Swagger UI desenha. Ele não desenha nada a partir dos
controllers; só sabe o que o documento diz, e é por isso que as duas seções anteriores importavam.

## Lendo a página

Abra `http://localhost:8080/swagger-ui.html` num navegador na máquina em que a livraria roda. No
alto ficam o título, a versão e a descrição do `OpenApiConfig`, e um botão chamado **Authorize**.
Abaixo, as operações vêm agrupadas por tag: **Catalogue** com suas cinco operações, nas palavras que
você escreveu em `@Tag` e `@Operation`, e `order-controller` e `token-controller`, que o springdoc
batizou com o nome das classes. Cada operação se abre mostrando seus parâmetros, o corpo da
requisição com um exemplo montado a partir do schema, e as respostas que declarou. `POST /books`
traz um cadeado, por causa da entrada `security`; os pedidos não trazem nenhum, embora precisem de
token tanto quanto, porque nada contou isso ao springdoc. No fim ficam os schemas, `ProblemDetail`
entre eles.

## Enviando uma requisição por ela

Toda operação tem um botão **Try it out**, que transforma os campos num formulário, e **Execute**,
que envia a requisição do seu navegador para a livraria e mostra o que voltou, com um comando `curl`
que envia a mesma requisição. As operações de leitura funcionam como estão.

Acrescentar um livro pede um token com `catalogue:write`, que o clerk tem. Pegue um no terminal,
como a aula 15 fez:

```
ana@vm:~/bookshop$ curl -s -u clerk:clerk-adds-books -X POST localhost:8080/auth/token | python3 -c 'import json,sys; print(json.load(sys.stdin)["accessToken"])' > clerk.token
```

Aperte **Authorize**, cole o conteúdo de `clerk.token` no campo de `bearer` e feche o diálogo. Agora
o Swagger UI envia `Authorization: Bearer` e o token em toda operação que declara o esquema. Abra
`POST /books`, aperte **Try it out**, transforme o exemplo num livro de verdade e aperte **Execute**.
Ele envia a mesma requisição que o primeiro comando abaixo, e recebe a mesma resposta. O segundo
comando é a mesma requisição sem token:

```
ana@vm:~/bookshop$ curl -s -w '\n%{http_code}\n' -H "Authorization: Bearer $(cat clerk.token)" -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
{"id":7,"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}
201
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' -H 'Content-Type: application/json' -d '{"isbn":"9786500000078","title":"Emma","author":"Jane Austen","priceCents":3300,"stock":2}' localhost:8080/books
401
```

Isto não é uma segunda porta para a livraria. O Swagger UI é um cliente como o `curl`, rodando no
seu navegador, e a livraria confere as requisições dele exatamente como confere as do `curl`: sem
token, `POST /books` recebe um 401, seja qual for o cliente que a envia.

## Em produção

O segundo terminal vem imprimindo dois avisos a cada subida desde que o springdoc chegou:

```
2026-10-22T20:08:06.908-03:00  WARN 14916 --- [bookshop] [           main] [] o.s.core.events.SpringDocAppInitializer  : SpringDoc /v3/api-docs endpoint is enabled by default. To disable it in production, set the property 'springdoc.api-docs.enabled=false'
2026-10-22T20:08:06.908-03:00  WARN 14916 --- [bookshop] [           main] [] o.s.core.events.SpringDocAppInitializer  : SpringDoc /swagger-ui.html endpoint is enabled by default. To disable it in production, set the property 'springdoc.swagger-ui.enabled=false'
```

O springdoc está dizendo que os padrões dele são para desenvolvimento. Em produção, uma descrição
completa de cada endpoint e um formulário para chamá-los são um presente para quem procura uma
entrada: não abrem fechadura nenhuma, já que toda operação continua conferindo o token, mas poupam
o visitante do trabalho de achar as portas. Algumas APIs são públicas e publicam o documento de
propósito. Uma API como a da livraria, chamada pela própria página web, não tem motivo para isso.

Basta a propriedade do primeiro aviso. Pare a aplicação no segundo terminal e suba-a com a propriedade na
linha de comando:

```sh
java -jar target/bookshop-0.1.0.jar --springdoc.api-docs.enabled=false
```

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs
404
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/swagger-ui.html
404
(SpringDocAppInitializer lines in the log: 0)
```

Os dois caminhos dão 404, a página e também o documento, porque o Swagger UI não tem o que desenhar
sem ele. Os avisos também sumiram do segundo terminal. A propriedade é configuração comum do Spring,
então vai para onde vai o resto da configuração de uma implantação: uma linha no arquivo de
propriedades de um perfil de produção, como a aula 4 montou o `dev`, ou uma variável de ambiente,
cujo nome é a propriedade em maiúsculas, com os pontos trocados por sublinhados e o hífen removido:

```sh
SPRINGDOC_APIDOCS_ENABLED=false java -jar target/bookshop-0.1.0.jar
```

```
ana@vm:~/bookshop$ curl -s -o /dev/null -w '%{http_code}\n' localhost:8080/v3/api-docs
404
(SpringDocAppInitializer lines in the log: 0)
```

A livraria mantém o documento ligado por padrão porque você ainda a está desenvolvendo; a aula 23
sobe a aplicação com a configuração no ambiente, que é onde esta variável deve ficar.
