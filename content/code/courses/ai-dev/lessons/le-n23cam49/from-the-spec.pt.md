---
title: Testes a partir do que o código deve fazer
version: 1
---

A correção para testes que fixam bugs é mudar de onde vêm os valores esperados. **O valor esperado
de um teste deve vir da especificação**: os termos do cupom, o chamado, a docstring escrita antes do
código, uma conversa com quem pediu a funcionalidade. O código sob teste é o único lugar de onde
ele não pode vir.

## Os termos como testes

A loja publica os termos dos cupons. A ana os copia para a docstring do arquivo de testes, para que o
motivo de cada valor esperado esteja no arquivo, e escreve um teste por frase:

```python
"""The coupon terms, as the shop publishes them:

    FRIENDS15  15% off, valid until 31 October 2026, inclusive.
    WELCOME10  10% off, no end date.
    Codes may be typed in any case.
"""
from datetime import date

import pytest

from shop.cart import Cart
from shop.coupons import ExpiredCoupon, apply_coupon


def test_friends15_is_valid_on_31_october():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_friends15_is_refused_on_1_november():
    with pytest.raises(ExpiredCoupon):
        apply_coupon(Cart(), "FRIENDS15", today=date(2026, 11, 1))


def test_welcome10_never_expires():
    cart = Cart()
    apply_coupon(cart, "WELCOME10", today=date(2099, 1, 1))
    assert cart.discount_percent == 10


@pytest.mark.parametrize("typed", ["friends15", "Friends15", " FRIENDS15 "])
def test_codes_may_be_typed_in_any_case(typed):
    cart = Cart()
    apply_coupon(cart, typed, today=date(2026, 10, 2))
    assert cart.discount_percent == 15
```

O limite é testado dos dois lados: o último dia válido e o primeiro inválido. Esse par é o que uma
especificação sobre datas sempre precisa, porque o bug está sempre no limite. Rodando no código da
aula 4 seção 02:

```
ana@dev:~/shop$ python -m pytest -q tests/test_coupon_terms.py
F.....                                                                   [100%]
=================================== FAILURES ===================================
____________________ test_friends15_is_valid_on_31_october _____________________

    def test_friends15_is_valid_on_31_october():
        cart = Cart()
>       apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))

tests/test_coupon_terms.py:17: 
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
FAILED tests/test_coupon_terms.py::test_friends15_is_valid_on_31_october - sh...
1 failed, 5 passed in 0.56s
```

Uma falha, e é o achado 1 de novo, desta vez achado sem revisor: os termos dizem que o dia 31 está
incluído, o código o recusa.

## A correção, e o que ela quebra

```
ana@dev:~/shop$ sed -i "s/today >= until/today > until/" shop/coupons.py && git diff --stat
 shop/coupons.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@dev:~/shop$ python -m pytest -q tests/test_coupon_terms.py tests/test_review.py
........                                                                 [100%]
8 passed in 0.56s
ana@dev:~/shop$ python -m pytest -q tests/test_generated.py
..F.                                                                     [100%]
=================================== FAILURES ===================================
_____________________ test_friends15_expires_on_2026_10_31 _____________________

    def test_friends15_expires_on_2026_10_31():
>       with pytest.raises(ExpiredCoupon):
E       Failed: DID NOT RAISE ExpiredCoupon

tests/test_generated.py:22: Failed
=========================== short test summary info ============================
FAILED tests/test_generated.py::test_friends15_expires_on_2026_10_31 - Failed...
1 failed, 3 passed in 0.55s
```

Um caractere no `shop/coupons.py`, e todo teste escrito a partir dos termos ou da revisão passa. O
teste gerado agora falha, **e essa falha está certa**: ele afirmava o bug. A resposta certa a ela é
apagá-lo, não desfazer a correção:

```
ana@dev:~/shop$ rm tests/test_generated.py && python -m pytest -q
................                                                         [100%]
16 passed in 0.56s
```

## Usando um assistente aqui

O assistente não era o problema na aula 4 seção 04; o que ele recebeu era. Dê a ele a especificação
e peça testes da especificação, e ele volta a ser útil:

- **Ponha os termos, o chamado ou a docstring na requisição**, e diga que os valores esperados têm
  de vir dali, não do código.
- **Peça os limites pelo nome**: o último dia válido e o primeiro inválido, zero, um, o máximo, uma
  entrada vazia.
- **Leia todo valor esperado** antes de ficar com um teste, como você conferiria a conta no teste
  de um colega. Um valor esperado errado num teste é um bug que deixa o build verde.
