---
title: Escopos e consentimento
version: 1
---

**É fácil confundir um escopo com um sistema de permissões, e ele é algo mais estreito: a lista do
que um cliente pediu para fazer, com a qual uma pessoa concordou, escrita no token.** É um limite
superior do que o token abre. Não diz o que a pessoa tem permissão de fazer: um token com
`books:read` para alguém que a loja baniu continua não abrindo nada, porque a API também confere as
suas próprias regras. A lição 11 trata dessas regras.

Nomes de escopo são strings que o servidor de autorização inventa. `books:read` é do `idp.py`, e os
dois-pontos são um costume, não uma sintaxe. Só o OpenID Connect define alguns: `openid`,
`profile`, `email`, `address` e `phone`. O cliente pede com `scope` no endereço de `/authorize`,
separados por espaços, que uma URL escreve como `+`.

## O que o consentimento decide

A tela de consentimento é onde o escopo é mostrado a uma pessoa: "O Shelf Reader quer ver o seu
nome e ler as suas compras". As pessoas apertam sim sem ler. Então **um cliente deve pedir o menor
conjunto que funcione e pedir mais quando um recurso precisar**, em vez de tudo na primeira
entrada; uma tela que lista nove coisas ensina as pessoas a aceitar qualquer lista.

A pessoa também pode aceitar menos do que foi pedido, e o servidor de autorização pode conceder
menos do que a pessoa aceitou. Por isso a resposta de token leva `scope`, e **um cliente a lê em vez
de supor que recebeu o que pediu.**

## Dois tokens, dois escopos

O token da seção anterior recebeu `openid profile books:read`. O `/userinfo` dá a ele o nome, por
causa de `profile`, e nenhum e-mail, porque ninguém pediu `email`:

```
ana@api:~/shelf$ curl -s localhost:8000/userinfo -H "Authorization: Bearer $AT"
{"sub": "u-81f3a2", "name": "Ana Souza"}
```

Agora uma segunda entrada pedindo `openid email` e nada mais, com um par de PKCE novo. Para manter
as linhas curtas, estas requisições deixam de fora `state` e `nonce`; um cliente de verdade envia
um par novo em cada uma:

```
ana@api:~/shelf$ read VERIFIER CHALLENGE < <(python3 pkce.py)
ana@api:~/shelf$ CODE=$(curl -s -o /dev/null -w '%{redirect_url}' "$AUTH&scope=openid+email&code_challenge=$CHALLENGE" | sed -E 's/.*code=([^&]+).*/\1/')
ana@api:~/shelf$ AT2=$(curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=authorization_code -d code=$CODE -d redirect_uri=http://127.0.0.1:9000/callback -d code_verifier=$VERIFIER | jq -r .access_token)
```

O `/userinfo` agora tem o e-mail e nenhum nome. A lista de estoque diz não:

```
ana@api:~/shelf$ curl -s localhost:8000/userinfo -H "Authorization: Bearer $AT2"
{"sub": "u-81f3a2", "email": "ana@shelf.example"}
ana@api:~/shelf$ curl -si localhost:8000/books/stock -H "Authorization: Bearer $AT2"
HTTP/1.1 403 Forbidden
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:02 GMT
Content-Type: application/json
Cache-Control: no-store
Content-Length: 88
WWW-Authenticate: Bearer error="insufficient_scope", scope="books:read"

{"error": "insufficient_scope", "error_description": "this needs the scope books:read"}
```

**403, não 401.** O token é válido; ele nunca recebeu `books:read`. A RFC 6750 dá a essa falha um
erro próprio, `insufficient_scope`, e põe o escopo que faltou no `WWW-Authenticate`, para que o
cliente possa mandar a pessoa de volta a `/authorize` para pedi-lo.

Um escopo para o qual o cliente nunca foi cadastrado é recusado logo no início, antes de alguém ser
consultado. O erro volta ao callback do cliente:

```
ana@api:~/shelf$ curl -si "$AUTH&scope=openid+books:write&code_challenge=$CHALLENGE"
HTTP/1.1 302 Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:02 GMT
Content-Length: 0
Location: http://127.0.0.1:9000/callback?error=invalid_scope
```
