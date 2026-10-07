---
title: Um assistente como revisor
version: 2
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

Ela salva o diff e pede uma revisão dele. Uma revisão é uma lista de afirmações, então ela pede uma
lista curta, e guarda a resposta num arquivo para poder numerar as linhas:

```
ana@dev:~/shop$ git diff main > review.diff
ana@dev:~/shop$ python scratch/assist.py ask "Review this diff. List the three most serious real problems, one short paragraph each." --open review.diff > review.txt
ana@dev:~/shop$ cat -n review.txt
```

Três achados, numerados, confiantes e específicos. Agora leia cada um contra o diff. O primeiro
quer que o `today` seja obrigatório; o padrão de que ele reclama é o que deixa a loja chamar o
`apply_coupon` sem passar uma data, então é uma preferência sobre o desenho, não um problema. O
segundo quer a data de validade na exceção, uma melhoria de que ninguém precisa para entregar isto.
O terceiro pede uma "dica de tipo mais específica" para `cart: Cart`, que dá o nome da classe que o
arquivo importa e é tão específica quanto uma dica pode ser, e sugere `Cart = object`, que a
deixaria menos. **Nenhum dos três é um bug, e o bug não está lá**: o FRIENDS15 é recusado no seu
último dia válido, 31 de outubro, porque o código diz `today >= until`. A próxima seção o acha.

O que importa aqui é o formato:

- **Uma revisão é uma lista de afirmações**, cada uma sobre uma linha e um comportamento. Isso torna
  cada uma conferível, o que um vago "parece bom, considere acrescentar testes" não é. Peça esse
  formato: só problemas reais, o mais sério primeiro, cada um com a linha e o caso que o quebra.
- **O assistente viu só o diff.** Não os testes, não os termos dos cupons que o marketing publicou,
  não o fuso horário em que a loja roda. Um diff sem contexto ganha uma revisão sem contexto, e a
  regra da aula 3 seção 02 vale: os arquivos que definem a expectativa vão na requisição.
- **Ele lê o código, não a intenção.** Não tem como saber que "até 31 de outubro" inclui o dia 31 a
  não ser que algo diga, e aqui o comentário no código por acaso diz. Um modelo maior lê esse
  comentário mais vezes que um pequeno. Nenhum substitui um teste que diga o que o dia 31 deve
  fazer.
