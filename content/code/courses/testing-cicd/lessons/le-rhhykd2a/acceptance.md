---
title: Acceptance tests
version: 1
---

An **acceptance test** checks a promise in the words of whoever asked for it. Its question is not
"does the code work?" but **"would the person who asked for this accept it?"** The technique is
often the same as a functional test, through the public interface; what differs is where the test
comes from and who can read it.

The bookshop's front page says: *free shipping on orders of R$ 199,00 or more, anywhere in
Brazil*. That sentence is a requirement written by the business, and it is the source of this
test:

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

Three things make it an acceptance test rather than one more functional test.

**It is written from the requirement, not from the code.** The test does not know there is a
`FREE_FROM` constant. It sends the amount the front page names, from one CEP in each region,
because "anywhere in Brazil" is the claim.

**Its steps are the customer's steps.** The *Given / When / Then* comments are a structure a
product owner can read and correct: if the promise is "from R$ 199,00" and the test says R$ 200,00,
somebody who never opens Python can spot it. Tools such as Cucumber and behave turn those three
words into executable steps, and the `qa` track teaches that style in `qa-fundamentals` lesson 16.
The comments here keep the shape without the tooling.

**Its failure is a business failure.** If this test is red, the shop is breaking a promise on its
front page, whatever the reason. That makes it a candidate for running last in a pipeline, against
the deployed application, which lesson 7 calls a smoke test.

```
ana@laptop:~/shipquote$ python -m pytest -m acceptance -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
testpaths: tests
plugins: hypothesis-6.168.5
collecting ... collected 31 items / 30 deselected / 1 selected

tests/test_acceptance.py::test_a_basket_of_199_reais_ships_free_to_every_region PASSED [100%]

======================= 1 passed, 30 deselected in 0.68s =======================
```

## How many

Acceptance tests are the most expensive kind to keep: slow, broad, and broken by any change in
the interface. So **they cover the promises, not the cases.** The edge at 19,899 cents is already
tested in the unit layer, in a millisecond. Repeating every edge here would make the suite slow
and say nothing new. One acceptance test per promise the business would notice is a good default;
the rest of the confidence comes from below.

## The four names, side by side

| | exercises | collaborators | fails because |
|---|---|---|---|
| unit | one behaviour | none outside the process | a rule is wrong |
| integration | your code with one real dependency | a database, a file, a service | the two sides disagree |
| functional | the whole application, through its interface | everything the app needs | the wiring is wrong |
| acceptance | a requirement, in its owner's terms | the application as deployed | a promise is broken |

The boundaries blur in practice, and teams argue about labels. The question that matters is the
last column: **when this test fails, what does it tell you?**
