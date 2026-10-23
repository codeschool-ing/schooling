---
title: Duas correções, cada uma com o teste que a prova
version: 1
---

Um achado se fecha com uma mudança no código, e **uma mudança no código se prova com um teste.** Sem
o teste, a correção é uma afirmação: o scanner para de reclamar, o que diz que o formato sumiu, não
que o comportamento está certo. E sem um teste, a próxima pessoa que mexer na busca pode devolver o
defeito numa forma que a regra não pega. Então cada correção aqui segue a mesma ordem: um teste que
falha por causa do defeito, depois a mudança, depois o mesmo teste passando.

### A injeção, como um teste que falha

A busca deveria achar um link cujo endereço tem uma aspa. Nada exótico: `it's` é uma palavra comum em
inglês, e alguém vai procurá-la. Acrescente um teste no fim do arquivo. Salve os testes como
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
```

Rode contra o código como está:

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q --tb=short
...F                                                                     [100%]
=================================== FAILURES ===================================
_________________________ test_search_survives_a_quote _________________________
tests/test_app.py:39: in test_search_survives_a_quote
    assert page.status_code == 200
E   assert 500 == 200
E    +  where 500 = <WrapperTestResponse streamed [500 INTERNAL SERVER ERROR]>.status_code
------------------------------ Captured log call -------------------------------
ERROR    app:app.py:825 Exception on /search [GET]
Traceback (most recent call last):
  File "/home/ana/linkbox/.venv/lib/python3.13/site-packages/flask/app.py", line 1455, in wsgi_app
    response = self.full_dispatch_request()
  File "/home/ana/linkbox/.venv/lib/python3.13/site-packages/flask/app.py", line 869, in full_dispatch_request
    rv = self.handle_user_exception(e)
  File "/home/ana/linkbox/.venv/lib/python3.13/site-packages/flask/app.py", line 867, in full_dispatch_request
    rv = self.dispatch_request()
  File "/home/ana/linkbox/.venv/lib/python3.13/site-packages/flask/app.py", line 852, in dispatch_request
    return self.ensure_sync(self.view_functions[rule.endpoint])(**view_args)
           ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^^^^^^^^^^^
  File "/home/ana/linkbox/app.py", line 46, in search
    rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall()
           ~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
sqlite3.OperationalError: near "s": syntax error
=========================== short test summary info ============================
FAILED tests/test_app.py::test_search_survives_a_quote - assert 500 == 200
1 failed, 3 passed in 0.39s
```

**O teste novo falha com um 500, um erro interno do servidor, numa busca por uma palavra do inglês.**
É o defeito, mostrado na sua própria aplicação e nada mais: a aspa fechou a string no SQL, o resto do
texto foi lido como SQL, o SQLite o recusou e o Flask respondeu 500. Uma busca por uma palavra com
apóstrofo quebra a página, e o mesmo erro permite a quem digita naquela caixa mudar o que a consulta
faz. O teste pede que a página funcione e mostre o link, escapado como o template escapa, que é o que
`it&#39;s-here` é.

### A mudança

Três alterações no `app.py`: a consulta recebe o valor como parâmetro, o token é conferido por uma
função que toda rota que grava chama, e o bloco que rodava o depurador do Flask saiu. Salve como
`app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "\"\"\"linkbox: short links for a small team, kept in one SQLite file.\"\"\"\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, redirect, render_template_string, request\n\nfrom settings import ADMIN_TOKEN, DATABASE\n\napp = Flask(__name__)\n\nPAGE = \"\"\"<!doctype html>\n<title>linkbox</title>\n<form action=\"/search\"><input name=\"q\" value=\"{{ q }}\"><button>Search</button></form>\n<ul>{% for code, url in rows %}<li><a href=\"/{{ code }}\">{{ code }}</a> {{ url }}</li>{% endfor %}</ul>\n\"\"\"\n\n\ndef db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(DATABASE)\n        g.db.execute(\"CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT)\")\n    return g.db\n\n\n@app.teardown_appcontext\ndef close_db(_):\n    conn = g.pop(\"db\", None)\n    if conn is not None:\n        conn.close()\n\n", "note": "O começo do arquivo é o da aula 1, sem mudança: os imports, a página e uma conexão com o banco por requisição."}, {"code": "def require_token():\n    sent = request.headers.get(\"X-Token\", \"\")\n    if not secrets.compare_digest(sent, ADMIN_TOKEN):\n        abort(401)\n\n", "note": "Novo: o único lugar onde o token é conferido. `secrets.compare_digest()` leva o mesmo tempo se o primeiro caractere estiver errado ou o último, então quanto a resposta demora não diz nada sobre quão perto um palpite chegou. Um cabeçalho ausente vira uma string vazia, que nunca confere."}, {"code": "@app.post(\"/links\")\ndef create():\n    require_token()\n    code = secrets.token_urlsafe(4)\n    db().execute(\"INSERT INTO links VALUES (?, ?)\", (code, request.form[\"url\"]))\n    db().commit()\n    return {\"code\": code}, 201\n\n", "note": "`create()` agora começa chamando essa função, que é o que a regra do Semgrep `writes-need-the-token` procura. Toda rota que grava daqui em diante começa com a mesma linha."}, {"code": "@app.get(\"/\")\n@app.get(\"/search\")\ndef search():\n    q = request.args.get(\"q\", \"\")\n    rows = db().execute(\n        \"SELECT code, url FROM links WHERE url LIKE ?\", (f\"%{q}%\",)\n    ).fetchall()\n    return render_template_string(PAGE, q=q, rows=rows)\n\n", "note": "A correção da injeção. O SQL tem um `?` onde vai o valor, e o valor, com os curingas `%` em volta, viaja separado, como parâmetro. O SQLite nunca lê o texto da busca como SQL, então uma aspa nele é só uma aspa."}, {"code": "@app.get(\"/<code>\")\ndef follow(code):\n    row = db().execute(\"SELECT url FROM links WHERE code = ?\", (code,)).fetchone()\n    if row is None:\n        abort(404)\n    return redirect(row[0])", "note": "`follow()` já estava certa. O bloco `if __name__ == \"__main__\"` que rodava o Flask com `debug=True` saiu: quem inicia o serviço é o gunicorn, que nunca o executou, e um servidor de desenvolvimento se inicia de propósito, com `flask --app app run --debug`, só na sua própria máquina."}]}
```

**A linha do depurador merece uma frase só dela.** `app.run(debug=True)` inicia o servidor de
desenvolvimento do Werkzeug com o depurador interativo, que transforma qualquer erro numa página onde
se digita Python e ele roda no servidor. Ele é protegido por um PIN impresso no console, e continua
sendo um jeito de rodar código na máquina para quem alcançar a página. No linkbox ele nunca rodou,
porque a imagem inicia o gunicorn, e é exatamente por isso que vale removê-lo: **código morto que
ganha vida por acidente** é um `python app.py` num servidor, numa tarde, para testar alguma coisa.

### Os testes, e os scanners

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
....                                                                     [100%]
4 passed in 0.13s
ana@vm:~/linkbox$ bash ci/sast.sh; echo "exit $?"
exit 0
```

Quatro testes passam, o novo incluído, e as duas ferramentas ficam quietas. O Bandit ainda sabe do
token; peça também os achados baixos e ele está lá:

```
ana@vm:~/linkbox$ bandit -q -r . -c bandit.yaml --format custom --msg-template "{relpath}:{line} {test_id} {severity}/{confidence} {msg}"
settings.py:4 B105 LOW/MEDIUM Possible hardcoded password: 'lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x'
```

Esse é o achado que esta aula deixa aberto de propósito, e é o limite do portão que o deixa passar. A
aula 6 troca o token por um novo primeiro, e só depois o tira do código.

### Verde de novo

```
ana@vm:~/linkbox$ git add app.py tests/test_app.py
ana@vm:~/linkbox$ git commit -q -m "the search takes a parameter, writes call require_token(), no debug server"
ana@vm:~/linkbox$ git push ci main
remote: run 2: main at b1002ea        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: build: passed in 0s        
remote: pipeline passed        
remote: run 2: passed        
To /home/ana/ci/linkbox.git
   879b6bb..b1002ea  main -> main
```

A segunda execução passa em todos os estágios. O teste que prova cada correção está no mesmo commit
que a correção, então todo push seguinte o roda, e as duas continuam corrigidas. Se alguém escrever a
busca com uma f-string de novo, o estágio de análise estática para a pessoa; se escrever de um jeito
que a regra não pega, o teste para.
