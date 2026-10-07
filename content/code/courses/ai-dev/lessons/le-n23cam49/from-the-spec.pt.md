---
title: Testes a partir do que o código deve fazer
version: 2
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

Uma falha, e é o bug da aula 4 seção 03 de novo, achado desta vez só a partir dos termos: eles
dizem que o dia 31 está incluído, e o código o recusa.

## A correção, e o que ela quebra

```
ana@dev:~/shop$ sed -i "s/today >= until/today > until/" shop/coupons.py && git diff --stat
ana@dev:~/shop$ python -m pytest -q tests/test_coupon_terms.py tests/test_review.py
ana@dev:~/shop$ python -m pytest -q tests/test_generated.py | tail -n 15
```

Um caractere no `shop/coupons.py`, e todo teste escrito a partir dos termos ou do que a mudança
prometia passa. O arquivo gerado vai de cinco falhas para três: os dois testes que esperavam que 31
de outubro funcionasse agora passam. O terceiro que usava essa data, o
`test_apply_coupon_code_with_end_date_expired`, continua parando em `NameError: name 'shop' is not
defined`, e o traceback mostra a linha que ele nunca alcançou: `pytest.raises(...ExpiredCoupon)` em
31 de outubro. **Ele afirmava o bug**, e com o import consertado agora falharia por isso. A resposta
certa é apagá-lo, não editar o código de volta, e o resto do arquivo vai junto, já que os valores
esperados dele vieram de lugar nenhum para onde alguém consiga apontar:

```
ana@dev:~/shop$ rm tests/test_generated.py && python -m pytest -q
```

## Usando um assistente aqui

Parte do que deu errado na aula 4 seção 04 era do próprio modelo, os imports, e parte era o que ele
recebeu: o código, e nada que dissesse para que o código serve. Dê a ele a especificação e peça
testes da especificação, e ele volta a ser útil:

- **Ponha os termos, o chamado ou a docstring na requisição**, e diga que os valores esperados têm
  de vir dali, não do código.
- **Peça os limites pelo nome**: o último dia válido e o primeiro inválido, zero, um, o máximo, uma
  entrada vazia.
- **Leia todo valor esperado** antes de ficar com um teste, como você conferiria a conta no teste
  de um colega. Um valor esperado errado num teste é um bug que deixa o build verde.
