---
title: Um primeiro teste, e o primeiro vermelho
version: 1
---

**O Cine Aurora vai começar a ter cupons.** A primeira frase da Joana sobre eles é curta: *o código PIPOCA tira
R$ 5,00 de um pedido.* O Rafael o constrói com TDD, e a Lia senta ao lado dele com os exemplos. Você pode
acompanhar cada passo no seu próprio laboratório: não precisa de nada além do Python que instalou na aula 1, porque
o executor de testes dele, o `unittest`, vem com o Python.

## O teste

O primeiro teste é a frase transformada num exemplo: um pedido de R$ 36,00 com o código PIPOCA custa R$ 31,00. Os
preços estão em centavos, como em `tickets.py`. Salve isto em `~/aurora` como `test_coupons.py`:

```python
# test_coupons.py
import unittest
from coupons import apply


class Coupons(unittest.TestCase):
    def test_pipoca_takes_five_reais_off(self):
        self.assertEqual(apply("PIPOCA", 3600), 3100)


if __name__ == "__main__":
    unittest.main()
```

Leia de baixo para cima no método. `assertEqual(a, b)` falha se `a` não for `b`. O que ele compara é o resultado de
`apply("PIPOCA", 3600)`, uma função que ainda não existe, com `3100`. O nome do método diz o que o exemplo mostra,
para um relato de falha se ler como uma frase. O `unittest` roda todo método cujo nome começa com `test`.

## Vermelho

Rode todos os testes da pasta com `python -m unittest -v`; o `-v` lista cada teste pelo nome:

```
lia@lab:~/aurora$ python -m unittest -v
test_coupons (unittest.loader._FailedTest.test_coupons) ... ERROR

======================================================================
ERROR: test_coupons (unittest.loader._FailedTest.test_coupons)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_coupons
Traceback (most recent call last):
  File "/usr/lib/python3.12/unittest/loader.py", line 394, in _find_test_path
    module = self._get_module_from_name(name)
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/unittest/loader.py", line 337, in _get_module_from_name
    __import__(name)
  File "/home/lia/aurora/test_coupons.py", line 3, in <module>
    from coupons import apply
ModuleNotFoundError: No module named 'coupons'


----------------------------------------------------------------------
Ran 1 test in 0.000s

FAILED (errors=1)
```

Vermelho, e pelo motivo mais simples: não existe `coupons.py`. O `unittest` relata isso como **ERROR** e não como
**FAIL**: o teste nem conseguiu rodar, em vez de rodar e dar a resposta errada. Ainda é uma falha útil. Mostra que
o executor acha o teste e que ele falha quando o código está faltando, que é a primeira coisa que um teste precisa
conseguir fazer.

## Verde, pelo mínimo de código

Agora o mínimo de código que o deixa verde. Salve isto como `coupons.py`:

```python
# coupons.py
def apply(code, total):
    return 3100
```

Parece trapaça, e de certo modo é. Chama-se **fingir** (*faking it*), e é de propósito: o teste pediu 3100 e
recebeu 3100. Rode os testes de novo:

```
lia@lab:~/aurora$ python -m unittest -v
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

Verde. O valor do fingimento está no que ele expõe. A função ignora os dois argumentos, e um teste só não percebe.
A Lia disse isso na hora: *"então todo código dá cinco reais de desconto, e todo pedido custa trinta e um?"* As
duas coisas estão erradas, e nenhuma está testada. A saída não é escrever o código de verdade de imaginação; é
escrever o próximo exemplo que o fingimento erra.
