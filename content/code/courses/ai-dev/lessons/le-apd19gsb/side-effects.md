---
title: A call that happens twice
version: 2
---

`get_stock` can run a hundred times and the shop is the same afterwards. `create_return` cannot:
**every run opens a return**. That difference decides how a host may retry, and retries happen
for ordinary reasons: a request that timed out after the work was done, a host restarted halfway
through a loop.

## The same call, run twice

`retry.py` stands in for a host that did not hear back the first time and tried again:

```python
"""The same call run twice, as a host that retries after a timeout would."""
from shop_tools import create_return

args = {"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}
for attempt in (1, 2):
    print(attempt, create_return(**args))
```

```
ana@dev:~/shop$ rm data/returns.json; python retry.py
1 {'id': 'R-1042-1', 'order_id': '1042', 'sku': 'MUG-01', 'quantity': 1, 'reason': 'changed_mind'}
2 {'id': 'R-1042-2', 'order_id': '1042', 'sku': 'MUG-01', 'quantity': 1, 'reason': 'changed_mind'}
ana@dev:~/shop$ cat data/returns.json
[
 {
  "id": "R-1042-1",
  "order_id": "1042",
  "sku": "MUG-01",
  "quantity": 1,
  "reason": "changed_mind"
 },
 {
  "id": "R-1042-2",
  "order_id": "1042",
  "sku": "MUG-01",
  "quantity": 1,
  "reason": "changed_mind"
 }
]
```

**Two returns, for a customer who asked for one.** Each run passed the shop's rules: two mugs were
bought, so a second return of one still fitted. Nothing was wrong with either call on its own;
the mistake is that it was the same request.

## An idempotency key

The fix is a key that names the request, and a function that answers a repeat with what it did the
first time. **The key comes from the host, not from the model.** The `id` of the `tool_use` block
is a natural choice: the API assigns one per call, a retry of that call carries the same one, and
the model cannot type it by accident.

```
ana@dev:~/shop$ git diff
diff --git a/retry.py b/retry.py
index 66dd52d..e4f4636 100644
--- a/retry.py
+++ b/retry.py
@@ -3,4 +3,4 @@ from shop_tools import create_return
 
 args = {"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}
 for attempt in (1, 2):
-    print(attempt, create_return(**args))
+    print(attempt, create_return(**args, key="call_0007"))
diff --git a/shop_tools.py b/shop_tools.py
index 5cc5b96..3bd50e4 100644
--- a/shop_tools.py
+++ b/shop_tools.py
@@ -46,7 +46,7 @@ def get_stock(sku):
     return stock[sku]
 
 
-def create_return(order_id, sku, quantity, reason):
+def create_return(order_id, sku, quantity, reason, *, key):
     orders = json.loads(Path("data/orders.json").read_text())
     order = orders.get(order_id)
     if order is None:
@@ -59,11 +59,14 @@ def create_return(order_id, sku, quantity, reason):
     bought = sum(line["quantity"] for line in order["lines"] if line["sku"] == sku)
     path = Path("data/returns.json")
     returns = json.loads(path.read_text()) if path.exists() else []
+    for r in returns:
+        if r["key"] == key:
+            return r  # this exact call already ran: answer as it did then
     taken = sum(r["quantity"] for r in returns if r["order_id"] == order_id and r["sku"] == sku)
     if quantity > bought - taken:
         raise ShopError(f"order {order_id} has {bought - taken} of {sku} left to return, not {quantity}")
     record = {"id": f"R-{order_id}-{len(returns) + 1}", "order_id": order_id, "sku": sku,
-              "quantity": quantity, "reason": reason}
+              "quantity": quantity, "reason": reason, "key": key}
     path.write_text(json.dumps(returns + [record], indent=1) + "\n")
     return record
 
```

```
ana@dev:~/shop$ rm data/returns.json; python retry.py
1 {'id': 'R-1042-1', 'order_id': '1042', 'sku': 'MUG-01', 'quantity': 1, 'reason': 'changed_mind', 'key': 'call_0007'}
2 {'id': 'R-1042-1', 'order_id': '1042', 'sku': 'MUG-01', 'quantity': 1, 'reason': 'changed_mind', 'key': 'call_0007'}
ana@dev:~/shop$ cat data/returns.json
[
 {
  "id": "R-1042-1",
  "order_id": "1042",
  "sku": "MUG-01",
  "quantity": 1,
  "reason": "changed_mind",
  "key": "call_0007"
 }
]
```

**The second attempt returns `R-1042-1` again**, and the file holds one return. The early `return r`
sits before the quantity check on purpose. A repeat of a call that already succeeded must answer
the same way, even though, by now, the order has fewer mugs left to return.

## What else a host should do

- **Retry reads freely and writes only with a key.** If a function has no key, a timeout on it is
  a question for a person, not a loop.
- **Mark which tools change something.** Lesson 7 put `destructiveHint` on `issue_refund` and held
  it for approval. The same list tells the host which calls need a key.
- **Make the key part of the record.** Keeping it in `returns.json` is what let the second call
  find the first. A key held only in memory protects you until the host restarts, which is
  exactly when the retry happens.
