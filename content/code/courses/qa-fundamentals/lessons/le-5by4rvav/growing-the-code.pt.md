---
title: Fazendo o código crescer um exemplo de cada vez
version: 1
---

**Cada teste novo é um exemplo que o código atual erra.** Escrevê-lo deixa o código vermelho; a menor mudança que o
deixa verde é a próxima peça da funcionalidade. Dois exemplos que puxam para lados diferentes obrigam o código a
parar de fingir, e isso se chama **triangulação**.

## O segundo exemplo: um código que não existe

A primeira pergunta da Lia foi sobre outros códigos. A resposta da Joana: um código que o cinema não emitiu não muda
nada. Esse é o segundo teste, acrescentado abaixo do primeiro:

```python
# test_coupons.py
import unittest
from coupons import apply


class Coupons(unittest.TestCase):
    def test_pipoca_takes_five_reais_off(self):
        self.assertEqual(apply("PIPOCA", 3600), 3100)

    def test_an_unknown_code_changes_nothing(self):
        self.assertEqual(apply("XYZ", 3600), 3600)


if __name__ == "__main__":
    unittest.main()
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... FAIL
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok

======================================================================
FAIL: test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/lia/aurora/test_coupons.py", line 11, in test_an_unknown_code_changes_nothing
    self.assertEqual(apply("XYZ", 3600), 3600)
AssertionError: 3100 != 3600

----------------------------------------------------------------------
Ran 2 tests in 0.000s

FAILED (failures=1)
```

Leia a falha, porque é aqui que um teste se paga. `3100 != 3600` é o resultado obtido primeiro e o esperado
depois, e a linha de cima nomeia o teste. O fingimento dá cinco reais de desconto a todo código, e agora há um
exemplo dizendo que não deveria. O primeiro teste continua passando. (O `unittest` roda os testes em ordem
alfabética dos nomes, por isso o novo aparece primeiro.)

O mínimo de código que satisfaz os dois:

```python
# coupons.py
def apply(code, total):
    if code == "PIPOCA":
        return total - 500
    return total
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

O fingimento acabou. O total é usado, o código é conferido, e as duas coisas acontecem porque um exemplo as exigiu,
não porque o Rafael adivinhou.

## O terceiro exemplo: como as pessoas digitam

A segunda pergunta da Lia veio da bilheteria, não da regra. A Célia lê os códigos no celular dos clientes, e os
clientes digitam em minúsculas. A resposta da Joana: *o código é o código, maiúsculo ou minúsculo.* Terceiro teste:

```python
# test_coupons.py
import unittest
from coupons import apply


class Coupons(unittest.TestCase):
    def test_pipoca_takes_five_reais_off(self):
        self.assertEqual(apply("PIPOCA", 3600), 3100)

    def test_an_unknown_code_changes_nothing(self):
        self.assertEqual(apply("XYZ", 3600), 3600)

    def test_the_code_is_read_in_any_case(self):
        self.assertEqual(apply("pipoca", 2800), 2300)


if __name__ == "__main__":
    unittest.main()
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... FAIL

======================================================================
FAIL: test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/lia/aurora/test_coupons.py", line 14, in test_the_code_is_read_in_any_case
    self.assertEqual(apply("pipoca", 2800), 2300)
AssertionError: 2800 != 2300

----------------------------------------------------------------------
Ran 3 tests in 0.001s

FAILED (failures=1)
```

Repare que este teste usa um preço de matinê, 2800, e não 3600 de novo. Mudar o total além das letras garante que
o desconto é tirado do total recebido, e não de um número que o código por acaso lembra.

```python
# coupons.py
def apply(code, total):
    if code.upper() == "PIPOCA":
        return total - 500
    return total
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

## De onde vieram os exemplos

Veja quem escreveu o quê. O Rafael escreveu cada linha de código e cada linha de teste. Os *exemplos* do segundo e
do terceiro testes vieram das perguntas da Lia e das respostas da Joana. O TDD deu às perguntas um lugar para
pousar: cada resposta virou um teste no momento em que foi dada, e o código só mudou para satisfazê-la.

Esse é o lugar de quem testa num time de TDD. Não escrever os testes por quem desenvolve, e não testar depois o que
os testes já provam, mas trazer os casos: a borda, o outro valor, o jeito como alguém digita de verdade. Quem faz
TDD sozinho testa o que pensa. Quem faz TDD ao lado de quem testa testa o que os dois pensam, e essa é outra suíte.
