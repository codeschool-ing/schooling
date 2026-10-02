---
title: Refatorando com um assistente
version: 1
---

Uma refatoração muda a forma do código sem mudar o que ele faz. A segunda metade é a definição
inteira, e é a metade que um assistente não consegue conferir: ele pode deixar o código mais curto,
não pode saber de qual comportamento alguém depende. **Os testes decidem se uma refatoração foi
mesmo uma**, e a lição desta seção é que testes que passam valem o quanto vale o que testam.

## Um pedido e um diff

O `Cart.total()` chama o `subtotal()` três vezes, uma direto e duas pelo `discount()` e pelo
`shipping()`. A ana pede ao `assist` que o calcule uma vez só, e pede um diff, que é o formato certo
para uma mudança que ela vai revisar (a aula 5 fala mais de pedir um). A resposta foi escrita pelo
curso:

```
ana@dev:~/shop$ python -m pytest -q
........                                                                 [100%]
8 passed in 0.55s
ana@dev:~/shop$ assist ask "Refactor Cart so total() computes the subtotal once. Reply with a unified diff." --open shop/cart.py > refactor.diff
context sent (265 of 3000 tokens):
    265  shop/cart.py
---
ana@dev:~/shop$ cat refactor.diff
diff --git a/shop/cart.py b/shop/cart.py
index 230a8bd..38a07b4 100644
--- a/shop/cart.py
+++ b/shop/cart.py
@@ -31,10 +31,14 @@ class Cart:
     def discount(self) -> int:
         return self.subtotal() * self.discount_percent // 100
 
-    def shipping(self) -> int:
-        if self.subtotal() - self.discount() >= FREE_SHIPPING_FROM:
+    def shipping(self, subtotal: int | None = None) -> int:
+        if subtotal is None:
+            subtotal = self.subtotal()
+        if subtotal >= FREE_SHIPPING_FROM:
             return 0
         return SHIPPING
 
     def total(self) -> int:
-        return self.subtotal() - self.discount() + self.shipping()
+        subtotal = self.subtotal()
+        discount = subtotal * self.discount_percent // 100
+        return subtotal - discount + self.shipping(subtotal)

```

## Aplicando, e os testes

```
ana@dev:~/shop$ git apply --stat refactor.diff
 shop/cart.py |   10 +++++++---
 1 file changed, 7 insertions(+), 3 deletions(-)
ana@dev:~/shop$ git apply refactor.diff && python -m pytest -q
........                                                                 [100%]
8 passed in 0.57s
```

Os oito testes passam, e o diff parece a refatoração pedida. **Não é uma.** Leia o `shipping()`
antigo contra o novo: o antigo comparava `subtotal - discount` com o limite do frete grátis, o
novo compara só o `subtotal`. Um carrinho de 210,00 com um cupom de 10% pagava 15,00 de frete,
porque 189,00 está abaixo de 200,00, e agora não paga nada. Se essa é uma regra melhor é uma
pergunta para quem cuida dos preços da loja. Refatoração não é.

Nenhum dos oito testes tem um cupom e um carrinho perto do limite ao mesmo tempo, então nenhum
percebeu.

## Fixando o comportamento antes

A ordem segura é a outra: **antes de uma refatoração, escreva os testes que fixam o que não pode
mudar**, em especial os casos em que duas regras se encontram. A ana escreve o que este diff
quebra:

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
ana@dev:~/shop$ python -m pytest -q tests/test_threshold.py
F                                                                        [100%]
=================================== FAILURES ===================================
__________ test_free_shipping_threshold_is_checked_after_the_discount __________

    def test_free_shipping_threshold_is_checked_after_the_discount():
        cart = Cart()
        cart.add("LAMP-02", 21000)
        apply_coupon(cart, "WELCOME10")
        assert cart.discount() == 2100
>       assert cart.total() == 21000 - 2100 + 1500
E       AssertionError: assert 18900 == ((21000 - 2100) + 1500)
E        +  where 18900 = total()
E        +    where total = Cart(lines=[Line(sku='LAMP-02', unit_price=21000, quantity=1)], discount_percent=10).total

tests/test_threshold.py:10: AssertionError
=========================== short test summary info ============================
FAILED tests/test_threshold.py::test_free_shipping_threshold_is_checked_after_the_discount
1 failed in 0.58s
```

`18900` contra `20400`: o carrinho refatorado esqueceu o frete. No código original o mesmo teste
passa, então agora faz parte do projeto:

```
ana@dev:~/shop$ git checkout shop/cart.py && python -m pytest -q
Updated 1 path from the index
.........                                                                [100%]
9 passed in 0.56s
```

## Como refatorar com um assistente

- **Peça um diff**, e leia-o como uma mudança, linha contra linha, não como código novo.
- **Diga o que não pode mudar** no pedido: "o comportamento precisa continuar igual, inclusive o
  limite do frete grátis depois do desconto". Isso torna o erro menos provável e dá à revisão algo
  contra o que conferir.
- **Fixe primeiro, depois refatore.** Se os testes em volta do código são poucos, o primeiro commit
  são testes novos, no código antigo, passando. A aula 4 é sobre escrever bem esses testes, e sobre
  por que testes gerados a partir do código atual não teriam fixado nada de útil aqui.
- **Mantenha a refatoração e a mudança de comportamento em commits separados.** Se o diff do
  assistente faz as duas coisas, divida-o, ou peça de novo.
