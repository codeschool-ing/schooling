---
title: O primeiro ciclo, rodado de verdade
version: 1
---

**A primeira volta do laço é a mais estranha, porque termina com um código obviamente errado e um
teste que passa mesmo assim.** É o método funcionando como deve. Cada volta depois dela troca um
pouco do errado por algo geral, e cada troca é forçada por um teste em vez de adivinhada.

Crie `~/patterns/tdd` e trabalhe lá:

```sh
mkdir -p ~/patterns/tdd
cd ~/patterns/tdd
```

## Vermelho: um teste para uma função que não existe

A primeira linha da lista é um livro devolvido com três dias de atraso. Antes de qualquer código,
decida o que você gostaria de chamar: uma função `fine` que recebe a data de vencimento e a data de
devolução e responde em centavos. Escreva essa chamada num teste.

```schooling-example
{"language": "python", "file": "test_fines.py", "parts": [
 {"code": "# test_fines.py\nimport unittest\nfrom datetime import date\n\nfrom fines import fine", "note": "O teste importa um módulo que ainda não existe. Dar o nome aqui é a primeira decisão de projeto: a calculadora mora em `fines.py` e a função dela é `fine`."},
 {"code": "\n\nclass FineTest(unittest.TestCase):", "note": "`unittest` está na biblioteca padrão. Um teste é um método de uma classe que herda de `TestCase`."},
 {"code": "    def test_three_days_late_costs_150_cents(self):\n        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 150)", "note": "O nome do método diz o comportamento, então um relatório de falha se lê como uma frase. Ele precisa começar com `test`, o que importa mais do que parece e aparece no fim desta seção."},
 {"code": "\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "Isso deixa o arquivo rodar sozinho com `python3 test_fines.py`. A seção sobre refatoração usa esse recurso."}
]}
```

Rode com `-v`, que dá o nome de cada teste conforme avança:

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_fines.py
test_fines (unittest.loader._FailedTest.test_fines) ... ERROR

======================================================================
ERROR: test_fines (unittest.loader._FailedTest.test_fines)
----------------------------------------------------------------------
ImportError: Failed to import test module: test_fines
Traceback (most recent call last):
  File "/usr/lib/python3.12/unittest/loader.py", line 137, in loadTestsFromName
    module = __import__(module_name)
             ^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/patterns/tdd/test_fines.py", line 5, in <module>
    from fines import fine
ModuleNotFoundError: No module named 'fines'


----------------------------------------------------------------------
Ran 1 test in 0.000s

FAILED (errors=1)
```

Vermelho, e pelo motivo esperado: a última linha do traceback diz que não existe módulo chamado
`fines`. Beck conta isso como um teste falhando. Em Java ou Go seria um erro de compilação, e a
questão é a mesma: o teste descreve algo que o código ainda não sabe fazer.

## Verde: o mínimo de código que passa

Agora escreva `fines.py`, e escreva o mínimo que conseguir:

```python
# fines.py
def fine(due, returned):
    return 150
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_fines.py
test_three_days_late_costs_150_cents (test_fines.FineTest.test_three_days_late_costs_150_cents) ... ok

----------------------------------------------------------------------
Ran 1 test in 0.000s

OK
```

**Sim, uma constante.** Parece piada e já fez três coisas úteis. O teste foi visto falhando e depois
passando, então sabemos que ele roda. A interface ficou fixada: o nome, os dois argumentos nomeados,
a unidade. E a suíte voltou ao verde um minuto depois do começo. O tempo na linha `Ran 1 test` varia
de uma execução para outra e de uma máquina para outra; ignore.

O passo de refatorar ainda tem pouco a fazer. Há uma duplicação, o 150 escrito no teste e no código,
e é o próximo teste da lista que vai tirá-la.

## Um teste que não consegue falhar

Aqui está a palavra faltando que a seção anterior prometeu. Salve isto como `test_typo.py`. O único
teste dele espera uma multa de 999 centavos, o que está errado, e o nome dele não começa com `test`:

```python
# test_typo.py
import unittest
from datetime import date

from fines import fine


class FineTest(unittest.TestCase):
    def three_days_late_costs_150_cents(self):
        self.assertEqual(fine(due=date(2026, 3, 16), returned=date(2026, 3, 19)), 999)
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_typo.py

----------------------------------------------------------------------
Ran 0 tests in 0.000s

NO TESTS RAN
```

O `unittest` só recolhe métodos cujo nome começa com `test`, então não achou nada, não rodou nada e
não imprimiu falha nenhuma. O Python 3.12 pelo menos diz `NO TESTS RAN` e sai com código diferente
de zero; versões mais antigas imprimiam `OK`. **Num arquivo com vinte testes, um método com nome
errado some sem uma palavra**, e a asserção errada dele continua errada enquanto ninguém olhar. Ver
cada teste novo ficar vermelho uma vez é o que pega isso, e custa uma execução.
