---
title: Conferindo um achado antes de agir
version: 2
---

Um achado de revisão é uma hipótese sobre o código: *se fizermos isto, acontece aquilo*. **O jeito
de conferir uma hipótese sobre código é rodá-lo**, ou ler a linha de que ela fala. E uma revisão
que não acha nada sobre uma parte da mudança também é uma hipótese: a de que essa parte está
certa. Essa se confere do mesmo jeito.

## As afirmações, uma por uma

Cada uma das três afirmações da revisão se resolve lendo a linha que ela cita. O `today` usa a data
de hoje como padrão de propósito, então a primeira é uma escolha a manter ou mudar, não um defeito.
A segunda pede mais informação numa exceção, o que é um desejo. A terceira é sobre `cart: Cart`, e
`Cart` é a classe importada no topo do arquivo: não há nada a corrigir, e a correção sugerida
pioraria o código. **Nenhuma delas precisa de teste.** Agir sobre a terceira sem ler a linha teria
custado uma tarde, baixado a qualidade do código e fechado um achado como resolvido.

É isso que a revisão de um modelo pequeno é, na maior parte: afirmações com a forma de uma revisão
e a substância de nada. A revisão de um modelo maior tem menos delas e alguns achados reais no
meio, e o jeito de separar um tipo do outro é o mesmo: a linha, e, quando a linha não resolve, um
teste.

## O que a mudança prometia

A mudança prometia duas coisas: o FRIENDS15 vale até 31 de outubro, e um código pode ser digitado
em qualquer caixa. A ana escreve um teste para cada uma, em `tests/test_review.py`, porque, diga a
revisão o que disser, esses são os dois comportamentos para os quais este branch existe:

```python
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_friends15_is_valid_on_its_last_day():
    cart = Cart()
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 31))
    assert cart.discount_percent == 15


def test_a_lower_case_code_is_accepted():
    cart = Cart()
    apply_coupon(cart, "welcome10", today=date(2026, 10, 2))
    assert cart.discount_percent == 10
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_review.py
```

**O último dia é recusado.** O teste falha com `ExpiredCoupon: FRIENDS15` em 31 de outubro, e o
traceback aponta para `today >= until`: a comparação deveria ser `>`, já que `until` é o último dia
válido. O código em minúsculas é aceito, porque a segunda linha do `apply_coupon` é
`code = code.strip().upper()`.

**O bug que a revisão não mencionou é o que o teste achou.** Um revisor que deixa algo passar não
diz nada sobre isso, e o silêncio parece aprovação. Esse é o mais perigoso dos dois erros de um
revisor, e é por isso que as promessas da própria mudança ganham um teste, diga a revisão o que
disser.

## Uma pergunta que nenhum teste resolve

O `date.today()` devolve a data do lugar onde o servidor roda. Se o servidor roda em UTC e os
clientes estão em São Paulo, três horas atrás, então a partir das 21h de 31 de outubro, hora local,
o servidor já acredita que é 1º de novembro. Essa é uma pergunta real, e é uma pergunta para uma
pessoa: que fuso os termos dos cupons querem dizer, e onde os servidores da loja rodam. **Um achado
pode ter valor sem ser um bug**, e ele se responde com uma decisão, escrita, não com um teste. Nada
nesta revisão levantou isso; um revisor que soubesse onde a loja roda levantaria.

Fique com os testes da conferência, inclusive o que passou. Ele custou dois minutos, documenta que
códigos em minúsculas funcionam, e falha se alguém tirar o `upper()` depois.
