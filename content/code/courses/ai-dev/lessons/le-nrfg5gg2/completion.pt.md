---
title: Aceitando uma completação
version: 2
---

Uma completação chega formatado, indentado, plausível e no seu estilo, e é tentador ler isso como
correto. **Leia como você leria o código de um colega numa revisão**: contra o que o código deveria
fazer, não contra a aparência dele. O jeito mais rápido de fazer isso é escrever o que ele deveria
fazer como testes, antes de decidir ficar com qualquer coisa.

## Testes a partir da docstring, antes do código

A ana escreve um teste por frase da docstring de `remove()`, em `tests/test_remove.py`. Ela os
escreve a partir do que quis dizer, antes de existir qualquer sugestão, porque um teste escrito
lendo o código sob teste confere que o código faz o que faz:

```python
import pytest

from shop.cart import Cart


def test_removing_some_units_keeps_the_line():
    cart = Cart()
    cart.add("MUG-01", 3990, 3)
    cart.remove("MUG-01", 2)
    assert cart.lines[0].quantity == 1


def test_removing_the_last_unit_removes_the_line():
    cart = Cart()
    cart.add("MUG-01", 3990)
    cart.remove("MUG-01")
    assert cart.lines == []


def test_removing_more_than_the_cart_holds_is_refused():
    cart = Cart()
    cart.add("MUG-01", 3990, 2)
    with pytest.raises(ValueError):
        cart.remove("MUG-01", 3)


def test_removing_a_sku_not_in_the_cart_is_refused():
    with pytest.raises(ValueError):
        Cart().remove("LAMP-02")
```

Depois ela faz commit da assinatura do método, da docstring e dos testes, para que o que quer que
uma ferramenta faça com o arquivo em seguida possa ser desfeito com um comando. O corpo ainda está
vazio, então os quatro testes falham:

```
ana@dev:~/shop$ git add shop/cart.py tests/test_remove.py && git commit -q -m "Cart.remove: what it must do"
ana@dev:~/shop$ python -m pytest -q tests/test_remove.py | tail -n 1
4 failed in 0.71s
```

## Aceitar, testar, desfazer

Agora o laço de que trata o resto desta seção: aceitar uma sugestão, rodar os quatro testes, e se
eles falharem, devolver o arquivo e pedir de novo. O `--accept` põe a sugestão onde estava o
cursor, como apertar Tab poria, e o `2>/dev/null` esconde o relatório sobre o contexto, que a
seção 02 já leu:

```
ana@dev:~/shop$ python scratch/assist.py complete shop/cart.py:34 --open shop/coupons.py tests/test_cart.py --accept 2>/dev/null
        line = next((line for line in self.lines if line.sku == sku), None)
        if not line:
            raise ValueError(f"cannot remove {sku}: it's not in the cart")
        if line.quantity < quantity:
            raise ValueError(f"cannot remove {sku}: {quantity} exceeds quantity in the cart")
        line.quantity -= quantity
        if line.quantity == 0:
            self.lines.remove(line)
ana@dev:~/shop$ python -m pytest -q tests/test_remove.py | tail -n 1
4 passed in 0.76s
```

A primeira sugestão passou nos quatro. Na máquina da gravação isso levou uma tentativa, e na sua
pode levar duas ou três: a seção 02 mostrou que cada pedido é um sorteio novo. **Repare no que os
quatro testes não conferem**, porém. A sugestão da seção 02 também teria passado neles, com o seu
falso `no MUG-01 in cart`, porque um teste que espera `ValueError` fica satisfeito com qualquer
`ValueError`. Um teste confere o que foi escrito para conferir, e uma mensagem só faz parte do
comportamento se um teste disser.

## Ficando com ela

```
ana@dev:~/shop$ git diff
diff --git a/shop/cart.py b/shop/cart.py
index 2e3e557..c74e8cd 100644
--- a/shop/cart.py
+++ b/shop/cart.py
@@ -31,7 +31,14 @@ class Cart:
         A line that reaches zero is removed. Removing more than the cart
         holds, or a sku it does not hold, raises ValueError.
         """
-
+        line = next((line for line in self.lines if line.sku == sku), None)
+        if not line:
+            raise ValueError(f"cannot remove {sku}: it's not in the cart")
+        if line.quantity < quantity:
+            raise ValueError(f"cannot remove {sku}: {quantity} exceeds quantity in the cart")
+        line.quantity -= quantity
+        if line.quantity == 0:
+            self.lines.remove(line)
     def subtotal(self) -> int:
         return sum(line.unit_price * line.quantity for line in self.lines)
 
ana@dev:~/shop$ python -m pytest -q
............                                                             [100%]
12 passed in 0.79s
```

Doze testes passam: os oito que o projeto tinha e os quatro novos. O diff mostra mais uma coisa que
os testes não conseguem: **sumiu a linha em branco entre `remove()` e `subtotal()`**. A sugestão
tomou o lugar da linha vazia do cursor e parou antes de escrever uma sua, então o próximo método
começa logo embaixo. Quem revisa a põe de volta. Esse é o formato da maioria dos completações
aceitas: certo, quase, com o último detalhe deixado para quem lê o diff.

## Os hábitos

- **Escreva a intenção antes de aceitar.** Uma docstring, um teste, ou os dois. Uma completação casa
  com o que recebeu, e um corpo de função vazio não lhe dá nada para casar além do nome.
- **Aceite pouco por vez.** Uma linha ou um bloco que você lê num relance. Aceitar quarenta linhas
  porque as cinco primeiras estavam certas é como um bug chega em código que ninguém escreveu. O
  `assist` para uma sugestão na primeira linha em branco por esse motivo.
- **Faça commit antes de uma ferramenta editar, e rode os testes logo depois.** O teste que falhou
  logo depois da sugestão aponta para a sugestão; a mesma falha três mudanças depois aponta para as
  três. E o `git checkout` é um desfazer melhor que tentar lembrar o que o arquivo dizia.
