---
title: Testes de unidade, e o código que eles fizeram a Ana mudar
version: 1
---

A primeira coisa que um teste pede ao código é que ele possa ser chamado. O validador da lição 16 não
podia: o trabalho dele era feito no nível de cima do arquivo, lendo o `sys.argv` no momento em que
era importado, então um teste que o importasse para chamar o `check` teria rodado o programa
inteiro. A Ana leva esse trabalho para uma função `main`, chamada só quando o arquivo roda como
script:

```
ana@vm:~/etl$ diff /tmp/validate_prices.before.py validate_prices.py | head -n 12; echo …; diff /tmp/validate_prices.before.py validate_prices.py | tail -n 6
49,58c49,58
< src, good_path, bad_path = sys.argv[1:4]
< fixed, rejected, good, bad = Counter(), Counter(), [], []
< for line in open(src, encoding="utf-8"):
<     rec = json.loads(line)
<     reason = check(rec, fixed)
<     if reason:
<         rejected[reason] += 1
<         bad.append({"reason": reason, "record": json.loads(line)})
<     else:
<         good.append(rec)
---
…
>         out.writelines(json.dumps(g, ensure_ascii=False) + "\n" for g in good)
>     return 0
> 
> 
> if __name__ == "__main__":
>     sys.exit(main(*sys.argv[1:4]))
```

O programa faz exatamente o que fazia. O que mudou é que o `check` e o `isbn13_ok` agora podem ser
importados e chamados sobre um registro por vez. **Código fácil de testar costuma ser código que
mantém as decisões separadas da entrada e da saída**, e a mudança valia a pena só por isso.

Depois, os testes: uma regra cada, com um registro que o validador aceita e um campo mudado.

```
"""Unit tests for the price validator: one record in, one decision out."""
from collections import Counter

from validate_prices import check, isbn13_ok


def price(**changes):
    """A record the validator accepts as it is, with some fields changed."""
    rec = {"isbn": "9786574218454", "publisher": "Borda", "list_price_cents": 10490,
           "currency": "BRL", "updated_at": "2026-01-01T05:01:00-03:00"}
    rec.update(changes)
    return rec


def test_a_real_isbn_passes_its_check_digit():
    assert isbn13_ok("9786574218454")


def test_one_wrong_digit_fails_it():
    assert not isbn13_ok("9786574218455")


def test_hyphens_are_removed_and_counted():
    rec, fixed = price(isbn="978-65-7421-845-4"), Counter()
    assert check(rec, fixed) is None
    assert rec["isbn"] == "9786574218454"
    assert fixed == {"isbn written with hyphens": 1}


def test_a_missing_price_is_rejected():
    assert check(price(list_price_cents=None), Counter()) == "price missing"


def test_a_price_with_a_decimal_comma_is_rejected():
    assert check(price(list_price_cents="104,90"), Counter()) == "price '104,90' is not a number"


def test_another_currency_is_rejected_not_converted():
    assert check(price(currency="USD"), Counter()) == "currency 'USD'"


def test_a_price_in_reais_is_not_taken_for_cents():
    assert check(price(list_price_cents=104.9), Counter()) == "price 104.9 is not a whole number of cents"
```

```
ana@vm:~/etl$ python -m pytest -q tests/test_validate.py 2>&1 | tail -n 15
......F                                                                  [100%]
=================================== FAILURES ===================================
_________________ test_a_price_in_reais_is_not_taken_for_cents _________________

    def test_a_price_in_reais_is_not_taken_for_cents():
>       assert check(price(list_price_cents=104.9), Counter()) == "price 104.9 is not a whole number of cents"
E       AssertionError: assert None == 'price 104.9 is not a whole number of cents'
E        +  where None = check({'isbn': '9786574218454', 'publisher': 'Borda', 'list_price_cents': 104.9, 'currency': 'BRL', ...}, Counter())
E        +    where {'isbn': '9786574218454', 'publisher': 'Borda', 'list_price_cents': 104.9, 'currency': 'BRL', ...} = price(list_price_cents=104.9)
E        +    and   Counter() = Counter()

tests/test_validate.py:43: AssertionError
=========================== short test summary info ============================
FAILED tests/test_validate.py::test_a_price_in_reais_is_not_taken_for_cents
1 failed, 6 passed in 0.02s
```

Seis passaram. O sétimo é o que a Ana escreveu perguntando *o que uma editora poderia mandar que eu
ainda não vi?* — um preço em reais com ponto decimal, `104.9`, como número e não como texto. O
validador **aceitou**: não é `None`, não é string, e está entre 100 e 100.000, então passou como um
preço de 104,9 centavos, um centésimo do que o livro custa. Nenhuma editora mandou um ainda. O
primeiro teria sido carregado sem uma palavra.

A correção é conferir que o preço é um número inteiro:

```
ana@vm:~/etl$ diff /tmp/validate_prices.before.py validate_prices.py | sed -n "/whole number/,+0p;/isinstance(rec/,+0p"
>     if not isinstance(rec["list_price_cents"], int):
>         return f"price {rec['list_price_cents']} is not a whole number of cents"
ana@vm:~/etl$ python -m pytest -q tests/test_validate.py
.......                                                                  [100%]
7 passed in 0.02s
```

Sete passaram. Esse é o argumento a favor de testes de unidade num pipeline: **eles deixam perguntar
sobre a entrada que ainda não chegou**, o que nenhum teste sobre os dados consegue.
