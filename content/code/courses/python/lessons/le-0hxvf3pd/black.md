---
title: `black`, and the options it does not have
version: 2
---

```python
def send_invoice(customer_id, amount_cents, currency = 'BRL', notify = True, retries=3):
    result = gateway.charge( customer_id, amount_cents, currency=currency, idempotency_key=make_key(customer_id, amount_cents) )
    if result.ok == True :
        return {'status':'ok','id':result.id}
```

```python
def send_invoice(customer_id, amount_cents, currency="BRL", notify=True, retries=3):
    result = gateway.charge(
        customer_id,
        amount_cents,
        currency=currency,
        idempotency_key=make_key(customer_id, amount_cents),
    )
    if result.ok == True:
        return {"status": "ok", "id": result.id}
```

**Four kinds of change, none of them a decision.** Double quotes. No spaces around `=` in a
keyword argument. No space before a `:`. And a call that does not fit on one line exploded one
argument per line, with a trailing comma.

Note what it did *not* touch: `result.ok == True` is still there. That is a linter's finding, and
a formatter has no opinion about it.

## The settings

```toml
[tool.black]
line-length = 88
target-version = ["py312"]
```

That is nearly all of them. **The absence is deliberate** — a formatter with settings is a
formatter a team can argue about, and removing the argument is the entire product. `88` is a
strange number and it is the default, which is the only property of it that matters.

## The magic trailing comma

```python
other = charge(customer, amount, currency,)
```

```python
other = charge(
    customer,
    amount,
    currency,
)
```

A trailing comma you leave in is a **request**: it tells `black` to keep this call exploded even
though it would fit on one line. It is the one place where you get to overrule it, and it is
useful for a list of arguments that is going to grow.

Take the comma out and it collapses back to one line.

## Running it

```sh
black app/            # rewrite
black --check app/    # exit 1 if anything would change, rewrite nothing
black --diff app/     # print what it would do
```

`--check` is what goes in CI. It prints `would reformat c.py` and exits non-zero, and it is the
whole of the review comment nobody has to write any more.

## The first run

It will rewrite the whole repository. Do that in **one commit, on its own**, with no other change
in it — and then add that commit's hash to `.git-blame-ignore-revs` and point git at it:

```sh
git config blame.ignoreRevsFile .git-blame-ignore-revs
```

Otherwise `git blame` answers "the formatting commit" for every line in the project, and the
history stops being usable on the day you adopted the tool.
