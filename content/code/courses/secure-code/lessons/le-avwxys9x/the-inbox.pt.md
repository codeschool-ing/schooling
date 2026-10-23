---
title: A caixa de entrada da equipe, e cinco testes
version: 1
---

Pacientes mandam mensagens à clínica, e as recepcionistas as leem numa caixa de entrada no console da
equipe. A caixa pode ser pesquisada, e um link para ela pode dizer a quem a recepcionista está
respondendo: `/inbox#reply=lucia` põe "Replying to lucia" no título. A pasta desta aula é
`~/sc/messages`:

```
(.venv) ana@vm:~/sc$ mkdir messages
(.venv) ana@vm:~/sc$ cd messages
(.venv) ana@vm:~/sc/messages$ git init -b main
Initialized empty Git repository in /home/ana/sc/messages/.git/
```

Esta é a caixa de entrada. A mensagem da lucia veio de um editor de e-mail, e o negrito em volta de
`much` veio junto. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nfrom flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nMESSAGES = [\n    {\"patient\": \"lucia\", \"text\": \"Knee <b>much</b> better since Monday.\\nSee you Thursday.\"},\n    {\"patient\": \"rafael\", \"text\": \"Can I move Tuesday's session?\"},\n]\n", "note": "Duas mensagens, guardadas em memória. A da lucia tem uma quebra de linha e, do editor de e-mail de onde ela copiou, um par de tags de negrito."}, {"code": "INBOX = \"\"\"<!doctype html>\n<html lang=\"en\">\n<head><meta charset=\"utf-8\"><title>Inbox</title></head>\n<body>\n<h1 id=\"reply\">Inbox</h1>\n<form action=\"/search\"><input name=\"q\"><button>Search</button></form>\n{% for m in messages %}\n<p class=\"message\"><strong>{{ m.patient }}</strong>: {{ m.text|replace(\"\\\\n\", \"<br>\")|safe }}</p>\n{% endfor %}\n<script src=\"/static/inbox.js\"></script>\n</body>\n</html>\n\"\"\"\n\n", "note": "A página da caixa de entrada. As quebras de linha de cada mensagem viram `<br>`, e o resultado é marcado `safe` para as tags `<br>` sobreviverem. Leia o que mais sobrevive junto."}, {"code": "@app.get(\"/inbox\")\ndef inbox():\n    return render_template_string(INBOX, messages=MESSAGES)\n\n", "note": "A caixa de entrada, desenhada pelo template, com as mensagens como variável."}, {"code": "@app.get(\"/search\")\ndef search():\n    term = request.args.get(\"q\", \"\")\n    found = [m for m in MESSAGES if term.lower() in m[\"text\"].lower()]\n    if not found:\n        return f\"<p>No messages match {term}.</p>\"\n    return render_template_string(INBOX, messages=found)", "note": "A busca mostra as mensagens encontradas no mesmo template, e uma frase quando nada é encontrado. Repare em como essa frase é montada."}]}
```

O título é escrito por um script pequeno que a página carrega. Crie a pasta dele e salve como
`static/inbox.js`:

```
(.venv) ana@vm:~/sc/messages$ mkdir static
```

```javascript
// static/inbox.js
const replyTo = new URLSearchParams(location.hash.slice(1)).get("reply");
if (replyTo) {
  document.getElementById("reply").innerHTML = "Replying to " + replyTo;
}
```

### Os testes

Quatro testes leem o que o servidor manda, e um lê o script, porque o tipo baseado no DOM nunca chega
ao servidor. Salve como `test_app.py`:

```python
# test_app.py
from pathlib import Path

import pytest

import app as portal


@pytest.fixture
def client():
    return portal.app.test_client()


def test_the_inbox_lists_messages(client):
    assert "rafael" in client.get("/inbox").get_data(as_text=True)


def test_a_stored_message_is_shown_as_text(client):
    page = client.get("/inbox").get_data(as_text=True)
    assert "Knee &lt;b&gt;much&lt;/b&gt; better" in page


def test_line_breaks_are_kept_by_css(client):
    assert "white-space: pre-line" in client.get("/inbox").get_data(as_text=True)


def test_a_search_term_is_shown_as_text(client):
    page = client.get("/search", query_string={"q": "<i>knee</i>"}).get_data(as_text=True)
    assert "No messages match &lt;i&gt;knee&lt;/i&gt;." in page


def test_the_script_writes_text_not_markup():
    script = Path("static/inbox.js").read_text()
    assert "innerHTML" not in script
    assert "textContent" in script
```

`&lt;b&gt;` é como uma página escreve `<b>` como texto: o navegador mostra os caracteres, e não
constrói nada.

### Vermelho

```
(.venv) ana@vm:~/sc/messages$ pytest -q --tb=no
.FFFF                                                                    [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_stored_message_is_shown_as_text - assert 'Knee &lt...
FAILED test_app.py::test_line_breaks_are_kept_by_css - assert 'white-space: p...
FAILED test_app.py::test_a_search_term_is_shown_as_text - AssertionError: ass...
FAILED test_app.py::test_the_script_writes_text_not_markup - assert 'innerHTM...
4 failed, 1 passed in 0.15s
```

**Quatro de cinco falham**, e o quinto só confere que a caixa tem mensagens. Faça o commit da versão
com falhas:

```
(.venv) ana@vm:~/sc/messages$ git add app.py static/inbox.js test_app.py look.py
(.venv) ana@vm:~/sc/messages$ git commit -q -m "Staff inbox, search and reply heading"
```

### O que um navegador constrói

Os testes leem o HTML. Para ver em que esse HTML se transforma, a aula conduz um navegador com o
Playwright, como a aula 8 faz; se você já fez a aula 8, ele já está instalado, e se não, a terceira
seção dela mostra os dois comandos. O `look.py` abre a caixa de entrada com uma resposta no endereço,
envolvida em `<b>` como um nome poderia chegar de outro sistema, e imprime o título, a primeira
mensagem e quantos elementos em negrito o navegador construiu:

```python
# look.py
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.goto("http://127.0.0.1:5000/inbox#reply=lucia <b>D'Ávila</b>")
    print("heading:", page.inner_text("#reply"))
    print("first message:", page.inner_text("p.message"))
    print("bold elements:", page.locator("b").count())
    browser.close()
```

Inicie o portal com `flask --app app run` e, num segundo terminal:

```
(.venv) ana@vm:~/sc/messages$ python3 look.py
heading: Replying to lucia D'Ávila
first message: lucia: Knee much better since Monday.
See you Thursday.
bold elements: 2
```

**Dois elementos em negrito**, e nenhum aparece como tag: um construído a partir da mensagem da lucia,
que o servidor mandou, e um a partir do endereço, que o servidor nunca viu. São dois dos três tipos
já, numa página só. O terceiro está na busca.
