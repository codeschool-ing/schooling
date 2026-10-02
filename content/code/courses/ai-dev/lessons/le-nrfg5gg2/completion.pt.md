---
title: Aceitando uma completação
version: 1
---

Uma completação chega formatada, indentada, plausível e no seu estilo, e é tentador ler isso como
correta. **Leia-a como você leria o código de um colega numa revisão**: contra o que o código deve
fazer, não contra a aparência dele. O jeito mais rápido de fazer isso é escrever o que ele deve
fazer na forma de testes, antes de decidir ficar com ele.

## A sugestão

Isto é o que o `assist` sugeriu para o `remove()` na aula 3 seção 02, posto depois da docstring que
a ana escreveu. Foi escrito pelo curso, com os erros de propósito:

```
ana@dev:~/shop$ sed -n 28,39p shop/cart.py
    def remove(self, sku: str, quantity: int = 1) -> None:
        """Take `quantity` units of `sku` out of the cart.

        A line that reaches zero is removed. Removing more than the cart
        holds, or a sku it does not hold, raises ValueError.
        """
        for line in self.lines:
            if line.sku == sku:
                line.quantity -= quantity
                return
        raise ValueError(f"{sku} is not in the cart")

```

Lê bem. Acha a linha, tira as unidades e recusa um sku que o carrinho não tem. Agora leia a
docstring de novo: *a line that reaches zero is removed* e *removing more than the cart holds
raises ValueError*. **A sugestão não faz nenhuma das duas coisas**, e nada na formatação dela diz
isso.

## Testes a partir da docstring, não do código

A ana escreve um teste por frase da docstring. Escreve a partir do que ela quis dizer, sem olhar a
sugestão, porque um teste escrito lendo o código sob teste confere que o código faz o que faz:

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

```
ana@dev:~/shop$ python -m pytest -q tests/test_remove.py
.FF.                                                                     [100%]
=================================== FAILURES ===================================
_________________ test_removing_the_last_unit_removes_the_line _________________

    def test_removing_the_last_unit_removes_the_line():
        cart = Cart()
        cart.add("MUG-01", 3990)
        cart.remove("MUG-01")
>       assert cart.lines == []
E       AssertionError: assert [Line(sku='MU..., quantity=0)] == []
E         
E         Left contains one more item: Line(sku='MUG-01', unit_price=3990, quantity=0)
E         Use -v to get more diff

tests/test_remove.py:17: AssertionError
______________ test_removing_more_than_the_cart_holds_is_refused _______________

    def test_removing_more_than_the_cart_holds_is_refused():
        cart = Cart()
        cart.add("MUG-01", 3990, 2)
>       with pytest.raises(ValueError):
E       Failed: DID NOT RAISE ValueError

tests/test_remove.py:23: Failed
=========================== short test summary info ============================
FAILED tests/test_remove.py::test_removing_the_last_unit_removes_the_line - A...
FAILED tests/test_remove.py::test_removing_more_than_the_cart_holds_is_refused
2 failed, 2 passed in 0.56s
```

Dois dos quatro falham, e as falhas dizem exatamente o que está errado: uma linha que fica no
carrinho com `quantity=0`, e nenhum erro ao tirar três canecas de duas. Os outros dois passam,
porque a sugestão acertou essas partes. **Esta é a forma habitual de uma sugestão errada**: quase
toda certa, errada nas bordas, e as bordas são onde a docstring era específica.

## A correção, à mão

```
ana@dev:~/shop$ sed -n 34,42p shop/cart.py
        for line in self.lines:
            if line.sku == sku:
                if quantity > line.quantity:
                    raise ValueError(f"the cart holds {line.quantity} of {sku}")
                line.quantity -= quantity
                if line.quantity == 0:
                    self.lines.remove(line)
                return
        raise ValueError(f"{sku} is not in the cart")
```

```
ana@dev:~/shop$ git diff --stat
 shop/cart.py | 16 ++++++++++++++++
 1 file changed, 16 insertions(+)
ana@dev:~/shop$ python -m pytest -q
............                                                             [100%]
12 passed in 0.53s
```

Os doze testes passam: os oito que o projeto tinha e os quatro novos. A sugestão poupou o laço e a
mensagem de erro e custou dois bugs, uma troca justa **só porque os testes os acharam**. Sem os
testes, o carrinho teria saído com uma linha de zero canecas que não soma nada ao total e ainda
aparece na página de fechamento.

## Os hábitos

- **Escreva a intenção antes de aceitar.** Uma docstring, um teste, ou os dois. Uma completação
  casa com o que recebeu, e um corpo de função vazio não lhe dá nada para casar além do nome.
- **Aceite pouco por vez.** Uma linha ou um bloco que você lê num relance. Aceitar quarenta linhas
  porque as cinco primeiras estavam certas é como um bug chega em código que ninguém escreveu.
- **Rode os testes antes de seguir em frente**, não no fim da tarde. O teste que falhou logo depois
  da sugestão aponta para a sugestão; a mesma falha três mudanças depois aponta para as três.
