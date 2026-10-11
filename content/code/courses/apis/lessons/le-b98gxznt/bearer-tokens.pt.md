---
title: Tokens bearer
version: 1
---

**Um token troca a senha por algo que vale menos.** O cliente envia a senha uma vez, para o
`/v1/login`, e recebe de volta uma sequência aleatória longa. Daí em diante envia a sequência, em
`Authorization: Bearer`, e a senha fica onde foi digitada.

```
ana@api:~/shelf$ curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{"username": "ana", "password": "river-lamp-42"}' | tee login.json
{"token": "6RE9jDMi2jfinx2GFkaNYn_3dxh7_0SClOQxCPsN0pk", "expires_in": 3600}
ana@api:~/shelf$ curl -s -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/whoami
{"kind": "person", "name": "ana"}
```

O `tee` imprime a resposta e guarda uma cópia em `login.json`, para que os próximos comandos leiam o
token com o `jq` em vez de você colá-lo. Esse arquivo é uma conveniência do laboratório: ele guarda uma
credencial viva, e um cliente de verdade mantém o token na memória ou no repositório de credenciais do
sistema operacional.

**Bearer quer dizer quem o portar.** O servidor não pergunta quem está segurando a sequência, só se a
sequência é uma que ele emitiu. Isso torna um token exatamente tão sensível quanto uma senha enquanto
ele vale, e o resto desta seção é sobre fazê-lo valer menos tempo e valer menos quando vaza.

## O que o servidor guarda

O token tem 43 caracteres de base64 tirados de 32 bytes aleatórios pelo `secrets.token_urlsafe`. O
servidor não o guarda. Guarda o SHA-256 dele:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM tokens'
d2e53762560e0308cc7fd0f5958bb6eaaf4723fe24fcb3a481058986b0ac26ff|1|1791609966
ana@api:~/shelf$ jq -j .token login.json | sha256sum
d2e53762560e0308cc7fd0f5958bb6eaaf4723fe24fcb3a481058986b0ac26ff  -
```

A primeira coluna da linha é o hash do token que está em `login.json`, caractere por caractere. Uma
cópia vazada do `shelf.db` dá ao atacante esse hash, e o hash não serve como token: o `keys.py` calcula
o hash do que receber, então enviar o hash o faz procurar o hash do hash, que não está em linha
nenhuma.

Por que SHA-256 aqui, se a senha precisou de scrypt? **Uma senha está a um palpite de ser descoberta;
um token aleatório não.** As pessoas escolhem senhas num conjunto pequeno de palavras prováveis, e um
hash lento é o que torna caro testá-las. Um token são 256 bits aleatórios que ninguém escolheu, e não
existe lista de tokens prováveis para testar, então um hash rápido não perde nada. A aula 10 faz a
mesma distinção do lado da senha.

## Validade e revogação

A segunda coluna é a quem o token pertence e a terceira é quando ele deixa de funcionar, em segundos
desde 1970. Lida como data:

```
ana@api:~/shelf$ sqlite3 shelf.db "SELECT datetime(expires, 'unixepoch', 'localtime') FROM tokens"
2026-10-10 02:26:06
```

Uma hora depois do login, porque `TOKEN_SECONDS` é 3600. **A validade limita o estrago de um token que
ninguém sabia que tinha vazado**: ele para de funcionar sozinho. A revogação é a outra metade, para o
token de que alguém sabe, e ela é apagar uma linha. O `/v1/logout` apaga a linha do token que recebe:

```
ana@api:~/shelf$ curl -si -X POST -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/logout
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:06 GMT
Content-Length: 0

ana@api:~/shelf$ curl -si -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/whoami
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:26:06 GMT
Content-Type: application/json
Content-Length: 38
WWW-Authenticate: Basic realm="shelf"
WWW-Authenticate: Bearer realm="shelf", error="invalid_token"

{"error": "invalid or expired token"}
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT count(*) FROM tokens'
0
```

O mesmo token, um segundo depois, é recusado, e a tabela está vazia. Repare no segundo
`WWW-Authenticate`: `error="invalid_token"` diz ao cliente que veio um token e ele não foi aceito, o que
é diferente de não vir token nenhum. Ele não diz se o token venceu, foi revogado ou nunca existiu, e o
cliente não precisa saber: ele entra de novo.

Em vez de esperar uma hora para ver um token vencer, entre de novo e mova a validade dele para o
passado:

```
ana@api:~/shelf$ curl -s localhost:8000/v1/login -H 'Content-Type: application/json' -d '{"username": "ana", "password": "river-lamp-42"}' -o login.json
ana@api:~/shelf$ sqlite3 shelf.db "UPDATE tokens SET expires = strftime('%s', 'now') - 1"
ana@api:~/shelf$ curl -s -w '%{http_code}\n' -H "Authorization: Bearer $(jq -r .token login.json)" localhost:8000/v1/whoami
{"error": "invalid or expired token"}
401
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT count(*) FROM tokens'
0
```

O `keys.py` tratou o token vencido como um que nunca existiu, e apagou a linha dele no caminho. Revogar
todas as sessões de um usuário é o mesmo movimento com um `WHERE` mais largo: `DELETE FROM tokens WHERE
user_id = 1` desconecta a ana de todo lugar, que é o que um servidor faz quando ela muda a senha.

## Opaco e autocontido

Este token é **opaco**: não significa nada sozinho, e o servidor precisa procurá-lo a cada requisição
para saber de quem é. Essa busca é o que torna a revogação instantânea, e é também uma leitura no banco
por requisição. A outra família de tokens é a **autocontida**: o token leva dentro dele o usuário e a
validade, assinados pelo servidor, então conferi-lo não exige busca, e revogá-lo antes de vencer exige
algo a mais. JWT é o formato comum, e a aula 8 pesa os dois lado a lado.
