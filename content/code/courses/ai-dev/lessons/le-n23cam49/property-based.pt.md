---
title: Propriedades em vez de exemplos
version: 1
---

Um teste baseado em exemplos confere as entradas em que você pensou. Um **teste baseado em
propriedades** afirma algo que tem de valer para toda entrada, e uma biblioteca gera centenas de
entradas procurando uma em que seja falso. Em Python essa biblioteca é o **hypothesis**. Quando acha
uma falha, ele a encolhe até a entrada mais simples que ainda falha, o que torna o relatório
legível.

Escrever uma propriedade é dizer para que o código serve em geral, e não para um caso. Essa é a
parte difícil, e é a parte em que um assistente pode sugerir candidatas que você depois julga.

## Duas propriedades do dinheiro como texto

A ana afirma duas coisas que têm de valer para todo valor entre menos e mais um bilhão de
centavos:

```python
from hypothesis import given
from hypothesis import strategies as st

from shop.money import format_price, parse_price

cents = st.integers(min_value=-10**9, max_value=10**9)


@given(cents)
def test_a_price_survives_a_round_trip_through_text(n):
    assert parse_price(format_price(n)) == n


@given(cents)
def test_a_negative_price_reads_as_minus_the_positive_one(n):
    if n < 0:
        assert format_price(n) == "-" + format_price(-n)
```

- **Uma ida e volta**: formatar um valor e interpretar o texto de volta dá o mesmo valor.
- **Simetria**: um valor negativo se lê como um sinal de menos seguido do valor positivo.

Rodando contra o `shop/money.py` original. O `--hypothesis-seed=0` fixa as entradas aleatórias,
então a execução desta aula é a que você vai obter:

```
ana@dev:~/shop$ python -m pytest -q -p no:cacheprovider --hypothesis-seed=0 tests/test_money_properties.py
.F                                                                       [100%]
=================================== FAILURES ===================================
____________ test_a_negative_price_reads_as_minus_the_positive_one _____________

    @given(cents)
>   def test_a_negative_price_reads_as_minus_the_positive_one(n):
                   ^^^

tests/test_money_properties.py:15: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

n = -1

    @given(cents)
    def test_a_negative_price_reads_as_minus_the_positive_one(n):
        if n < 0:
>           assert format_price(n) == "-" + format_price(-n)
E           AssertionError: assert '-1.99' == '-0.01'
E             
E             - -0.01
E             + -1.99
E           Failing test case: test_a_negative_price_reads_as_minus_the_positive_one(
E               n=-1,
E           )
E           Explanation:
E               These lines were always and only run by failing test cases:
E                   /home/ana/shop/tests/test_money_properties.py:17

tests/test_money_properties.py:17: AssertionError
=========================== short test summary info ============================
FAILED tests/test_money_properties.py::test_a_negative_price_reads_as_minus_the_positive_one
1 failed, 1 passed in 0.15s
```

**A ida e volta passou.** A propriedade de simetria falhou na hora, encolhida até `n = -1`: menos um
centavo vira `'-1.99'`. Então o `format_price` está errado para todo número negativo, e a ida e volta
não percebeu, porque o `parse_price` está errado do jeito correspondente: `'-1.99'` volta a ser menos
um. **Dois bugs que se anulam passam numa ida e volta.** Vale saber isso sobre propriedades de ida e
volta em geral: elas testam que duas funções concordam, não que alguma delas esteja certa.

## Corrigindo um lado

A ana corrige o `format_price` para tratar o sinal:

```
ana@dev:~/shop$ git diff shop/money.py
diff --git a/shop/money.py b/shop/money.py
index 9af0e26..9d4ce02 100644
--- a/shop/money.py
+++ b/shop/money.py
@@ -9,5 +9,7 @@ def parse_price(text: str) -> int:
 
 
 def format_price(cents: int) -> str:
-    """Turn cents into a price as people read it: 1290 -> '12.90'."""
-    return f"{cents // 100}.{cents % 100:02d}"
+    """Turn cents into a price as people read it: 1290 -> '12.90', -5 -> '-0.05'."""
+    sign = "-" if cents < 0 else ""
+    cents = abs(cents)
+    return f"{sign}{cents // 100}.{cents % 100:02d}"
```

```
ana@dev:~/shop$ python -m pytest -q -p no:cacheprovider --hypothesis-seed=0 tests/test_money_properties.py
F.                                                                       [100%]
=================================== FAILURES ===================================
_______________ test_a_price_survives_a_round_trip_through_text ________________

    @given(cents)
>   def test_a_price_survives_a_round_trip_through_text(n):
                   ^^^

tests/test_money_properties.py:10: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

n = -1

    @given(cents)
    def test_a_price_survives_a_round_trip_through_text(n):
>       assert parse_price(format_price(n)) == n
E       AssertionError: assert 1 == -1
E        +  where 1 = parse_price('-0.01')
E        +    where '-0.01' = format_price(-1)
E       Failing test case: test_a_price_survives_a_round_trip_through_text(
E           n=-1,
E       )

tests/test_money_properties.py:11: AssertionError
=========================== short test summary info ============================
FAILED tests/test_money_properties.py::test_a_price_survives_a_round_trip_through_text
1 failed, 1 passed in 0.14s
```

Agora a simetria vale e a ida e volta falha, na mesma entrada mais simples: `'-0.01'` vira `1`. A
outra metade do par que se anulava aparece, o `parse_price` lendo `-0` como `0` e somando os
centavos. Ela corrige isso também, para o sinal ser lido primeiro e aplicado ao valor inteiro, e
roda tudo:

```
ana@dev:~/shop$ python -m pytest -q -p no:cacheprovider --hypothesis-seed=0
..........................                                               [100%]
26 passed in 0.17s
```

## De onde vêm propriedades

- **Idas e voltas**: codificar e decodificar, salvar e carregar, formatar e interpretar.
- **Invariantes**: um total nunca é negativo, uma lista ordenada tem os mesmos itens, tirar o que
  você pôs deixa o carrinho como estava.
- **Comparação com uma versão mais simples**: a função rápida concorda com a óbvia e lenta.

Um assistente pode sugerir propriedades para uma função, e as sugestões são afirmações sobre para que
o código serve, a ler com o mesmo cuidado que valores esperados. **Uma propriedade errada é um teste
que codifica um requisito errado**, que é o problema da aula 4 seção 04 de novo.
