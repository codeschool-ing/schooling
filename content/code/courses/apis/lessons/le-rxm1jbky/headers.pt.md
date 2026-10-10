---
title: CSP e os outros cabeçalhos que uma API manda
version: 1
---

**Quatro cabeçalhos vão em toda resposta que o `secure.py` dá, e um quinto em toda resposta sobre
HTTPS.** Nenhum deles muda o que um cliente escrito em código recebe. Cada um diz ao navegador o que
não fazer com a resposta, para o caso de um navegador ser, um dia, quem a lê.

| cabeçalho | o que diz ao navegador | por que uma API o manda |
|---|---|---|
| `Content-Security-Policy: default-src 'none'; frame-ancestors 'none'` | não carregue nada, não execute nada, e não deixe página nenhuma pôr isto num frame | uma resposta que acabe exibida como documento não consegue fazer nada |
| `X-Content-Type-Options: nosniff` | confie no `Content-Type` e nunca adivinhe | JSON nunca é executado como script nem desenhado como página |
| `Cache-Control: no-store` | não guarde cópia, nem em disco nem em cache nenhum no caminho | uma resposta sobre uma pessoa fica fora de caches compartilhados e do disco do navegador |
| `Referrer-Policy: no-referrer` | não mande `Referer` ao sair deste documento | um endereço que carrega um id ou um token não é passado ao próximo site |
| `Strict-Transport-Security` | só HTTPS, por `max-age` segundos | a seção anterior |

## Por que uma API JSON manda um CSP

A objeção comum é que uma Content Security Policy é para HTML: ela limita quais scripts, estilos e
imagens uma página pode carregar, e uma API não manda nada disso. É exatamente por isso que a política
não custa nada. `default-src 'none'` proíbe tudo, e JSON não precisa de nada, então nenhuma resposta
legítima é afetada.

**O que ela protege é uma resposta que acaba tratada como página.** Alguém abre o endereço da API numa
aba. Uma mensagem de erro repete parte da requisição, `no book 99` aqui, e um dia a parte repetida é
um texto que um estranho escolheu e mandou como link. Um bug em outro lugar rotula uma resposta como
`text/html`. Em cada caso o navegador tem nas mãos algo que poderia renderizar, e com esta política o
que ele renderizar não carrega nada nem executa nada. `frame-ancestors 'none'` acrescenta que nenhum
outro site pode pôr a resposta dentro de um frame da própria página, que é como uma página disfarça o
conteúdo de outra para conseguir cliques que não devia.

O `nosniff` cobre a outra direção. Sem ele, alguns navegadores olhavam os bytes e decidiam sozinhos o
que uma resposta era, então uma resposta JSON podia ser aceita como script por uma página que a
carregasse numa tag `<script>`.

## Toda resposta, erros incluídos

Cabeçalhos que só algumas respostas levam protegem só essas respostas, e os erros são os que ninguém
confere. O `secure.py` manda tudo por `reply`, e sobrescreve `send_error`, o método que a biblioteca
usa quando responde por conta própria. Um método que ninguém definiu, que o `rest.py` da lição 1
respondia com uma página HTML e a versão do Python:

```
ana@api:~/shelf$ curl -si -X FOO localhost:8000/v1/books/1
HTTP/1.1 501 Not Implemented
Server: shelf
Date: Sat, 10 Oct 2026 04:23:18 GMT
Content-Type: application/json
Content-Length: 40
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Vary: Origin

{"error": "Unsupported method ('FOO')"}
```

**JSON, os mesmos cabeçalhos, e um `Server` que nomeia o programa sem versão.** A versão não é uma
vulnerabilidade, e tirá-la não conserta nada que esteja quebrado; ela deixa de anunciar quais falhas
conhecidas tentar primeiro. Manter o software atualizado é a correção. Um erro comum leva os mesmos
cabeçalhos:

```
ana@api:~/shelf$ curl -si localhost:8000/v1/books/99
HTTP/1.1 404 Not Found
Server: shelf
Date: Sat, 10 Oct 2026 04:23:18 GMT
Content-Type: application/json
Content-Length: 24
Content-Security-Policy: default-src 'none'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
Referrer-Policy: no-referrer
Cache-Control: no-store
Vary: Origin

{"error": "no book 99"}
```

## Duas escolhas que vale conhecer

`Cache-Control: no-store` em toda resposta é o padrão seguro, não o único certo. Um catálogo que é
igual para todo mundo fica melhor em cache, e os limites da lição 12 ficam mais fáceis de manter
quando a maioria das requisições nem chega à API. Quais respostas podem ir para cache, e onde, é assunto do
curso `servers-cache`. O que cabe aqui é que uma resposta sobre uma pessoa em particular,
um pedido, uma conta, qualquer coisa por trás das lições 7 a 11, é `no-store` a não ser que alguém
tenha decidido outra coisa de propósito.

Você também vai encontrar o `X-Frame-Options: DENY`, o cabeçalho mais antigo que o `frame-ancestors`
substituiu, e o `X-XSS-Protection`, que ligava um filtro que os navegadores já removeram. O primeiro é
inofensivo ao lado de um CSP; o segundo não faz nada num navegador atual, e um scanner que o exige
está desatualizado.
