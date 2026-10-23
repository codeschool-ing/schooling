---
title: Os cabeçalhos, o teste que os mantém, e um falso positivo
version: 1
---

A varredura disse que faltam três cabeçalhos. A correção são três linhas, e a ordem é a de sempre no
curso: **um teste que falha porque o defeito está ali, depois a mudança, depois o mesmo teste
passando.** A varredura não é esse teste. Ela roda uma vez por dia, leva uns vinte segundos e relata
uma URL. Um teste unitário roda em todo push, em menos de um segundo, e o nome dele diz o que
quebrou.

### Primeiro o teste

O teste novo pede a página inicial e confere os três cabeçalhos. Salve o arquivo como
`tests/test_app.py`:

```python
import pytest

from app import app
from settings import ADMIN_TOKEN


@pytest.fixture
def client(tmp_path, monkeypatch):
    monkeypatch.setattr("app.DATABASE", str(tmp_path / "test.db"))
    return app.test_client()


def test_create_needs_the_token(client):
    assert client.post("/links", data={"url": "https://example.org"}).status_code == 401


def test_a_link_redirects(client):
    made = client.post("/links", data={"url": "https://example.org/a"},
                       headers={"X-Token": ADMIN_TOKEN})
    assert made.status_code == 201
    code = made.get_json()["code"]
    followed = client.get(f"/{code}")
    assert followed.status_code == 302
    assert followed.headers["Location"] == "https://example.org/a"


def test_search_finds_a_link(client):
    client.post("/links", data={"url": "https://example.org/docs"},
                headers={"X-Token": ADMIN_TOKEN})
    page = client.get("/search?q=docs")
    assert page.status_code == 200
    assert b"https://example.org/docs" in page.data


def test_search_survives_a_quote(client):
    client.post("/links", data={"url": "https://example.org/it's-here"},
                headers={"X-Token": ADMIN_TOKEN})
    page = client.get("/search?q=it's")
    assert page.status_code == 200
    assert b"it&#39;s-here" in page.data


def test_every_answer_carries_the_headers(client):
    page = client.get("/")
    assert page.headers["X-Content-Type-Options"] == "nosniff"
    assert page.headers["X-Frame-Options"] == "DENY"
    assert "frame-ancestors 'none'" in page.headers["Content-Security-Policy"]
```

O teste falha no código da aula 3, e essa é a prova de que ele testa alguma coisa:

```
ana@vm:~/linkbox$ uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q --tb=short
....F                                                                    [100%]
=================================== FAILURES ===================================
____________________ test_every_answer_carries_the_headers _____________________
tests/test_app.py:45: in test_every_answer_carries_the_headers
    assert page.headers["X-Content-Type-Options"] == "nosniff"
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
.venv/lib/python3.13/site-packages/werkzeug/datastructures/headers.py:72: in __getitem__
    raise BadRequestKeyError(key)
E   werkzeug.exceptions.BadRequestKeyError: 400 Bad Request: The browser (or proxy) sent a request that this server could not understand.
=========================== short test summary info ============================
FAILED tests/test_app.py::test_every_answer_carries_the_headers - werkzeug.ex...
1 failed, 4 passed in 0.42s
```

`BadRequestKeyError` é o tipo de `KeyError` do próprio Werkzeug: a resposta não tem
`X-Content-Type-Options` nenhum, então lê-lo levanta a exceção antes de a comparação acontecer.

### A correção

Uma função, registrada com `after_request`, acrescenta os cabeçalhos a toda resposta. Salve o
arquivo como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "\"\"\"linkbox: short links for a small team, kept in one SQLite file.\"\"\"\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, redirect, render_template_string, request\n\nfrom settings import ADMIN_TOKEN, DATABASE\n\napp = Flask(__name__)\n", "note": "O serviço da aula 3, sem mudança até o template da página."}, {"code": "PAGE = \"\"\"<!doctype html>\n<title>linkbox</title>\n<form action=\"/search\"><input name=\"q\" value=\"{{ q }}\"><button>Search</button></form>\n<ul>{% for code, url in rows %}<li><a href=\"/{{ code }}\">{{ code }}</a> {{ url }}</li>{% endfor %}</ul>\n\"\"\"\n\n", "note": "A caixa de busca escreve o texto digitado de volta no atributo `value` do input. O Jinja o escapa no caminho, e é isso que decide o alerta que o ZAP ainda levanta depois da correção."}, {"code": "def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(DATABASE)\n        g.db.execute(\"CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT)\")\n    return g.db\n\n"}, {"code": "@app.after_request\ndef security_headers(response):", "note": "A parte nova. O Flask chama uma função `after_request` em toda resposta que envia, os 404 inclusive, então nenhuma rota precisa se lembrar dos cabeçalhos, e uma rota criada no ano que vem também os recebe."}, {"code": "    response.headers[\"Content-Security-Policy\"] = (\n        \"default-src 'none'; form-action 'self'; frame-ancestors 'none'\"\n    )", "note": "A política: nada carrega sem uma diretiva que permita. A página não usa script, estilo nem imagem, então o padrão é `'none'`; o formulário de busca só pode enviar para esta origem; e nenhuma outra página pode pôr esta num frame. A aula 8 de `secure-code` ensina as diretivas."}, {"code": "    response.headers[\"X-Content-Type-Options\"] = \"nosniff\"", "note": "O navegador deve acreditar no `Content-Type` que o servidor manda, em vez de adivinhar um pelos bytes."}, {"code": "    response.headers[\"X-Frame-Options\"] = \"DENY\"\n    return response\n\n", "note": "O cabeçalho mais antigo que recusa frames, para navegadores que não leem `frame-ancestors`."}, {"code": "@app.teardown_appcontext\ndef close_db(_):\n    conn = g.pop(\"db\", None)\n    if conn is not None:\n        conn.close()\n\n\ndef require_token():\n    sent = request.headers.get(\"X-Token\", \"\")\n    if not secrets.compare_digest(sent, ADMIN_TOKEN):\n        abort(401)\n\n\n@app.post(\"/links\")\ndef create():\n    require_token()\n    code = secrets.token_urlsafe(4)\n    db().execute(\"INSERT INTO links VALUES (?, ?)\", (code, request.form[\"url\"]))\n    db().commit()\n    return {\"code\": code}, 201\n\n\n@app.get(\"/\")\n@app.get(\"/search\")\ndef search():\n    q = request.args.get(\"q\", \"\")\n    rows = db().execute(\n        \"SELECT code, url FROM links WHERE url LIKE ?\", (f\"%{q}%\",)\n    ).fetchall()\n    return render_template_string(PAGE, q=q, rows=rows)\n\n\n@app.get(\"/<code>\")\ndef follow(code):\n    row = db().execute(\"SELECT url FROM links WHERE code = ?\", (code,)).fetchone()\n    if row is None:\n        abort(404)\n    return redirect(row[0])"}]}
```

Os valores são os mais estritos que esta página permite, e essa é uma escolha que vale a pena numa
página tão pequena. Uma página que carrega scripts de uma rede de distribuição de conteúdo, ou
estilos inline, precisa de uma política mais longa, e escrevê-la é assunto da aula 8 de
`secure-code`. O que importa para o pipeline é que a política está no código, sob um teste, e não
numa configuração de proxy que ninguém versiona.

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
.....                                                                    [100%]
5 passed in 0.14s
```

### A varredura concorda, quase

Construa a imagem de novo e rode o estágio:

```
ana@vm:~/linkbox$ bash ci/build.sh
sha256:9bc6c45b950209db1d54ef697dc38ac6179f1774610b72101332d13faf5be90f
ana@vm:~/linkbox$ bash ci/dast.sh > /tmp/dast.log; echo "exit status $?"
2026-10-23 04:47:24,188 Unable to copy yaml file to /zap/wrk/zap.yaml [Errno 30] Read-only file system: '/zap/wrk/zap.yaml'
exit status 0
ana@vm:~/linkbox$ grep -v ^PASS /tmp/dast.log
Using the Automation Framework
Total of 4 URLs
WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
	http://linkbox-staging-6852-app:8000/search?q=ZAP (200 OK)
FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 60
```

**Status de saída 0, e um alerta restante: 10031.** As três regras de cabeçalho agora passam em toda
URL que o spider achou, o que dá 60 regras aprovadas, e duas dessas URLs eram páginas 404. Os
cabeçalhos estão nelas também, porque o `after_request` roda também nas páginas 404 do Flask. O
teste não pergunta sobre um 404, então confira uma vez à mão: suba a imagem nova com os dois
comandos da seção de staging e peça a ela uma página que não existe e a busca duas vezes:

```
ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -sI http://linkbox-app:8000/nothing-here
HTTP/1.1 404 NOT FOUND
Server: gunicorn
Date: Fri, 23 Oct 2026 04:47:43 GMT
Connection: close
Content-Type: text/html; charset=utf-8
Content-Length: 207
Content-Security-Policy: default-src 'none'; form-action 'self'; frame-ancestors 'none'
X-Content-Type-Options: nosniff
X-Frame-Options: DENY

ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -s "http://linkbox-app:8000/search?q=ZAP"
<!doctype html>
<title>linkbox</title>
<form action="/search"><input name="q" value="ZAP"><button>Search</button></form>
<ul></ul>
ana@vm:~/linkbox$ docker run --rm --network linkbox-staging zaproxy/zap-stable:2.17.0 curl -s "http://linkbox-app:8000/search?q=a%22b"
<!doctype html>
<title>linkbox</title>
<form action="/search"><input name="q" value="a&#34;b"><button>Search</button></form>
<ul></ul>
```

O primeiro comando é a evidência da página 404. Os outros dois são a evidência do 10031.

### Decidindo que o 10031 é um falso positivo

A regra 10031 procura **um valor que o scanner mandou e que volta dentro de um atributo HTML**. A
busca escreve o texto digitado no atributo `value` da caixa, então a palavra `ZAP` volta como
`value="ZAP"`, e a regra bate. O que preocupa a regra é um valor escrito num atributo sem escape.
Nesse caso, uma aspa dupla digitada na caixa fecharia o atributo, e o que viesse depois seria lido
pelo navegador como marcação: isso é cross-site scripting, uma página que executa o que um estranho
digitou.

A regra não distingue um valor com escape de um sem escape. Ela mandou uma palavra simples, viu a
palavra voltar e alertou. **A decisão tem de ser tomada a partir da resposta, por uma pessoa**, e o
terceiro comando acima a toma: a busca recebeu uma aspa dupla, e a página a escreveu como `&#34;`, a
forma com escape. O Jinja escapa todo valor que põe num template renderizado com
`render_template_string`, então uma aspa não consegue fechar o atributo. O
`test_search_survives_a_quote` da aula 3 já garante o mesmo comportamento para um apóstrofo, `&#39;`,
então o escape também está sob um teste.

Então o 10031 é um falso positivo **para esta página, do jeito que está escrita hoje**. Essa última
parte é o motivo de a regra ficar em WARN e não ir para IGNORE. O arquivo de configuração funciona
por regra, não por URL nem por parâmetro: o IGNORE calaria o 10031 em toda página que o linkbox um
dia tiver, inclusive uma escrita no ano que vem que marque um valor com `|safe` e desligue o escape.
Em WARN, o achado continua visível, e o motivo de ele ser aceito fica ao lado, onde a próxima pessoa
que ler a varredura vai encontrá-lo. A aula 7 dá um lugar a esse motivo: uma exceção com dono e
data, que o portão respeita até a data passar.

| achado | decisão | por quê |
|---|---|---|
| 10020, 10021, 10038 | corrigidos, regras em FAIL | reais, corrigidos no código, mantidos por um teste unitário e pela varredura |
| 10031 | falso positivo, deixado em WARN | o valor tem escape, como a resposta mostra; o IGNORE esconderia um verdadeiro mais tarde |

### O que mudou, e o que não mudou

Antes da correção, as respostas do linkbox podiam ser postas num frame, ter o tipo adivinhado e
carregar qualquer coisa. Depois dela, o navegador recusa as três. Nada mudou no escape da busca: ela
já era segura antes, e o único alerta que resta é a varredura sendo cuidadosa, não o linkbox
estando errado.
