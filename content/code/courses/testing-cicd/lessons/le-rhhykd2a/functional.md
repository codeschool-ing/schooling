---
title: Functional tests
version: 1
---

A **functional test** exercises the application through the interface its users use, here HTTP,
and checks what comes back. It does not know about `freight` or `Store`. It knows that a GET on
`/quote` with a CEP and a weight must answer 200 and a JSON body with a formatted price.

Before automating it, here is the same check by hand, against the server running on a laptop:

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

The second request is a refusal: a status line of `400 Bad Request`, and a body that says why.
Both answers are behaviour a client depends on, and a unit test of `freight` reaches neither of
them: not the status code, not the JSON encoding, not the parsing of `weight` from a query string.

## The same check, automated

The functional tests start the real server inside the test process, on a port the operating
system picks, and send real HTTP requests to it. The fixture that does this lives in
`tests/conftest.py`:

```schooling-example
{
  "language": "python",
  "file": "tests/conftest.py",
  "parts": [
    {
      "code": "@pytest.fixture(scope=\"module\")\ndef base_url():\n    server = ThreadingHTTPServer((\"127.0.0.1\", 0), Handler)\n    threading.Thread(target=server.serve_forever, daemon=True).start()\n    yield f\"http://127.0.0.1:{server.server_port}\"\n    server.shutdown()\n    server.server_close()",
      "note": "Port `0` asks the operating system for any free port, so two test runs on one machine never collide. The server runs in a background thread, and the fixture hands the tests its address. Everything after `yield` runs once the tests are done: the server is stopped and its socket closed."
    },
    {
      "code": "def get(url):\n    \"\"\"GET a URL and return (status, decoded JSON), whatever the status.\"\"\"\n    try:\n        with urllib.request.urlopen(url) as resp:\n            return resp.status, json.load(resp)\n    except urllib.error.HTTPError as e:\n        return e.code, json.load(e)",
      "note": "A helper that returns the status and the decoded body whatever the status is. `urllib` raises on a 4xx, and a test about a refusal needs the refusal's body."
    }
  ]
}
```

and the tests read like the session above:

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

## What this layer costs

Three tests took 0.68 seconds, against 0.16 for eleven unit tests. Section 09 measures where the
time goes; it is not the requests. What matters here is the trade: **a functional test sees the
wiring that every other layer assumes**, the route, the parsing, the encoding, the status code, at
the price of being slower and of pointing less precisely at the cause when it fails. A red
functional test says "the quote endpoint is wrong"; a red unit test says "the 501 g row is wrong".

A functional test can also be written against a browser rather than an API. Driving a real
browser is its own craft, covered in the `qa` track by `web-automation`. The principle is the
same: the test uses the interface a person would.
