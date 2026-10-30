---
title: The account's level, and asking for less
version: 1
---

**The level is a property of the account, and a client may only ask for less.** Every read and
query is served at the account's default unless the request says otherwise, and Microsoft's
documentation allows a request to name a weaker level than the default and never a stronger one. An
account at session can serve the catalogue page at eventual, saving nothing in request units but
reading from whichever copy is closest. An account at eventual cannot serve one read at strong,
because the writes were never committed in the way strong needs.

**Writes ignore the setting.** A write is committed the way the account's level requires whatever
the request says, which is why the request-level choice is a read-side choice only.

## On the emulator

`overriding.py` asks the emulator's account for its default level, then reads one order through
four clients, each created at a different level. The last is not a level at all:

`overriding.py`:

```python
from azure.cosmos import CosmosClient

URL = "http://localhost:8081"
KEY = "C2y6yDjf5/R+ob0N8A7Cgv30VRDJIWEHLM+4QDU5DE2nQ9nDuVTqobD4b8mGGyPMbIZnqyMsEcaGQy67XIw/Jw=="

account = CosmosClient(URL, KEY).get_database_account()
print("the account's default:", account.ConsistencyPolicy["defaultConsistencyLevel"])

for level in ["Eventual", "Session", "Strong", "Linearizable"]:
    client = CosmosClient(URL, KEY, consistency_level=level)
    orders = client.get_database_client("quitanda").get_container_client("orders")
    orders.read_item("o-1002", "c-7")
    charge = orders.client_connection.last_response_headers["x-ms-request-charge"]
    print(f"{level:13} read answered, request charge {charge}")
```

Run it after `session.py`, which wrote the order it reads:

```
ana@laptop:~/azure$ python overriding.py
the account's default: Eventual
Eventual      read answered, request charge 1
Session       read answered, request charge 1
Strong        read answered, request charge 1
Linearizable  read answered, request charge 1
```

**Four answers, one request unit each, and not one of them was checked.** The emulator's account
says `Eventual`, which is not what Azure gives a new account: that default is session. A strong
read against an eventual account is the request Microsoft's documentation says cannot be made, and
the emulator served it. `Linearizable` is a word from the theory of distributed systems and is not
one of Cosmos DB's levels; the library sent it as the header `x-ms-consistency-level` and the
emulator served that too. The charge of one is lesson 1's placeholder again. On Azure that strong
read, against an account at eventual, would not have been served at all; against an account at
strong it would have cost about twice the session read, as the section before this one explained.

So **the level a program runs at is the one the account was created with, minus whatever the client
asked to give up**, and the emulator can confirm neither half. Read the account's level from its
declaration, which is the next section, and treat a client's `consistency_level` as a way of giving
something up, never of getting something.

## Where the library takes the level

In version 4.17.1 of the Python library the level is an argument of `CosmosClient`, as above, and
applies to every request that client makes. `read_items`, which reads several items in one call,
takes one of its own; `read_item` and `query_items` list none in the library's documentation of
them. A program that needs two levels therefore keeps two clients, and a client is expensive to
create, so it keeps them for its whole life rather than making one per request.
