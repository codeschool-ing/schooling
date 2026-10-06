---
title: Stub
version: 1
---

A **stub** answers calls with values the test chose in advance. It has no logic and no memory. Its
job is to put the code under test into a particular situation: the carrier answered 1999, the
carrier timed out, the database returned no rows.

`tests/fakes.py` holds the stub for the carrier:

```python
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

Given cents, it answers them; given an error, it raises it. That is enough to test both branches of
`price` without a network:

```python
from unittest import mock

from shipquote.carrier import CarrierError, price
from tests.fakes import StubCarrier


def test_the_carriers_price_wins_when_it_answers():
    assert price(StubCarrier(cents=1999), "01310-100", 1200, 5000) == 1999


def test_the_table_is_used_when_the_carrier_is_down():
    stub = StubCarrier(error=CarrierError("timed out"))
    assert price(stub, "01310-100", 1200, 5000, log=lambda line: None) == 2190
```

The first test says *when the carrier answers, its price wins*. The second says *when the carrier
fails, the table's price is used*, and 2190 is what lesson 1 showed the table charges for 1200 g to
São Paulo. Neither test cares how the carrier is reached, only what it said.

## Situations you could not arrange otherwise

The second test is the reason stubs exist. Making a real carrier time out on demand is hard: you
would need to slow its network, or point at an address that never answers, and wait. Here is what
waiting costs, with the lab's carrier stand-in delaying every answer by three seconds and the
client giving up after two:

```
ana@laptop:~/shipquote$ time python3 -c '
from shipquote.carrier import CarrierClient, price
client = CarrierClient("http://127.0.0.1:9090", "lab-token-not-a-secret", timeout=2)
print(price(client, "01310-100", 1200, 5000))
'
carrier unavailable, using the table: timed out
2190

real	0m2.091s
user	0m0.065s
sys	0m0.024s
```

The fallback worked: the log line, then the table's 2190. But the run took **2.091 seconds**, and
every test written this way would pay that. The stub raises the same `CarrierError` in no time at
all, which is why the stub test is in the fast layer and this session is not.

**A stub is only as honest as the situations you give it.** It answers 1999 because you said so,
whatever a real carrier would answer. If the real carrier changes what it sends, the stub does not
change with it, and section 10 is about catching exactly that.

## Stubs do not check anything

Notice that neither test asks whether `rate` was called, or with which CEP. A stub feeds the code;
assertions are about the result. When the *calls themselves* are what you need to check, you need
something that records them, which is the next two sections.
