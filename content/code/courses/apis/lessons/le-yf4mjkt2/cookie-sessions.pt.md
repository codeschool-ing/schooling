---
title: Uma sessão num cookie
version: 1
---

Um login com sessão tem três passos. O cliente envia um nome e uma senha uma única vez. O servidor
os confere, grava uma linha dizendo "este id aleatório é de ana até tal hora" e devolve o id num
cabeçalho `Set-Cookie`. Daí em diante o cliente devolve o id num cabeçalho `Cookie` em toda
requisição, e o servidor acha a linha. **O id é a credencial inteira**, e não carrega informação
nenhuma: não há nada nele para ler nem para forjar, só algo para adivinhar, e 32 bytes aleatórios
não se adivinham.

## O arquivo

O `sessions.py` é isso, para o shelf. Salve-o em `~/shelf` com `nano sessions.py`, do jeito que a
aula 1 salvou o `rest.py`.

```schooling-example
{
  "language": "python",
  "file": "shelf/sessions.py",
  "parts": [
    {
      "code": "# shelf/sessions.py\n\"\"\"Signing in with a session cookie: the server remembers you in a row.\n\nRun it with `python3 sessions.py`; it answers on http://127.0.0.1:8000.\n\"\"\"\nimport hashlib\nimport hmac\nimport json\nimport secrets\nimport time\nfrom http.cookies import SimpleCookie\nfrom http.server import BaseHTTPRequestHandler, ThreadingHTTPServer\n\nimport db",
      "note": "Só a biblioteca padrão e o `db.py`, como no `rest.py`. É o `http.cookies` que lê o cabeçalho `Cookie` que o cliente devolve."
    },
    {
      "code": "\nLIFETIME = 30 * 60\n\n# The lab's two accounts. Never put a real password in a source file.\nUSERS = [(1, \"ana\", \"correct-horse\"), (2, \"bruno\", \"battery-staple\")]",
      "note": "Uma sessão dura trinta minutos, contados em segundos. As duas contas trazem a senha no arquivo só porque isto é um laboratório; a aula 10 trata de onde uma senha vai de verdade."
    },
    {
      "code": "\n\ndef scrypt(password, salt):\n    return hashlib.scrypt(password.encode(), salt=salt, n=2**14, r=8, p=1)\n\n\ndef connect():\n    \"\"\"shelf.db, with the users, sessions and wishlist tables added to it.\"\"\"\n    conn = db.connect()\n    conn.executescript(\"\"\"\n        CREATE TABLE IF NOT EXISTS users (\n            id   INTEGER PRIMARY KEY,\n            name TEXT NOT NULL UNIQUE,\n            salt BLOB NOT NULL,\n            hash BLOB NOT NULL);\n        CREATE TABLE IF NOT EXISTS sessions (\n            id_hash TEXT PRIMARY KEY,\n            user_id INTEGER NOT NULL REFERENCES users (id),\n            csrf    TEXT NOT NULL,\n            expires INTEGER NOT NULL);\n        CREATE TABLE IF NOT EXISTS wishlist (\n            user_id INTEGER NOT NULL REFERENCES users (id),\n            book_id INTEGER NOT NULL REFERENCES books (id),\n            PRIMARY KEY (user_id, book_id));\n    \"\"\")\n    if conn.execute(\"SELECT count(*) FROM users\").fetchone()[0] == 0:\n        for ident, name, password in USERS:\n            salt = secrets.token_bytes(16)\n            conn.execute(\"INSERT INTO users VALUES (?, ?, ?, ?)\",\n                         (ident, name, salt, scrypt(password, salt)))\n        conn.commit()\n    return conn",
      "note": "Três tabelas se juntam às duas que o `db.py` criou, cada uma criada só se ainda não existir. Uma senha fica guardada como um sal aleatório e o scrypt da senha com esse sal, **nunca como ela mesma**. O `hashlib.scrypt` está na biblioteca padrão, e a aula 10 o compara com bcrypt e Argon2."
    },
    {
      "code": "\n\ndef check_login(conn, name, password):\n    \"\"\"The user's id, or None. A name nobody has costs the same as a wrong password.\"\"\"\n    row = conn.execute(\"SELECT id, salt, hash FROM users WHERE name = ?\", (name,)).fetchone()\n    if row is None:\n        scrypt(password, bytes(16))\n        return None\n    return row[\"id\"] if hmac.compare_digest(scrypt(password, row[\"salt\"]), row[\"hash\"]) else None\n\n\ndef digest(token):\n    return hashlib.sha256(token.encode()).hexdigest()",
      "note": "Um nome que ninguém tem ainda custa um scrypt, então nome errado e senha errada levam o mesmo tempo e recebem a mesma resposta; do contrário o formulário de login conta a um estranho quem tem conta. `digest` é SHA-256, aplicado a todo token aleatório antes de ele tocar o banco."
    },
    {
      "code": "\n\nclass Handler(BaseHTTPRequestHandler):\n    \"\"\"Reading requests and writing answers, the way rest.py does.\"\"\"\n    protocol_version = \"HTTP/1.1\"\n\n    def parse_request(self):\n        if not super().parse_request():\n            return False\n        self.raw = self.rfile.read(int(self.headers.get(\"Content-Length\") or 0))\n        return True\n\n    def reply(self, status, value=None, headers=()):\n        body = b\"\" if value is None else (json.dumps(value, ensure_ascii=False) + \"\\n\").encode()\n        self.send_response(status)\n        if value is not None:\n            self.send_header(\"Content-Type\", \"application/json\")\n        self.send_header(\"Content-Length\", str(len(body)))\n        for name, val in headers:\n            self.send_header(name, val)\n        self.end_headers()\n        self.wfile.write(body)\n\n    def error(self, status, message, headers=()):\n        self.reply(status, {\"error\": message}, headers)\n\n    def body(self):\n        \"\"\"The request's JSON object, or None after answering 415 or 400.\"\"\"\n        if self.headers.get(\"Content-Type\", \"\").split(\";\")[0] != \"application/json\":\n            self.error(415, \"send application/json\")\n            return None\n        try:\n            value = json.loads(self.raw)\n        except ValueError:\n            value = None\n        if not isinstance(value, dict):\n            self.error(400, \"the body must be a JSON object\")\n            return None\n        return value\n\n    def login(self, conn):\n        \"\"\"The user id for the name and password in the body, or None after answering.\"\"\"\n        value = self.body()\n        if value is None:\n            return None\n        user = check_login(conn, str(value.get(\"name\", \"\")), str(value.get(\"password\", \"\")))\n        if user is None:\n            self.error(401, \"wrong name or password\")\n        return user",
      "note": "O encanamento que o `rest.py` já tem: ler a requisição inteira, responder com o tamanho, ler um corpo JSON. `login` acrescenta a verificação de cima e responde **401** quando ela falha. O `tokens.py` reaproveita esta classe inteira."
    },
    {
      "code": "\n\nclass Sessions(Handler):\n\n    def session(self, conn):\n        \"\"\"The live session named by the request's cookie, or None.\"\"\"\n        cookie = SimpleCookie(self.headers.get(\"Cookie\", \"\"))\n        if \"sid\" not in cookie:\n            return None\n        return conn.execute(\n            \"SELECT s.id_hash, s.user_id, s.csrf, u.name FROM sessions s\"\n            \" JOIN users u ON u.id = s.user_id WHERE s.id_hash = ? AND s.expires > ?\",\n            (digest(cookie[\"sid\"].value), int(time.time()))).fetchone()\n\n    def do_GET(self):\n        if self.path not in (\"/me\", \"/wishlist\"):\n            return self.error(404, \"no such resource\")\n        with connect() as conn:\n            s = self.session(conn)\n            if s is None:\n                return self.error(401, \"sign in first\")\n            if self.path == \"/me\":\n                return self.reply(200, {\"name\": s[\"name\"], \"csrf\": s[\"csrf\"]})\n            rows = conn.execute(\"SELECT b.id, b.title FROM wishlist w JOIN books b ON b.id = w.book_id\"\n                                \" WHERE w.user_id = ? ORDER BY b.id\", (s[\"user_id\"],)).fetchall()\n            return self.reply(200, [dict(row) for row in rows])",
      "note": "A sessão é procurada pelo **hash** do valor do cookie, e só enquanto `expires` estiver no futuro. O próprio servidor impõe os trinta minutos, faça o cliente o que fizer com o `Max-Age`. `/me` diz quem você é e devolve o token CSRF da sessão."
    },
    {
      "code": "\n    def do_POST(self):\n        if self.path not in (\"/login\", \"/logout\", \"/wishlist\"):\n            return self.error(404, \"no such resource\")\n        with connect() as conn:\n            if self.path == \"/login\":\n                user = self.login(conn)\n                if user is None:\n                    return\n                sid = secrets.token_urlsafe(32)\n                conn.execute(\"INSERT INTO sessions VALUES (?, ?, ?, ?)\",\n                             (digest(sid), user, secrets.token_urlsafe(32), int(time.time()) + LIFETIME))\n                cookie = f\"sid={sid}; Path=/; Max-Age={LIFETIME}; HttpOnly; Secure; SameSite=Lax\"\n                return self.reply(204, headers=[(\"Set-Cookie\", cookie)])",
      "note": "Um login certo gera um id aleatório novo a partir de 32 bytes do `secrets`, guarda o hash dele com o usuário, um token CSRF e um vencimento, e envia o id em si uma única vez, no `Set-Cookie`. O id é novo a cada login, e nunca um que o cliente tenha proposto."
    },
    {
      "code": "            s = self.session(conn)\n            if s is None:\n                return self.error(401, \"sign in first\")\n            sent = self.headers.get(\"X-CSRF-Token\", \"\").encode()\n            if not hmac.compare_digest(sent, s[\"csrf\"].encode()):\n                return self.error(403, \"missing or wrong X-CSRF-Token\")\n            if self.path == \"/logout\":\n                conn.execute(\"DELETE FROM sessions WHERE id_hash = ?\", (s[\"id_hash\"],))\n                gone = \"sid=; Path=/; Max-Age=0; HttpOnly; Secure; SameSite=Lax\"\n                return self.reply(204, headers=[(\"Set-Cookie\", gone)])\n            value = self.body()\n            if value is None:\n                return\n            if conn.execute(\"SELECT 1 FROM books WHERE id = ?\", (value.get(\"book_id\"),)).fetchone() is None:\n                return self.error(422, \"no such book\")\n            conn.execute(\"INSERT OR IGNORE INTO wishlist VALUES (?, ?)\", (s[\"user_id\"], value[\"book_id\"]))\n            return self.reply(201, {\"book_id\": value[\"book_id\"]})",
      "note": "Todo outro `POST` precisa de uma sessão viva **e** do token dessa sessão em `X-CSRF-Token`, ou recebe 403. O logout apaga a linha e manda o cliente descartar o cookie com `Max-Age=0`. A lista de desejos existe para haver algo que uma requisição forjada poderia mudar."
    },
    {
      "code": "\n\nif __name__ == \"__main__\":\n    server = ThreadingHTTPServer((\"127.0.0.1\", 8000), Sessions)\n    print(\"sessions on http://127.0.0.1:8000\", flush=True)\n    server.serve_forever()",
      "note": "O mesmo endereço do `rest.py`, então só um dos dois roda de cada vez."
    }
  ]
}
```

Se o `rest.py` ainda estiver rodando no segundo terminal, pare-o com `Ctrl+C`; depois inicie este
no lugar dele:

```sh
cd ~/shelf && python3 sessions.py
```

## Entrando

O curl não lembra de cookies a menos que peçam. `-c jar.txt` grava num arquivo cada cookie que o
servidor define, o **pote de cookies**, e `-b jar.txt` os devolve. Entre como ana, com `-i` para ver
os cabeçalhos:

```
ana@api:~/shelf$ curl -si -c jar.txt localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-horse"}'
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:06 GMT
Content-Length: 0
Set-Cookie: sid=kr6NIl3Zl2MI3d3XSey1PcqabSRq9R3JpTLrnPuvQB0; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax
```

Não há corpo: o **204** diz que deu certo, e a resposta é o cabeçalho. O cookie é um nome e um
valor, `sid` e 43 caracteres de base64url, seguidos de **atributos** que dizem ao cliente como
tratá-lo. Nenhum deles volta para o servidor; são instruções, e cada um fecha uma porta específica.

| atributo | o que diz ao cliente | sem ele |
|---|---|---|
| `Path=/` | enviá-lo nas requisições a qualquer caminho deste host | o cliente escolhe um padrão pelo endereço que o definiu, e um login em `/v1/login` ganharia um cookie só para `/v1` |
| `Max-Age=1800` | esquecê-lo depois de 1800 segundos | ele dura até o navegador fechar, e um navegador que restaura as abas nunca fecha de verdade |
| `HttpOnly` | nunca mostrá-lo ao JavaScript da página | qualquer script na página o lê, inclusive um que um atacante injetou |
| `Secure` | enviá-lo só por HTTPS | ele passa também por HTTP puro, legível por qualquer um no caminho da rede |
| `SameSite=Lax` | deixá-lo fora de requisições que outros sites iniciam, exceto ao seguir um link | a página de outro site consegue fazer o navegador enviá-lo; a seção sobre CSRF |

**Falta um atributo de propósito.** Sem `Domain`, o cookie pertence exatamente a este host e não vai
para os subdomínios. `Domain=example.com` o compartilharia com todo `*.example.com`, inclusive um
que outra pessoa administra.

O `Max-Age` é um pedido ao cliente, e um cliente pode ignorá-lo, manter o cookie ou copiá-lo para
algum lugar. Por isso o `sessions.py` guarda o próprio vencimento na linha, e recusa um id passado
desse horário, diga o cookie o que disser. A regra que atravessa a aula inteira começa aqui: **o
servidor impõe; os atributos só ajudam um cliente bem-comportado.**

## O pote

O pote é um arquivo de texto no formato que o navegador da Netscape usava, um cookie por linha:

```
ana@api:~/shelf$ cat jar.txt
# Netscape HTTP Cookie File
# https://curl.se/docs/http-cookies.html
# This file was generated by libcurl! Edit at your own risk.

#HttpOnly_localhost	FALSE	/	TRUE	1791608466	sid	kr6NIl3Zl2MI3d3XSey1PcqabSRq9R3JpTLrnPuvQB0
```

As colunas são o host, se os subdomínios o recebem (`FALSE`, porque não havia `Domain`), o caminho,
se ele é `Secure` (`TRUE`), o vencimento em segundos desde 1970, o nome e o valor. O curl registra o
`HttpOnly` pondo `#HttpOnly_` na frente do host, de modo que uma ferramenta que lê só as linhas não
comentadas pula o cookie. Um navegador guarda os mesmos dados num banco próprio.

Com o pote o servidor sabe quem você é; sem ele, não sabe:

```
ana@api:~/shelf$ curl -s -b jar.txt localhost:8000/me
{"name": "ana", "csrf": "3xdPJTXc4XNCVCO8j9gEGxoTFXcXxxhjLgoIzjnqxJ4"}
ana@api:~/shelf$ curl -si localhost:8000/me
HTTP/1.1 401 Unauthorized
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:06 GMT
Content-Type: application/json
Content-Length: 27

{"error": "sign in first"}
```

O `/me` também devolveu um valor `csrf`, que a seção sobre requisições entre sites usa.

## A linha

A metade do servidor é uma linha no `shelf.db`:

```
ana@api:~/shelf$ sqlite3 shelf.db 'SELECT id_hash, user_id, expires FROM sessions'
e9a4c1c74f4a350137338bca3bc868f54e4db4175ea6a12b689e8c4d9725c341|1|1791608466
```

**A tabela não guarda o id, guarda o SHA-256 do id.** Faça o hash do valor que está no pote e você
obtém os mesmos 64 caracteres hexadecimais:

```
ana@api:~/shelf$ awk '$6 == "sid" {printf "%s", $7}' jar.txt | sha256sum
e9a4c1c74f4a350137338bca3bc868f54e4db4175ea6a12b689e8c4d9725c341  -
```

O servidor ainda acha a linha, fazendo o hash do cookie que recebe. O que ele não tem mais é o id
em si, então uma cópia do banco, um backup que alguém esqueceu numa pasta compartilhada por exemplo,
dá a quem a lê linhas e nenhum cookie que funcione. SHA-256 basta aqui, enquanto a aula 10 vai
exigir algo bem mais lento para senhas: um id de sessão são 32 bytes aleatórios, e não existe lista
de valores prováveis para testar.

## Duas recusas

`Secure` quer dizer o que diz. O curl trata `localhost` como seguro mesmo por HTTP puro, como os
navegadores fazem, e é por isso que o pote acima tem o cookie. Peça o mesmo servidor por outro nome,
que o `--resolve` aponta para esta máquina, e o cookie `Secure` chega por HTTP puro e é descartado:

```
ana@api:~/shelf$ curl -si -c shop.txt --resolve shop.test:8000:127.0.0.1 http://shop.test:8000/login -H 'Content-Type: application/json' -d '{"name": "bruno", "password": "battery-staple"}'
HTTP/1.1 204 No Content
Server: BaseHTTP/0.6 Python/3.12.3
Date: Sat, 10 Oct 2026 04:31:06 GMT
Content-Length: 0
Set-Cookie: sid=2lZcbYKu970J_2qU4i1hI-Ui5REr-bVd2nH6VOOKQrM; Path=/; Max-Age=1800; HttpOnly; Secure; SameSite=Lax

ana@api:~/shelf$ cat shop.txt
# Netscape HTTP Cookie File
# https://curl.se/docs/http-cookies.html
# This file was generated by libcurl! Edit at your own risk.
```

O pote está vazio. O servidor definiu o cookie; o cliente se recusou a guardá-lo.

E uma senha errada e um nome que ninguém tem recebem **a mesma resposta**, então o formulário de
login não serve para descobrir quem tem conta. O `check_login` também gasta um scrypt com o nome
desconhecido, para que os dois levem o mesmo tempo:

```
ana@api:~/shelf$ curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "ana", "password": "correct-hors"}'
{"error": "wrong name or password"}
ana@api:~/shelf$ curl -s localhost:8000/login -H 'Content-Type: application/json' -d '{"name": "anna", "password": "correct-horse"}'
{"error": "wrong name or password"}
```
