---
title: A página de perfil, montada com f-strings
version: 1
---

A aplicação é a página de perfil do paciente: um título com o nome, um campo com o apelido, um link
para o site da própria pessoa, um link para os agendamentos e uma nota clínica que o JavaScript da
página usa. Os dados ficam num arquivo próprio para a página poder mudar sem eles. Salve como
`profiles.py`:

```python
# profiles.py
PROFILES = {
    "lucia": {
        "name": "Lucia & Bia <3",
        "nickname": 'Lu "the fast"',
        "website": "https://lucia.example/blog?a=1&b=2",
        "note": "back pain </script> again",
    },
}
```

Cada valor ali é algo que um paciente poderia digitar num formulário, e cada um carrega um caractere
que importa no lugar onde vai ser escrito. Esta é a página como a ana a escreveu primeiro, com
f-strings do Python e sem template. Salve como `app.py`:

```python
# app.py
from flask import Flask

from profiles import PROFILES

app = Flask(__name__)


@app.get("/patients/<user>")
def profile(user):
    p = PROFILES[user]
    return f"""<h1>{p['name']}</h1>
<input name="nickname" value="{p['nickname']}">
<a href="{p['website']}">website</a>
<a href="/search?q={p['name']}">bookings of {p['name']}</a>
<script>const note = "{p['note']}";</script>
"""


@app.get("/search")
def search():
    return ""
```

Uma f-string cola texto em texto. Ela não sabe que está escrevendo HTML, então não codifica nada, em
lugar nenhum. Peça a página com `curl` com a aplicação rodando, e todas as linhas da figura da
primeira seção deram errado ao mesmo tempo:

```
(.venv) ana@vm:~/sc/profile$ curl -s http://127.0.0.1:5000/patients/lucia
<h1>Lucia & Bia <3</h1>
<input name="nickname" value="Lu "the fast"">
<a href="https://lucia.example/blog?a=1&b=2">website</a>
<a href="/search?q=Lucia & Bia <3">bookings of Lucia & Bia <3</a>
<script>const note = "back pain </script> again";</script>
```

Leia como um navegador leria. O título contém um `<3` que o interpretador de HTML vai tentar ler como
começo de tag. O valor do campo termina no segundo `"`, depois de `Lu `, e `the fast""` sobra como
algo que não é atributo. A query do link de busca termina no `&`, então a busca recebe `Lucia ` e um
parâmetro perdido. E o script termina no `</script>`, no meio da string, deixando ` again";`
impresso na página como texto.

### Os testes, um por contexto

Cada teste pede a página e procura a codificação exata de que o seu contexto precisa. Salve como
`test_app.py`:

```python
# test_app.py
import pytest

import app as portal


@pytest.fixture
def page():
    return portal.app.test_client().get("/patients/lucia").get_data(as_text=True)


def test_text_is_html_escaped(page):
    assert "<h1>Lucia &amp; Bia &lt;3</h1>" in page


def test_a_quoted_attribute_keeps_its_value(page):
    assert 'value="Lu &#34;the fast&#34;"' in page


def test_an_address_in_an_attribute_is_escaped_too(page):
    assert 'href="https://lucia.example/blog?a=1&amp;b=2"' in page


def test_a_query_value_is_url_encoded(page):
    assert 'href="/search?q=Lucia+%26+Bia+%3C3"' in page


def test_a_script_cannot_be_closed_from_inside_a_string(page):
    assert "</script> again" not in page
    assert r'const note = "back pain \u003c/script\u003e again";' in page


def test_only_web_addresses_become_links(monkeypatch):
    monkeypatch.setitem(portal.PROFILES["lucia"], "website", "data:text/html,hello")
    html = portal.app.test_client().get("/patients/lucia").get_data(as_text=True)
    assert "data:" not in html
```

O último teste trata de outra propriedade, e as próximas seções voltam a ela: **o escape torna
inofensivo o texto de um link e não diz nada sobre para onde o link vai.** Um endereço `data:` ou
`file:` em `href` está perfeitamente escapado e continua não sendo uma página web.

### Vermelho

A saída do curl já mostrou por que cada um falha, então o `--tb=no` pede ao pytest só os veredictos:

```
(.venv) ana@vm:~/sc/profile$ pytest -q --tb=no
FFFFFF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_text_is_html_escaped - assert '<h1>Lucia &amp; Bia &...
FAILED test_app.py::test_a_quoted_attribute_keeps_its_value - assert 'value="...
FAILED test_app.py::test_an_address_in_an_attribute_is_escaped_too - assert '...
FAILED test_app.py::test_a_query_value_is_url_encoded - assert 'href="/search...
FAILED test_app.py::test_a_script_cannot_be_closed_from_inside_a_string - ass...
FAILED test_app.py::test_only_web_addresses_become_links - assert 'data:' not...
6 failed in 0.15s
```

Os seis falham. Faça commit da versão com f-strings antes de substituí-la:

```
(.venv) ana@vm:~/sc/profile$ git add contexts.py profiles.py app.py test_app.py
(.venv) ana@vm:~/sc/profile$ git commit -m "Show the patient profile"
[main (root-commit) e13eff4] Show the patient profile
 4 files changed, 79 insertions(+)
 create mode 100644 app.py
 create mode 100644 contexts.py
 create mode 100644 profiles.py
 create mode 100644 test_app.py
```
