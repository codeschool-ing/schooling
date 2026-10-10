---
title: idp.py, um servidor de autorização de brinquedo
version: 1
---

Para ver um fluxo por dentro você precisa de um servidor de autorização que consiga ler, e os que
rodam em produção são grandes. O `idp.py` tem 222 linhas que fazem as partes que esta lição ensina:
`/authorize` com PKCE, `/token` para três grants, um ID token, o documento de discovery, uma chave
pública publicada e dois endpoints que fazem o papel da API. **É um brinquedo para ensinar, e a
tabela no fim desta seção lista o que ele deixa de fora.**

Ele faz uma coisa que nenhum servidor de verdade faz, para que o `curl` consiga conduzi-lo: **tem
uma usuária, a Ana, que está sempre conectada e já disse sim.** Onde um `/authorize` de verdade
mostraria uma página de entrada e depois uma tela de consentimento, este responde na hora com o
redirecionamento. Tudo depois desse momento é real: os códigos, a conferência do PKCE, as
assinaturas e as recusas.

Salve-o como `~/shelf/idp.py` do mesmo jeito que salvou o `rest.py`.

```schooling-example
{
  "language": "python",
  "file": "shelf/idp.py",
  "parts": [
    {
      "code": "# shelf/idp.py\n\"\"\"A teaching authorization server and OpenID provider for shelf.\n\nOne client, one user, and consent that is already given. Run it with\n`python3 idp.py`; it answers on http://127.0.0.1:8000. It is kept small enough\nto read in one sitting, and that is why it must never face a real user.\n\"\"\"\nimport base64\nimport hashlib\nimport hmac\nimport json\nimport os\nimport secrets\nimport time\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\nfrom urllib.parse import parse_qs, urlencode, urlsplit\n\nimport jwt\nfrom cryptography.hazmat.primitives import serialization\nfrom cryptography.hazmat.primitives.asymmetric import rsa\n\nimport db",
      "note": "A biblioteca padrão do Python, o PyJWT para assinar tokens, o `cryptography` para a chave RSA e o `db.py` para os livros. Os três vêm da linha de `apt-get` da lição 1; nada é instalado aqui."
    },
    {
      "code": "\nISSUER = \"http://localhost:8000\"\nAPI = \"shelf-api\"\nCLIENT = {\"id\": \"shelf-web\", \"secret\": \"lab-only-secret\",\n          \"redirect_uri\": \"http://127.0.0.1:9000/callback\",\n          \"scopes\": {\"openid\", \"profile\", \"email\", \"books:read\"},\n          \"machine_scopes\": {\"books:read\"}}\nUSER = {\"sub\": \"u-81f3a2\", \"name\": \"Ana Souza\", \"email\": \"ana@shelf.example\"}",
      "note": "**O cadastro inteiro são estas linhas.** Um cliente, com seu segredo, o único endereço para onde seus códigos podem ir, os escopos que uma pessoa pode conceder a ele e o conjunto menor que ele pode pedir sozinho. Um usuário. `ISSUER` é o nome que todo token leva em `iss`, e `API` é a audiência para a qual todo access token é emitido."
    },
    {
      "code": "\nKEY_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), \"idp-key.pem\")\nif not os.path.exists(KEY_FILE):\n    new = rsa.generate_private_key(public_exponent=65537, key_size=2048)\n    with os.fdopen(os.open(KEY_FILE, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600), \"wb\") as f:\n        f.write(new.private_bytes(serialization.Encoding.PEM, serialization.PrivateFormat.PKCS8,\n                                  serialization.NoEncryption()))\nwith open(KEY_FILE, \"rb\") as f:\n    KEY = serialization.load_pem_private_key(f.read(), password=None)\nPUBLIC = KEY.public_key()\nKID = hashlib.sha256(PUBLIC.public_bytes(serialization.Encoding.DER,\n                     serialization.PublicFormat.SubjectPublicKeyInfo)).hexdigest()[:8]\nJWK = {**json.loads(jwt.algorithms.RSAAlgorithm.to_jwk(PUBLIC)), \"kid\": KID, \"use\": \"sig\",\n       \"alg\": \"RS256\"}",
      "note": "A chave de assinatura. A primeira execução gera uma chave RSA de 2048 bits e a grava com permissão `0600`, para que só você consiga lê-la; as seguintes carregam a mesma. `KID` é uma impressão digital curta da metade pública, e `JWK` é essa metade pública no formato JSON que o `/jwks.json` publica."
    },
    {
      "code": "\nCODES = {}      # code -> what the user granted; works once, for 60 seconds\nREFRESH = {}    # refresh token -> the grant it belongs to, and whether it was used\nREVOKED = set()  # grants ended because one of their refresh tokens came back twice",
      "note": "Três tabelas em memória. Parar o servidor esquece todo código e todo refresh token que ele já entregou, e é a primeira coisa que um servidor de verdade guardaria num banco de dados."
    },
    {
      "code": "\n\ndef s256(verifier):\n    digest = hashlib.sha256(verifier.encode()).digest()\n    return base64.urlsafe_b64encode(digest).rstrip(b\"=\").decode()\n\n\ndef sign(claims, seconds):\n    now = int(time.time())\n    return jwt.encode({\"iss\": ISSUER, \"iat\": now, \"exp\": now + seconds, **claims},\n                      KEY, algorithm=\"RS256\", headers={\"kid\": KID})",
      "note": "`s256` é a transformação do PKCE: o SHA-256 do verifier, em base64url sem preenchimento. `sign` gera um JWT assinado com a chave privada, carimbado com o emissor, a hora em que foi feito e a hora em que deixa de valer."
    },
    {
      "code": "\n\ndef issue(scope, sub=None, grant=None, login=None):\n    \"\"\"The token response: an access token always, the others when they apply.\"\"\"\n    words = \" \".join(sorted(scope))\n    out = {\"token_type\": \"Bearer\", \"expires_in\": 300, \"scope\": words,\n           \"access_token\": sign({\"aud\": API, \"sub\": sub or CLIENT[\"id\"],\n                                 \"client_id\": CLIENT[\"id\"], \"scope\": words,\n                                 \"jti\": secrets.token_hex(8)}, 300)}\n    if grant:\n        refresh = secrets.token_urlsafe(32)\n        REFRESH[refresh] = {\"grant\": grant, \"scope\": scope, \"sub\": sub, \"used\": False}\n        out[\"refresh_token\"] = refresh\n    if login is not None and \"openid\" in scope:\n        out[\"id_token\"] = sign({\"aud\": CLIENT[\"id\"], \"sub\": sub, **login}, 300)\n    return out",
      "note": "**Uma função escreve toda resposta de token.** Um access token sempre, por cinco minutos, emitido para a API. Um refresh token só quando uma pessoa concedeu algo, porque uma máquina pode simplesmente pedir de novo. Um ID token só quando uma pessoa entrou e o cliente pediu `openid`."
    },
    {
      "code": "\n\nclass IdP(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def reply(self, status, value=None, headers=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n            self.send_header(\"Cache-Control\", \"no-store\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def refuse(self, status, error, description, headers=()):\n        self.reply(status, {\"error\": error, \"error_description\": description}, headers)",
      "note": "Toda resposta sai por `reply`, como no `rest.py`. Uma resposta JSON leva `Cache-Control: no-store`, porque um token num cache é um token que pode ser entregue a outra pessoa. `refuse` escreve o formato de erro do OAuth: um código de uma lista fixa em `error`, e uma frase para gente em `error_description`."
    },
    {
      "code": "\n    def do_GET(self):\n        url = urlsplit(self.path)\n        q = {k: v[0] for k, v in parse_qs(url.query).items()}\n        if url.path == \"/authorize\":\n            return self.authorize(q)\n        if url.path == \"/.well-known/openid-configuration\":\n            return self.reply(200, {\n                \"issuer\": ISSUER, \"authorization_endpoint\": ISSUER + \"/authorize\",\n                \"token_endpoint\": ISSUER + \"/token\", \"userinfo_endpoint\": ISSUER + \"/userinfo\",\n                \"jwks_uri\": ISSUER + \"/jwks.json\", \"response_types_supported\": [\"code\"],\n                \"grant_types_supported\": [\"authorization_code\", \"refresh_token\",\n                                          \"client_credentials\"],\n                \"code_challenge_methods_supported\": [\"S256\"],\n                \"scopes_supported\": sorted(CLIENT[\"scopes\"]), \"subject_types_supported\": [\"public\"],\n                \"id_token_signing_alg_values_supported\": [\"RS256\"],\n                \"token_endpoint_auth_methods_supported\": [\"client_secret_basic\"]})\n        if url.path == \"/jwks.json\":\n            return self.reply(200, {\"keys\": [JWK]})\n        if url.path == \"/userinfo\":\n            claims = self.bearer(\"openid\")\n            if claims:\n                scope = claims[\"scope\"].split()\n                info = {\"sub\": claims[\"sub\"]}\n                if \"profile\" in scope:\n                    info[\"name\"] = USER[\"name\"]\n                if \"email\" in scope:\n                    info[\"email\"] = USER[\"email\"]\n                self.reply(200, info)\n            return\n        if url.path == \"/books/stock\":\n            if self.bearer(\"books:read\"):\n                with db.connect() as conn:\n                    rows = conn.execute(\"SELECT id, title, stock FROM books ORDER BY id\").fetchall()\n                self.reply(200, [dict(row) for row in rows])\n            return\n        self.refuse(404, \"not_found\", \"no such endpoint\")",
      "note": "Os endpoints de GET. Dois são públicos e descrevem o servidor: o documento de discovery e a chave pública. Dois são o **servidor de recursos**: `/userinfo` e `/books/stock` só respondem a um access token com o escopo certo, e quem decide isso é o `bearer`, mais abaixo."
    },
    {
      "code": "\n    def authorize(self, q):\n        if q.get(\"client_id\") != CLIENT[\"id\"] or q.get(\"redirect_uri\") != CLIENT[\"redirect_uri\"]:\n            return self.refuse(400, \"invalid_request\", \"unknown client or redirect_uri\")\n\n        def back(**params):\n            if \"state\" in q:\n                params[\"state\"] = q[\"state\"]\n            self.reply(302, None, [(\"Location\", CLIENT[\"redirect_uri\"] + \"?\" + urlencode(params))])\n\n        if q.get(\"response_type\") != \"code\":\n            return back(error=\"unsupported_response_type\")\n        scope = set(q.get(\"scope\", \"\").split())\n        if not scope or not scope <= CLIENT[\"scopes\"]:\n            return back(error=\"invalid_scope\")\n        if q.get(\"code_challenge_method\") != \"S256\" or len(q.get(\"code_challenge\", \"\")) != 43:\n            return back(error=\"invalid_request\", error_description=\"PKCE with S256 is required\")\n        # A real server signs the user in here and shows a consent screen.\n        # This one has one user, who has already said yes to every scope.\n        code = secrets.token_urlsafe(24)\n        CODES[code] = {\"scope\": scope, \"challenge\": q[\"code_challenge\"],\n                       \"login\": {\"nonce\": q[\"nonce\"]} if \"nonce\" in q else {},\n                       \"expires\": time.time() + 60}\n        back(code=code)",
      "note": "`/authorize`. Um cliente desconhecido ou um `redirect_uri` que não seja exatamente o cadastrado recebe 400 e **nenhum redirecionamento**, porque mandar o navegador para um endereço que ninguém cadastrou é o caminho de um código até um estranho. Toda outra recusa volta para o endereço do próprio cliente com um `error`. Depois vem o código: aleatório, guardado por 60 segundos com o escopo, o challenge do PKCE e o nonce."
    },
    {
      "code": "\n    def client_ok(self):\n        auth = self.headers.get(\"Authorization\", \"\")\n        if not auth.startswith(\"Basic \"):\n            return False\n        given = base64.b64decode(auth[6:]).decode(errors=\"replace\")\n        return hmac.compare_digest(given, CLIENT[\"id\"] + \":\" + CLIENT[\"secret\"])",
      "note": "O cliente prova quem é com HTTP Basic, o esquema da lição 7, e a comparação usa `hmac.compare_digest`, que leva o mesmo tempo quer o primeiro caractere esteja errado, quer o último."
    },
    {
      "code": "\n    def do_POST(self):\n        size = int(self.headers.get(\"Content-Length\") or 0)\n        f = {k: v[0] for k, v in parse_qs(self.rfile.read(size).decode()).items()}\n        if urlsplit(self.path).path != \"/token\":\n            return self.refuse(404, \"not_found\", \"no such endpoint\")\n        if not self.client_ok():\n            return self.refuse(401, \"invalid_client\", \"the client did not authenticate\",\n                               [(\"WWW-Authenticate\", 'Basic realm=\"idp\"')])\n        grant = f.get(\"grant_type\")\n        if grant == \"authorization_code\":\n            c = CODES.pop(f.get(\"code\", \"\"), None)\n            if c is None or c[\"expires\"] < time.time():\n                return self.refuse(400, \"invalid_grant\", \"unknown, used or expired code\")\n            if f.get(\"redirect_uri\") != CLIENT[\"redirect_uri\"]:\n                return self.refuse(400, \"invalid_grant\", \"redirect_uri differs from /authorize\")\n            if not hmac.compare_digest(s256(f.get(\"code_verifier\", \"\")), c[\"challenge\"]):\n                return self.refuse(400, \"invalid_grant\", \"code_verifier does not match\")\n            return self.reply(200, issue(c[\"scope\"], USER[\"sub\"], secrets.token_hex(4), c[\"login\"]))\n        if grant == \"refresh_token\":\n            r = REFRESH.get(f.get(\"refresh_token\", \"\"))\n            if r is None or r[\"grant\"] in REVOKED:\n                return self.refuse(400, \"invalid_grant\", \"unknown or revoked refresh token\")\n            if r[\"used\"]:\n                REVOKED.add(r[\"grant\"])\n                return self.refuse(400, \"invalid_grant\", \"refresh token used twice; grant revoked\")\n            r[\"used\"] = True\n            return self.reply(200, issue(r[\"scope\"], r[\"sub\"], r[\"grant\"]))\n        if grant == \"client_credentials\":\n            scope = set(f.get(\"scope\", \"books:read\").split())\n            if not scope <= CLIENT[\"machine_scopes\"]:\n                return self.refuse(400, \"invalid_scope\", \"a machine may ask for books:read only\")\n            return self.reply(200, issue(scope))\n        self.refuse(400, \"unsupported_grant_type\", f\"{grant} is not offered here\")",
      "note": "`/token`, um ramo por grant. O código sai da tabela **antes** de ser conferido, então funciona uma vez só, mesmo quando a conferência falha. Um refresh token é marcado como usado e substituído; um que volte depois disso encerra o grant inteiro. Client credentials recebe só os escopos de máquina. Qualquer outro tipo de grant é recusado pelo nome."
    },
    {
      "code": "\n    def bearer(self, needed):\n        \"\"\"The access token's claims, or None after answering 401 or 403.\"\"\"\n        auth = self.headers.get(\"Authorization\", \"\")\n        if not auth.startswith(\"Bearer \"):\n            self.refuse(401, \"invalid_token\", \"send an access token\",\n                        [(\"WWW-Authenticate\", 'Bearer realm=\"shelf\"')])\n            return None\n        try:\n            claims = jwt.decode(auth[7:], PUBLIC, algorithms=[\"RS256\"], audience=API,\n                                issuer=ISSUER)\n        except jwt.InvalidTokenError as e:\n            self.refuse(401, \"invalid_token\", str(e),\n                        [(\"WWW-Authenticate\", 'Bearer realm=\"shelf\", error=\"invalid_token\"')])\n            return None\n        if needed not in claims[\"scope\"].split():\n            self.refuse(403, \"insufficient_scope\", f\"this needs the scope {needed}\",\n                        [(\"WWW-Authenticate\", f'Bearer error=\"insufficient_scope\", scope=\"{needed}\"')])\n            return None\n        return claims",
      "note": "O que uma API faz com um bearer token, sem perguntar a ninguém: verifica a assinatura com a chave pública, recusa qualquer algoritmo que não seja RS256, confere o emissor, a audiência e a validade, e então o escopo. Sem token, ou com um token ruim, é **401**; um token bom sem o escopo é **403**, e o `WWW-Authenticate` diz qual escopo faltou."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), IdP)\n    print(f\"idp on {ISSUER}, signing key {KID}\", flush=True)\n    server.serve_forever()",
      "note": "Escuta só em 127.0.0.1, na porta que o `rest.py` usa, então os dois não rodam ao mesmo tempo. A primeira linha que imprime diz o id da chave."
    }
  ]
}
```

## Rodando

O `idp.py` escuta na porta 8000, como o `rest.py`, então pare o `rest.py` antes se ele estiver
rodando (`Ctrl+C` no terminal dele). Depois, no segundo terminal:

```sh
cd ~/shelf && python3 idp.py
```

Ele imprime uma linha e espera. O id no fim é a impressão digital da chave, e o seu vai ser
diferente porque a sua chave é:

```
idp on http://localhost:8000, signing key 420dabcd
```

A primeira execução gravou a chave privada ao lado do programa, legível só por você:

```
ana@api:~/shelf$ ls -l idp-key.pem
-rw------- 1 ana ana 1704 Oct 10 01:31 idp-key.pem
```

**Esse arquivo é toda a autoridade do servidor de autorização.** Quem o lê assina tokens que toda
API que confia neste servidor aceita, para qualquer usuário e qualquer escopo. Uma instalação de
verdade o guarda num cofre de chaves ou num módulo de hardware, e o programa pede assinaturas em
vez de ler a chave.

## O que um de verdade acrescenta

| `idp.py` | um servidor de autorização de verdade |
|---|---|
| um cliente, escrito no código-fonte | cadastro: muitos clientes, cada um com seus endereços, escopos e credenciais |
| uma usuária, sempre conectada, consentimento já dado | uma página de entrada, senhas guardadas como a lição 10 descreve, um segundo fator, uma tela de consentimento que o usuário pode recusar |
| um segredo de cliente no código-fonte | segredos gerados por cliente, guardados com hash, trocados periodicamente; ou chaves e certificados em vez de segredos |
| códigos e refresh tokens em memória, esquecidos a cada reinício | um banco de dados, e revogações que sobrevivem a um reinício |
| uma chave de assinatura, para sempre | chaves trocadas num calendário, com a chave pública antiga publicada até expirar o último token que ela assinou |
| HTTP puro no loopback | HTTPS em todo endpoint, já que um token numa conexão sem cifra é legível por todos no caminho (lição 13) |
| nada conta tentativas que falharam | limites de taxa (lição 12), logs de auditoria e um alerta quando um refresh token é reusado |
| nenhum jeito de revogar um token ou perguntar sobre um | o endpoint de revogação (RFC 7009) e a introspecção (RFC 7662) |

Use-o para ver como as peças se encaixam. **Nunca o ponha, nem nada que você tenha escrito do mesmo
jeito, na frente de um usuário de verdade**; a última seção desta lição diz o que usar no lugar.
