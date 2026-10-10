---
title: Um teste de unidade do desconto
version: 1
---

A função sob teste é a que a versão 1.1 mudou. Na aula 1 ela era uma série de `if`; a aula 9 a
trocou por uma linha só:

```python
def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    return max(10 if member else 0, 15 if tickets >= 5 else 0)
```

Ela recebe três fatos sobre um pedido e devolve uma porcentagem. Não lê formulário, não monta
página e não precisa de servidor, e é isso que faz dela uma **unidade**: algo que pode ser chamado
sozinho, com entradas que o teste escolhe, e cuja resposta pode ser conferida contra o requisito. O
R5 diz que estudante paga meia, membro ganha 10%, cinco ingressos ou mais ganham 15%, e vale o maior
desconto. Cinco chamadas cobrem essa regra, e o arquivo de teste abaixo as faz.

## O arquivo de teste

Salve-o como `test_discount.py`, em `~/boxoffice`, ao lado do `boxoffice.py`. O botão de copiar leva
o arquivo inteiro, sem as notas:

```schooling-example
{"language": "python", "file": "test_discount.py", "parts": [
 {"code": "import unittest\n\nfrom boxoffice import discount\n\n", "note": "`unittest` vem com o Python, então não há nada para instalar. O segundo import tira uma função de dentro do `boxoffice.py`, e é por isso que os dois arquivos ficam no mesmo diretório."},
 {"code": "class DiscountTest(unittest.TestCase):\n", "note": "Uma classe reúne os testes de uma coisa. Cada método dentro dela cujo nome começa com `test_` é um teste, e o executor os encontra por esse prefixo."},
 {"code": "    def test_nobody(self):\n        self.assertEqual(discount(student=False, member=False, tickets=1), 0)\n", "note": "Um teste é uma linha da tabela de decisão da aula 5: as condições entram como argumentos, e `assertEqual` compara o que voltou com o que o R5 diz. Ninguém especial, um ingresso: 0% de desconto."},
 {"code": "    def test_member(self):\n        self.assertEqual(discount(student=False, member=True, tickets=2), 10)\n\n    def test_five_tickets(self):\n        self.assertEqual(discount(student=False, member=False, tickets=5), 15)\n\n    def test_member_and_five(self):\n        self.assertEqual(discount(student=False, member=True, tickets=5), 15)\n", "note": "Um membro, um grupo, e um membro com um grupo. O terceiro é a regra de que descontos não se somam, e é a linha que a aula 5 achou quebrada: a versão 1.0 devolvia 25 aqui."},
 {"code": "    def test_student(self):\n        self.assertEqual(discount(student=True, member=False, tickets=1), 50)", "note": "Estudante paga meia. É a linha que a versão 1.1 quebrou, e a única que falha logo abaixo."}
]}
```

Leia-o como uma tabela, e não como um programa. Cada método `test_` é uma linha: os fatos à
esquerda, a porcentagem esperada à direita. **É a tabela de decisão do R5 da aula 5, escrita de um
jeito que uma máquina consegue rodar** toda vez que o código muda, o que uma pessoa não tem como
bancar à mão.

O executor de testes do próprio Python é o `unittest`. Quando roda sem nenhum arquivo nomeado, ele procura no diretório atual arquivos
chamados `test_*.py` e roda todos os testes que houver neles. O `-v` imprime uma linha por teste em
vez de um ponto. No Windows o comando começa com `py` ou `python` em vez de `python3`, como na aula
1.

## Rodando na 1.1

```
ana@laptop:~/boxoffice$ python3 -m unittest -v
test_five_tickets (test_discount.DiscountTest.test_five_tickets) ... ok
test_member (test_discount.DiscountTest.test_member) ... ok
test_member_and_five (test_discount.DiscountTest.test_member_and_five) ... ok
test_nobody (test_discount.DiscountTest.test_nobody) ... ok
test_student (test_discount.DiscountTest.test_student) ... FAIL

======================================================================
FAIL: test_student (test_discount.DiscountTest.test_student)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/boxoffice/test_discount.py", line 21, in test_student
    self.assertEqual(discount(student=True, member=False, tickets=1), 50)
    ~~~~~~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
AssertionError: 0 != 50

----------------------------------------------------------------------
Ran 5 tests in 0.001s

FAILED (failures=1)
```

As cinco primeiras linhas são os veredictos, em ordem alfabética do nome dos testes, que é a ordem
que o `unittest` usa. Quatro dizem `ok`. Uma diz `FAIL`, e o bloco abaixo dela explica:

- que teste: `test_student`;
- que linha: a linha 21 de `test_discount.py`, o `assertEqual` de um estudante com um ingresso;
- o que voltou e o que se esperava: `AssertionError: 0 != 50`. O valor da esquerda é o que
  `discount` devolveu, o da direita é o que o teste pediu.

As duas últimas linhas são o resumo: cinco testes rodaram, e a rodada falhou com uma falha. O código
de saída do comando também não é zero, e é assim que um servidor de build sabe que deve parar.

## A regressão, vista de baixo

**Este é o defeito que a aula 10 achou**, e vale comparar as duas visões. A aula 10 reservou como
estudante pela aplicação e viu um total que não era meia: um sintoma numa tela, e um relatório de
defeito com passos, um total e um total esperado. O teste de unidade vê a causa. Perguntaram a
`discount` sobre um estudante e ela respondeu 0, e com a função na tela, logo acima, o motivo fica
claro: a linha nova nunca menciona `student`. O argumento é recebido e ignorado.

Um desenvolvedor que recebesse as duas coisas corrigiria a função, rodaria este arquivo de novo e
veria cinco `ok` numa fração de segundo. Esse é o valor prático de um teste de unidade para um
testador: **o mesmo defeito custa um minuto para confirmar nesta camada e vários minutos na sua**, e
por isso, quando um teste de unidade segura uma regra, a rodada manual pode gastar o tempo em
outra coisa.

O mesmo arquivo teria falhado de outro jeito na versão 1.0. Lá, `discount` somava os 10% do membro
aos 15% do grupo e devolvia 25, então `test_member_and_five` teria falhado com `25 != 15`: o defeito
que a aula 5 achou com a tabela de decisão. Um arquivo, duas versões, duas linhas diferentes
falhando. Isso é uma suíte de regressão no seu menor tamanho.

## O que ele não consegue ver

Todos esses cinco testes podem passar enquanto um cliente paga o preço errado. O teste chama
`discount` com `student=True`, mas nada aqui confere que o formulário de reserva envia a caixa de
estudante, que `book` a lê pelo nome que o formulário usa, ou que o total na página do pedido é
calculado a partir da porcentagem que voltou. Isso são emendas entre pedaços, e **um teste de
unidade para na borda da sua unidade, de propósito**. A seção 04 desta aula sobe uma camada e testa
através delas.
