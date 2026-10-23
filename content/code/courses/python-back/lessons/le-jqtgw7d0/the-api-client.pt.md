---
title: O cliente da API, e as portas da aula 12 como teste
version: 1
---

O DRF tem seu próprio cliente, o `APIClient`, que codifica JSON e consegue **pular a autenticação**: o
`force_authenticate(user)` faz toda requisição ser daquele usuário, sem tokens nem senhas. O
`doors.py` da aula 12 precisava de um servidor rodando, três senhas e um token para cada pessoa; como
teste, ele é uma tabela. O `tests/test_api.py`:

```python
# tests/test_api.py
import pytest
from rest_framework.test import APIClient

DOORS = [
    (None, "get", "/api/events/testing-dojo/", 200),
    (None, "patch", "/api/events/testing-dojo/", 401),
    ("carla", "patch", "/api/events/testing-dojo/", 403),
    ("bruno", "patch", "/api/events/testing-dojo/", 200),
    ("bruno", "patch", "/api/events/async-workshop/", 403),
    ("ana", "patch", "/api/events/async-workshop/", 200),
    ("bruno", "post", "/api/events/", 403),
    ("ana", "post", "/api/events/", 400),
]


@pytest.mark.parametrize("who, method, path, expected", DOORS)
def test_doors(request, workshop, dojo, who, method, path, expected):
    client = APIClient()
    if who is not None:
        client.force_authenticate(request.getfixturevalue(who))
    answer = getattr(client, method)(path, {}, format="json")
    assert answer.status_code == expected
```

O `@pytest.mark.parametrize` roda o teste uma vez por linha, cada uma com suas fixtures e seu rollback.
O `request.getfixturevalue(who)` transforma o nome da linha na fixture com esse nome:

```
ana@vm:~/agenda$ uv run pytest tests/test_api.py -v
======================================= test session starts ========================================
platform linux -- Python 3.12.3, pytest-9.1.1, pluggy-1.7.0 -- /home/ana/agenda/.venv/bin/python
cachedir: .pytest_cache
django: version: 6.1.2, settings: config.settings (from ini)
rootdir: /home/ana/agenda
configfile: pyproject.toml
plugins: anyio-4.15.1, django-4.14.0
collecting ... collected 8 items

tests/test_api.py::test_doors[None-get-/api/events/testing-dojo/-200] PASSED                 [ 12%]
tests/test_api.py::test_doors[None-patch-/api/events/testing-dojo/-401] PASSED               [ 25%]
tests/test_api.py::test_doors[carla-patch-/api/events/testing-dojo/-403] PASSED              [ 37%]
tests/test_api.py::test_doors[bruno-patch-/api/events/testing-dojo/-200] PASSED              [ 50%]
tests/test_api.py::test_doors[bruno-patch-/api/events/async-workshop/-403] PASSED            [ 62%]
tests/test_api.py::test_doors[ana-patch-/api/events/async-workshop/-200] PASSED              [ 75%]
tests/test_api.py::test_doors[bruno-post-/api/events/-403] PASSED                            [ 87%]
tests/test_api.py::test_doors[ana-post-/api/events/-400] PASSED                              [100%]

======================================== 8 passed in 5.75s =========================================
```

**Cada porta é um teste próprio**, com o nome da sua linha, então uma falha diz qual pessoa, qual método
e qual caminho. A diferença para o `doors.py` é onde ele roda: a cada mudança, antes de qualquer coisa
chegar a um servidor, que é o ponto da aula 12 sobre uma permissão esquecida. A última seção desta aula
mostra a tabela pegando uma.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 254\" role=\"img\" aria-label=\"Cinco tipos de requisição desenhados contra as camadas por onde passam: HTTP por um socket, middlewares e roteamento, view ou rota, serviço, banco. O test_services.py chama o register direto e cobre o serviço e o banco. O cliente de testes do Django, o APIClient do DRF e o TestClient do Starlette começam nos middlewares e no roteamento e descem até o banco. O doors.py da aula 12 também atravessa um socket de verdade até um servidor rodando.\"> <text x=\"220\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">HTTP por</text> <text x=\"220\" y=\"43\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um socket</text> <text x=\"330\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">middlewares</text> <text x=\"330\" y=\"43\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">e roteamento</text> <text x=\"440\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">view</text> <text x=\"440\" y=\"43\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ou rota</text> <text x=\"550\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">serviço</text> <text x=\"660\" y=\"30\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">banco</text> <text x=\"160\" y=\"77\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">test_services.py</text> <rect x=\"500\" y=\"60\" width=\"210\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"508\" y=\"76\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">register() chamado direto</text> <text x=\"160\" y=\"111\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">test_pages.py</text> <rect x=\"280\" y=\"94\" width=\"430\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"288\" y=\"110\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente de testes do Django</text> <text x=\"160\" y=\"145\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">test_api.py, Django</text> <rect x=\"280\" y=\"128\" width=\"430\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"288\" y=\"144\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">APIClient do DRF</text> <text x=\"160\" y=\"179\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">test_api.py, FastAPI</text> <rect x=\"280\" y=\"162\" width=\"430\" height=\"24\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.18\" stroke=\"var(--phosphor)\"></rect> <text x=\"288\" y=\"178\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">TestClient do Starlette</text> <text x=\"160\" y=\"213\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">doors.py, aula 12</text> <rect x=\"170\" y=\"196\" width=\"540\" height=\"24\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\"0.18\" stroke=\"var(--amber)\"></rect> <text x=\"178\" y=\"212\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um servidor rodando</text> <text x=\"360\" y=\"240\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Todo teste aqui, menos o último, roda num processo, contra um banco de testes.</text> </svg>", "caption": "Quanto da aplicação cada tipo de teste exercita. Os clientes só pulam a rede, e é por isso que são rápidos.", "same": ["view"]}
```
