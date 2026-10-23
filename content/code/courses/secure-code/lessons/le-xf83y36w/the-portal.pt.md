---
title: A página do portal, e seis testes
version: 1
---

A pasta desta aula é `~/sc/csp`:

```
(.venv) ana@vm:~/sc$ mkdir csp
(.venv) ana@vm:~/sc$ cd csp
(.venv) ana@vm:~/sc/csp$ git init -b main
Initialized empty Git repository in /home/ana/sc/csp/.git/
```

A página que cumprimenta a paciente com a próxima sessão é pequena, e tem os dois hábitos que uma
política está prestes a quebrar: um `<script>` inline que define o título da página, e um atributo
`onclick` num botão. Os dois são código do próprio portal, escritos pela ana, e os dois são
inofensivos. Salve como `app.py`:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "# app.py\nimport logging\n\nfrom flask import Flask, render_template_string\n\napp = Flask(__name__)\nlog = logging.getLogger(\"portal\")\n", "note": "Um logger chamado `portal`, como na aula 15. Nada escreve nele ainda; os relatórios da terceira seção vão escrever."}, {"code": "PAGE = \"\"\"<!doctype html>\n<html lang=\"en\">\n<head><meta charset=\"utf-8\"><title>Vereda</title></head>\n<body>\n<h1>Your next session</h1>\n<p id=\"when\">Monday 16 November, 09:00, with carla</p>", "note": "O título da página no HTML é só `Vereda`. Repare no que define o resto dele."}, {"code": "<button onclick=\"document.getElementById('when').classList.toggle('large')\">Larger text</button>", "note": "Um tratador de evento inline: JavaScript dentro de um atributo, rodado quando o botão é clicado. Uma política que recusa script inline recusa isto também."}, {"code": "<script>\n  document.title = \"Vereda: \" + document.getElementById(\"when\").textContent;\n</script>\n</body>\n</html>\n\"\"\"\n\n", "note": "Um script inline, do próprio portal, que põe a próxima sessão no título da aba do navegador."}, {"code": "@app.get(\"/\")\ndef home():\n    return render_template_string(PAGE)", "note": "Uma página. No portal de verdade a sessão vem do banco; aqui está escrita na página."}]}
```

### Os testes

Os testes abaixo leem o cabeçalho como um navegador lê. `policy()` o separa em diretivas, para um teste
dizer exatamente que valor cada uma precisa ter. O quinto teste lê a própria página: nenhum `<script>`
sem `src`, e nenhum atributo `on…=`, porque a política recusaria os dois. Salve como `test_app.py`:

```python
# test_app.py
import logging
import re

import pytest

import app as portal


@pytest.fixture
def client():
    return portal.app.test_client()


def policy(response):
    header = response.headers.get("Content-Security-Policy", "")
    return dict(
        (part.split()[0], " ".join(part.split()[1:]))
        for part in header.split(";")
        if part.strip()
    )


def test_the_page_shows_the_next_session(client):
    assert "with carla" in client.get("/").get_data(as_text=True)


def test_every_page_sends_an_enforced_policy(client):
    assert "Content-Security-Policy" in client.get("/").headers


def test_scripts_come_only_from_the_portal(client):
    directives = policy(client.get("/"))
    assert directives.get("script-src") == "'self'"
    assert directives.get("object-src") == "'none'"
    assert directives.get("base-uri") == "'none'"
    assert directives.get("frame-ancestors") == "'none'"


def test_no_page_carries_inline_script(client):
    page = client.get("/").get_data(as_text=True)
    assert not re.search(r"<script(?![^>]*\ssrc=)[^>]*>", page)
    assert not re.search(r"\son[a-z]+=", page)


def test_the_script_file_is_served(client):
    assert client.get("/static/portal.js").status_code == 200


def test_a_violation_report_is_logged(client, caplog):
    caplog.set_level(logging.WARNING, logger="portal")
    report = {"csp-report": {"violated-directive": "script-src-elem", "blocked-uri": "inline"}}
    assert client.post("/csp-report", json=report).status_code == 204
    assert "csp violation" in caplog.text
```

### Vermelho

```
(.venv) ana@vm:~/sc/csp$ pytest -q --tb=no
.FFFFF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_every_page_sends_an_enforced_policy - AssertionError...
FAILED test_app.py::test_scripts_come_only_from_the_portal - assert None == "...
FAILED test_app.py::test_no_page_carries_inline_script - assert not <re.Match...
FAILED test_app.py::test_the_script_file_is_served - AssertionError: assert 4...
FAILED test_app.py::test_a_violation_report_is_logged - AssertionError: asser...
5 failed, 1 passed in 0.15s
```

**Cinco de seis falham**: a página funciona, e nada nela está pronto para uma política. Faça o commit
como está:

```
(.venv) ana@vm:~/sc/csp$ git add app.py test_app.py
(.venv) ana@vm:~/sc/csp$ git commit -q -m "Greet the patient with her next session"
```

### Um navegador para observar

Os testes conferem o que o servidor manda. Aquilo **para que** a política existe acontece no navegador,
então esta aula também conduz um de verdade. O **Playwright** é uma biblioteca que inicia um navegador e
o controla a partir do Python. Instale no ambiente do curso, e depois o navegador que ele conduz:

```
(.venv) ana@vm:~/sc/csp$ pip install --progress-bar off playwright==1.56.0
Collecting playwright==1.56.0
  Downloading playwright-1.56.0-py3-none-manylinux1_x86_64.whl.metadata (3.5 kB)
Collecting pyee<14,>=13 (from playwright==1.56.0)
  Downloading pyee-13.0.1-py3-none-any.whl.metadata (3.0 kB)
Collecting greenlet<4.0.0,>=3.1.1 (from playwright==1.56.0)
  Downloading greenlet-3.5.6-cp313-cp313-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl.metadata (3.8 kB)
Collecting typing-extensions (from pyee<14,>=13->playwright==1.56.0)
  Downloading typing_extensions-4.16.0-py3-none-any.whl.metadata (3.3 kB)
Downloading playwright-1.56.0-py3-none-manylinux1_x86_64.whl (46.3 MB)
Downloading greenlet-3.5.6-cp313-cp313-manylinux_2_24_x86_64.manylinux_2_28_x86_64.whl (623 kB)
Downloading pyee-13.0.1-py3-none-any.whl (15 kB)
Downloading typing_extensions-4.16.0-py3-none-any.whl (45 kB)
Installing collected packages: typing-extensions, greenlet, pyee, playwright
Successfully installed greenlet-3.5.6 playwright-1.56.0 pyee-13.0.1 typing-extensions-4.16.0
```

```
$ playwright install chromium
```

O segundo comando baixa a versão do Chromium do próprio Playwright para a sua pasta pessoal. Ele **não
foi rodado** na gravação desta aula: a máquina da gravação já tinha uma versão do Chromium instalada, a
153, e é dela que vêm as transcrições abaixo. Em outra versão as mensagens podem vir com palavras um
pouco diferentes; o que elas dizem, não.

O `look.py` abre a página, clica no botão e imprime o título da página, se o clique funcionou, e toda
mensagem que o navegador escreve no console. Salve ao lado do `app.py`:

```python
# look.py
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch()
    page = browser.new_page()
    page.on("console", lambda message: print("console:", message.text))
    page.goto("http://127.0.0.1:5000/")
    page.click("button")
    print("title:", page.title())
    print("larger text:", page.eval_on_selector("#when", "e => e.classList.contains('large')"))
    browser.close()
```

Inicie o portal com `flask --app app run`, e num segundo terminal:

```
(.venv) ana@vm:~/sc/csp$ python3 look.py
title: Vereda: Monday 16 November, 09:00, with carla
larger text: True
```

Sem política, sem mensagens: o script inline definiu o título e o tratador `onclick` aumentou o texto.
