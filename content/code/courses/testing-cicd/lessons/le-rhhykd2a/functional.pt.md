---
title: Testes funcionais
version: 1
---

Um **teste funcional** exercita a aplicação pela interface que os usuários usam, aqui HTTP, e
confere o que volta. Ele não sabe de `freight` nem de `Store`. Sabe que um GET em `/quote` com um
CEP e um peso precisa responder 200 e um corpo JSON com o preço formatado.

Antes de automatizar, eis a mesma verificação à mão, contra o servidor rodando num notebook:

```
ana@laptop:~/shipquote$ curl -s 'http://127.0.0.1:8080/quote?cep=01310-100&weight=1200&subtotal=5000'; echo
{"cep": "01310-100", "zone": "SP", "cents": 2190, "price": "R$ 21,90"}
ana@laptop:~/shipquote$ curl -s -i 'http://127.0.0.1:8080/quote?cep=abc&weight=1200'; echo
HTTP/1.0 400 Bad Request
Server: BaseHTTP/0.6 Python/3.13.16
Date: Tue, 06 Oct 2026 15:53:59 GMT
Content-Type: application/json
Content-Length: 29

{"error": "not a CEP: 'abc'"}
```

A segunda requisição é uma recusa: uma linha de status `400 Bad Request` e um corpo que diz por
quê. As duas respostas são comportamento do qual um cliente depende, e um teste unitário de
`freight` não alcança nenhuma: nem o código de status, nem a codificação JSON, nem a leitura de
`weight` da query string.

## A mesma verificação, automatizada

Os testes funcionais sobem o servidor de verdade dentro do processo de teste, numa porta que o
sistema operacional escolhe, e mandam requisições HTTP reais para ele. A fixture que faz isso fica
em `tests/conftest.py`:

```schooling-example
{
  "language": "python",
  "file": "tests/conftest.py",
  "parts": [
    {
      "code": "@pytest.fixture(scope=\"module\")\ndef base_url():\n    server = ThreadingHTTPServer((\"127.0.0.1\", 0), Handler)\n    threading.Thread(target=server.serve_forever, daemon=True).start()\n    yield f\"http://127.0.0.1:{server.server_port}\"\n    server.shutdown()\n    server.server_close()",
      "note": "A porta `0` pede ao sistema operacional qualquer porta livre, então duas execuções na mesma máquina nunca colidem. O servidor roda numa thread de fundo, e a fixture entrega aos testes o endereço dele. Tudo depois do `yield` roda quando os testes terminam: o servidor para e o socket é fechado."
    },
    {
      "code": "def get(url):\n    \"\"\"GET a URL and return (status, decoded JSON), whatever the status.\"\"\"\n    try:\n        with urllib.request.urlopen(url) as resp:\n            return resp.status, json.load(resp)\n    except urllib.error.HTTPError as e:\n        return e.code, json.load(e)",
      "note": "Uma função auxiliar que devolve o status e o corpo decodificado, seja qual for o status. O `urllib` levanta exceção num 4xx, e um teste sobre uma recusa precisa do corpo da recusa."
    }
  ]
}
```

e os testes se leem como a sessão acima:

```python
import pytest

from tests.conftest import get

pytestmark = pytest.mark.functional


def test_health_answers_ok(base_url):
    assert get(base_url + "/health") == (200, {"status": "ok"})


def test_a_quote_comes_back_as_json_with_the_price_formatted(base_url):
    status, body = get(base_url + "/quote?cep=01310-100&weight=1200&subtotal=5000")
    assert status == 200
    assert body == {"cep": "01310-100", "zone": "SP",
                    "cents": 2190, "price": "R$ 21,90"}


def test_a_bad_cep_is_a_400_that_says_why(base_url):
    status, body = get(base_url + "/quote?cep=abc&weight=1200")
    assert status == 400
    assert body == {"error": "not a CEP: 'abc'"}
```

```
ana@laptop:~/shipquote$ python -m pytest -m functional -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
testpaths: tests
plugins: hypothesis-6.168.5
collecting ... collected 31 items / 28 deselected / 3 selected

tests/test_app.py::test_health_answers_ok PASSED                         [ 33%]
tests/test_app.py::test_a_quote_comes_back_as_json_with_the_price_formatted PASSED [ 66%]
tests/test_app.py::test_a_bad_cep_is_a_400_that_says_why PASSED          [100%]

======================= 3 passed, 28 deselected in 0.68s =======================
```

## O que esta camada custa

Três testes levaram 0,68 segundo, contra 0,16 de onze testes unitários. A seção 09 mede para onde o
tempo vai; não são as requisições. O que importa aqui é a troca: **um teste funcional vê a ligação
que todas as outras camadas supõem**, a rota, a leitura dos parâmetros, a codificação, o código de
status, ao preço de ser mais lento e de apontar com menos precisão a causa quando falha. Um teste
funcional vermelho diz "o endpoint de cotação está errado"; um unitário vermelho diz "a linha de
501 g está errada".

Um teste funcional também pode ser escrito contra um navegador em vez de uma API. Pilotar um
navegador de verdade é um ofício à parte, coberto na trilha `qa` por `web-automation`. O princípio
é o mesmo: o teste usa a interface que uma pessoa usaria.
