---
title: O teste que envia o que o navegador não enviaria
version: 1
---

A requisição de `curl` da seção anterior é a evidência; os testes a tornam permanente. Eles enviam
os campos do formulário do jeito que o cliente de teste do Flask envia, sem navegador nenhum, e esse
é o ponto: **um teste de servidor é o primeiro cliente que ignora o HTML**. Salve como `test_app.py`:

```python
# test_app.py
import pytest

import app as portal

GOOD = {"name": "Lucia Prado", "email": "lucia@mail.example", "birth": "1988-04-12"}


@pytest.fixture
def client():
    portal.PATIENTS.clear()
    return portal.app.test_client()


def test_a_good_signup_is_stored(client):
    assert client.post("/signup", data=GOOD).status_code == 201
    assert portal.PATIENTS == [GOOD]


@pytest.mark.parametrize("field, value", [
    ("name", ""),
    ("name", "x" * 61),
    ("email", "lucia"),
    ("birth", "2031-01-01"),
    ("birth", "yesterday"),
])
def test_what_the_browser_refuses_the_server_refuses_too(client, field, value):
    response = client.post("/signup", data=dict(GOOD, **{field: value}))
    assert response.status_code == 400
    assert portal.PATIENTS == []


def test_a_field_the_form_never_had_is_not_stored(client):
    client.post("/signup", data=dict(GOOD, role="staff"))
    assert "role" not in portal.PATIENTS[0]


def test_the_form_states_the_servers_limits(client):
    page = client.get("/signup").get_data(as_text=True)
    for f in portal.FIELDS.values():
        if "maxlength" in f:
            assert f'maxlength="{f["maxlength"]}"' in page
```

Dois desses testes tratam de falhas que a primeira seção não nomeou, e as duas vêm de confiar no
formulário:

- **Um campo que o formulário nunca teve.** O código antigo guarda `dict(request.form)`, todo campo
  que chegou. Um formulário com três campos não impede que uma requisição traga um quarto,
  `role=staff`, e o código adiante que lê `patient.get("role")` vai acreditar nele. Montar o registro
  guardado a partir de uma lista de campos conhecidos, e mais nada, fecha essa classe inteira de uma
  vez. Ela costuma ser chamada de **atribuição em massa** (*mass assignment*), e é o mesmo erro em
  todo framework que consegue preencher um objeto a partir de uma requisição.
- **Duas cópias de um limite.** O último teste pede ao servidor os limites dele e confere se a página
  diz os mesmos. Um limite escrito uma vez no HTML e outra no Python são dois números que vão se
  afastar; o teste falha no dia em que isso acontecer.

### Vermelho

```
(.venv) ana@vm:~/sc/signup$ pytest --tb=line
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/signup
collected 8 items

test_app.py .FFFFFFF                                                     [100%]

=================================== FAILURES ===================================
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   assert 201 == 400
     +  where 201 = <WrapperTestResponse streamed [201 CREATED]>.status_code
/home/ana/sc/signup/test_app.py:29: assert 201 == 400
E   AssertionError: assert 'role' not in {'name': 'Lucia Prado', 'email': 'lucia@mail.example', 'birth': '1988-04-12', 'role': 'staff'}
/home/ana/sc/signup/test_app.py:35: AssertionError: assert 'role' not in {'name': 'Lucia Prado', 'email': 'lucia@mail.example', 'birth': '1988-04-12', 'role': 'staff'}
E   AttributeError: module 'app' has no attribute 'FIELDS'
/home/ana/sc/signup/test_app.py:40: AttributeError: module 'app' has no attribute 'FIELDS'
=========================== short test summary info ============================
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[name-]
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[name-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx]
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[email-lucia]
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[birth-2031-01-01]
FAILED test_app.py::test_what_the_browser_refuses_the_server_refuses_too[birth-yesterday]
FAILED test_app.py::test_a_field_the_form_never_had_is_not_stored - Assertion...
FAILED test_app.py::test_the_form_states_the_servers_limits - AttributeError:...
========================= 7 failed, 1 passed in 0.11s ==========================
```

Sete falhas. As cinco recusas falham porque o servidor antigo aceitava tudo, o campo a mais falha
porque `role` foi guardado, e o último teste nem consegue começar: **`FIELDS` não existe**, porque no
código antigo os limites só existem como texto HTML. Faça commit como está:

```
(.venv) ana@vm:~/sc/signup$ git add app.py test_app.py
(.venv) ana@vm:~/sc/signup$ git commit -m "Sign up from the form"
[main (root-commit) d67a375] Sign up from the form
 2 files changed, 64 insertions(+)
 create mode 100644 app.py
 create mode 100644 test_app.py
```
