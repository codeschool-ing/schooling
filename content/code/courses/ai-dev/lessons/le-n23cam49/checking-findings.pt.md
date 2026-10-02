---
title: Conferindo um achado antes de agir
version: 1
---

Um achado de revisão é uma hipótese sobre o código: *se fizermos isto, acontece aquilo*. **O jeito
de conferir uma hipótese sobre código é rodá-lo.** Escreva o menor teste que falharia se o achado
estivesse certo, e veja.

## Um teste por achado

O achado 1 diz que o FRIENDS15 é recusado no último dia. O achado 3 diz que um código em
minúsculas é recusado. O achado 2 é sobre o relógio do servidor, nenhum teste de unidade o alcança,
e ele espera. A ana escreve um teste para cada um dos outros dois, com o nome do achado:

```python
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_finding_1_friends15_is_valid_on_its_last_day():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_finding_3_a_lower_case_code_is_accepted():
    cart = Cart()
    apply_coupon(cart, "welcome10", today=date(2026, 10, 2))
    assert cart.discount_percent == 10
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_review.py
F.                                                                       [100%]
=================================== FAILURES ===================================
______________ test_finding_1_friends15_is_valid_on_its_last_day _______________

    def test_finding_1_friends15_is_valid_on_its_last_day():
        cart = Cart()
>       apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))

tests/test_review.py:9: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

cart = Cart(lines=[], discount_percent=0), code = 'FRIENDS15'
today = datetime.date(2026, 10, 31)

    def apply_coupon(cart: Cart, code: str, today: date | None = None) -> None:
        """Set the cart's discount from a coupon code, typed in any case."""
        today = today or date.today()
        code = code.strip().upper()
        if code not in COUPONS:
            raise UnknownCoupon(code)
        percent, until = COUPONS[code]
        if until is not None and today >= until:
>           raise ExpiredCoupon(code)
E           shop.coupons.ExpiredCoupon: FRIENDS15

shop/coupons.py:25: ExpiredCoupon
=========================== short test summary info ============================
FAILED tests/test_review.py::test_finding_1_friends15_is_valid_on_its_last_day
1 failed, 1 passed in 0.57s
```

**O achado 1 é real.** O teste falha com `ExpiredCoupon: FRIENDS15` em 31 de outubro, e o traceback
aponta para `today >= until`. **O achado 3 não é.** O código em minúsculas foi aceito, porque a
segunda linha de `apply_coupon` é `code = code.strip().upper()`. O assistente disse que a busca
distingue maiúsculas enquanto a linha que resolve isso estava no diff que ele revisava.

Esse achado falso é o mais instrutivo dos dois. Era específico, citava uma linha real e um
comportamento real de cliente, e estava errado com confiança. Quem agisse sem conferir teria posto
uma segunda chamada a `upper()`, piorado o código e fechado o achado como resolvido.

## O achado 2, que nenhum teste resolve

`date.today()` devolve a data de onde o servidor roda. Se o servidor roda em UTC e os clientes estão
em São Paulo, três horas atrás, então a partir das 21h de 31 de outubro, hora local, o servidor já
acha que é 1º de novembro. É uma pergunta real, e é uma pergunta para uma pessoa: a que fuso os
termos do cupom se referem, e onde rodam os servidores da loja. A revisão fez bem em levantá-la.
**Um achado pode valer sem ser um bug**, e se responde com uma decisão, por escrito, não com um
teste.

## A triagem

| achado | como foi conferido | resultado |
|---|---|---|
| 1, último dia recusado | um teste que falha | um bug: corrigir, e guardar o teste |
| 2, fuso do servidor | uma pergunta a quem cuida dos termos | uma decisão a tomar |
| 3, busca sensível a maiúsculas | um teste que passa | errado: descartar, com o teste como motivo |

Guarde os testes da triagem, inclusive o do achado falso. Custou dois minutos, documenta que
códigos em minúsculas funcionam, e falha se alguém tirar o `upper()` depois.
