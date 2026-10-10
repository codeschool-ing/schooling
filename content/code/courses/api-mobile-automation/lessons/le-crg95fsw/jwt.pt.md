---
title: Dentro de um JWT, e os dois jeitos de um servidor recusar um
version: 1
---

**Um JWT, JSON Web Token, são três pedaços de texto unidos por pontos: um cabeçalho, um payload de
claims e uma assinatura sobre os dois primeiros.** Os tokens do boxoffice são JWTs, e quem testa os
abre, porque o que está dentro decide o que o token pode fazer e por quanto tempo.

A crença a abandonar é a de que um token é criptografado. Ele é **assinado**, não criptografado:
qualquer um que tenha um consegue lê-lo, e só quem tem o segredo consegue fazer um novo que o
servidor aceite. Os pontos o dividem nos três pedaços:

```
ana@laptop:~/boxoffice$ echo "$TOKEN" | tr . "\n"
eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
eyJzdWIiOiJjaS10ZXN0cyIsInNjb3BlIjoib3JkZXJzOnJlYWQgb3JkZXJzOndyaXRlIiwiaWF0IjoxNzkxNjYxMzg3LCJleHAiOjE3OTE2NjIyODd9
ZYNygARAi8VHK-A59GydT_uT2q6wG8ebDb8D67_sJQU
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 196\" role=\"img\" aria-label=\"Um JWT desenhado como três caixas unidas por pontos: o cabeçalho, com alg HS256; o payload, com as claims, como sub ci-tests; e a assinatura. Um colchete sob o cabeçalho e o payload diz que qualquer um os lê, por serem base64url e não criptografia. Uma linha desse colchete até a assinatura diz que a assinatura é um HMAC-SHA256 dos dois com o segredo do servidor, então mudar um caractere à esquerda faz a assinatura deixar de bater.\"><defs><marker id=\"f03jwt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"350\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">um token, três partes unidas por pontos</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"120\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">cabeçalho</text><text x=\"120\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{\"alg\":\"HS256\"}</text><rect x=\"250\" y=\"40\" width=\"220\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">payload: as claims</text><text x=\"360\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">{\"sub\":\"ci-tests\",…}</text><rect x=\"500\" y=\"40\" width=\"180\" height=\"56\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"590\" y=\"61\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">assinatura</text><text x=\"590\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">lwdWgGhtfpp9…</text><text x=\"235\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">.</text><text x=\"485\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">.</text><line x1=\"20\" y1=\"112\" x2=\"470\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><line x1=\"20\" y1=\"106\" x2=\"20\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><line x1=\"470\" y1=\"106\" x2=\"470\" y2=\"112\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></line><line x1=\"245\" y1=\"112\" x2=\"245\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"245\" y1=\"140\" x2=\"590\" y2=\"140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><line x1=\"590\" y1=\"140\" x2=\"590\" y2=\"98\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#f03jwt-ah)\"></line><text x=\"236\" y=\"126\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">qualquer um lê: base64url, não criptografia</text><text x=\"420\" y=\"154\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">HMAC-SHA256 das duas, com o segredo do servidor</text><text x=\"350\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">mude um caractere à esquerda e a assinatura deixa de bater</text></svg>", "caption": "O cabeçalho e o payload podem ser lidos por qualquer um; a assinatura cobre os dois, e só o segredo consegue produzi-la."}
```

## Lendo as claims

Os dois primeiros pedaços são JSON escrito em base64url, um alfabeto de letras, dígitos, `-` e `_`
que viaja com segurança num cabeçalho. O Node os transforma de volta em texto numa linha, que passa
pelos dois pedaços e decodifica cada um:

```
ana@laptop:~/boxoffice$ node -e 'for (const part of process.argv[1].split(".").slice(0, 2)) console.log(Buffer.from(part, "base64url").toString())' "$TOKEN"
{"alg":"HS256","typ":"JWT"}
{"sub":"ci-tests","scope":"orders:read orders:write","iat":1791661387,"exp":1791662287}
```

O cabeçalho diz como o token foi assinado: `HS256`, um HMAC com SHA-256, que usa um único segredo
compartilhado tanto para assinar quanto para conferir. O payload traz quatro **claims**:

| claim | significa | aqui |
|---|---|---|
| `sub` | o sujeito: de quem é o token | o cliente `ci-tests` |
| `scope` | o que ele pode fazer, separado por espaços | ler e escrever pedidos |
| `iat` | emitido em, em segundos desde 1º de janeiro de 1970 UTC | quando o endpoint de token respondeu |
| `exp` | expira em, nos mesmos segundos | `iat` mais a duração |

Segundos desde 1970 são difíceis de ler, então mais uma linha os subtrai e transforma `exp` numa
data:

```
ana@laptop:~/boxoffice$ node -e 'const c = JSON.parse(Buffer.from(process.argv[1].split(".")[1], "base64url")); console.log(c.exp - c.iat, new Date(c.exp * 1000).toString())' "$TOKEN"
900 Sat Oct 10 2026 16:58:07 GMT-0300 (Brasilia Standard Time)
```

900 segundos entre a emissão e a expiração, o `expires_in` da seção 03, e o momento em que ele para
de funcionar, no horário local. **Duas verificações que quem testa faz em todo token**: a duração é
a que a API documenta, e o escopo não é mais amplo do que o concedido ao cliente.

## Mudando uma claim

Já que qualquer um lê um token, qualquer um também consegue editá-lo. O cliente `auditor` só pode
ler; pegue um token dele e reescreva o escopo para que ele diga que também escreve. Primeiro o token
do auditor, do jeito que a seção 03 buscou o outro:

```
ana@laptop:~/boxoffice$ AUDITOR=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=auditor -d client_secret=auditor-secret | jq -r .access_token)
```

Depois uma linha que decodifica o payload, muda `scope`, codifica de novo e remonta o token **com a
assinatura original**:

```
ana@laptop:~/boxoffice$ FORGED=$(node -e 'const [head, body, sig] = process.argv[1].split("."); const claims = JSON.parse(Buffer.from(body, "base64url")); claims.scope = "orders:read orders:write"; console.log([head, Buffer.from(JSON.stringify(claims)).toString("base64url"), sig].join("."))' "$AUDITOR")
```

Mandado ao servidor como pedido:

```
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $FORGED" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":1}' | grep -iE '^HTTP|^www'
HTTP/1.1 401 Unauthorized
www-authenticate: Bearer error="invalid_token", error_description="bad signature"
```

`bad signature`. A assinatura foi feita sobre o cabeçalho e o payload originais; o boxoffice a
recalculou sobre os editados, as duas diferem, e o token é recusado antes mesmo de as claims serem
lidas. Este é o teste mais importante da lição: **um servidor que aceitasse um token editado
deixaria todo cliente se dar qualquer escopo**. O companheiro dele é um token cujo cabeçalho diz
`"alg": "none"` e cuja assinatura está vazia, que uma biblioteca descuidada trata como dispensado de
conferência. O `readToken` do `boxoffice.mjs` nunca olha o `alg` e sempre recalcula a própria
assinatura, então recusaria esse também; contra uma API cujo código você não pode ler, você manda e
vê.

## O que reiniciar faz com um token

O boxoffice não guarda lista dos tokens que emitiu. Ele confere um token recalculando a assinatura,
então um token continua válido enquanto o segredo e o relógio deixarem. Pare o servidor no segundo
terminal com Ctrl-C e inicie-o de novo:

```
ana@laptop:~/boxoffice$ node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Todo pedido sumiu e todo lugar está livre de novo, como a lição 1 disse. Agora o token buscado antes
de reiniciar, num pedido:

```
ana@laptop:~/boxoffice$ code localhost:8080/v1/orders -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":1}'
201
```

`201`. **O servidor que emitiu o token não existe mais, e o token continua funcionando**, porque o
segredo é o mesmo. O outro lado da moeda é que um JWT não pode ser retirado antes de expirar sem
maquinário extra, e é por isso que a duração dele deve ser curta.

## Expiração, sem esperar quinze minutos

`TOKEN_TTL` define a duração em segundos. Reinicie o boxoffice com tokens que vivem cinco segundos:

```
ana@laptop:~/boxoffice$ TOKEN_TTL=5 node boxoffice.mjs
boxoffice listening on http://localhost:8080
```

Busque um token, use-o na hora, espere seis segundos, use-o de novo:

```
ana@laptop:~/boxoffice$ SHORT=$(curl -s localhost:8080/oauth/token -d grant_type=client_credentials -d client_id=ci-tests -d client_secret=ci-secret | jq -r .access_token)
ana@laptop:~/boxoffice$ code localhost:8080/v1/orders -H "authorization: Bearer $SHORT" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":1}'
201
ana@laptop:~/boxoffice$ sleep 6
ana@laptop:~/boxoffice$ curl -si localhost:8080/v1/orders -H "authorization: Bearer $SHORT" -H 'content-type: application/json' -d '{"show_id":"sh-101","seats":1}' | grep -iE '^HTTP|^www'
HTTP/1.1 401 Unauthorized
www-authenticate: Bearer error="invalid_token", error_description="token expired"
```

O mesmo token, um `201` e depois um `401`, e o cabeçalho `www-authenticate` diz por quê: `token
expired`. Um teste de expiração não precisa da duração real, só de um servidor configurado para
encurtá-la, que é exatamente para o que serve uma configuração como `TOKEN_TTL`. Reinicie o
boxoffice mais uma vez com um `node boxoffice.mjs` simples antes de seguir, e busque o `TOKEN` de
novo: o que você tinha foi emitido por um servidor cujos tokens viviam quinze minutos, e pode ter
acabado a esta altura.
