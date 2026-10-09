---
title: Montando o shipquote
version: 1
---

O projeto em que todas as aulas trabalham se chama `shipquote`. Ele responde a uma pergunta de uma
pequena livraria online de São Paulo: **quanto custa mandar este pacote para aquele CEP?** É Python
sem nada fora da biblioteca padrão, e os testes usam pytest. Esta seção monta o projeto como ele
está no começo do curso: 24 arquivos e umas quinhentas linhas, todos abaixo, inteiros.

**Copie cada arquivo com o botão do bloco** em vez de redigitá-lo. O Python lê a indentação como
estrutura, e uma linha que perdeu quatro espaços no caminho é o jeito mais comum de esta seção dar
errado; a próxima mostra como isso aparece. Três dos arquivos, `carrier.py`, `orders.py` e
`dispatch.py`, e os testes ao lado deles, são das aulas 2 e 3. Eles estão aqui agora para o
projeto ficar inteiro desde a primeira aula, e as execuções desta aula contam os testes deles.

## Os diretórios

```sh
mkdir -p ~/shipquote/shipquote ~/shipquote/tests
cd ~/shipquote
touch shipquote/__init__.py tests/__init__.py
```

Os dois `__init__.py` vazios tornam `shipquote` e `tests` pacotes, e é isso que deixa um teste
escrever `from shipquote.money import brl` e `from tests.conftest import get`. Todo arquivo abaixo
é salvo relativo a `~/shipquote`.

## Como o projeto se descreve

Um README curto, salvo como `README.md`:

```
# shipquote

What it costs to send a parcel from our shop in São Paulo to any CEP in
Brazil, in cents. Run the tests with:

    python -m pytest
```

Os arquivos que o git nunca deve guardar: o ambiente virtual, os caches do Python, os dados do
coverage e as versões construídas da aula 7. Salve como `.gitignore`:

```
.venv/
__pycache__/
.pytest_cache/
.coverage
htmlcov/
dist/
```

As três bibliotecas que os testes usam, fixadas em versões exatas para que as suas execuções
imprimam o que estas aulas imprimem. Salve como `requirements-dev.txt`:

```
pytest==9.1.1
coverage==7.16.2
hypothesis==6.168.5
```

E a configuração que o pytest e o coverage leem. Os `markers` são os nomes das camadas de teste de
que esta aula trata, e a seção 14 explica cada linha da parte do pytest. Salve como
`pyproject.toml`:

```toml
[project]
name = "shipquote"
version = "0"
requires-python = ">=3.11"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers"
markers = [
    "integration: talks to a real SQLite file",
    "functional: starts the HTTP server",
    "acceptance: a promise the shop makes, checked from outside",
]

[tool.coverage.run]
branch = true
source = ["shipquote"]

[tool.coverage.report]
show_missing = true
```

## O programa

Dinheiro, guardado em centavos inteiros e formatado do jeito brasileiro. Salve como
`shipquote/money.py`:

```python
"""Money as integer cents, never as a float."""


def brl(cents: int) -> str:
    """Format cents the way a Brazilian price tag shows them: R$ 1.234,56."""
    sign = "-" if cents < 0 else ""
    reais, centavos = divmod(abs(cents), 100)
    return f"{sign}R$ {reais:,}".replace(",", ".") + f",{centavos:02d}"


def split(cents: int, parts: int) -> list[int]:
    """Split a total into instalments that add back up; odd cents go first."""
    if parts < 1:
        raise ValueError(f"parts must be at least 1, got {parts}")
    base, rest = divmod(cents, parts)
    return [base + 1 if i < rest else base for i in range(parts)]
```

A tabela de frete: uma zona pelo primeiro dígito do CEP, um preço base por zona, um acréscimo a
cada 500 g e frete grátis a partir de R$ 199,00. A seção 08 a lê linha por linha. Salve como
`shipquote/quote.py`:

```python
"""What it costs to send a parcel, in cents."""

# The first digit of a CEP says which region of Brazil it is in.
ZONES = {"0": "SP", "1": "SP", "2": "SE", "3": "SE", "4": "NE",
         "5": "NE", "6": "N", "7": "CO", "8": "S", "9": "S"}
BASE = {"SP": 1290, "SE": 1590, "S": 1890, "CO": 2190, "NE": 2490, "N": 2990}
EXTRA_PER_500G = 450      # every 500 g started after the first
FREE_FROM = 19900         # an order of R$ 199,00 or more ships free


def normalise_cep(cep: str) -> str:
    digits = cep.replace("-", "")
    if len(digits) != 8 or not digits.isdigit():
        raise ValueError(f"not a CEP: {cep!r}")
    return digits


def zone_of(cep: str) -> str:
    return ZONES[normalise_cep(cep)[0]]


def freight(cep: str, weight_g: int, subtotal_cents: int) -> int:
    if weight_g <= 0:
        raise ValueError(f"weight must be positive, got {weight_g}")
    zone = zone_of(cep)
    if subtotal_cents >= FREE_FROM:
        return 0
    extra = (weight_g - 1) // 500
    return BASE[zone] + extra * EXTRA_PER_500G
```

Cotações guardadas em SQLite, para o cliente poder voltar a uma delas. A seção 09 trata disso.
Salve como `shipquote/store.py`:

```python
"""Quotes kept in SQLite, so a customer can come back to one."""
import sqlite3

SCHEMA = """
CREATE TABLE IF NOT EXISTS quotes (
    id INTEGER PRIMARY KEY,
    cep TEXT NOT NULL CHECK (length(cep) = 8),
    weight_g INTEGER NOT NULL CHECK (weight_g > 0),
    cents INTEGER NOT NULL CHECK (cents >= 0),
    created_at TEXT NOT NULL
)
"""
COLUMNS = ("id", "cep", "weight_g", "cents", "created_at")


class Store:
    def __init__(self, path):
        self.db = sqlite3.connect(path)
        self.db.execute(SCHEMA)

    def save(self, cep, weight_g, cents, created_at):
        with self.db:
            cur = self.db.execute(
                "INSERT INTO quotes (cep, weight_g, cents, created_at)"
                " VALUES (?, ?, ?, ?)",
                (cep, weight_g, cents, created_at))
        return cur.lastrowid

    def get(self, quote_id):
        row = self.db.execute(
            "SELECT id, cep, weight_g, cents, created_at FROM quotes"
            " WHERE id = ?", (quote_id,)).fetchone()
        return None if row is None else dict(zip(COLUMNS, row))

    def recent(self, n):
        rows = self.db.execute(
            "SELECT id FROM quotes ORDER BY created_at DESC, id DESC LIMIT ?",
            (n,)).fetchall()
        return [r[0] for r in rows]

    def close(self):
        self.db.close()
```

A versão que o programa informa. Um build na aula 7 grava um arquivo chamado `VERSION` ao lado
deste; até lá ele diz `dev`. Salve como `shipquote/version.py`:

```python
"""The version this copy of shipquote was built as.

The build writes it into a file beside this one. A copy that nobody built,
such as a checkout, says "dev" rather than guessing.
"""
from pathlib import Path

_stamp = Path(__file__).with_name("VERSION")
VERSION = _stamp.read_text().strip() if _stamp.exists() else "dev"
```

O servidor HTTP, com três rotas: `/health`, `/version` e `/quote`. A seção 10 fala com ele. Salve
como `shipquote/app.py`:

```python
"""The HTTP face of shipquote: /health, /version and /quote."""
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from . import money, quote
from .version import VERSION


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.started = time.monotonic()
        url = urlparse(self.path)
        if url.path == "/health":
            return self.reply(200, {"status": "ok"})
        if url.path == "/version":
            env = os.environ.get("SHIPQUOTE_ENV", "dev")
            return self.reply(200, {"version": VERSION, "env": env})
        if url.path != "/quote":
            return self.reply(404, {"error": "not found"})
        args = parse_qs(url.query)
        try:
            cep = args["cep"][0]
            weight_g = int(args["weight"][0])
            subtotal = int(args.get("subtotal", ["0"])[0])
            cents = quote.freight(cep, weight_g, subtotal)
        except KeyError as e:
            return self.reply(400, {"error": f"missing {e.args[0]}"})
        except ValueError as e:
            return self.reply(400, {"error": str(e)})
        try:
            body = self.quote_body(cep, cents)
        except Exception as e:  # noqa: BLE001 -- answered as a 500 and logged
            print(f"error: {type(e).__name__}: {e}", file=sys.stderr)
            return self.reply(500, {"error": "internal error"})
        self.reply(200, body)

    def quote_body(self, cep, cents):
        return {"cep": cep, "zone": quote.zone_of(cep),
                "cents": cents, "price": money.brl(cents)}

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        ms = (time.monotonic() - getattr(self, "started", time.monotonic())) * 1000
        print(f"{self.command} {self.path} {args[1]} {ms:.1f}ms v={VERSION}",
              file=sys.stderr)


def main():
    port = int(os.environ.get("SHIPQUOTE_PORT", "8080"))
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"shipquote {VERSION} listening on 127.0.0.1:{port}", file=sys.stderr)
    server.serve_forever()


if __name__ == "__main__":
    main()
```

O assunto da aula 2: pedir à transportadora o preço dela, e cair na tabela quando ela não responde.
Salve como `shipquote/carrier.py`:

```python
"""The carrier's own price, asked over HTTP, with our table as the fallback."""
import json
import urllib.error
import urllib.request

from . import quote


class CarrierError(Exception):
    pass


class CarrierClient:
    def __init__(self, base_url, token, timeout=2.0,
                 opener=urllib.request.urlopen):
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.timeout = timeout
        self.opener = opener

    def rate(self, cep, weight_g):
        req = urllib.request.Request(
            f"{self.base_url}/v1/rate?cep={cep}&weight={weight_g}",
            headers={"Authorization": f"Bearer {self.token}"})
        try:
            with self.opener(req, timeout=self.timeout) as resp:
                return int(json.load(resp)["cents"])
        except (OSError, KeyError, ValueError) as e:
            raise CarrierError(str(e)) from e


def price(carrier, cep, weight_g, subtotal_cents, log=print):
    """The carrier's price when it answers, the table's when it does not."""
    if subtotal_cents >= quote.FREE_FROM:
        return 0
    try:
        return carrier.rate(quote.normalise_cep(cep), weight_g)
    except CarrierError as e:
        log(f"carrier unavailable, using the table: {e}")
        return quote.freight(cep, weight_g, subtotal_cents)
```

Também da aula 2: fazer um pedido, o que o grava e manda uma confirmação. Salve como
`shipquote/orders.py`:

```python
"""Placing an order: record it, then tell the customer, once."""
from .money import brl


def place(orders, mailer, email, cents):
    if cents <= 0:
        raise ValueError(f"an order must cost something, got {cents}")
    order_id = orders.add(email, cents)
    mailer.send(to=email, subject=f"Order {order_id} confirmed",
                body=f"Total: {brl(cents)}")
    return order_id
```

E da aula 3: o dia em que um pedido sai do depósito, com corte às duas da tarde. Salve como
`shipquote/dispatch.py`:

```python
"""Which day an order leaves the warehouse."""
from datetime import date, datetime, time, timedelta
from zoneinfo import ZoneInfo

WAREHOUSE = ZoneInfo("America/Sao_Paulo")
CUTOFF = time(14, 0)          # orders after 14:00 leave the next working day


def dispatch_date(ordered_at: float) -> date:
    """The day an order placed at this Unix time leaves the warehouse."""
    local = datetime.fromtimestamp(ordered_at, WAREHOUSE)
    day = local.date()
    if local.time() >= CUTOFF:
        day += timedelta(days=1)
    while day.weekday() >= 5:     # Saturday and Sunday
        day += timedelta(days=1)
    return day
```

## Os testes

O que vários arquivos de teste compartilham: um banco novo por teste, o servidor HTTP iniciado uma
vez por arquivo e uma função que faz um GET. A aula 3 trata das duas primeiras. Salve como
`tests/conftest.py`:

```python
import json
import threading
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer

import pytest

from shipquote.app import Handler
from shipquote.store import Store


@pytest.fixture
def store(tmp_path):
    s = Store(tmp_path / "quotes.db")
    yield s
    s.close()


@pytest.fixture(scope="module")
def base_url():
    server = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    yield f"http://127.0.0.1:{server.server_port}"
    server.shutdown()
    server.server_close()


def get(url):
    """GET a URL and return (status, decoded JSON), whatever the status."""
    try:
        with urllib.request.urlopen(url) as resp:
            return resp.status, json.load(resp)
    except urllib.error.HTTPError as e:
        return e.code, json.load(e)
```

Os primeiros testes que o projeto teve, que a seção 06 executa. Salve como `tests/test_money.py`:

```python
from shipquote.money import brl, split


def test_brl_uses_a_dot_for_thousands_and_a_comma_for_cents():
    assert brl(123456) == "R$ 1.234,56"


def test_brl_keeps_two_digits_of_cents():
    assert brl(1205) == "R$ 12,05"


def test_split_hands_the_odd_cents_to_the_first_instalments():
    assert split(10000, 3) == [3334, 3333, 3333]


def test_split_adds_back_up_to_the_total():
    assert sum(split(19990, 7)) == 19990
```

As regras de frete nas bordas, assunto da seção 08. Salve como `tests/test_quote.py`:

```python
import pytest

from shipquote.quote import FREE_FROM, freight, zone_of


def test_a_cep_in_the_city_of_sao_paulo_is_zone_sp():
    assert zone_of("01310-100") == "SP"


@pytest.mark.parametrize("weight_g, cents", [
    (1, 1290),
    (500, 1290),
    (501, 1740),
    (1000, 1740),
    (1001, 2190),
])
def test_every_500_g_started_after_the_first_costs_extra(weight_g, cents):
    assert freight("01310-100", weight_g, 5000) == cents


@pytest.mark.parametrize("subtotal, cents", [
    (FREE_FROM - 1, 1290),
    (FREE_FROM, 0),
    (FREE_FROM + 1, 0),
])
def test_an_order_of_199_reais_or_more_ships_free(subtotal, cents):
    assert freight("01310-100", 300, subtotal) == cents


def test_a_weight_of_zero_is_refused():
    with pytest.raises(ValueError, match="weight must be positive"):
        freight("01310-100", 0, 5000)


def test_a_cep_with_a_letter_in_it_is_refused():
    with pytest.raises(ValueError, match="not a CEP"):
        zone_of("0131O-100")
```

O store contra um arquivo SQLite de verdade, da seção 09. Salve como `tests/test_store.py`:

```python
import sqlite3

import pytest

pytestmark = pytest.mark.integration


def test_a_saved_quote_comes_back_by_id(store):
    quote_id = store.save("01310100", 1200, 2190, "2026-10-05T13:30:00-03:00")
    assert store.get(quote_id)["cents"] == 2190


def test_recent_lists_the_newest_first(store):
    first = store.save("01310100", 1200, 2190, "2026-10-05T13:30:00-03:00")
    second = store.save("20040002", 300, 1590, "2026-10-05T13:31:00-03:00")
    assert store.recent(2) == [second, first]


def test_the_database_refuses_a_cep_of_the_wrong_length(store):
    with pytest.raises(sqlite3.IntegrityError, match="CHECK constraint failed"):
        store.save("0131010", 1200, 2190, "2026-10-05T13:30:00-03:00")
```

O servidor por HTTP, da seção 10. Salve como `tests/test_app.py`:

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

A promessa de frete grátis da loja, da seção 11. Salve como `tests/test_acceptance.py`:

```python
"""The promise on the shop's front page, checked through the same door a
customer's browser uses: free shipping from R$ 199,00, anywhere in Brazil."""
import pytest

from tests.conftest import get

pytestmark = pytest.mark.acceptance

ONE_CEP_PER_REGION = ["01310-100", "20040-002", "40010-000",
                      "69005-010", "70040-010", "80010-000"]


def test_a_basket_of_199_reais_ships_free_to_every_region(base_url):
    # Given a basket worth exactly R$ 199,00, weighing 2.5 kg
    # When a customer in each region of Brazil asks for a quote
    # Then every one of them is told the freight is R$ 0,00
    for cep in ONE_CEP_PER_REGION:
        status, body = get(f"{base_url}/quote?cep={cep}&weight=2500&subtotal=19900")
        assert (status, body["price"]) == (200, "R$ 0,00"), cep
```

Dois substitutos que a aula 2 explica, uma transportadora que responde o que mandaram e pedidos
guardados numa lista. Salve como `tests/fakes.py`:

```python
class FakeOrders:
    """Orders kept in a list: the real table's behaviour, without the table."""

    def __init__(self):
        self.rows = []

    def add(self, email, cents):
        self.rows.append((email, cents))
        return len(self.rows)


class StubCarrier:
    """Answers whatever it was told to answer. No network and no logic."""

    def __init__(self, cents=None, error=None):
        self.cents = cents
        self.error = error

    def rate(self, cep, weight_g):
        if self.error is not None:
            raise self.error
        return self.cents
```

Os testes da transportadora, que os usam. Salve como `tests/test_carrier.py`:

```python
from unittest import mock

from shipquote.carrier import CarrierError, price
from tests.fakes import StubCarrier


def test_the_carriers_price_wins_when_it_answers():
    assert price(StubCarrier(cents=1999), "01310-100", 1200, 5000) == 1999


def test_the_table_is_used_when_the_carrier_is_down():
    stub = StubCarrier(error=CarrierError("timed out"))
    assert price(stub, "01310-100", 1200, 5000, log=lambda line: None) == 2190


def test_the_fallback_is_logged_with_the_reason():
    lines = []
    stub = StubCarrier(error=CarrierError("timed out"))
    price(stub, "01310-100", 1200, 5000, log=lines.append)
    assert lines == ["carrier unavailable, using the table: timed out"]


def test_a_free_order_never_asks_the_carrier():
    carrier = mock.Mock()
    assert price(carrier, "01310-100", 1200, 19900) == 0
    carrier.rate.assert_not_called()
```

Os testes dos pedidos. Salve como `tests/test_orders.py`:

```python
from unittest import mock

import pytest

from shipquote.orders import place
from tests.fakes import FakeOrders


def test_placing_an_order_sends_exactly_one_confirmation():
    mailer = mock.Mock()
    order_id = place(FakeOrders(), mailer, "bia@example.org", 8990)
    mailer.send.assert_called_once_with(
        to="bia@example.org", subject=f"Order {order_id} confirmed",
        body="Total: R$ 89,90")


def test_an_order_of_nothing_is_refused_before_anything_is_written():
    orders = FakeOrders()
    with pytest.raises(ValueError, match="must cost something"):
        place(orders, mailer=None, email="bia@example.org", cents=0)
    assert orders.rows == []
```

E os do dia de despacho. Salve como `tests/test_dispatch.py`:

```python
from datetime import date

from shipquote.dispatch import dispatch_date

# 2026-10-05 is a Monday, and São Paulo is three hours behind UTC.
MONDAY_1330_SP = 1791217800                    # 16:30 UTC
MONDAY_1430_SP = MONDAY_1330_SP + 3600
FRIDAY_1500_SP = MONDAY_1330_SP + 4 * 86400 + 5400


def test_an_order_before_two_leaves_the_same_day():
    assert dispatch_date(MONDAY_1330_SP) == date(2026, 10, 5)


def test_an_order_after_two_leaves_the_next_day():
    assert dispatch_date(MONDAY_1430_SP) == date(2026, 10, 6)


def test_an_order_on_friday_afternoon_leaves_on_monday():
    assert dispatch_date(FRIDAY_1500_SP) == date(2026, 10, 12)
```

## Rodando uma vez

O ambiente virtual fica dentro do projeto, em `.venv`, com Python 3.13 e as três bibliotecas
fixadas. O `source` o ativa, para que `python` neste terminal signifique o do ambiente:

```
ana@laptop:~/shipquote$ uv venv -p 3.13
Using CPython 3.13.16 interpreter at: /usr/bin/python3.13
Creating virtual environment at: .venv
Activate with: source .venv/bin/activate
ana@laptop:~/shipquote$ source .venv/bin/activate
ana@laptop:~/shipquote$ uv pip install -r requirements-dev.txt
Resolved 8 packages in 282ms
Downloading pygments (1.2MiB)
Downloading hypothesis (1.1MiB)
 Downloaded hypothesis
 Downloaded pygments
Prepared 8 packages in 62ms
Installed 8 packages in 8ms
 + coverage==7.16.2
 + hypothesis==6.168.5
 + iniconfig==2.3.1
 + packaging==26.3
 + pluggy==1.6.0
 + pygments==2.21.0
 + pytest==9.1.1
 + sortedcontainers==2.4.0
```

Num Ubuntu 24.04 novo, cujo Python é o 3.12, o `uv venv` primeiro baixa um Python 3.13 e diz isso
em algumas linhas a mais que estas; esta máquina já tinha um. Depois a suíte inteira, uma vez:

```
ana@laptop:~/shipquote$ python -m pytest -q
...............................                                          [100%]
31 passed in 1.77s
```

**31 passed.** Se você vê esse número, o projeto é o mesmo em que as aulas trabalham. Qualquer
outra coisa é assunto da próxima seção.

## Guardando

O projeto é um repositório git daqui em diante: a aula 5 faz push dele, e a aula 7 constrói versões
a partir das tags dele.

```
ana@laptop:~/shipquote$ git init
Initialized empty Git repository in /home/ana/shipquote/.git/
ana@laptop:~/shipquote$ git add .
ana@laptop:~/shipquote$ git commit -q -m "shipquote as the course begins"
ana@laptop:~/shipquote$ git log --oneline
055b654 shipquote as the course begins
```

O seu hash não é `055b654`; o resto da linha é igual. **Cada terminal novo precisa de
`cd ~/shipquote` e `source .venv/bin/activate`** antes que qualquer transcrição deste curso funcione
nele.
