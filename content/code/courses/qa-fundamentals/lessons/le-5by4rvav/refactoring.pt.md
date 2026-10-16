---
title: Refatorar no verde, e mais um vermelho
version: 1
---

**Refatorar é mudar a forma do código sem mudar o que ele faz, e os testes são o que torna isso seguro.** Com três
testes verdes, o Rafael pode reescrever `apply` como quiser; se a reescrita mudar um comportamento que um exemplo
cobre, um teste fica vermelho na hora.

## A refatoração

A Joana já disse que um segundo cupom vem aí. Um `if` por código cresceria numa lista que ninguém consegue ler,
então o Rafael passa os códigos para uma tabela e deixa a função procurar neles:

```python
# coupons.py
COUPONS = {"PIPOCA": 500}


def apply(code, total):
    off = COUPONS.get(code.upper(), 0)
    return total - off
```

`COUPONS.get(chave, 0)` dá o desconto de um código conhecido e 0 para qualquer outro, o que cobre o código
desconhecido sem um `if`. Nada novo é prometido, então nenhum teste novo é escrito. Os antigos são rodados:

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

Continua verde, três de três. Essa linha é toda a segurança de uma refatoração, e ela só é tão larga quanto os
exemplos. Se nenhum teste cobrisse códigos em minúsculas, essa reescrita poderia ter perdido o `.upper()` e todos os
testes continuariam passando.

## Mais um vermelho: o que a Célia colou

Uma semana de uso na bilheteria produziu o quarto exemplo. A Célia copia os códigos das mensagens do cinema e cola,
e às vezes a colagem traz um espaço junto. `" PIPOCA "` com espaços não está na tabela, então o cliente pagou o preço
cheio. A Lia relatou como defeito, e o primeiro movimento do Rafael, antes de tocar no código, foi transformar o
relato num teste:

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

    def test_spaces_around_the_code_are_ignored(self):
        self.assertEqual(apply(" PIPOCA ", 3600), 3100)


if __name__ == "__main__":
    unittest.main()
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_spaces_around_the_code_are_ignored (test_coupons.Coupons.test_spaces_around_the_code_are_ignored) ... FAIL
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... ok

======================================================================
FAIL: test_spaces_around_the_code_are_ignored (test_coupons.Coupons.test_spaces_around_the_code_are_ignored)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/lia/aurora/test_coupons.py", line 17, in test_spaces_around_the_code_are_ignored
    self.assertEqual(apply(" PIPOCA ", 3600), 3100)
AssertionError: 3600 != 3100

----------------------------------------------------------------------
Ran 4 tests in 0.000s

FAILED (failures=1)
```

Este é o hábito do TDD que vale levar até para times que não o praticam: **um defeito é reproduzido como um teste
que falha antes de ser corrigido.** A execução vermelha prova que o teste pega o defeito; a verde, depois da
correção, prova que a correção funciona; e o teste fica, para o defeito não poder voltar sem ninguém perceber. São
os passos de reprodução da aula 4, escritos para uma máquina repetir todo dia.

```python
# coupons.py
COUPONS = {"PIPOCA": 500}


def apply(code, total):
    off = COUPONS.get(code.strip().upper(), 0)
    return total - off
```

```
lia@lab:~/aurora$ python -m unittest -v
test_an_unknown_code_changes_nothing (test_coupons.Coupons.test_an_unknown_code_changes_nothing) ... ok
test_pipoca_takes_five_reais_off (test_coupons.Coupons.test_pipoca_takes_five_reais_off) ... ok
test_spaces_around_the_code_are_ignored (test_coupons.Coupons.test_spaces_around_the_code_are_ignored) ... ok
test_the_code_is_read_in_any_case (test_coupons.Coupons.test_the_code_is_read_in_any_case) ... ok

----------------------------------------------------------------------
Ran 4 tests in 0.000s

OK
```

## O que os quatro testes não dizem

Quatro testes verdes, e a Lia ainda tem perguntas que nenhum deles responde. Dois cupons podem ser usados num
pedido? O PIPOCA se combina com o desconto de quarta, a pergunta do planejamento da aula 12? Um total pode ficar
abaixo de zero? Os R$ 5,00 saem de cada ingresso ou do pedido? A suíte não consegue levantar essas perguntas,
porque um teste só existe depois que alguém perguntou. **Uma suíte de TDD verde é um registro das perguntas que
foram feitas, não uma prova de que eram as certas.** Fazer as outras continua sendo trabalho de uma pessoa, e as
duas próximas aulas tratam de fazê-las cedo, numa forma que todos conseguem ler.
