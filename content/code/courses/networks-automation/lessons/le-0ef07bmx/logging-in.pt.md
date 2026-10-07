---
title: Fazendo login, e o que volta
version: 2
---

A maioria das APIs de equipamentos autentica de um de dois jeitos. **HTTP Basic** envia o
usuário e a senha em toda requisição; é o que o RESTCONF usa na aula 3. **Um token** é obtido
uma vez, com a senha, e enviado no lugar dela depois disso. Os roteadores do lab usam tokens:

```
ana@ctl:~$ jq -n --arg p "$(cat .netops-password)" '{username: "netops", password: $p}' > login.json
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @login.json https://edge1.example.net/api/v1/auth/login
{
  "token": "81cd674ef3160c308dfbaf02c16cb9ee",
  "token_type": "Bearer",
  "expires_in": 900
}
```

A senha nunca aparece no comando. Ela é lida de `~/.netops-password`, um arquivo que só a `ana`
consegue ler e que o `netlab.sh` grava na home dela a cada construção, e o `jq` monta o corpo JSON a partir dela em `login.json`. **Uma senha digitada
numa linha de comando acaba no histórico do shell e na lista de processos**, onde qualquer um na
máquina pode vê-la enquanto o comando roda.

A resposta é um **bearer token**: quem o tiver é tratado como `netops`, por `expires_in`
segundos, quinze minutos aqui. Ele vai no cabeçalho `Authorization` de toda requisição depois
disso:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @login.json https://edge1.example.net/api/v1/auth/login | jq -r .token > .token
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .token)" https://edge1.example.net/api/v1/system
{
  "hostname": "edge1",
  "software": "FRRouting 8.4.4",
  "uptime_seconds": 17,
  "management_address": "192.0.2.12"
}
```

Uma senha errada é recusada com o mesmo `401` de um token ausente, e com um corpo que não diz
qual metade estava errada. Isso é de propósito, e é assim que qualquer login deve responder:
dizer a um estranho que o usuário existe é dizer a ele metade do que ele precisa.

```
ana@ctl:~$ curl -si --cacert lab-ca.pem -H "Content-Type: application/json" -d '{"username": "netops", "password": "guess"}' https://edge1.example.net/api/v1/auth/login
HTTP/1.1 401 Unauthorized
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:43 GMT
Content-Type: application/json
Content-Length: 44
WWW-Authenticate: Bearer realm="devapi"

{
  "error": "wrong username or password"
}
```

**Autenticação diz quem você é; autorização diz o que você pode fazer.** O roteador tem uma
segunda conta, `audit`, que pode ler tudo e não pode mudar nada. O token dela lê uma interface,
e depois tenta alterá-la:

```
ana@ctl:~$ jq -n --arg p "$(cat .audit-password)" '{username: "audit", password: $p}' > audit.json
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Content-Type: application/json" -d @audit.json https://edge1.example.net/api/v1/auth/login | jq -r .token > .audit-token
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat .audit-token)" https://edge1.example.net/api/v1/interfaces/eth2
{
  "name": "eth2",
  "description": "branch LAN",
  "enabled": true,
  "oper_status": "up",
  "mtu": 1500,
  "mac_address": "52:54:00:00:71:01",
  "addresses": [
    "203.0.113.1/26"
  ]
}
ana@ctl:~$ curl -si --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat .audit-token)" -H "Content-Type: application/json" -d '{"description": "branch 1 LAN"}' https://edge1.example.net/api/v1/interfaces/eth2
HTTP/1.1 403 Forbidden
Server: devapi/1.0
Date: Tue, 29 Sep 2026 11:00:43 GMT
Content-Type: application/json
Content-Length: 60

{
  "error": "audit may read and may not change anything"
}
```

`403 Forbidden` não é `401`. O servidor sabe exatamente quem está perguntando e recusa mesmo
assim, então fazer login de novo não vai ajudar. **Um script que monitora deve rodar com uma
conta como `audit`**, porque o pior que um token só de leitura vazado pode fazer é ler.
