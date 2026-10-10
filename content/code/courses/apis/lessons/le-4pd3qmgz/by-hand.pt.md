---
title: O fluxo, uma requisição de cada vez
version: 1
---

Você vai fazer dois papéis ao mesmo tempo. **Você é o navegador, lendo cada redirecionamento em vez
de segui-lo, e é o cliente, guardando entre uma requisição e outra os valores de que o fluxo
precisa.** O servidor no segundo terminal é o servidor de autorização e a API. Todo comando roda em
`~/shelf`, no terminal onde `VERIFIER` e `CHALLENGE` foram definidos na seção do PKCE; se você
abriu um novo desde então, rode de novo a linha do `read` daquela seção.

## O redirecionamento para /authorize

Um cliente de verdade gera um `state` novo, e um `nonce` novo para o OpenID Connect, a cada
entrada. Depois, as partes do endereço que nunca mudam vão para uma variável, para os comandos
ficarem legíveis:

```
ana@api:~/shelf$ STATE=$(openssl rand -hex 8); NONCE=$(openssl rand -hex 8)
ana@api:~/shelf$ AUTH='localhost:8000/authorize?response_type=code&client_id=shelf-web&redirect_uri=http://127.0.0.1:9000/callback&code_challenge_method=S256'
```

Agora a requisição que um navegador faria. O `-i` mostra os cabeçalhos, e o curl não segue um
redirecionamento a menos que você peça, então a resposta para no `Location`:

```
ana@api:~/shelf$ curl -si "$AUTH&scope=openid+profile+books:read&state=$STATE&nonce=$NONCE&code_challenge=$CHALLENGE"
HTTP/1.1 302 Found
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:01 GMT
Content-Length: 0
Location: http://127.0.0.1:9000/callback?code=27pQ9sZu0wzrzQYmThN7DbGjWZMjV52T&state=512a38221f3037e5
```

Isso são os passos 2, 3 e 4 do desenho do fluxo de uma vez, porque a usuária do `idp.py` está
sempre conectada e sempre concordou. **O `Location` é o callback do cliente, levando o código e o
mesmo `state` que a requisição enviou**; `echo $STATE` imprime o que você gerou. Nada escuta na
porta 9000. Num navegador, o endereço carregaria a página do cliente, que leria o código dele.

Você precisa do código numa variável. O jeito mais simples é pedir de novo e guardar só o código,
que o `-w '%{redirect_url}'` imprime e o `sed` recorta. O primeiro código nunca é usado e expira
sozinho um minuto depois:

```
ana@api:~/shelf$ CODE=$(curl -s -o /dev/null -w '%{redirect_url}' "$AUTH&scope=openid+profile+books:read&state=$STATE&nonce=$NONCE&code_challenge=$CHALLENGE" | sed -E 's/.*code=([^&]+).*/\1/'); echo $CODE
oIbY0jbm8Xka3l5qbtbpE3tDwg1ZZu3L
```

## A troca em /token

O código vai para `/token` com o verifier, o mesmo `redirect_uri` e as credenciais do próprio
cliente, que o `-u` envia como HTTP Basic. O `tee` guarda a resposta em `tokens.json`, e o `jq` a
imprime:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=authorization_code -d code=$CODE -d redirect_uri=http://127.0.0.1:9000/callback -d code_verifier=$VERIFIER | tee tokens.json | jq .
{
  "token_type": "Bearer",
  "expires_in": 300,
  "scope": "books:read openid profile",
  "access_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQyMGRhYmNkIiwidHlwIjoiSldUIn0.eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwMDAiLCJpYXQiOjE3OTE2MDY2NjEsImV4cCI6MTc5MTYwNjk2MSwiYXVkIjoic2hlbGYtYXBpIiwic3ViIjoidS04MWYzYTIiLCJjbGllbnRfaWQiOiJzaGVsZi13ZWIiLCJzY29wZSI6ImJvb2tzOnJlYWQgb3BlbmlkIHByb2ZpbGUiLCJqdGkiOiJkZmRlYTNkMmFhYzRmZTdhIn0.G_4CM3DIarza-tMoJk5gqNsFNZUGeVtGLFQxa7JAgEmICG8TLQNbO3j_Vmkx4Gs5AK5WY6jIh8ruY19-aiHSELvEePyfPl1EEXf8488u_13L7rxAV5aPqmAYsPKNqkGhdH0Nxsgprze0zaI_hkInAnLarvtCJ8cg4GVmeysI4dzsRNEzcjHQ2PsQBASunG3UT_Y5PSuqGnHlzH5I1ncJATXsqp-s92htcLX7ynGHekr5IUUCs-j8MWmiH-9pXL1n_blRo1sANSw15Sueb1g06iDBHGZJx9gIn8HH_o40KlaUjV6SBxLhmzhQe35x9VaCKZJleGnQyvOxRmVJM2tbYQ",
  "refresh_token": "IMn9szUzfVNK0MgY32rQLBFvNzf179TwXPC2i73FdAQ",
  "id_token": "eyJhbGciOiJSUzI1NiIsImtpZCI6IjQyMGRhYmNkIiwidHlwIjoiSldUIn0.eyJpc3MiOiJodHRwOi8vbG9jYWxob3N0OjgwMDAiLCJpYXQiOjE3OTE2MDY2NjEsImV4cCI6MTc5MTYwNjk2MSwiYXVkIjoic2hlbGYtd2ViIiwic3ViIjoidS04MWYzYTIiLCJub25jZSI6ImE4YmY3ZWJkNDEzNmUzYmMifQ.Q_xikm4l6zjbx6TsXwVdW3rbSmb8cUHeQYVWiH-pLKM5f52vLvWjsHL9CZTxDTuAISGruSm8BrO7TsE2fUEBNrm2OR6vd9qZUBT2qJGrpp5Vt6fJFwIDxj2oK_EkbwN5VBGTxpE2ydfrkKc5pbjsa3ds0Wn7MlFgvqayqnYyK42cNxt7kVic2ohtcTRf-jHKL7NW6Yoh2i1qvQr12ip74NXrQNjJLo348vtGRiZxyz5c-DGAvrPG7TiDN05TKEFxlsSpKcG8DDTJ8sBHyQTB7N95oDCRMgAsAAXyjvS3NhuxqJvZrOp6YUXDi4vPlJcvT2A3ZievhKMYqHwD5QpXnA"
}
```

Três tokens, e cada um tem um leitor diferente. O **access token** é para a API. O **refresh
token** é só para o servidor de autorização, e a seção sobre refresh tokens o usa. O **ID token** é
para o cliente e diz quem entrou; a seção de OpenID Connect o lê. `scope` diz o que foi concedido,
e `expires_in` diz que o access token dura 300 segundos. Os dois compridos são JWTs, três partes em
base64url unidas por pontos, que a lição 8 desmontou.

Guarde os três em variáveis:

```
ana@api:~/shelf$ AT=$(jq -r .access_token tokens.json); RT=$(jq -r .refresh_token tokens.json); IDT=$(jq -r .id_token tokens.json)
```

## Chamando a API

O access token vai no cabeçalho `Authorization`, e a API responde:

```
ana@api:~/shelf$ curl -s localhost:8000/books/stock -H "Authorization: Bearer $AT" | jq -c '.[]'
{"id":1,"title":"Dom Casmurro","stock":12}
{"id":2,"title":"Memórias Póstumas de Brás Cubas","stock":7}
{"id":3,"title":"A Hora da Estrela","stock":0}
{"id":4,"title":"Perto do Coração Selvagem","stock":3}
{"id":5,"title":"Ensaio sobre a Cegueira","stock":9}
{"id":6,"title":"Americanah","stock":4}
```

Sem ele, a mesma requisição é recusada com **401**, e o `WWW-Authenticate` diz que tipo de
credencial a API quer:

```
ana@api:~/shelf$ curl -si localhost:8000/books/stock
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:01 GMT
Content-Type: application/json
Cache-Control: no-store
Content-Length: 72
WWW-Authenticate: Bearer realm="shelf"

{"error": "invalid_token", "error_description": "send an access token"}
```

## O que o servidor recusa

O fluxo só é tão bom quanto as suas recusas, e quatro delas valem a pena ver. **Um código funciona
uma vez.** A mesma troca pela segunda vez:

```
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=authorization_code -d code=$CODE -d redirect_uri=http://127.0.0.1:9000/callback -d code_verifier=$VERIFIER
{"error": "invalid_grant", "error_description": "unknown, used or expired code"}
```

**Um código não serve sem o seu verifier.** Pegue um código novo e apresente-o com um verifier que
não é o que está por trás do challenge, como teria de fazer quem pegasse o código no caminho:

```
ana@api:~/shelf$ CODE=$(curl -s -o /dev/null -w '%{redirect_url}' "$AUTH&scope=openid+profile+books:read&state=$STATE&nonce=$NONCE&code_challenge=$CHALLENGE" | sed -E 's/.*code=([^&]+).*/\1/')
ana@api:~/shelf$ curl -s localhost:8000/token -u shelf-web:lab-only-secret -d grant_type=authorization_code -d code=$CODE -d redirect_uri=http://127.0.0.1:9000/callback -d code_verifier=not-the-verifier
{"error": "invalid_grant", "error_description": "code_verifier does not match"}
```

O código saiu da tabela antes da conferência, então esse também foi gasto. Uma segunda tentativa
precisaria de um terceiro código.

**Um endereço que ninguém cadastrou não recebe código nenhum.** `${AUTH/9000/9999}` é o shell
escrevendo `$AUTH` com a porta trocada, e assim a requisição cita um `redirect_uri` que difere do
cadastrado em um dígito:

```
ana@api:~/shelf$ curl -si "${AUTH/9000/9999}&scope=openid&code_challenge=$CHALLENGE"
HTTP/1.1 400 Bad Request
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:01 GMT
Content-Type: application/json
Cache-Control: no-store
Content-Length: 84

{"error": "invalid_request", "error_description": "unknown client or redirect_uri"}
```

**Um 400 e nenhum `Location`.** Todo outro erro desta lição volta ao callback do cliente com um
parâmetro `error`, porque o servidor sabe que aquele endereço pertence ao cliente. Este não pode:
o endereço é justamente o que está em dúvida, e redirecionar para ele entregaria a quem estiver lá
uma mensagem do servidor de autorização.
