---
title: Um assistente como revisor
version: 1
---

Pedir a um assistente que revise uma mudança é o contrário de pedir que a escreva, e de certo modo
a metade mais segura. **Uma revisão produz afirmações, e uma afirmação pode ser conferida** antes
de qualquer coisa mudar. O risco se desloca: de código errado para achados errados, nas duas
direções. Um problema real que ele não menciona, e um problema que ele inventa.

## A mudança

A ana tem um branch que deixa os clientes digitarem códigos de cupom em maiúsculas ou minúsculas e
dá aos cupons uma data de fim. O FRIENDS15 vale até 31 de outubro de 2026:

```python
from datetime import date

from shop.cart import Cart

# code: (percent off, last day it is valid, or None for no end)
COUPONS = {"WELCOME10": (10, None), "FRIENDS15": (15, date(2026, 10, 31))}


class UnknownCoupon(Exception):
    pass


class ExpiredCoupon(Exception):
    pass


def apply_coupon(cart: Cart, code: str, today: date | None = None) -> None:
    """Set the cart's discount from a coupon code, typed in any case."""
    today = today or date.today()
    code = code.strip().upper()
    if code not in COUPONS:
        raise UnknownCoupon(code)
    percent, until = COUPONS[code]
    if until is not None and today >= until:
        raise ExpiredCoupon(code)
    cart.discount_percent = percent
```

```
ana@dev:~/shop$ git switch -c coupon-expiry
Switched to a new branch 'coupon-expiry'
ana@dev:~/shop$ git commit -qam "Coupons in any case, with an end date" && python -m pytest -q
........                                                                 [100%]
8 passed in 0.55s
ana@dev:~/shop$ git diff main --stat
 shop/coupons.py | 20 ++++++++++++++++----
 1 file changed, 16 insertions(+), 4 deletions(-)
```

Os oito testes passam, porque nenhum deles sabe ainda de datas de fim.

## A revisão

Ela salva o diff e pede uma revisão dele. A resposta foi escrita pelo curso, do jeito que a revisão
de um assistente costuma ser: numerada, confiante e específica:

```
ana@dev:~/shop$ git diff main > review.diff
ana@dev:~/shop$ assist ask "Review this diff. List real problems only, most serious first." --open review.diff
context sent (328 of 3000 tokens):
    328  review.diff
---
Three things in this diff:

1. Expiry is off by one day. `today >= until` refuses a coupon on its last valid day: FRIENDS15 says it runs until 2026-10-31, and on 2026-10-31 it is refused. If `until` is the last day it is valid, the test should be `today > until`.

2. `date.today()` is the server's local date. If the shop runs in UTC and its customers are in Brazil, a coupon expires three hours early for them, every evening. Consider passing the date from the request, in the shop's time zone.

3. The lookup is still case-sensitive: `COUPONS` has upper-case keys, so a customer who types `welcome10` will get UnknownCoupon. Normalise the code before looking it up.
```

**Três achados, e são três tipos diferentes de coisa.** Um é um bug. Um é uma pergunta real sobre o
desenho, que nenhum teste pegaria. Um está errado. A aula 4 seção 03 os separa. O que importa aqui é
a forma:

- **A revisão é uma lista de afirmações**, cada uma sobre uma linha e um comportamento. Isso torna
  cada uma conferível, o que um vago "parece bom, considere acrescentar testes" não é. Peça essa
  forma: só problemas reais, o mais sério primeiro, cada um com a linha e o caso que quebra.
- **O assistente só viu o diff.** Não os testes, não os termos do cupom que o marketing publicou,
  não o fuso horário em que a loja roda. Um diff sem contexto ganha uma revisão sem contexto, e vale
  a regra da aula 3 seção 02: os arquivos que definem o que se espera pertencem à requisição.
- **Ele lê o código, não a intenção.** Não tem como saber que "até 31 de outubro" inclui o dia 31 a
  menos que algo diga, e aqui o comentário no código por acaso diz. Onde nada diz, um assistente
  chuta, e um revisor humano também.
