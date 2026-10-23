---
title: linkbox, o projeto que você herda
version: 1
---

Todas as aulas deste curso trabalham num serviço pequeno, o **linkbox**: links curtos para um time,
do tipo que transforma `https://example.org/docs/handbook/onboarding` numa barra e seis caracteres.
Ele é escrito em Python com Flask e guarda os links num arquivo SQLite. A linguagem é incidental; o
que o curso faz com o pipeline é o mesmo para um serviço em Go ou em Node.

**Você o herda, do jeito que a maior parte do código é encontrada no trabalho.** Ele roda, os testes
passam, e alguém o construiu com pressa. Ele tem pelo menos quatro defeitos de segurança, e isso é
proposital: as aulas 3 a 6 os acham com ferramentas, uma classe de ferramenta por aula, e corrigem
cada um com um teste que prova a correção. Ler o código agora e enxergá-los é um bom exercício.
Corrigi-los agora deixaria aquelas aulas sem nada para achar, então deixe-os onde estão.

### Os arquivos

Crie o diretório do projeto e comece um repositório nele:

```
ana@vm:~$ mkdir linkbox && cd linkbox
ana@vm:~/linkbox$ git init
Initialized empty Git repository in /home/ana/linkbox/.git/
```

O serviço é um arquivo só. Salve-o como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "\"\"\"linkbox: short links for a small team, kept in one SQLite file.\"\"\"\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, redirect, render_template_string, request\n\nfrom settings import ADMIN_TOKEN, DATABASE\n", "note": "Um arquivo, uma tabela e três rotas. Tudo o que o serviço sabe fica num arquivo SQLite cujo nome vem de `settings.py`."}, {"code": "app = Flask(__name__)\n\nPAGE = \"\"\"<!doctype html>\n<title>linkbox</title>\n<form action=\"/search\"><input name=\"q\" value=\"{{ q }}\"><button>Search</button></form>\n<ul>{% for code, url in rows %}<li><a href=\"/{{ code }}\">{{ code }}</a> {{ url }}</li>{% endfor %}</ul>\n\"\"\"\n\n", "note": "A página é uma string de template: uma caixa de busca e a lista dos links que casam com ela."}, {"code": "def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(DATABASE)\n        g.db.execute(\"CREATE TABLE IF NOT EXISTS links (code TEXT PRIMARY KEY, url TEXT)\")\n    return g.db\n\n", "note": "Uma conexão por requisição, aberta na primeira vez que uma rota pede. A tabela é criada se ainda não existir, então um arquivo de banco novo não precisa de nenhum passo de preparação."}, {"code": "@app.teardown_appcontext\ndef close_db(_):\n    conn = g.pop(\"db\", None)\n    if conn is not None:\n        conn.close()\n\n", "note": "A conexão é fechada quando a requisição termina, faça a rota o que fizer."}, {"code": "@app.post(\"/links\")\ndef create():\n    if request.headers.get(\"X-Token\") != ADMIN_TOKEN:\n        abort(401)\n    code = secrets.token_urlsafe(4)\n    db().execute(\"INSERT INTO links VALUES (?, ?)\", (code, request.form[\"url\"]))\n    db().commit()\n    return {\"code\": code}, 201\n\n", "note": "Criar um link exige o token de administração num cabeçalho `X-Token`. O código curto são quatro bytes aleatórios, escritos como seis caracteres seguros para URL."}, {"code": "@app.get(\"/\")\n@app.get(\"/search\")\ndef search():\n    q = request.args.get(\"q\", \"\")\n    rows = db().execute(f\"SELECT code, url FROM links WHERE url LIKE '%{q}%'\").fetchall()\n    return render_template_string(PAGE, q=q, rows=rows)\n\n", "note": "A página inicial e a busca são a mesma rota: todo link cujo endereço contém o texto digitado, ou todos os links quando nada foi digitado."}, {"code": "@app.get(\"/<code>\")\ndef follow(code):\n    row = db().execute(\"SELECT url FROM links WHERE code = ?\", (code,)).fetchone()\n    if row is None:\n        abort(404)\n    return redirect(row[0])\n\n", "note": "Seguir um código responde com um redirecionamento para o endereço que ele representa, ou com um 404."}, {"code": "if __name__ == \"__main__\":\n    app.run(debug=True)", "note": "Executado como `python app.py`, o arquivo sobe o servidor de desenvolvimento do próprio Flask."}]}
```

As configurações ficam num segundo arquivo, para os testes poderem apontar o banco para outro
lugar. Salve como `settings.py`:

```python
import os

DATABASE = os.environ.get("LINKBOX_DB", "linkbox.db")
ADMIN_TOKEN = "lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x"
```

As dependências, cada uma fixada numa versão exata, como estavam no dia em que o projeto foi
entregue. Salve como `requirements.txt`:

```
flask==3.0.0
werkzeug==3.0.1
jinja2==3.1.2
markupsafe==2.1.3
itsdangerous==2.1.2
click==8.1.7
blinker==1.7.0
gunicorn==21.2.0
```

O que só os testes precisam, como `requirements-dev.txt`:

```
pytest==8.4.2
```

Três testes: um link não pode ser criado sem o token, um link redireciona, e a busca acha o que foi
salvo. Cada teste ganha um banco próprio num diretório temporário. Salve como `tests/test_app.py`:

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
```

A imagem em que o serviço roda. É o Dockerfile mais curto que funciona, e a aula 8 o desmonta. Salve
como `Dockerfile`:

```dockerfile
FROM python:3.13
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
EXPOSE 8000
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]
```

O que o git nunca deve registrar, como `.gitignore`:

```
.venv/
__pycache__/
.pytest_cache/
*.db
*.pid
ci-logs/
```

E o que o `docker build` nunca deve copiar para a imagem, como `.dockerignore`:

```
.venv
.git
*.db
```

### Rode os testes

Um ambiente virtual mantém os pacotes fixados dentro do projeto. `uv venv` o cria e `uv pip
install` o preenche, em poucos segundos, porque o uv resolve e instala em paralelo:

```
ana@vm:~/linkbox$ uv venv
Using CPython 3.13.16 interpreter at: /usr/bin/python
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
ana@vm:~/linkbox$ uv pip install -r requirements.txt -r requirements-dev.txt
Resolved 13 packages in 548ms
Downloading pygments (1.2MiB)
   Building markupsafe==2.1.3
 Downloaded pygments
      Built markupsafe==2.1.3
Prepared 13 packages in 1.33s
Installed 13 packages in 15ms
 + blinker==1.7.0
 + click==8.1.7
 + flask==3.0.0
 + gunicorn==21.2.0
 + iniconfig==2.3.1
 + itsdangerous==2.1.2
 + jinja2==3.1.2
 + markupsafe==2.1.3
 + packaging==26.3
 + pluggy==1.7.0
 + pygments==2.21.0
 + pytest==8.4.2
 + werkzeug==3.0.1
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
...                                                                      [100%]
3 passed in 0.42s
```

### Use o serviço

O gunicorn é o servidor que a imagem roda, e ele roda na sua máquina do mesmo jeito. `--daemon` o
põe em segundo plano e `--pid` anota o número do processo, para você poder pará-lo depois:

```
ana@vm:~/linkbox$ .venv/bin/gunicorn --daemon --pid linkbox.pid --bind 127.0.0.1:8000 app:app
ana@vm:~/linkbox$ curl -s -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org/docs/handbook/onboarding http://127.0.0.1:8000/links
{"code":"kJOsxQ"}
ana@vm:~/linkbox$ code=$(curl -s -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org/status http://127.0.0.1:8000/links | jq -r .code)
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" http://127.0.0.1:8000/$code
302 https://example.org/status
ana@vm:~/linkbox$ curl -s "http://127.0.0.1:8000/search?q=handbook"
<!doctype html>
<title>linkbox</title>
<form action="/search"><input name="q" value="handbook"><button>Search</button></form>
<ul><li><a href="/kJOsxQ">kJOsxQ</a> https://example.org/docs/handbook/onboarding</li></ul>
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -d url=https://example.org http://127.0.0.1:8000/links
401
ana@vm:~/linkbox$ kill $(cat linkbox.pid)
```

Cinco requisições: dois links criados, um seguido, uma busca, e uma tentativa sem token, que
responde `401`. O token está em `settings.py` para quem puder ler o arquivo, que é um dos quatro
defeitos, e ele espera pela aula 6. Os códigos são aleatórios, então os seus serão outros.

### O primeiro commit

```
ana@vm:~/linkbox$ git add -A
ana@vm:~/linkbox$ git status --short
A  .dockerignore
A  .gitignore
A  Dockerfile
A  app.py
A  requirements-dev.txt
A  requirements.txt
A  settings.py
A  tests/test_app.py
ana@vm:~/linkbox$ git commit -q -m "linkbox as it was handed over"
ana@vm:~/linkbox$ git log --oneline
3215f0f linkbox as it was handed over
```
