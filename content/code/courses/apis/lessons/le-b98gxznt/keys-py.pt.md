---
title: keys.py, os livros atrás de uma porta
version: 1
---

Esta aula põe os livros do `shelf` atrás de três tipos de credencial ao mesmo tempo, num arquivo novo,
o `keys.py`. É um segundo servidor, e não uma mudança no `rest.py`, então a API da aula 1 continua
como era. Ele não precisa de nada além do `db.py` e do banco ao lado: se você terminou a aula 1, tem
tudo o que ele usa.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 330\" role=\"img\" aria-label=\"Três colunas, uma por esquema. O Basic envia Authorization: Basic com o nome e a senha em base64 a cada requisição, identifica uma pessoa, e o shelf.db guarda um hash scrypt da senha. Um token bearer vai como Authorization: Bearer depois de um login, identifica uma pessoa, e o shelf.db guarda o SHA-256 do token com uma validade. Uma chave de API vai como X-API-Key a cada requisição, identifica uma aplicação, e o shelf.db guarda o prefixo visível e o SHA-256 da chave.\"><text x=\"20\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">enviado</text><text x=\"20\" y=\"130\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">quando</text><text x=\"20\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">identifica</text><text x=\"20\" y=\"258\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">o shelf.db</text><text x=\"20\" y=\"272\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">guarda</text><rect x=\"105\" y=\"15\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Basic</text><rect x=\"300\" y=\"15\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Token bearer</text><rect x=\"495\" y=\"15\" width=\"180\" height=\"30\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"30.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Chave de API</text><rect x=\"105\" y=\"50\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization:</text><text x=\"195.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Basic YW5h…</text><rect x=\"300\" y=\"50\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Authorization:</text><text x=\"390.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">Bearer &lt;token&gt;</text><rect x=\"495\" y=\"50\" width=\"180\" height=\"40\" rx=\"5\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"63.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">X-API-Key:</text><text x=\"585.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shelf_&lt;id&gt;_&lt;secret&gt;</text><text x=\"195\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a cada requisição</text><text x=\"195\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma pessoa</text><text x=\"390\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">depois de um login</text><text x=\"390\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma pessoa</text><text x=\"585\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a cada requisição</text><text x=\"585\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma aplicação</text><rect x=\"105\" y=\"235\" width=\"180\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"195.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">hash scrypt</text><text x=\"195.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">da senha, lento</text><rect x=\"300\" y=\"235\" width=\"180\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"390.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SHA-256</text><text x=\"390.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">do token, e uma validade</text><rect x=\"495\" y=\"235\" width=\"180\" height=\"60\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">prefixo + SHA-256</text><text x=\"585.0\" y=\"273.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">da chave, e um nome</text><text x=\"390\" y=\"315\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">nunca o próprio segredo</text></svg>", "caption": "Três portas para os mesmos livros. O que viaja muda, quem é identificado muda, e o que fica guardado nunca é o que viajou.", "same": ["Basic", "SHA-256"]}
```

**Cada esquema envia uma coisa diferente, e o servidor guarda uma coisa diferente para cada um.** É a
aula inteira num desenho, e cada coluna tem uma seção própria mais adiante. O que elas têm em comum é
a última linha: o que quer que o cliente envie, o `shelf.db` nunca guarda do jeito que chegou.

Salve o arquivo como `~/shelf/keys.py` com o `nano`, do jeito que a aula 1 salvou o `rest.py`:

```schooling-example
{
  "language": "python",
  "file": "shelf/keys.py",
  "parts": [
    {
      "code": "# shelf/keys.py\n\"\"\"The books behind three kinds of credential: Basic, bearer tokens and API keys.\n\nAdd a user with `python3 keys.py adduser NAME`, then run `python3 keys.py`;\nit answers on http://127.0.0.1:8000.\n\"\"\"\nimport base64\nimport getpass\nimport hashlib\nimport hmac\nimport json\nimport re\nimport secrets\nimport sys\nimport time\nfrom datetime import datetime, timezone\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport db",
      "note": "Só a biblioteca padrão, como o `rest.py`. `hashlib`, `hmac` e `secrets` são os três módulos que fazem o trabalho desta aula: calcular hashes, comparar e sortear valores aleatórios."
    },
    {
      "code": "\nTABLES = \"\"\"\nCREATE TABLE IF NOT EXISTS users (\n    id       INTEGER PRIMARY KEY,\n    username TEXT NOT NULL UNIQUE,\n    password_hash TEXT NOT NULL\n);\nCREATE TABLE IF NOT EXISTS tokens (\n    hash    TEXT PRIMARY KEY,\n    user_id INTEGER NOT NULL REFERENCES users (id),\n    expires INTEGER NOT NULL\n);\nCREATE TABLE IF NOT EXISTS api_keys (\n    prefix    TEXT PRIMARY KEY,\n    hash      TEXT NOT NULL,\n    name      TEXT NOT NULL,\n    created   TEXT NOT NULL,\n    last_used TEXT\n);\n\"\"\"\nTOKEN_SECONDS = 3600\n\n\ndef connect():\n    conn = db.connect()\n    conn.executescript(TABLES)\n    return conn",
      "note": "Três tabelas, criadas ao lado dos livros no `shelf.db` se ainda não existirem. **Nenhuma coluna guarda um segredo como ele foi enviado**: a senha fica como hash scrypt, o token e a chave como SHA-256. Um token vale por uma hora."
    },
    {
      "code": "\n\ndef scrypt(password, salt):\n    return hashlib.scrypt(password.encode(), salt=salt, n=2**14, r=8, p=1, dklen=32)\n\n\ndef hash_password(password):\n    salt = secrets.token_bytes(16)\n    return f\"scrypt${salt.hex()}${scrypt(password, salt).hex()}\"\n\n\nDECOY = hash_password(secrets.token_hex(16))\n\n\ndef check_password(username, password):\n    \"\"\"The user's id if the password is theirs, otherwise None, in the same time.\"\"\"\n    with connect() as conn:\n        row = conn.execute(\"SELECT id, password_hash FROM users WHERE username = ?\",\n                           (username,)).fetchone()\n    _, salt, stored = (row[\"password_hash\"] if row else DECOY).split(\"$\")\n    same = hmac.compare_digest(scrypt(password, bytes.fromhex(salt)).hex(), stored)\n    return row[\"id\"] if row and same else None",
      "note": "A conferência da senha. O scrypt é lento de propósito, e a aula 10 trata de escolhê-lo e de escolher os números dele. `DECOY` é o hash da senha de ninguém: um usuário que não existe é conferido contra ele, e a resposta leva o mesmo tempo nos dois casos."
    },
    {
      "code": "\n\ndef sha256(secret):\n    return hashlib.sha256(secret.encode()).hexdigest()\n\n\ndef now():\n    return datetime.now(timezone.utc).strftime(\"%Y-%m-%dT%H:%M:%SZ\")",
      "note": "Um token e uma chave são sequências aleatórias longas, não palavras que alguém escolheu, e por isso um hash rápido basta. `now` escreve datas em UTC."
    },
    {
      "code": "\n\nclass Keys(BaseHTTPRequestHandler):\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True\n\n    def reply(self, status, value=None, headers=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)",
      "note": "O mesmo começo do `rest.py`: ler a requisição inteira primeiro e responder sempre por um único `reply`."
    },
    {
      "code": "\n    def audit(self, line):\n        sys.stderr.write(f\"auth: {line}\\n\")\n\n    def refuse(self, message=\"authentication required\", bearer_error=None):\n        bearer = 'Bearer realm=\"shelf\"'\n        if bearer_error:\n            bearer += f', error=\"{bearer_error}\"'\n        self.reply(401, {\"error\": message},\n                   [(\"WWW-Authenticate\", 'Basic realm=\"shelf\"'), (\"WWW-Authenticate\", bearer)])",
      "note": "`audit` escreve uma linha por decisão no terminal do servidor. `refuse` é todo **401** que este arquivo envia, e todos levam um `WWW-Authenticate` para cada esquema que a API aceita."
    },
    {
      "code": "\n    def who(self):\n        \"\"\"(kind, name) for the credential on this request, or None after answering 401.\"\"\"\n        key = self.headers.get(\"X-API-Key\")\n        if key is not None:\n            return self.by_key(key)\n        scheme, _, credentials = self.headers.get(\"Authorization\", \"\").partition(\" \")\n        if scheme.lower() == \"basic\":\n            return self.by_password(credentials)\n        if scheme.lower() == \"bearer\":\n            return self.by_token(credentials)\n        self.refuse()\n        return None",
      "note": "Qual credencial veio na requisição. Um cabeçalho `X-API-Key` é uma chave; senão, a palavra do esquema em `Authorization` decide. Nenhuma credencial é um 401."
    },
    {
      "code": "\n    def by_password(self, credentials):\n        try:\n            username, _, password = base64.b64decode(credentials, validate=True).decode().partition(\":\")\n        except ValueError:\n            username, password = \"\", \"\"\n        if check_password(username, password) is None:\n            self.audit(f\"basic refused user={username!r}\")\n            self.refuse()\n            return None\n        self.audit(f\"basic ok user={username!r}\")\n        return \"person\", username",
      "note": "**Basic**: o base64 decodificado de volta em nome e senha, e a senha conferida a cada requisição."
    },
    {
      "code": "\n    def by_token(self, token):\n        with connect() as conn:\n            row = conn.execute(\"SELECT username, expires FROM tokens JOIN users ON users.id = user_id\"\n                               \" WHERE hash = ?\", (sha256(token),)).fetchone()\n            if row and row[\"expires\"] <= time.time():\n                conn.execute(\"DELETE FROM tokens WHERE hash = ?\", (sha256(token),))\n                row = None\n        if row is None:\n            self.audit(f\"bearer refused token={sha256(token)[:8]}\")\n            self.refuse(\"invalid or expired token\", \"invalid_token\")\n            return None\n        self.audit(f\"bearer ok user={row['username']!r}\")\n        return \"person\", row[\"username\"]",
      "note": "**Bearer**: o token vira hash e é procurado. Uma linha vencida é apagada na hora e tratada como inexistente."
    },
    {
      "code": "\n    def by_key(self, key):\n        m = re.fullmatch(r\"(shelf_[0-9a-f]{8})_[\\w-]{43}\", key)\n        with connect() as conn:\n            row = conn.execute(\"SELECT hash, name FROM api_keys WHERE prefix = ?\",\n                               (m.group(1) if m else \"\",)).fetchone()\n            if row and hmac.compare_digest(row[\"hash\"], sha256(key)):\n                conn.execute(\"UPDATE api_keys SET last_used = ? WHERE prefix = ?\", (now(), m.group(1)))\n                self.audit(f\"key ok prefix={m.group(1)}\")\n                return \"application\", row[\"name\"]\n        self.audit(f\"key refused prefix={m.group(1) if m else '?'}\")\n        self.refuse()\n        return None",
      "note": "**Chave de API**: o prefixo visível encontra a linha, `compare_digest` compara os hashes, e `last_used` registra que a chave continua em uso."
    },
    {
      "code": "\n    def person(self):\n        \"\"\"The username, or None after answering 401 or 403.\"\"\"\n        who = self.who()\n        if who and who[0] != \"person\":\n            self.reply(403, {\"error\": \"an API key cannot manage keys\"})\n            return None\n        return who and who[1]",
      "note": "Gerenciar chaves é coisa de pessoa. Uma chave que pede isso recebe **403**: o servidor sabe quem ela é e diz não."
    },
    {
      "code": "\n    def do_GET(self):\n        path = self.path.split(\"?\")[0]\n        if path == \"/v1/keys\":\n            if self.person():\n                with connect() as conn:\n                    rows = conn.execute(\"SELECT prefix, name, created, last_used FROM api_keys\"\n                                        \" ORDER BY created\").fetchall()\n                self.reply(200, [dict(row) for row in rows])\n            return\n        m = re.fullmatch(r\"/v1/(whoami|books|books/(\\d+))\", path)\n        if not m:\n            return self.reply(404, {\"error\": \"no such resource\"})\n        who = self.who()\n        if who is None:\n            return\n        if m.group(1) == \"whoami\":\n            return self.reply(200, {\"kind\": who[0], \"name\": who[1]})\n        with db.connect() as conn:\n            if m.group(2):\n                row = conn.execute(\"SELECT id, title, stock FROM books WHERE id = ?\",\n                                   (m.group(2),)).fetchone()\n                return self.reply(200, dict(row)) if row else self.reply(404, {\"error\": \"no such book\"})\n            rows = conn.execute(\"SELECT id, title, stock FROM books ORDER BY id\").fetchall()\n        self.reply(200, [dict(row) for row in rows])",
      "note": "Leitura. `/v1/whoami` diz quem o servidor acha que você é; os livros respondem com três campos cada, o suficiente para ver que a porta abriu."
    },
    {
      "code": "\n    def do_POST(self):\n        if self.path == \"/v1/login\":\n            try:\n                value = json.loads(self.raw)\n                user = check_password(str(value[\"username\"]), str(value[\"password\"]))\n            except (ValueError, KeyError, TypeError):\n                return self.reply(400, {\"error\": \"send username and password as JSON\"})\n            if user is None:\n                self.audit(f\"login refused user={value['username']!r}\")\n                return self.refuse(\"wrong username or password\")\n            token = secrets.token_urlsafe(32)\n            expires = int(time.time()) + TOKEN_SECONDS\n            with connect() as conn:\n                conn.execute(\"INSERT INTO tokens VALUES (?, ?, ?)\", (sha256(token), user, expires))\n            self.audit(f\"login ok user={value['username']!r}\")\n            return self.reply(200, {\"token\": token, \"expires_in\": TOKEN_SECONDS})\n        if self.path == \"/v1/logout\":\n            scheme, _, token = self.headers.get(\"Authorization\", \"\").partition(\" \")\n            with connect() as conn:\n                gone = conn.execute(\"DELETE FROM tokens WHERE hash = ?\", (sha256(token),)).rowcount\n            if scheme.lower() == \"bearer\" and gone:\n                return self.reply(204)\n            return self.refuse(\"invalid or expired token\", \"invalid_token\")\n        if self.path == \"/v1/keys\":\n            if not self.person():\n                return\n            try:\n                name = str(json.loads(self.raw)[\"name\"])\n            except (ValueError, KeyError, TypeError):\n                return self.reply(400, {\"error\": \"send the key's name as JSON\"})\n            prefix = \"shelf_\" + secrets.token_hex(4)\n            key = f\"{prefix}_{secrets.token_urlsafe(32)}\"\n            with connect() as conn:\n                conn.execute(\"INSERT INTO api_keys (prefix, hash, name, created) VALUES (?, ?, ?, ?)\",\n                             (prefix, sha256(key), name, now()))\n            return self.reply(201, {\"key\": key, \"prefix\": prefix, \"name\": name,\n                                    \"note\": \"shown once: store it now\"})\n        self.reply(404, {\"error\": \"no such resource\"})",
      "note": "Três escritas. `/v1/login` troca uma senha por um token, `/v1/logout` apaga a linha do token, e `/v1/keys` cria uma chave e a mostra esta única vez."
    },
    {
      "code": "\n    def do_DELETE(self):\n        m = re.fullmatch(r\"/v1/keys/(shelf_[0-9a-f]{8})\", self.path)\n        if not m:\n            return self.reply(404, {\"error\": \"no such resource\"})\n        if self.person():\n            with connect() as conn:\n                gone = conn.execute(\"DELETE FROM api_keys WHERE prefix = ?\", (m.group(1),)).rowcount\n            if gone:\n                return self.reply(204)\n            self.reply(404, {\"error\": \"no such key\"})",
      "note": "Revogar uma chave é apagar a linha dela, pelo prefixo."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    if sys.argv[1:2] == [\"adduser\"]:\n        name = sys.argv[2]\n        password = getpass.getpass() if sys.stdin.isatty() else sys.stdin.readline().rstrip(\"\\n\")\n        with connect() as conn:\n            conn.execute(\"INSERT INTO users (username, password_hash) VALUES (?, ?)\",\n                         (name, hash_password(password)))\n        print(f\"user {name} added\")\n    else:\n        server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Keys)\n        print(\"keys on http://127.0.0.1:8000\", flush=True)\n        server.serve_forever()",
      "note": "`adduser` grava um usuário. Num terminal, pede a senha sem mostrá-la; vindo de um pipe, lê uma linha. Qualquer outra coisa sobe o servidor."
    }
  ]
}
```

## Rodando

O `keys.py` escuta na mesma porta que o `rest.py`, então pare antes o `rest.py` no segundo terminal
com `Ctrl+C`. Depois, no primeiro terminal, crie um usuário. O arquivo não tem página de cadastro, e
por isso um usuário é criado pela linha de comando:

```
ana@api:~/shelf$ ls
db.py
keys.py
rest.py
ana@api:~/shelf$ printf 'river-lamp-42\n' | python3 keys.py adduser ana
user ana added
```

Digitado num terminal, `python3 keys.py adduser ana` pede `Password:` e não mostra nada enquanto você
digita. A captura acima manda a senha por um pipe, porque uma gravação não tem teclado; no seu
terminal, deixe o `printf` de fora. Depois veja o que foi guardado:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT * FROM users'
1|ana|scrypt$0091e3c7013068c5f51c65cd7361c6a4$cd3175e0712e0adab9db597d995ed63cf962848cd76bc98857b40f785ad0a501
```

**Essa linha não pode ser transformada de volta em `river-lamp-42`.** São três campos unidos por `$`:
o nome da função, um sal aleatório e o resultado. Conferir uma senha é rodar a mesma função sobre o
que alguém envia, com o mesmo sal, e comparar os resultados. Por que a função é o scrypt, por que o sal
está ali e o quanto ela deve ser lenta é assunto da aula 10; aqui ela é uma caixa que recebe uma senha
e responde sim ou não.

Agora suba o servidor no segundo terminal:

```sh
cd ~/shelf && python3 keys.py
```

Ele imprime `keys on http://127.0.0.1:8000` e, como o `rest.py`, uma linha por requisição. Também
imprime uma linha começando com `auth:` para cada decisão que toma sobre uma credencial; a seção sobre
não dizer nada lê essas linhas.
