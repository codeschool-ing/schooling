---
title: Pegar um token de volta
version: 1
---

Uma sessão acaba no momento em que a linha dela é apagada. Um token assinado não tem linha. Depois
de emitido, ele é aceito por todo servidor que tenha a chave até o `exp`, aconteça o que acontecer
nesse meio-tempo: o usuário faz logout, troca a senha, é demitido ou avisa que o notebook foi
roubado. **O servidor não consegue chamar um token de volta, porque chamar de volta exige um registro
e o token foi projetado para não precisar de nenhum.**

Então "fazer logout de um JWT" costuma querer dizer que o cliente joga fora a cópia dele, a mesma
arrumação que a seção sobre logout deixou de lado para os cookies. Qualquer outra cópia continua
funcionando. Três ferramentas estreitam a brecha, e cada uma devolve parte da ausência de estado que
era o motivo de escolher um token.

## Uma vida curta

A primeira ferramenta é aritmética. O `tokens.py` dá **cinco minutos** a um token de acesso, então
um roubado serve por no máximo cinco minutos. Cinco minutos é também a frequência com que o cliente
precisa voltar por um novo, e ele não deveria pedir a senha ao usuário a cada vez.

## Um refresh token, usado uma vez

É para isso que serve o segundo token da resposta do login. O **refresh token** vive catorze dias e
faz uma coisa só: em `POST /refresh` ele compra um par novo. É uma string aleatória, como um id de
sessão, e o servidor o guarda numa tabela pelo hash, como uma sessão. Ele vai a um único endpoint, e
é por isso que pode viver mais que o token de acesso, que vai a todo lugar.

O `tokens.py` o **rotaciona**: cada refresh token funciona uma vez e é substituído pelo novo da
resposta. Gaste o do login:

```
ana@api:~/shelf$ jq '{refresh_token}' login.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @- | tee second.json | jq .
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiaXNzIjoic2hlbGYiLCJhdWQiOiJzaGVsZi1hcGkiLCJpYXQiOjE3OTE2MDY2NjksIm5iZiI6MTc5MTYwNjY2OSwiZXhwIjoxNzkxNjA2OTY5LCJqdGkiOiIzNjJkYmI2MjdiM2I5MWU2In0.07uZ_cEskfcWYjwqHJBat_kDH4a6leS2oNqU29MmOf4",
  "token_type": "Bearer",
  "expires_in": 300,
  "refresh_token": "e7P8enUOEKeBJ6Y1fzbT-Ww-KbAc_fr5m4va6VF7Wjw"
}
```

Agora suponha que alguém tivesse copiado esse primeiro refresh token. A rotação faz uma cópia se
denunciar: o dono e quem copiou têm o mesmo token, e quem o apresentar em segundo lugar está
apresentando um token já gasto. O servidor não sabe qual dos dois é o legítimo, então encerra o login
inteiro, todos os tokens que descendem daquele login:

```
ana@api:~/shelf$ jq '{refresh_token}' login.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @-
{"error": "refresh token used twice: this sign-in is revoked"}
```

O refresh token novo, que estava com o cliente honesto, morreu junto:

```
ana@api:~/shelf$ jq '{refresh_token}' second.json | curl -s localhost:8000/refresh -H 'Content-Type: application/json' -d @-
{"error": "unknown or expired refresh token"}
```

**E o token de acesso emitido um instante atrás ainda funciona.** Nada sobre ele foi guardado, então
não havia o que apagar:

```
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token second.json)"
{"name": "ana", "exp": 1791606969, "jti": "362dbb627b3b91e6"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 300\" role=\"img\" aria-label=\"Uma linha do tempo em minutos de 0 a 15. O token de acesso A1 vale de 0 a 5. Aos 5 o cliente usa o refresh token R1 e recebe A2, válido de 5 a 10, e R2. Aos 7 alguém apresenta R1 de novo: o reuso é detectado e a família inteira, R2 inclusive, é apagada, então nenhum token de acesso novo pode ser obtido. A2 ainda é aceito até os 10, porque nada sobre ele está guardado para ser apagado.\"><defs><marker id=\"l08-refresh-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><line x1=\"140\" y1=\"250\" x2=\"680\" y2=\"250\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"140\" y1=\"246\" x2=\"140\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"140\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0 min</text><line x1=\"320\" y1=\"246\" x2=\"320\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"320\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 min</text><line x1=\"500\" y1=\"246\" x2=\"500\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"500\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10 min</text><line x1=\"680\" y1=\"246\" x2=\"680\" y2=\"254\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"680\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">15 min</text><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">tokens de acesso</text><text x=\"20\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">refresh tokens</text><rect x=\"140\" y=\"56\" width=\"180\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A1</text><rect x=\"320\" y=\"56\" width=\"72\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"356.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">A2</text><rect x=\"392\" y=\"56\" width=\"108\" height=\"28\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"446.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">A2 ainda aceito</text><rect x=\"140\" y=\"126\" width=\"180\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"230.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R1</text><rect x=\"320\" y=\"126\" width=\"72\" height=\"28\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"356.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">R2</text><rect x=\"392\" y=\"126\" width=\"288\" height=\"28\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></rect><text x=\"536.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">família apagada: nenhum refresh funciona</text><line x1=\"320\" y1=\"154\" x2=\"320\" y2=\"196\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-refresh-ah)\"></line><text x=\"320\" y=\"208\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">R1 usado: A2 + R2</text><line x1=\"392\" y1=\"228\" x2=\"392\" y2=\"158\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#l08-refresh-ah)\"></line><text x=\"398\" y=\"228\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">R1 apresentado de novo</text><text x=\"506\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">A2 vence: o estrago acaba aqui</text><line x1=\"500\" y1=\"46\" x2=\"500\" y2=\"90\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" stroke-dasharray=\"4 3\"></line></svg>", "caption": "Rotação com detecção de reuso, desenhada ao longo de quinze minutos. Reusar o R1 mata de uma vez todos os refresh tokens daquele login; o token de acesso já emitido continua valendo até o exp.", "same": ["0 min", "10 min", "15 min", "5 min", "refresh tokens"]}
```

## Uma lista de bloqueio, conferida toda vez

Para encerrar um token de acesso antes do `exp`, o servidor precisa lembrar que ele foi encerrado. O
`tokens.py` mantém uma tabela de valores de `jti` revogados, e o `verify` a lê em toda requisição.
Entre de novo e faça logout:

```
ana@api:~/shelf$ curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-horse"}' > login.json
ana@api:~/shelf$ curl -si -X POST localhost:8000/logout -H "Authorization: Bearer $(jq -r .access_token login.json)"
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:09 GMT
Content-Length: 0

ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token login.json)"
{"error": "token revoked"}
```

A tabela tem uma linha por token revogado, e só até o momento em que aquele token venceria de
qualquer jeito. Depois do `exp` a verificação da assinatura o recusa sem ajuda, então o `logout`
apaga as linhas cujo horário já passou:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT jti, exp FROM revoked'
333d78c320d234d6|1791606969
```

**Repare no que isso fez com a ausência de estado.** O `tokens.py` agora mantém uma tabela de
refresh e uma lista de bloqueio, e confere a segunda em toda requisição: uma consulta por requisição
a um armazenamento compartilhado, que é exatamente o custo que o token deveria eliminar. A consulta é
menor, porque só os tokens revogados entram na lista, não todos os vivos, e ela pode ir para um
cache. Continua sendo uma consulta. Um JWT que pode ser revogado na hora é uma sessão que também
carrega as próprias claims.
