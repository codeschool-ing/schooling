---
title: Pedindo as bordas
version: 1
---

A maioria dos bugs mora nas bordas da entrada: zero, um, a lista vazia, o maior valor, o número
negativo que ninguém esperava. Uma especificação raramente as lista, porque quem a escreveu pensava
no caso normal. **Listar casos de borda é algo que um assistente faz bem**, e é seguro pedir: uma
lista de entradas se confere lendo, e as saídas esperadas continuam vindo de você.

## Uma tabela de casos

A aula 3 seção 07 achou que `format_price(-5)` devolve `'-1.95'`. A ana pede casos de borda para a
função, fica com as entradas que a lista sugere (zero, um centavo, logo abaixo e em cima de uma
unidade inteira, um valor grande, negativos) e escreve ela mesma o texto esperado de cada uma. O
`parametrize` do pytest transforma a tabela num teste por linha:

```python
import pytest

from shop.money import format_price


@pytest.mark.parametrize("cents, text", [
    (0, "0.00"),
    (5, "0.05"),
    (99, "0.99"),
    (100, "1.00"),
    (1290, "12.90"),
    (100000, "1000.00"),
    (-5, "-0.05"),
    (-1290, "-12.90"),
])
def test_format_price(cents, text):
    assert format_price(cents) == text
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_format_edges.py
......FF                                                                 [100%]
=================================== FAILURES ===================================
_________________________ test_format_price[-5--0.05] __________________________

cents = -5, text = '-0.05'

    @pytest.mark.parametrize("cents, text", [
        (0, "0.00"),
        (5, "0.05"),
        (99, "0.99"),
        (100, "1.00"),
        (1290, "12.90"),
        (100000, "1000.00"),
        (-5, "-0.05"),
        (-1290, "-12.90"),
    ])
    def test_format_price(cents, text):
>       assert format_price(cents) == text
E       AssertionError: assert '-1.95' == '-0.05'
E         
E         - -0.05
E         + -1.95

tests/test_format_edges.py:17: AssertionError
_______________________ test_format_price[-1290--12.90] ________________________

cents = -1290, text = '-12.90'

    @pytest.mark.parametrize("cents, text", [
        (0, "0.00"),
        (5, "0.05"),
        (99, "0.99"),
        (100, "1.00"),
        (1290, "12.90"),
        (100000, "1000.00"),
        (-5, "-0.05"),
        (-1290, "-12.90"),
    ])
    def test_format_price(cents, text):
>       assert format_price(cents) == text
E       AssertionError: assert '-13.10' == '-12.90'
E         
E         - -12.90
E         + -13.10

tests/test_format_edges.py:17: AssertionError
=========================== short test summary info ============================
FAILED tests/test_format_edges.py::test_format_price[-5--0.05] - AssertionErr...
FAILED tests/test_format_edges.py::test_format_price[-1290--12.90] - Assertio...
2 failed, 6 passed in 0.57s
```

Seis linhas passam e as duas negativas falham, cada uma com a saída errada exata: `-5` vira `-1.95`
e `-1290` vira `-13.10`. Uma tabela torna o padrão visível de uma vez. **Todo valor negativo está
errado, não um**, o que diz que o bug está na conta e não num caso especial.

## De onde vem a lista de bordas

A lista de casos de borda de um assistente é uma lista do que é comum para aquele tipo de função:
para uma string, vazia, espaços e caracteres fora do ASCII; para um número, zero, negativo, muito
grande; para uma data, o fim do mês, um dia bissexto, um fuso horário. É um checklist, e como todo
checklist é bom nos casos que todo mundo esquece e cego aos que são próprios do seu domínio. Nada
genérico teria sugerido "um cupom no último dia válido". **Acrescente as bordas que a sua
especificação cria**: todo limite, todo teto, toda data que aparece nela, testados no valor e um
passo para cada lado.

Um reembolso é um valor negativo, e é por isso que a loja precisa que `format_price(-5)` esteja
certo. Achar todo o resto que está errado com preços negativos é o trabalho da próxima seção.
