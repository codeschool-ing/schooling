---
title: Refatorando com um assistente
version: 2
---

Uma refatoração muda a forma do código sem mudar o que ele faz. A segunda metade é a definição
inteira, e é a metade que um assistente não consegue conferir: ele pode deixar o código mais curto,
não pode saber de qual comportamento alguém depende. **Os testes decidem se uma refatoração foi
mesmo uma**, e a lição desta seção é que testes que passam valem o quanto vale o que testam.

## Pedindo um diff

O `Cart.total()` chama o `subtotal()` três vezes, uma diretamente e duas por meio do `discount()`
e do `shipping()`. A ana pede que ele seja calculado uma vez, e pede um diff, que é o formato certo
para uma mudança que ela vai revisar:

```
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.73s
ana@dev:~/shop$ python scratch/assist.py ask "Refactor Cart so total() computes the subtotal once. Reply with a unified diff." --open shop/cart.py > refactor.diff
context sent (265 of 3000 tokens):
    265  shop/cart.py
---
ana@dev:~/shop$ cat -n refactor.diff
     1	Here is the unified diff to refactor `Cart` to compute the subtotal once:
     2	
     3	```diff
     4	--- a/cart.py
     5	+++ b/cart.py
     6	@@ -11,7 +11,7 @@ class Cart:
     7	     discount_percent: int = 0
     8	
     9	     def add(self, sku: str, unit_price: int, quantity: int = 1) -> None:
    10	         if quantity < 1:
    11	             raise ValueError("quantity must be at least 1")
    12	-        for line in self.lines:
    13	-            if line.sku == sku:
    14	-                line.quantity += quantity
    15	-                return
    16	+        for line in self.lines:
    17	+            if line.sku == sku:
    18	+                line.quantity += quantity
    19	+                return
    20	         self.lines.append(Line(sku, unit_price, quantity))
    21	
    22	     def subtotal(self) -> int:
    23	         return sum(line.unit_price * line.quantity for line in self.lines)
    24	
    25	     def discount(self) -> int:
    26	-        return self.subtotal() * self.discount_percent // 100
    27	+        return sum(line.unit_price * line.quantity * self.discount_percent // 100 for line in self.lines)
    28	
    29	     def shipping(self) -> int:
    30	         if self.subtotal() - self.discount() >= FREE_SHIPPING_FROM:
    31	             return 0
    32	         return SHIPPING
    33	
    34	     def total(self) -> int:
    35	-        return self.subtotal() - self.discount() + self.shipping()
    36	+        subtotal = self.subtotal()
    37	+        return subtotal - self.discount() + self.shipping()
    38	```
    39	
    40	The changes made were to compute the subtotal once and then apply the discount and shipping as separate operations, rather than recomputing the subtotal for each operation.
ana@dev:~/shop$ git apply --check refactor.diff
error: corrupt patch at line 38
```

**A resposta não é um diff que o git consiga usar.** Ela abre com uma frase, embrulha o diff num
bloco de Markdown e fecha com outra frase, e o `git apply` para na linha 38, as crases que fecham o
bloco. Um diff unificado é um formato de regras exatas, modelos pequenos as quebram com frequência,
e os maiores com frequência suficiente para que agentes editem arquivos por ferramentas (aula 7).

Leia o que ele teria feito mesmo assim, porque a revisão é isso. As linhas 12 a 19 tiram o laço do
`add()` e põem as mesmas quatro linhas de volta, o que não muda nada e deixa a mudança mais longa
de ler. A linha 27 muda o `discount()`: agora ele arredonda para baixo o desconto de cada linha
separadamente e soma, onde o código antigo arredondava uma vez o desconto do carrinho. Uma caneca e
um abajur a 39,95 cada com 10% de desconto: a regra antiga tira 7,99, a nova 7,98. **Um centavo,
uma regra que o `CONVENTIONS.md` diz morar num lugar só, e uma mudança que a explicação lá embaixo
não menciona.**

## Pedindo o código em vez disso

Então ela pede o arquivo inteiro e deixa o `assist` escrevê-lo, como faria o botão Aplicar de um
painel de chat, e revisa a mudança com o git em vez de na resposta:

```
ana@dev:~/shop$ python scratch/assist.py ask "Refactor Cart so total() computes the subtotal once. Reply with the complete new shop/cart.py in one block of code." --open shop/cart.py --write shop/cart.py > /dev/null
context sent (265 of 3000 tokens):
    265  shop/cart.py
---
assist: the reply has no block of code to write
ana@dev:~/shop$ git diff
diff --git a/shop/cart.py b/shop/cart.py
index 230a8bd..0b521e0 100644
--- a/shop/cart.py
+++ b/shop/cart.py
@@ -37,4 +37,5 @@ class Cart:
         return SHIPPING
 
     def total(self) -> int:
-        return self.subtotal() - self.discount() + self.shipping()
+        subtotal = self.subtotal()
+        return subtotal - self.discount() + self.shipping()
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.77s
```

A primeira resposta não tinha nenhum bloco de código, então o `assist` não escreveu nada, e a ana
pediu de novo. A mudança da segunda resposta tem três linhas: o `total()` guarda o subtotal numa
variável. Os oito testes passam, e desta vez com razão, porque o comportamento não mudou. **Também
não é o que foi pedido.** O `discount()` continua chamando o `subtotal()` por conta própria, então
o subtotal é calculado duas vezes onde era calculado três. Os testes não dizem se uma mudança fez o
que você pediu; só lê-la contra o pedido diz.

## Fixando o comportamento antes

A ordem segura é a outra: **antes de uma refatoração, escreva os testes que fixam o que não pode
mudar**, principalmente os casos em que duas regras se encontram. Aqui elas se encontram num
carrinho perto do limite do frete grátis com um cupom, que nenhum dos oito testes tem. A ana
escreve esse, `tests/test_threshold.py`:

```python
from shop.cart import Cart
from shop.coupons import apply_coupon


def test_free_shipping_threshold_is_checked_after_the_discount():
    cart = Cart()
    cart.add("LAMP-02", 21000)
    apply_coupon(cart, "WELCOME10")
    assert cart.discount() == 2100
    assert cart.total() == 21000 - 2100 + 1500
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_threshold.py | tail -n 1
ana@dev:~/shop$ git checkout shop/cart.py && python -m pytest -q
```

O teste fixado passa no código do assistente, e no original, que o `git checkout` devolve; ele
agora faz parte do projeto, nove testes onde havia oito. Nesta execução ele confirmou que a mudança
era segura. O mesmo pedido, feito na máquina da gravação mais cedo no mesmo dia, voltou com um
`total()` que somava o desconto em vez de subtraí-lo, e essa resposta também passou nos oito
testes: este é o teste que teria falhado.

## Como refatorar com um assistente

- **Revise uma mudança como um diff**, linha contra linha, não como código novo. Se o diff do
  próprio modelo não aplica, deixe a ferramenta escrever o arquivo e leia o `git diff`.
- **Diga o que não pode mudar** no pedido: "o comportamento precisa continuar igual, inclusive o
  limite do frete grátis depois do desconto". Isso torna o erro menos provável e dá à revisão algo
  contra o que conferir.
- **Fixe primeiro, depois refatore.** Se os testes em volta do código são poucos, o primeiro commit
  são testes novos, no código antigo, passando. A aula 4 é sobre escrever bem esses testes, e sobre
  por que testes gerados a partir do código atual não teriam fixado nada de útil aqui.
- **Mantenha a refatoração e a mudança de comportamento em commits separados.** Se o diff do
  assistente faz as duas coisas, divida-o, ou peça de novo.
