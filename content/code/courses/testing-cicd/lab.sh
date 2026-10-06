#!/usr/bin/env bash
# shipquote, the project every lesson of testing-cicd tests, builds and ships.
#
# shipquote answers one question for a small online bookshop in São Paulo: what
# does it cost to send this parcel to that CEP? It is Python with no dependency
# outside the standard library; its tests use pytest, coverage and hypothesis,
# pinned in requirements-dev.txt. The language is incidental. What the course
# teaches about a test, a pipeline or a release is the same in any of them.
#
#   bash lab.sh stage N [DIR]   rebuild DIR (default ~/shipquote) with steps 1..N
#   bash lab.sh venv DIR [PY]   a virtual environment in DIR/.venv with the pins
#   bash lab.sh carrier DIR     write the carrier stand-in to DIR/server.py
#   bash lab.sh ci DIR          a bare repository in DIR/shipquote.git whose
#                               post-receive hook is the lab's CI
#   bash lab.sh steps           list the steps
#
# THE HISTORY IS STAGED, NOT LIVED. Every commit carries the date written beside
# it, so the hashes are the same every time the history is rebuilt, and a lesson
# that prints one prints the same one. The code at each step is the code that
# step committed, and each step passes the tests that existed when it was made.
#
# THE CARRIER IS A STAND-IN. A real bookshop would ask a carrier's API for a
# price. This lab cannot reach one, so `lab.sh carrier` writes a small HTTP
# server that answers the same shape of question on 127.0.0.1. The lessons say
# so wherever it appears.
#
# The venv command needs uv (https://docs.astral.sh/uv/) and, the first time,
# the network to fetch the three pinned packages.
set -euo pipefail
REPO=${SHIPQUOTE:-$HOME/shipquote}
export GIT_AUTHOR_NAME='Ana Lima' GIT_AUTHOR_EMAIL=ana@example.org
export GIT_COMMITTER_NAME='Ana Lima' GIT_COMMITTER_EMAIL=ana@example.org

at() { GIT_AUTHOR_DATE=$1 GIT_COMMITTER_DATE=$1 git commit -q -m "$2"; }

# ---- step 1: Money in cents, with its first tests
step_1() {
  mkdir -p shipquote tests
  cat > README.md <<'EOF'
# shipquote

What it costs to send a parcel from our shop in São Paulo to any CEP in
Brazil, in cents. Run the tests with:

    python -m pytest
EOF
  cat > .gitignore <<'EOF'
.venv/
__pycache__/
.pytest_cache/
.coverage
htmlcov/
dist/
EOF
  cat > requirements-dev.txt <<'EOF'
pytest==9.1.1
coverage==7.16.2
hypothesis==6.168.5
EOF
  cat > pyproject.toml <<'EOF'
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
EOF
  : > shipquote/__init__.py
  : > tests/__init__.py
  cat > shipquote/money.py <<'EOF'
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
EOF
  cat > tests/test_money.py <<'EOF'
from shipquote.money import brl, split


def test_brl_uses_a_dot_for_thousands_and_a_comma_for_cents():
    assert brl(123456) == "R$ 1.234,56"


def test_brl_keeps_two_digits_of_cents():
    assert brl(1205) == "R$ 12,05"


def test_split_hands_the_odd_cents_to_the_first_instalments():
    assert split(10000, 3) == [3334, 3333, 3333]


def test_split_adds_back_up_to_the_total():
    assert sum(split(19990, 7)) == 19990
EOF
}
commit_1() { at 2026-09-01T09:20:00-03:00 'Money in cents, with its first tests'; }

# ---- step 2: Price a parcel by zone and weight
step_2() {
  cat > shipquote/quote.py <<'EOF'
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
EOF
  cat > tests/test_quote.py <<'EOF'
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
EOF
}
commit_2() { at 2026-09-02T10:05:00-03:00 'Price a parcel by zone and weight'; }

# ---- step 3: Keep quotes in SQLite and answer over HTTP
step_3() {
  cat > shipquote/version.py <<'EOF'
"""The version this copy of shipquote was built as.

The build writes it into a file beside this one. A copy that nobody built,
such as a checkout, says "dev" rather than guessing.
"""
from pathlib import Path

_stamp = Path(__file__).with_name("VERSION")
VERSION = _stamp.read_text().strip() if _stamp.exists() else "dev"
EOF
  cat > shipquote/store.py <<'EOF'
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
EOF
  cat > shipquote/app.py <<'EOF'
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
EOF
  cat > tests/conftest.py <<'EOF'
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
EOF
  cat > tests/test_store.py <<'EOF'
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
EOF
  cat > tests/test_app.py <<'EOF'
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
EOF
  cat > tests/test_acceptance.py <<'EOF'
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
EOF
}
commit_3() { at 2026-09-03T14:40:00-03:00 'Keep quotes in SQLite and answer over HTTP'; }

# ---- step 4: Ask the carrier first, and confirm orders by e-mail
step_4() {
  cat > shipquote/carrier.py <<'EOF'
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
EOF
  cat > shipquote/orders.py <<'EOF'
"""Placing an order: record it, then tell the customer, once."""
from .money import brl


def place(orders, mailer, email, cents):
    if cents <= 0:
        raise ValueError(f"an order must cost something, got {cents}")
    order_id = orders.add(email, cents)
    mailer.send(to=email, subject=f"Order {order_id} confirmed",
                body=f"Total: {brl(cents)}")
    return order_id
EOF
  cat > tests/fakes.py <<'EOF'
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
EOF
  cat > tests/test_carrier.py <<'EOF'
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
EOF
  cat > tests/test_orders.py <<'EOF'
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
EOF
}
commit_4() { at 2026-09-08T11:10:00-03:00 'Ask the carrier first, and confirm orders by e-mail'; }

# ---- step 5: Say which day an order leaves the warehouse
step_5() {
  cat > shipquote/dispatch.py <<'EOF'
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
EOF
  cat > tests/test_dispatch.py <<'EOF'
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
EOF
}
commit_5() { at 2026-09-10T16:25:00-03:00 'Say which day an order leaves the warehouse'; }

# ---- step 6: Send e-mail over SMTP, and mock the mailer by its real shape
step_6() {
  cat > shipquote/mailer.py <<'EOF'
"""E-mail through an SMTP server."""
import smtplib
from email.message import EmailMessage


class SmtpMailer:
    def __init__(self, host, port=25):
        self.host = host
        self.port = port

    def send(self, to, subject, body):
        msg = EmailMessage()
        msg["From"] = "pedidos@livraria.example"
        msg["To"] = to
        msg["Subject"] = subject
        msg.set_content(body)
        with smtplib.SMTP(self.host, self.port, timeout=5) as smtp:
            smtp.send_message(msg)
EOF
  cat > tests/test_orders.py <<'EOF'
from unittest import mock

import pytest

from shipquote.mailer import SmtpMailer
from shipquote.orders import place
from tests.fakes import FakeOrders


def test_placing_an_order_sends_exactly_one_confirmation():
    mailer = mock.create_autospec(SmtpMailer, instance=True)
    order_id = place(FakeOrders(), mailer, "bia@example.org", 8990)
    mailer.send.assert_called_once_with(
        to="bia@example.org", subject=f"Order {order_id} confirmed",
        body="Total: R$ 89,90")


def test_an_order_of_nothing_is_refused_before_anything_is_written():
    orders = FakeOrders()
    with pytest.raises(ValueError, match="must cost something"):
        place(orders, mailer=None, email="bia@example.org", cents=0)
    assert orders.rows == []
EOF
  cat > tests/test_carrier_contract.py <<'EOF'
"""The questions the stubs answer, asked of a real carrier endpoint.

Runs only when CARRIER_URL says where one is; CARRIER_TOKEN is its key.
"""
import os

import pytest

from shipquote.carrier import CarrierClient, CarrierError

URL = os.environ.get("CARRIER_URL")
pytestmark = [pytest.mark.contract,
              pytest.mark.skipif(not URL, reason="CARRIER_URL is not set")]


@pytest.fixture
def client():
    return CarrierClient(URL, os.environ.get("CARRIER_TOKEN", ""))


def test_a_rate_is_a_whole_number_of_cents(client):
    cents = client.rate("01310100", 1200)
    assert isinstance(cents, int) and cents > 0


def test_a_wrong_token_is_a_carrier_error_not_a_crash():
    with pytest.raises(CarrierError, match="401"):
        CarrierClient(URL, "not-the-token").rate("01310100", 1200)
EOF
  sed -i 's/^    "acceptance: a promise the shop makes, checked from outside",$/&\n    "contract: asks the real carrier the questions the stubs answer",/' pyproject.toml
}
commit_6() { at 2026-09-14T10:30:00-03:00 'Send e-mail over SMTP, and mock the mailer by its real shape'; }

# ---- step 7: Build test data with a factory, a table and a property
step_7() {
  mkdir -p tests/data
  cat > tests/factories.py <<'EOF'
"""Test data with sensible defaults: a test names only what it is about."""
from itertools import count

_ids = count(1)


def a_quote(**overrides):
    """A valid quote row; override the fields the test cares about."""
    n = next(_ids)
    quote = {
        "cep": "01310100",
        "weight_g": 1200,
        "cents": 2190,
        "created_at": f"2026-10-05T13:{n % 60:02d}:00-03:00",
    }
    quote.update(overrides)
    return quote
EOF
  cat > tests/test_store.py <<'EOF'
import sqlite3

import pytest

from tests.factories import a_quote

pytestmark = pytest.mark.integration


def test_a_saved_quote_comes_back_by_id(store):
    quote_id = store.save(**a_quote(cents=2190))
    assert store.get(quote_id)["cents"] == 2190


def test_recent_lists_the_newest_first(store):
    first = store.save(**a_quote(created_at="2026-10-05T13:30:00-03:00"))
    second = store.save(**a_quote(created_at="2026-10-05T13:31:00-03:00"))
    assert store.recent(2) == [second, first]


def test_the_database_refuses_a_cep_of_the_wrong_length(store):
    with pytest.raises(sqlite3.IntegrityError, match="CHECK constraint failed"):
        store.save(**a_quote(cep="0131010"))
EOF
  cat > tests/data/quotes.csv <<'EOF'
cep,weight_g,subtotal_cents,cents
01310-100,300,5000,1290
01310-100,1200,5000,2190
20040-002,300,5000,1590
40010-000,2600,5000,4740
69005-010,300,5000,2990
69005-010,5000,5000,7040
70040-010,800,5000,2640
80010-000,300,19900,0
EOF
  cat > tests/test_quote_table.py <<'EOF'
"""The price table the shop publishes, one row per case, checked as data."""
import csv
from pathlib import Path

import pytest

from shipquote.quote import freight

ROWS = list(csv.DictReader(open(Path(__file__).parent / "data" / "quotes.csv")))


@pytest.mark.parametrize("row", ROWS, ids=lambda r: f"{r['cep']}-{r['weight_g']}g")
def test_the_published_table(row):
    cents = freight(row["cep"], int(row["weight_g"]), int(row["subtotal_cents"]))
    assert cents == int(row["cents"])
EOF
  cat > tests/test_money_properties.py <<'EOF'
"""Properties of split that hold for every total and every number of parts."""
from hypothesis import given
from hypothesis import strategies as st

from shipquote.money import split

totals = st.integers(min_value=0, max_value=10_000_000)
parts = st.integers(min_value=1, max_value=24)


@given(totals, parts)
def test_the_instalments_add_back_up(cents, n):
    assert sum(split(cents, n)) == cents


@given(totals, parts)
def test_no_instalment_is_more_than_a_cent_from_another(cents, n):
    instalments = split(cents, n)
    assert max(instalments) - min(instalments) <= 1
EOF
}
commit_7() { at 2026-09-17T15:00:00-03:00 'Build test data with a factory, a table and a property'; }

# ---- step 8: Run the checks on GitHub Actions and on GitLab CI
step_8() {
  mkdir -p .github/workflows
  cat > .github/workflows/ci.yml <<'EOF'
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: read

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  fast:
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.13"
          cache: pip
          cache-dependency-path: requirements-dev.txt
      - run: pip install -r requirements-dev.txt
      - run: python -m pytest -q -m "not integration and not functional and not acceptance"

  suite:
    needs: fast
    runs-on: ubuntu-24.04
    timeout-minutes: 10
    strategy:
      fail-fast: false
      matrix:
        python: ["3.11", "3.12", "3.13"]
        tz: ["America/Sao_Paulo", "UTC"]
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: ${{ matrix.python }}
          cache: pip
          cache-dependency-path: requirements-dev.txt
      - run: pip install -r requirements-dev.txt
      - name: Tests in ${{ matrix.tz }}
        shell: bash
        env:
          TZ: ${{ matrix.tz }}
        run: |
          set -euo pipefail
          coverage run -p -m pytest -q --junitxml=junit.xml
      - uses: actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a # v7.0.1
        if: always()
        with:
          name: results-${{ strategy.job-index }}
          path: |
            junit.xml
            .coverage.*
          include-hidden-files: true

  coverage:
    needs: suite
    if: always()
    runs-on: ubuntu-24.04
    timeout-minutes: 5
    steps:
      - uses: actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0 # v7.0.0
      - uses: actions/setup-python@5fda3b95a4ea91299a34e894583c3862153e4b97 # v7.0.0
        with:
          python-version: "3.13"
      - run: pip install coverage==7.16.2
      - uses: actions/download-artifact@3e5f45b2cfb9172054b4087a40e8e0b5a5461e7c # v8.0.1
        with:
          pattern: results-*
          merge-multiple: true
      - run: coverage combine && coverage report
EOF
  cat > .gitlab-ci.yml <<'EOF'
stages: [fast, test, report]

workflow:
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"
    - if: $CI_COMMIT_BRANCH == $CI_DEFAULT_BRANCH

default:
  image: python:3.13-slim

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"

cache:
  key:
    files: [requirements-dev.txt]
  paths: [.cache/pip]

fast:
  stage: fast
  script:
    - pip install -q -r requirements-dev.txt
    - python -m pytest -q -m "not integration and not functional and not acceptance"

suite:
  stage: test
  image: python:${PYTHON}-slim
  parallel:
    matrix:
      - PYTHON: ["3.11", "3.12", "3.13"]
        TZ: ["America/Sao_Paulo", "UTC"]
  script:
    - pip install -q -r requirements-dev.txt
    - coverage run -p -m pytest -q --junitxml=junit.xml
  artifacts:
    when: always
    paths: [".coverage.*"]
    reports:
      junit: junit.xml

coverage:
  stage: report
  when: always
  script:
    - pip install -q coverage==7.16.2
    - coverage combine
    - coverage report
  coverage: '/^TOTAL.*\s(\d+)%$/'
EOF
}
commit_8() { at 2026-09-22T10:00:00-03:00 'Run the checks on GitHub Actions and on GitLab CI'; }

# ---- step 9: Build one artifact, deploy it, and check it answers  [v1.4.0]
step_9() {
  mkdir -p ops
  cat > ops/build.sh <<'EOF'
#!/usr/bin/env bash
# Build the release artifact: the committed tree at HEAD with its version
# stamped in, as one tarball, and the SHA-256 that names those exact bytes.
# The version is the tag on HEAD without its "v", or dev-<commit> if none.
set -euo pipefail
tag=$(git describe --tags --exact-match 2>/dev/null || true)
version=${tag#v}
version=${version:-dev-$(git rev-parse --short HEAD)}
name=shipquote-$version
mkdir -p dist
git archive --format=tar.gz --prefix="$name/" \
  --add-virtual-file="$name/shipquote/VERSION:$version" \
  -o "dist/$name.tar.gz" HEAD
(cd dist && sha256sum "$name.tar.gz" > "$name.tar.gz.sha256")
echo "dist/$name.tar.gz"
EOF
  cat > ops/smoke.sh <<'EOF'
#!/usr/bin/env bash
# The smoke test: is the deployed program up, and is it the version we meant?
#   ops/smoke.sh http://127.0.0.1:8200 1.4.0
set -uo pipefail
url=$1 want=$2
health=$(curl -s --max-time 2 "$url/health") || { echo "smoke: $url does not answer"; exit 1; }
[ "$health" = '{"status": "ok"}' ] || { echo "smoke: /health said $health"; exit 1; }
version=$(curl -s --max-time 2 "$url/version")
case $version in
  *"\"version\": \"$want\""*) echo "smoke: $url is up and running $want" ;;
  *) echo "smoke: $url runs $version, expected $want"; exit 1 ;;
esac
EOF
  cat > ops/deploy.sh <<'EOF'
#!/usr/bin/env bash
# Deploy one built artifact to one environment, then smoke-test it.
#   ops/deploy.sh staging dist/shipquote-1.4.0.tar.gz
# An environment is a directory under ~/envs holding its own config.env;
# every release is unpacked beside the others, and `current` points at one.
set -euo pipefail
env=$1 artifact=$2
root=${SHIPQUOTE_ENVS:-$HOME/envs}/$env
[ -f "$root/config.env" ] || { echo "deploy: $root/config.env does not exist" >&2; exit 1; }
(cd "$(dirname "$artifact")" && sha256sum --check --quiet "$(basename "$artifact").sha256")
name=$(basename "$artifact" .tar.gz)
version=${name#shipquote-}
mkdir -p "$root/releases"
tar -xzf "$artifact" -C "$root/releases"
[ -L "$root/current" ] && ln -sfn "$(readlink "$root/current")" "$root/previous"
ln -sfn "releases/$name" "$root/current"
"$(dirname "$0")/restart.sh" "$env"
set -a; . "$root/config.env"; set +a
"$(dirname "$0")/smoke.sh" "http://127.0.0.1:$SHIPQUOTE_PORT" "$version"
EOF
  cat > ops/restart.sh <<'EOF'
#!/usr/bin/env bash
# Stop the environment's running process, if any, and start `current` with
# the environment's own configuration.
set -euo pipefail
env=$1
root=${SHIPQUOTE_ENVS:-$HOME/envs}/$env
if [ -f "$root/pid" ] && kill -0 "$(cat "$root/pid")" 2>/dev/null; then
  kill "$(cat "$root/pid")"
  while kill -0 "$(cat "$root/pid")" 2>/dev/null; do sleep 0.1; done
fi
set -a; . "$root/config.env"; set +a
export SHIPQUOTE_ENV=$env
cd "$root/current"
setsid python3 -m shipquote.app >> "$root/app.log" 2>&1 < /dev/null &
echo $! > "$root/pid"
for _ in $(seq 50); do
  curl -s --max-time 1 "http://127.0.0.1:$SHIPQUOTE_PORT/health" > /dev/null && exit 0
  sleep 0.1
done
echo "restart: $env did not answer on port $SHIPQUOTE_PORT" >&2
exit 1
EOF
  cat > ops/rollback.sh <<'EOF'
#!/usr/bin/env bash
# Point the environment back at the release it ran before, restart, smoke.
set -euo pipefail
env=$1
root=${SHIPQUOTE_ENVS:-$HOME/envs}/$env
[ -L "$root/previous" ] || { echo "rollback: $env has no previous release" >&2; exit 1; }
before=$(readlink "$root/previous")
ln -sfn "$(readlink "$root/current")" "$root/previous"
ln -sfn "$before" "$root/current"
"$(dirname "$0")/restart.sh" "$env"
set -a; . "$root/config.env"; set +a
"$(dirname "$0")/smoke.sh" "http://127.0.0.1:$SHIPQUOTE_PORT" "${before#releases/shipquote-}"
EOF
  chmod +x ops/*.sh
}
commit_9() {
  at 2026-09-24T11:00:00-03:00 'Build one artifact, deploy it, and check it answers'
  GIT_COMMITTER_DATE=2026-09-24T11:00:00-03:00 git tag -a v1.4.0 -m 'shipquote 1.4.0'
}

steps() {
  echo ' 1  2026-09-01  Money in cents, with its first tests'
  echo ' 2  2026-09-02  Price a parcel by zone and weight'
  echo ' 3  2026-09-03  Keep quotes in SQLite and answer over HTTP'
  echo ' 4  2026-09-08  Ask the carrier first, and confirm orders by e-mail'
  echo ' 5  2026-09-10  Say which day an order leaves the warehouse'
  echo ' 6  2026-09-14  Send e-mail over SMTP, and mock the mailer by its real shape'
  echo ' 7  2026-09-17  Build test data with a factory, a table and a property'
  echo ' 8  2026-09-22  Run the checks on GitHub Actions and on GitLab CI'
  echo ' 9  2026-09-24  Build one artifact, deploy it, and check it answers  [v1.4.0]'
}
LAST=9

venv() {
  local dir=$1 py=${2:-3.13}
  uv venv -q -p "$py" "$dir/.venv"
  VIRTUAL_ENV="$dir/.venv" uv pip install -q -r "$dir/requirements-dev.txt"
}

carrier() {
  mkdir -p "$1"
  cat > "$1/server.py" <<'EOF'
"""A stand-in for a carrier's rate API, on 127.0.0.1, for the lab only.

GET /v1/rate?cep=NNNNNNNN&weight=G with "Authorization: Bearer <token>"
answers {"cents": N}. The token it accepts is read from CARRIER_TOKEN.
CARRIER_DELAY makes every answer that many seconds late.
"""
import json
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

TOKEN = os.environ["CARRIER_TOKEN"]
DELAY = float(os.environ.get("CARRIER_DELAY", "0"))


class Rate(BaseHTTPRequestHandler):
    def do_GET(self):
        time.sleep(DELAY)
        if self.headers.get("Authorization") != f"Bearer {TOKEN}":
            return self.answer(401, {"error": "bad token"})
        url = urlparse(self.path)
        if url.path != "/v1/rate":
            return self.answer(404, {"error": "not found"})
        q = parse_qs(url.query)
        weight = int(q["weight"][0])
        self.answer(200, {"cents": 1500 + 3 * (weight // 100) * 10})

    def answer(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", int(os.environ.get("CARRIER_PORT", "9090"))),
                    Rate).serve_forever()
EOF
}

# ---- the lab's CI: a bare repository whose post-receive hook runs the suite
ci() {
  local dir=$1
  rm -rf "$dir/shipquote.git" "$dir/runs"
  mkdir -p "$dir"
  git init -q --bare -b main "$dir/shipquote.git"
  cat > "$dir/shipquote.git/hooks/post-receive" <<'EOF'
#!/usr/bin/env bash
# The lab's whole CI. On every push to main: a clean checkout of the pushed
# commit, then the test suite once per Python version and per time zone. What
# it prints reaches the person who pushed, each line prefixed with "remote:".
set -uo pipefail
PYTHONS=${CI_PYTHONS:-"3.11 3.12 3.13"}
ZONES=${CI_ZONES:-"America/Sao_Paulo UTC"}
RUNS=$(cd "$(dirname "$0")/../.." && pwd)/runs

while read -r old new ref; do
  if [ "$ref" != refs/heads/main ]; then
    echo "ci: ${ref#refs/heads/} is not main, nothing to run"
    continue
  fi
  mkdir -p "$RUNS"
  n=$(( $(ls "$RUNS" | wc -l) + 1 ))
  run=$RUNS/$n
  mkdir "$run"
  work=$(mktemp -d)
  git archive "$new" | tar -x -C "$work"
  echo "ci: run $n, commit ${new:0:7}, checked out clean"
  failed=0
  for py in $PYTHONS; do
    venv=$work/.venv-$py
    if ! { uv venv -q -p "$py" "$venv" &&
           VIRTUAL_ENV=$venv uv pip install -q -r "$work/requirements-dev.txt"; } \
         > "$run/install-$py.log" 2>&1; then
      echo "ci: python $py could not be installed, see install-$py.log"
      failed=1
      continue
    fi
    for tz in $ZONES; do
      cell="py$py-${tz//\//-}"
      if (cd "$work" && TZ=$tz "$venv/bin/python" -m pytest -q -p no:cacheprovider \
            --junitxml="$run/$cell.xml" > "$run/$cell.log" 2>&1); then
        result=pass
      else
        result=FAIL
        failed=1
      fi
      printf 'ci: %-5s %-18s %-4s  %s\n' "$py" "$tz" "$result" "$(tail -1 "$run/$cell.log")"
    done
  done
  rm -rf "$work"
  if [ "$failed" = 0 ]; then
    echo "ci: run $n passed"
  else
    echo "ci: run $n FAILED, logs in $run"
  fi
done
EOF
  chmod +x "$dir/shipquote.git/hooks/post-receive"
}

case ${1:-} in
  stage)
    n=$2; [ "$n" = last ] && n=$LAST
    REPO=${3:-$REPO}
    rm -rf "$REPO"; mkdir -p "$REPO"; cd "$REPO"; git init -q -b main
    for i in $(seq 1 "$n"); do "step_$i"; git add -A; "commit_$i"; done ;;
  venv) venv "$2" "${3:-3.13}" ;;
  carrier) carrier "$2" ;;
  ci) ci "$2" ;;
  steps) steps ;;
  *) echo "usage: lab.sh stage N|last [DIR] | venv DIR [PY] | carrier DIR | ci DIR | steps" >&2; exit 2 ;;
esac
