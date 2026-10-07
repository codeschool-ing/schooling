---
title: A versão 1.6.1, os três artefatos e a produção
version: 1
---

**A versão 1.6.1 veio um dia depois da 1.6.0.** Ela corrige uma faixa na tabela de dias de entrega,
acrescenta um teste de que todo estado tem uma entrada e põe a estimativa de entrega atrás de uma
chave conferida contra a requisição do cliente. As seções 11 a 13 tratam dessa chave, uma feature
flag, e de por que a 1.6.1 tem uma; ela é montada aqui para que os três artefatos estejam prontos
antes da primeira estratégia.

A chave mora num módulo próprio. Salve como `shipquote/flags.py`:

```python
"""Feature flags: who sees a feature is decided outside the code.

SHIPQUOTE_FLAGS names a JSON file of {"flag": percent}. A missing file, or a
flag missing from it, means 0: the feature is off until somebody turns it on.
"""
import hashlib
import json
import os


def load():
    path = os.environ.get("SHIPQUOTE_FLAGS")
    if not path or not os.path.exists(path):
        return {}
    with open(path) as f:
        return json.load(f)


def enabled(flags, name, customer):
    """On for the flag's percentage of customers, the same ones every time."""
    bucket = int(hashlib.sha256(f"{name}:{customer}".encode()).hexdigest(), 16) % 100
    return bucket < flags.get(name, 0)
```

e tem testes próprios. Salve como `tests/test_flags.py`:

```python
from shipquote.flags import enabled


def test_a_flag_nobody_set_is_off():
    assert not enabled({}, "delivery_estimate", "c1")


def test_a_flag_at_100_is_on_for_everybody():
    assert all(enabled({"delivery_estimate": 100}, "delivery_estimate", f"c{i}")
               for i in range(1000))


def test_the_same_customer_gets_the_same_answer_every_time():
    flags = {"delivery_estimate": 30}
    first = [enabled(flags, "delivery_estimate", f"c{i}") for i in range(1000)]
    again = [enabled(flags, "delivery_estimate", f"c{i}") for i in range(1000)]
    assert first == again
```

A faixa da tabela para os estados a partir da Bahia agora vai até 57, um a mais que antes. Salve
como `shipquote/quote.py`:

```python
"""What it costs to send a parcel, in cents."""

# The first digit of a CEP says which region of Brazil it is in.
ZONES = {"0": "SP", "1": "SP", "2": "SE", "3": "SE", "4": "NE",
         "5": "NE", "6": "N", "7": "CO", "8": "S", "9": "S"}
BASE = {"SP": 1290, "SE": 1590, "S": 1890, "CO": 2190, "NE": 2490, "N": 2990}
EXTRA_PER_500G = 450      # every 500 g started after the first
FREE_FROM = 19900         # an order of R$ 199,00 or more ships free

# Business days to deliver, by the first two digits of the CEP: the state.
DAYS = {**{p: 1 for p in range(1, 20)},      # São Paulo
        **{p: 2 for p in range(20, 40)},     # Rio, Espírito Santo, Minas
        **{p: 4 for p in range(40, 58)},     # Bahia to Alagoas
        **{p: 5 for p in range(58, 66)},     # Paraíba to Maranhão
        **{p: 6 for p in range(66, 70)},     # the North
        **{p: 3 for p in range(70, 80)},     # the Centre-West
        **{p: 2 for p in range(80, 100)}}    # the South


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


def delivery_days(cep: str) -> int:
    return DAYS[int(normalise_cep(cep)[:2])]
```

A cotação acrescenta `days` só quando a flag está ligada para o cliente que perguntou. Salve como
`shipquote/app.py`:

```python
"""The HTTP face of shipquote: /health, /version and /quote."""
import json
import os
import sys
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

from . import carrier, flags, money, quote
from .version import VERSION


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.started = time.monotonic()
        url = urlparse(self.path)
        if url.path == "/health":
            return self.reply(200, {"status": "ok"})
        if url.path == "/version":
            env = os.environ.get("SHIPQUOTE_ENV", "dev")
            source = os.environ.get("SHIPQUOTE_CARRIER_URL") or "table"
            return self.reply(200, {"version": VERSION, "env": env,
                                    "carrier": source})
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
        carrier_url = os.environ.get("SHIPQUOTE_CARRIER_URL")
        if carrier_url and cents:
            client = carrier.CarrierClient(
                carrier_url, os.environ.get("SHIPQUOTE_CARRIER_TOKEN", ""))
            cents = carrier.price(client, cep, weight_g, subtotal,
                                  log=lambda line: print(line, file=sys.stderr))
        customer = args.get("customer", [""])[0]
        try:
            body = self.quote_body(cep, cents)
            if flags.enabled(flags.load(), "delivery_estimate", customer):
                body["days"] = quote.delivery_days(cep)
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

Os testes acompanham: a resposta sem `days` de novo, e todo prefixo de 01 a 99 com uma estimativa.
Salve como `tests/test_quote.py`:

```python
import pytest

from shipquote.quote import DAYS, FREE_FROM, delivery_days, freight, zone_of


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


@pytest.mark.parametrize("cep, days", [
    ("01310-100", 1),
    ("20040-002", 2),
    ("69005-010", 6),
    ("80010-000", 2),
])
def test_delivery_takes_the_days_of_the_state(cep, days):
    assert delivery_days(cep) == days


def test_every_state_prefix_has_a_delivery_estimate():
    missing = [p for p in range(1, 100) if p not in DAYS]
    assert missing == []
```

Salve como `tests/test_app.py`:

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


def test_version_says_the_table_is_used_when_no_carrier_is_named(base_url):
    assert get(base_url + "/version")[1]["carrier"] == "table"
```

Commit e tag como na anterior:

```sh
git add shipquote tests
git commit -m "Give Alagoas its delivery days, and put the estimate behind a flag"
git tag -a v1.6.1 -m "shipquote 1.6.1"
```

## Três artefatos

Cada versão é construída a partir da própria tag, fazendo checkout da tag e rodando o build da aula
7, e a cópia de trabalho volta para a `main` depois:

```sh
for t in v1.5.0 v1.6.0 v1.6.1; do git checkout -q $t && ops/build.sh; done
git checkout -q main
```

## A produção, duas vezes

O que as aulas 8 e 9 deixaram rodando para aqui: os ambientes com `kill $(cat ~/envs/*/pid)` e
`rm -rf ~/envs`, e as duas transportadoras com Ctrl-C nos terminais delas. Nada nesta aula pergunta
a uma transportadora, então todo preço vem da tabela da loja.

A produção agora são três diretórios. `production` é a cópia única que a seção 04 reinicia.
`production-blue` e `production-green` são as duas cópias diante das quais fica o roteador, da seção
06 em diante, e as duas leem as flags de um arquivo só, que ainda não existe:

```sh
mkdir -p ~/envs/production ~/envs/production-blue ~/envs/production-green
echo SHIPQUOTE_PORT=8300 > ~/envs/production/config.env
printf 'SHIPQUOTE_PORT=8301\nSHIPQUOTE_FLAGS=%s/envs/flags.json\n' "$HOME" > ~/envs/production-blue/config.env
printf 'SHIPQUOTE_PORT=8302\nSHIPQUOTE_FLAGS=%s/envs/flags.json\n' "$HOME" > ~/envs/production-green/config.env
```
