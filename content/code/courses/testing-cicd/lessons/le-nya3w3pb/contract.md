---
title: Checking the stubs against the real thing
version: 1
---

Every stub is a statement: *the carrier answers like this*. `StubCarrier(cents=1999)` assumes the
carrier sends a JSON object with a `cents` key holding a whole number. If the carrier changes its
answer, the stubs go on saying the old thing, and every test that uses them stays green while
production fails. Nothing in the doubles can notice; they are the thing that went stale.

A **contract test** closes the loop by asking the real collaborator the questions the doubles
answer. `shipquote` has two, in `tests/test_carrier_contract.py`:

```python
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
```

They are marked `contract` and **skipped unless `CARRIER_URL` says where a carrier is**, because
they need one. Run them on a laptop with nothing configured and this is what you get:

```
ana@laptop:~/shipquote$ python -m pytest -m contract -v -rs
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
testpaths: tests
plugins: hypothesis-6.168.5
collecting ... collected 33 items / 31 deselected / 2 selected

tests/test_carrier_contract.py::test_a_rate_is_a_whole_number_of_cents SKIPPED [ 50%]
tests/test_carrier_contract.py::test_a_wrong_token_is_a_carrier_error_not_a_crash SKIPPED [100%]

=========================== short test summary info ============================
SKIPPED [1] tests/test_carrier_contract.py:21: CARRIER_URL is not set
SKIPPED [1] tests/test_carrier_contract.py:26: CARRIER_URL is not set
====================== 2 skipped, 31 deselected in 0.22s =======================
```

Two `SKIPPED`, with the reason. `-rs` asks pytest to print the reasons, and without it the run
ends in a quiet `2 skipped` that is easy to read as fine. **A skipped test is not a passing test.**
If the pipeline never sets `CARRIER_URL`, the contract is never checked, and the suite reports
success forever. Lesson 9 is about giving a pipeline the address and the token without putting the
token in the repository.

## Against a carrier

The lab cannot reach a real carrier, so it runs a stand-in: a small HTTP server that answers the
same shape of question on 127.0.0.1:9090, with a token the lab made up. Pointed at it, both
contract tests pass:

```
ana@laptop:~/shipquote$ CARRIER_URL=http://127.0.0.1:9090 CARRIER_TOKEN=lab-token-not-a-secret python -m pytest -m contract -q
..                                                                       [100%]
2 passed, 31 deselected in 0.19s
```

Now the carrier changes its answer. The stand-in is edited to send `price_cents` instead of
`cents`, as a real provider might in a new API version, and restarted:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_carrier.py -q
....                                                                     [100%]
4 passed in 0.14s
ana@laptop:~/shipquote$ CARRIER_URL=http://127.0.0.1:9090 CARRIER_TOKEN=lab-token-not-a-secret python -m pytest -m contract -q --tb=line
F.                                                                       [100%]
=================================== FAILURES ===================================
E   KeyError: 'cents'

The above exception was the direct cause of the following exception:
E   shipquote.carrier.CarrierError: 'cents'
/home/ana/shipquote/shipquote/carrier.py:29: shipquote.carrier.CarrierError: 'cents'
=========================== short test summary info ============================
FAILED tests/test_carrier_contract.py::test_a_rate_is_a_whole_number_of_cents
1 failed, 1 passed, 31 deselected in 0.19s
```

The four stub tests are still green: they never talk to the carrier. The contract test fails with
`CarrierError: 'cents'`, the key that is no longer there. In production the fallback would quietly
quote from the table on every request, and only the log line from section 05 would say so.

## Contracts in practice

Running contract tests against a provider's live API on every push is often impossible: it costs
money per call, it is rate-limited, or the sandbox is down. The usual compromise is to run them
**on a schedule**, nightly, against the provider's test environment, and to treat a failure as
"our stubs are out of date". Lesson 5 sets up scheduled runs. Some teams go further with
*consumer-driven contracts*, where the consumer publishes the requests it relies on and the
provider's own pipeline runs them before every release; Pact is the best-known tool for it.
