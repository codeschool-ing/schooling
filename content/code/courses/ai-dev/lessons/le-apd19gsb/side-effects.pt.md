---
title: Uma chamada que acontece duas vezes
version: 1
---

O `get_stock` pode rodar cem vezes e a loja fica igual depois. O `create_return` não: **cada execução
abre uma devolução**. Essa diferença decide como um host pode repetir, e repetições acontecem por
motivos comuns: uma requisição que estourou o tempo depois de o trabalho estar feito, um host
reiniciado no meio de um laço, um modelo que pede a mesma chamada de novo.

## A mesma chamada, rodada duas vezes

O `retry.py` faz o papel de um host que não ouviu a resposta da primeira vez e tentou de novo:

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

**Duas devoluções, para um cliente que pediu uma.** Cada execução passou pelas regras da loja: duas
canecas foram compradas, então uma segunda devolução de uma ainda cabia. Nada estava errado em
nenhuma chamada sozinha; o erro é que era a mesma requisição.

## Uma chave de idempotência

O conserto é uma chave que dá nome à requisição, e uma função que responde a uma repetição com o
que fez da primeira vez. **A chave vem do host, não do modelo.** O `id` do bloco `tool_use` é uma
escolha natural: a API atribui um por chamada, uma repetição daquela chamada traz o mesmo, e o
modelo não consegue digitá-lo por acidente.

```
ana@dev:~/shop$ git diff
diff --git a/retry.py b/retry.py
index 66dd52d..51b6787 100644
--- a/retry.py
+++ b/retry.py
@@ -3,4 +3,4 @@ from shop_tools import create_return
 
 args = {"order_id": "1042", "sku": "MUG-01", "quantity": 1, "reason": "changed_mind"}
 for attempt in (1, 2):
-    print(attempt, create_return(**args))
+    print(attempt, create_return(**args, key="toolu_lab_0007_1"))
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
1 {'id': 'R-1042-1', 'order_id': '1042', 'sku': 'MUG-01', 'quantity': 1, 'reason': 'changed_mind', 'key': 'toolu_lab_0007_1'}
2 {'id': 'R-1042-1', 'order_id': '1042', 'sku': 'MUG-01', 'quantity': 1, 'reason': 'changed_mind', 'key': 'toolu_lab_0007_1'}
ana@dev:~/shop$ cat data/returns.json
[
 {
  "id": "R-1042-1",
  "order_id": "1042",
  "sku": "MUG-01",
  "quantity": 1,
  "reason": "changed_mind",
  "key": "toolu_lab_0007_1"
 }
]
```

**A segunda tentativa devolve a `R-1042-1` de novo**, e o arquivo guarda uma devolução. O `return r`
antecipado fica antes da verificação de quantidade de propósito. Uma repetição de uma chamada que já
deu certo precisa responder do mesmo jeito, mesmo que, a essa altura, o pedido tenha menos canecas
para devolver.

## O que mais um host deve fazer

- **Repita leituras à vontade e escritas só com chave.** Se uma função não tem chave, um estouro de
  tempo nela é uma pergunta para uma pessoa, não um laço.
- **Marque que ferramentas mudam algo.** A aula 7 pôs `destructiveHint` no `issue_refund` e o
  segurou para aprovação. A mesma lista diz ao host que chamadas precisam de chave.
- **Faça da chave parte do registro.** Guardá-la no `returns.json` foi o que deixou a segunda
  chamada achar a primeira. Uma chave guardada só na memória protege até o host reiniciar, que é
  exatamente quando a repetição acontece.
