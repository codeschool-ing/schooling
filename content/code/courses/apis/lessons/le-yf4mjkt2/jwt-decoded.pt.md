---
title: Um JWT, decodificado
version: 1
---

Um JWT, JSON Web Token, são três pedaços de base64url unidos por pontos: um **cabeçalho** que diz
como o token foi assinado, um **payload** de claims sobre o usuário e uma **assinatura** sobre os
dois primeiros. O cabeçalho e o payload estão codificados, não criptografados. Qualquer um que tenha
o token consegue lê-los, e esta seção faz isso à mão.

Isso corrige a crença mais comum sobre JWTs, a de que a string comprida é opaca e portanto um lugar
seguro para dados. Ela só é opaca para quem nunca tentou `base64 -d`. **A assinatura impede que
alguém sem a chave altere as claims sem ser notado; nada impede ninguém de lê-las.** Um token que
precisa esconder o conteúdo é outro formato, o JWE, pouco usado; o que todo mundo chama de JWT é o
tipo assinado.

## O arquivo

O `tokens.py` faz o login de ana com um JWT. Ele importa o `sessions.py` para os usuários, a
verificação de senha e o encanamento das requisições, então os dois arquivos precisam estar em
`~/shelf`. Salve-o com `nano tokens.py`.

```schooling-example
{
  "language": "python",
  "file": "shelf/tokens.py",
  "parts": [
    {
      "code": "# shelf/tokens.py\n\"\"\"Signing in with a JWT: the token says who you are, and the server's key vouches for it.\n\nRun it with `python3 tokens.py`; it answers on http://127.0.0.1:8000.\n\"\"\"\nimport os\nimport secrets\nimport time\nfrom http.server import ThreadingHTTPServer\n\nimport jwt\n\nimport sessions\nfrom sessions import digest",
      "note": "O PyJWT, importado como `jwt`, é o pacote `python3-jwt` que a aula 1 instalou. Os usuários, a verificação de senha e o encanamento das requisições são os do `sessions.py`, importados em vez de copiados, para que os dois servidores difiram só no jeito de lembrar de você."
    },
    {
      "code": "\nISSUER, AUDIENCE = \"shelf\", \"shelf-api\"\nACCESS_LIFETIME = 5 * 60\nREFRESH_LIFETIME = 14 * 24 * 60 * 60\nLEEWAY = 30",
      "note": "Os nomes que vão em `iss` e `aud`, os dois tempos de vida e quantos segundos de diferença de relógio perdoar. Cinco minutos para um token de acesso é pouco de propósito, e a seção sobre revogação explica por quê."
    },
    {
      "code": "\n\ndef signing_key():\n    \"\"\"32 random bytes in jwt.key, made on first use and readable by its owner only.\"\"\"\n    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), \"jwt.key\")\n    if not os.path.exists(path):\n        fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)\n        os.write(fd, secrets.token_bytes(32))\n        os.close(fd)\n    with open(path, \"rb\") as f:\n        return f.read()\n\n\nKEY = signing_key()",
      "note": "A chave do HMAC: 32 bytes aleatórios em `jwt.key`, criados no primeiro uso com permissões `600`. **Quem consegue ler este arquivo consegue assinar tokens em que a API acredita**, então ele é um segredo como a senha de um banco, e nunca vai para o código-fonte nem para um repositório."
    },
    {
      "code": "\n\ndef connect():\n    conn = sessions.connect()\n    conn.executescript(\"\"\"\n        CREATE TABLE IF NOT EXISTS refresh_tokens (\n            id_hash TEXT PRIMARY KEY,\n            user_id INTEGER NOT NULL REFERENCES users (id),\n            family  TEXT NOT NULL,\n            expires INTEGER NOT NULL,\n            used    INTEGER NOT NULL DEFAULT 0);\n        CREATE TABLE IF NOT EXISTS revoked (\n            jti TEXT PRIMARY KEY,\n            exp INTEGER NOT NULL);\n    \"\"\")\n    return conn",
      "note": "Duas tabelas para o que um JWT não faz sozinho: os refresh tokens, guardados pelo hash como as sessões, e a lista de bloqueio com os ids de tokens revogados."
    },
    {
      "code": "\n\ndef issue(user_id, now=None):\n    \"\"\"A signed access token for the user, valid for ACCESS_LIFETIME seconds from now.\"\"\"\n    now = int(time.time() if now is None else now)\n    claims = {\"sub\": str(user_id), \"iss\": ISSUER, \"aud\": AUDIENCE, \"iat\": now, \"nbf\": now,\n              \"exp\": now + ACCESS_LIFETIME, \"jti\": secrets.token_hex(8)}\n    return jwt.encode(claims, KEY, algorithm=\"HS256\")",
      "note": "As claims, e então o `jwt.encode` as assina com HS256. Nada sobre o login é anotado aqui: o token é o registro inteiro."
    },
    {
      "code": "\n\ndef verify(conn, token):\n    \"\"\"The claims of a good access token; raises jwt.InvalidTokenError for any other.\"\"\"\n    claims = jwt.decode(token, KEY, algorithms=[\"HS256\"], issuer=ISSUER, audience=AUDIENCE,\n                        leeway=LEEWAY,\n                        options={\"require\": [\"sub\", \"iss\", \"aud\", \"iat\", \"nbf\", \"exp\", \"jti\"]})\n    if conn.execute(\"SELECT 1 FROM revoked WHERE jti = ?\", (claims[\"jti\"],)).fetchone():\n        raise jwt.InvalidTokenError(\"token revoked\")\n    return claims",
      "note": "`algorithms=[\"HS256\"]` é a linha que mais importa. O servidor decide como um token tem de ser assinado, e um token que diga outra coisa é recusado. Depois vêm o emissor, a audiência, os horários com 30 segundos de tolerância, e as sete claims exigidas. A última verificação lê a lista de bloqueio, o que é uma consulta a cada requisição."
    },
    {
      "code": "\n\ndef pair(conn, user_id, family=None):\n    \"\"\"A new access token and a new refresh token, the second remembered by its hash.\"\"\"\n    refresh = secrets.token_urlsafe(32)\n    conn.execute(\"INSERT INTO refresh_tokens VALUES (?, ?, ?, ?, 0)\",\n                 (digest(refresh), user_id, family or secrets.token_hex(8),\n                  int(time.time()) + REFRESH_LIFETIME))\n    return {\"access_token\": issue(user_id), \"token_type\": \"Bearer\",\n            \"expires_in\": ACCESS_LIFETIME, \"refresh_token\": refresh}",
      "note": "Login e refresh respondem os dois com um par: um token de acesso de vida curta e um refresh token de vida longa. O refresh token é uma string aleatória, não um JWT, e a `family` liga todos os tokens que descendem de um mesmo login."
    },
    {
      "code": "\n\nclass Tokens(sessions.Handler):\n\n    def bearer(self, conn):\n        \"\"\"The claims of the request's access token, or None after answering 401.\"\"\"\n        scheme, _, token = self.headers.get(\"Authorization\", \"\").partition(\" \")\n        problem = \"send Authorization: Bearer <token>\"\n        if scheme == \"Bearer\" and token:\n            try:\n                return verify(conn, token)\n            except jwt.InvalidTokenError as e:\n                problem = str(e)\n        self.error(401, problem, [(\"WWW-Authenticate\", 'Bearer error=\"invalid_token\"')])\n        return None\n\n    def do_GET(self):\n        if self.path != \"/me\":\n            return self.error(404, \"no such resource\")\n        with connect() as conn:\n            claims = self.bearer(conn)\n            if claims is not None:\n                name = conn.execute(\"SELECT name FROM users WHERE id = ?\", (claims[\"sub\"],)).fetchone()\n                self.reply(200, {\"name\": name[\"name\"], \"exp\": claims[\"exp\"], \"jti\": claims[\"jti\"]})",
      "note": "O token chega em `Authorization: Bearer`. Um ausente ou ruim recebe **401** com `WWW-Authenticate: Bearer`, e o corpo diz qual verificação falhou. `/me` acha o usuário pelo `sub`."
    },
    {
      "code": "\n    def do_POST(self):\n        if self.path not in (\"/login\", \"/refresh\", \"/logout\"):\n            return self.error(404, \"no such resource\")\n        with connect() as conn:\n            if self.path == \"/login\":\n                user = self.login(conn)\n                if user is not None:\n                    self.reply(200, pair(conn, user))\n                return",
      "note": "O login é a verificação do `sessions.py`, respondida com um par em vez de um cookie."
    },
    {
      "code": "            if self.path == \"/logout\":\n                claims = self.bearer(conn)\n                if claims is not None:\n                    conn.execute(\"DELETE FROM revoked WHERE exp < ?\", (int(time.time()),))\n                    conn.execute(\"INSERT INTO revoked VALUES (?, ?)\", (claims[\"jti\"], claims[\"exp\"]))\n                    conn.execute(\"DELETE FROM refresh_tokens WHERE user_id = ?\", (claims[\"sub\"],))\n                    self.reply(204)\n                return",
      "note": "O logout põe o `jti` do token na lista de bloqueio até o `exp` dele, limpando as entradas que já venceram de qualquer jeito, e apaga os refresh tokens do usuário, o que o desconecta de todos os aparelhos de uma vez."
    },
    {
      "code": "            value = self.body()\n            if value is None:\n                return\n            row = conn.execute(\"SELECT * FROM refresh_tokens WHERE id_hash = ? AND expires > ?\",\n                               (digest(str(value.get(\"refresh_token\"))), int(time.time()))).fetchone()\n            if row is None:\n                return self.error(401, \"unknown or expired refresh token\")\n            if row[\"used\"]:\n                conn.execute(\"DELETE FROM refresh_tokens WHERE family = ?\", (row[\"family\"],))\n                return self.error(401, \"refresh token used twice: this sign-in is revoked\")\n            conn.execute(\"UPDATE refresh_tokens SET used = 1 WHERE id_hash = ?\", (row[\"id_hash\"],))\n            self.reply(200, pair(conn, row[\"user_id\"], row[\"family\"]))",
      "note": "Refresh com **rotação**: um refresh token funciona uma vez e volta substituído. Um apresentado pela segunda vez quer dizer que duas partes o têm, então a família inteira é apagada e as duas precisam entrar de novo."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Tokens)\n    print(\"tokens on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "A porta 8000 de novo: pare o `sessions.py` antes de iniciar este."
    }
  ]
}
```

Pare o `sessions.py` no segundo terminal com `Ctrl+C` e inicie este:

```sh
cd ~/shelf && python3 tokens.py
```

## Entrando

O login é a mesma requisição, e a resposta é outra: nenhum cookie, um corpo JSON com dois tokens
dentro. O `tee login.json` guarda esse corpo num arquivo, para que os comandos depois deste leiam o
token dali com o `jq`:

```
ana@api:~/shelf$ curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-horse"}' | tee login.json | jq .
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiaXNzIjoic2hlbGYiLCJhdWQiOiJzaGVsZi1hcGkiLCJpYXQiOjE3OTE2MDY2NjcsIm5iZiI6MTc5MTYwNjY2NywiZXhwIjoxNzkxNjA2OTY3LCJqdGkiOiIxOTAyYTFhY2FhNDNiMzE2In0.6htCZVCQFrI9WiAkcaMaskVDcb9mPSuA6V_RF0cmR2M",
  "token_type": "Bearer",
  "expires_in": 300,
  "refresh_token": "2D7viIKQ5cVy58OnUMwMza_z8_kb7pPMLaHwUWMJ02U"
}
```

O `/me` quer o token de acesso em `Authorization: Bearer`, o esquema que a aula 7 apresentou. Sem
token, a resposta é 401, e o `WWW-Authenticate` diz o esquema que o cliente deve usar:

```
ana@api:~/shelf$ curl -s localhost:8000/me -H "Authorization: Bearer $(jq -r .access_token login.json)"
{"name": "ana", "exp": 1791606967, "jti": "1902a1acaa43b316"}
ana@api:~/shelf$ curl -si localhost:8000/me
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:07 GMT
Content-Type: application/json
Content-Length: 48
WWW-Authenticate: Bearer error="invalid_token"

{"error": "send Authorization: Bearer <token>"}
```

A primeira execução também criou a chave de assinatura. Só ana consegue lê-la:

```
ana@api:~/shelf$ ls -l jwt.key
-rw------- 1 ana ana 32 Oct 10 01:31 jwt.key
```

## Lendo à mão

Parta o token de acesso nos pontos. O primeiro pedaço é o cabeçalho, e o `base64 -d` o lê:

```
ana@api:~/shelf$ jq -r .access_token login.json | cut -d. -f1 | base64 -d; echo
{"alg":"HS256","typ":"JWT"}
```

O segundo pedaço é o payload. JWTs usam **base64url**, a variante com `-` e `_` onde o base64 comum
tem `+` e `/`, para caber numa URL; o `basenc --base64url` decodifica esse alfabeto. Ele imprime o
JSON e depois reclama:

```
ana@api:~/shelf$ jq -r .access_token login.json | cut -d. -f2 | basenc --base64url -d; echo
{"sub":"1","iss":"shelf","aud":"shelf-api","iat":1791606667,"nbf":1791606667,"exp":1791606967,"jti":"1902a1acaa43b316"}basenc: invalid input
```

O JSON está todo ali; a reclamação é sobre o fim. O base64 trabalha em grupos de quatro caracteres e
completa o último grupo com `=`. O base64url, do jeito que os JWTs o usam, **omite esse
preenchimento**, então um pedaço cujo tamanho não é múltiplo de quatro parece cortado para um
decodificador rígido. Este tem 159 caracteres:

```
ana@api:~/shelf$ jq -r .access_token login.json | cut -d. -f2 | tr -d "\n" | wc -c
159
```

Um `=` leva a 160, e o decodificador fica satisfeito:

```
ana@api:~/shelf$ jq -r .access_token login.json | cut -d. -f2 | sed 's/$/=/' | basenc --base64url -d; echo
{"sub":"1","iss":"shelf","aud":"shelf-api","iat":1791606667,"nbf":1791606667,"exp":1791606967,"jti":"1902a1acaa43b316"}
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 380\" role=\"img\" aria-label=\"Um JWT partido nos dois pontos em três partes base64url. A primeira decodifica para o cabeçalho, alg HS256 e typ JWT. A segunda decodifica para o payload, sete claims: sub, iss, aud, iat, nbf, exp e jti. A terceira é a assinatura, HMAC-SHA256 sobre as duas primeiras partes e o ponto entre elas, feita com a chave em jwt.key. As duas primeiras estão só codificadas e qualquer um as lê; só a terceira precisa da chave.\"><defs><marker id=\"l08-jwt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"12\" width=\"680\" height=\"34\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"20\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">eyJhbGciOiJIUzI1NiIsIn…</text><text x=\"196\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">.</text><text x=\"206\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">eyJzdWIiOiIxIiwiaXNzIjoic2hlbGYiLCJhdWQi…</text><text x=\"530\" y=\"29\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">.</text><text x=\"540\" y=\"29\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6htCZVCQFrI9WiAk…</text><line x1=\"100\" y1=\"46\" x2=\"100\" y2=\"78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-jwt-ah)\"></line><line x1=\"360\" y1=\"46\" x2=\"360\" y2=\"78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-jwt-ah)\"></line><line x1=\"600\" y1=\"46\" x2=\"600\" y2=\"78\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#l08-jwt-ah)\"></line><rect x=\"10\" y=\"80\" width=\"180\" height=\"110\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\" font-weight=\"600\">cabeçalho</text><text x=\"22\" y=\"124\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;alg&quot;: &quot;HS256&quot;</text><text x=\"22\" y=\"144\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">&quot;typ&quot;: &quot;JWT&quot;</text><text x=\"100\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">como foi assinado</text><rect x=\"210\" y=\"80\" width=\"300\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\" font-weight=\"600\">payload: as claims</text><text x=\"222\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;sub&quot;: &quot;1&quot;</text><text x=\"498\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quem: usuário 1, ana</text><text x=\"222\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;iss&quot;: &quot;shelf&quot;</text><text x=\"498\" y=\"146\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">quem emitiu</text><text x=\"222\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;aud&quot;: &quot;shelf-api&quot;</text><text x=\"498\" y=\"170\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">para quem é</text><text x=\"222\" y=\"194\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;iat&quot;: 1791606667</text><text x=\"498\" y=\"194\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">emitido em</text><text x=\"222\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;nbf&quot;: 1791606667</text><text x=\"498\" y=\"218\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">não vale antes de</text><text x=\"222\" y=\"242\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;exp&quot;: 1791606967</text><text x=\"498\" y=\"242\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">vence, 300 s depois</text><text x=\"222\" y=\"266\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">&quot;jti&quot;: &quot;1902a1acaa43b316&quot;</text><text x=\"498\" y=\"266\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o id deste token</text><rect x=\"530\" y=\"80\" width=\"160\" height=\"220\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"98\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">assinatura</text><text x=\"610\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">HMAC-SHA256(</text><text x=\"610\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--amber)\">jwt.key,</text><text x=\"610\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">header.payload</text><text x=\"610\" y=\"184\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">)</text><text x=\"610\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">32 bytes, depois</text><text x=\"610\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">base64url</text><text x=\"250\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">codificado: quem tem o token lê isto</text><line x1=\"20\" y1=\"316\" x2=\"500\" y2=\"316\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><text x=\"610\" y=\"330\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">precisa da chave</text><line x1=\"530\" y1=\"316\" x2=\"690\" y2=\"316\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line></svg>", "caption": "O token de acesso do login acima, decodificado. Duas das três partes são JSON puro em base64url; a terceira é a única que precisa da chave.", "same": ["base64url"]}
```

Sete claims em 159 caracteres, legíveis pelo navegador, por todo proxy e todo log que vê o
cabeçalho, e por quem achar o token num print de tela. Por isso **um payload carrega identificadores
e horários, nunca segredos**: nada de senha, nada de número de cartão, nada de endereço que você não
escreveria do lado de fora de um envelope. A seção sobre claims pega as sete uma a uma.
