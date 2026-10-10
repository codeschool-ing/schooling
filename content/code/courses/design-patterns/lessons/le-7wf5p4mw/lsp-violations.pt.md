---
title: Três jeitos de um filho quebrar uma promessa
version: 1
---

**Uma falha de substituição tem um de três formatos: o filho recusa algo que o pai aceitava, devolve
algo que o pai descartava, ou deixa o objeto chegar a um estado que o pai nunca permitiu.** A seção
anterior mostrou o primeiro. Esta mostra os outros dois, e depois o teste que pega os três antes de
quem chama.

As violações que vale aprender são as silenciosas. `ReferenceBook` levantava uma exceção, o que pelo
menos para o programa na linha errada. As duas abaixo rodam até o fim e imprimem uma resposta
errada, que é o formato que um bug em produção costuma ter.

## Um vencimento que não é posterior

A biblioteca começa a emprestar notebooks para uso dentro do prédio, com devolução no mesmo dia. É
um item, é emprestado, então parece um `Item` com empréstimo de zero dias:

```python
# laptop.py
from items import Item


class Laptop(Item):
    loan_days = 0
```

Nada é sobrescrito e nada levanta exceção. Mas `lend` prometia um vencimento *posterior* ao dia do
empréstimo, e `Laptop` devolve o mesmo dia. Isso é uma **pós-condição enfraquecida**, e quem quebra
é o código escrito confiando nela: a rotina que manda "vence em dois dias" subtraindo dois dias do
vencimento, ou um relatório dos empréstimos em aberto, que conta um item como fora enquanto
`today < due`. O `ReferenceBook` da lição 1 também tinha `loan_days = 0`. Era esta violação,
esperando alguém chamar.

## O quadrado que é um retângulo

O exemplo mais citado é de geometria, porque mostra que um *é um* verdadeiro na matemática pode ser
falso no código. Todo quadrado é um retângulo. Mas um `Rectangle` mutável promete algo a mais:
mudar a largura não mexe na altura.

```schooling-example
{"language": "python", "file": "shapes.py", "parts": [
 {"code": "# shapes.py\nclass Rectangle:\n    def __init__(self, width: int, height: int):\n        self._width = width\n        self._height = height\n\n    @property\n    def width(self) -> int:\n        return self._width\n\n    @width.setter\n    def width(self, value: int) -> None:\n        self._width = value\n\n    @property\n    def height(self) -> int:\n        return self._height\n\n    @height.setter\n    def height(self, value: int) -> None:\n        self._height = value\n\n    def area(self) -> int:\n        return self._width * self._height", "note": "Dois lados que podem ser definidos de forma independente. Essa independência faz parte do que um `Rectangle` é para o código que o usa."},
 {"code": "\n\nclass Square(Rectangle):\n    def __init__(self, side: int):\n        super().__init__(side, side)\n\n    def _set_side(self, value: int) -> None:\n        self._width = self._height = value\n\n    width = property(Rectangle.width.fget, _set_side)\n    height = property(Rectangle.height.fget, _set_side)", "note": "Para continuar quadrado, mudar qualquer lado muda os dois. Dentro da classe isso está correto; é o único jeito de manter a invariante do próprio quadrado."},
 {"code": "\n\ndef widen(board: Rectangle) -> None:\n    height = board.height\n    board.width = 10\n    print(f\"{type(board).__name__:<9} height before {height}, after {board.height}, area {board.area()}\")", "note": "Um código que alarga um quadro de avisos e espera que a altura fique onde está, como todo `Rectangle` prometeu."},
 {"code": "\n\nif __name__ == \"__main__\":\n    widen(Rectangle(4, 3))\n    widen(Square(3))"}
]}
```

```
ana@laptop:~/patterns/solid-1$ python3 shapes.py
Rectangle height before 3, after 3, area 30
Square    height before 3, after 10, area 100
```

O retângulo sai 10 por 3, área 30. O quadrado, entregue à mesma função, sai 10 por 10, área 100:
quem chamou mudou um lado e o outro se mexeu. Nenhuma das classes está errada nos próprios termos.
**O quadrado não consegue manter ao mesmo tempo a própria invariante e a promessa do pai, então ele
não substitui um retângulo mutável.** Um imutável seria diferente: se `Rectangle` não tivesse
setters, um quadrado não quebraria nada, e esse é um dos motivos de a lição 15 preferir valores que
não mudam.

## Um teste escrito para o pai, rodado para cada filho

A ferramenta que pega os três formatos é um **teste de contrato**: as promessas do pai escritas como
asserções uma vez, e rodadas contra cada classe que diz ser o pai. Ele não precisa saber nada dos
filhos além dos nomes.

```python
# test_contract.py
import unittest
from datetime import date

from items import Book, Film, ReferenceBook
from laptop import Laptop


class ItemContract(unittest.TestCase):
    def test_lend_returns_a_later_due_date(self):
        lent_on = date(2026, 3, 2)
        for cls in (Book, Film, ReferenceBook, Laptop):
            with self.subTest(cls.__name__):
                self.assertGreater(cls("any title").lend(lent_on), lent_on)
```

`subTest` roda o corpo uma vez por classe e relata cada falha separadamente, em vez de parar na
primeira:

```
ana@laptop:~/patterns/solid-1$ python3 -m unittest test_contract.py
EF
======================================================================
ERROR: test_lend_returns_a_later_due_date (test_contract.ItemContract.test_lend_returns_a_later_due_date) [ReferenceBook]
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/solid-1/test_contract.py", line 14, in test_lend_returns_a_later_due_date
    self.assertGreater(cls("any title").lend(lent_on), lent_on)
                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ana/patterns/solid-1/items.py", line 26, in lend
    raise ValueError(f"{self.title!r} is for the reading room only")
ValueError: 'any title' is for the reading room only

======================================================================
FAIL: test_lend_returns_a_later_due_date (test_contract.ItemContract.test_lend_returns_a_later_due_date) [Laptop]
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/solid-1/test_contract.py", line 14, in test_lend_returns_a_later_due_date
    self.assertGreater(cls("any title").lend(lent_on), lent_on)
AssertionError: datetime.date(2026, 3, 2) not greater than datetime.date(2026, 3, 2)

----------------------------------------------------------------------
Ran 1 test in 0.001s

FAILED (failures=1, errors=1)
```

Dois filhos passam e dois não, e o relatório diz quais e como. `ReferenceBook` é um **erro**, a
exceção da seção anterior. `Laptop` é uma **falha**: o vencimento voltou igual ao dia do
empréstimo, a pós-condição enfraquecida. O tempo na linha `Ran` depende da sua máquina e vai ser
diferente.

Um teste de contrato é barato de manter: um filho novo é mais um nome na tupla, e um filho que
quebra uma promessa falha no dia em que é escrito. Em bases de código maiores a mesma ideia aparece
como uma classe de teste base que os testes de cada filho herdam, um dos casos em que a herança
serve, como a lição 2 descreveu.

## Consertar a hierarquia, não quem chama

Cada um dos três consertos é uma mudança no que se afirma, nunca um teste em quem chama:

| filho | a promessa quebrada | o conserto |
|---|---|---|
| `ReferenceBook` | pré-condição: recusa emprestar | não é emprestável; não o faça dizer que é |
| `Laptop` | pós-condição: vence no mesmo dia | mudar a promessa do pai para "não anterior", se empréstimos no mesmo dia são reais, e revisar quem chama |
| `Square` | invariante: os lados se mexem juntos | nenhuma herança entre os dois, ou nenhum setter em nenhum deles |

O segundo conserto mostra que o contrato do pai também é uma decisão. Se empréstimos no mesmo dia
fazem parte da biblioteca, a promessa estava errada e é enfraquecida de propósito, com todo código
que a usa relido. O que o princípio proíbe é um filho enfraquecê-la em silêncio.
