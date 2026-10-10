---
title: "MVP: uma view fina demais para precisar de teste"
version: 1
---

**O model-view-presenter tira da view toda decisão sobre o que a tela mostra e a passa para um
presenter, de modo que na view não sobra nada que valha a pena testar.** A view fica passiva: ela
repassa ao presenter o que a pessoa fez e mostra o que o presenter manda, com as strings já
formatadas. O presenter fala com a view por uma interface, o que quer dizer que um teste pode lhe
entregar uma view falsa e ler de volta cada palavra que a tela teria mostrado.

O nome vem da Taligent, uma empreitada conjunta da IBM e da Apple no começo dos anos noventa, e a
forma usada aqui é a que Martin Fowler chamou de *passive view* em 2006. A imagem a abandonar é "MVP
é MVC com o controller renomeado". As setas mudam: no MVC a view lia o modelo diretamente, e no MVP
**a view nunca vê o modelo**.

```schooling-example
{"language": "python", "file": "mvp.py", "parts": [
 {"code": "# mvp.py\nfrom datetime import date\nfrom typing import Protocol\nfrom desk_model import Desk", "note": "O mesmo modelo de novo."},
 {"code": "\n\nclass DeskView(Protocol):\n    def show_shelf(self, lines: list[str]) -> None: ...\n    def show_message(self, text: str, alarm: bool = False) -> None: ...", "note": "A view é descrita pelo que o presenter pode pedir a ela: mostre estas linhas, mostre esta mensagem, dispare o alarme ou não. Nada no protocolo menciona balcão, empréstimo ou data."},
 {"code": "\n\ndef money(cents: int) -> str:\n    return f\"R$ {cents // 100},{cents % 100:02d}\"", "note": "Lógica de apresentação: 150 centavos são `R$ 1,50` neste balcão. É uma função simples, então se testa chamando."},
 {"code": "\n\nclass DeskPresenter:\n    def __init__(self, desk: Desk, view: DeskView, today: date):\n        self.desk, self.view, self.today = desk, view, today\n\n    def start(self) -> None:\n        self._refresh()", "note": "O presenter guarda o modelo e a view, e a data da sessão, como o controller guardava."},
 {"code": "\n    def on_lend(self, code: str, member: str) -> None:\n        try:\n            loan = self.desk.lend(code, member, self.today)\n        except ValueError as err:\n            self.view.show_message(str(err), alarm=True)\n            return\n        self.view.show_message(f\"{code} lent to {member}, due {loan.due:%d/%m}\")\n        self._refresh()", "note": "A view chama isto quando alguém pede um empréstimo. O presenter chama o modelo e depois decide cada palavra que a pessoa vê, inclusive a data no formato dia/mês."},
 {"code": "\n    def on_return(self, code: str) -> None:\n        try:\n            fine = self.desk.give_back(code, self.today)\n        except ValueError as err:\n            self.view.show_message(str(err), alarm=True)\n            return\n        if fine:\n            self.view.show_message(f\"{code} is back. Fine: {money(fine)}\", alarm=True)\n        else:\n            self.view.show_message(f\"{code} is back, on time\")\n        self._refresh()", "note": "Se uma devolução é alarme ou não é decidido aqui. A view só fica sabendo que deve parecer alarmante; como fazer isso é a única coisa que sobra para ela."},
 {"code": "\n    def _refresh(self) -> None:\n        lines = [f\"{c}  on the shelf\" for c in sorted(self.desk.on_shelf)]\n        lines += [f\"{l.code}  {l.member}, due {l.due:%d/%m}\" for l in self.desk.loans.values()]\n        self.view.show_shelf(sorted(lines))", "note": "O presenter monta a estante como linhas prontas e as empurra. A view não ordena, não conta e não formata nada."},
 {"code": "\n\nclass ConsoleView:\n    def show_shelf(self, lines: list[str]) -> None:\n        for line in lines:\n            print(\"   \", line)\n\n    def show_message(self, text: str, alarm: bool = False) -> None:\n        print(\"!!\" if alarm else \"--\", text)", "note": "A view de verdade é tão fina que não há nada nela para dar errado: ela põe strings na tela e marca alarmes com `!!`. Uma janela ou uma página web implementaria os mesmos dois métodos."},
 {"code": "\n\nif __name__ == \"__main__\":\n    desk = Desk([\"B1\", \"B2\", \"B3\"], limit=2)\n    presenter = DeskPresenter(desk, ConsoleView(), date(2026, 3, 2))\n    presenter.start()\n    presenter.on_lend(\"B2\", \"bia\")\n    presenter.today = date(2026, 3, 20)\n    presenter.on_return(\"B2\")", "note": "Aqui o bloco principal faz o papel da pessoa no balcão, chamando direto os métodos de evento do presenter."}
]}
```

```
ana@laptop:~/patterns/presentation$ python3 mvp.py
    B1  on the shelf
    B2  on the shelf
    B3  on the shelf
-- B2 lent to bia, due 16/03
    B1  on the shelf
    B2  bia, due 16/03
    B3  on the shelf
!! B2 is back. Fine: R$ 2,00
    B1  on the shelf
    B2  on the shelf
    B3  on the shelf
```

A Bia pega o B2 em 2 de março, com vencimento no dia 16, e o devolve no dia 20: quatro dias de
atraso, 200 centavos, que o presenter transforma em `R$ 2,00` e marca como alarme. Cada uma dessas
decisões, o `16/03`, a vírgula antes dos centavos, o `!!`, foi tomada por `DeskPresenter`, e
`ConsoleView` não tomou nenhuma.

## O teste que não precisa de tela

Esse é o retorno. O presenter só conhece a view por dois métodos, então um teste pode lhe dar
qualquer objeto com esses dois métodos. Este anota o que lhe pediram para mostrar:

```python
# test_presenter.py
import unittest
from datetime import date
from desk_model import Desk
from mvp import DeskPresenter


class FakeView:
    def __init__(self):
        self.shelf: list[str] = []
        self.messages: list[tuple[str, bool]] = []

    def show_shelf(self, lines):
        self.shelf = lines

    def show_message(self, text, alarm=False):
        self.messages.append((text, alarm))


class PresenterTest(unittest.TestCase):
    def setUp(self):
        self.view = FakeView()
        self.desk = Desk(["B1", "B2", "B3"], limit=2)
        self.presenter = DeskPresenter(self.desk, self.view, date(2026, 3, 2))

    def test_a_late_return_shows_the_fine_in_reais(self):
        self.presenter.on_lend("B1", "bia")
        self.presenter.today = date(2026, 3, 19)
        self.presenter.on_return("B1")
        self.assertEqual(self.view.messages[-1], ("B1 is back. Fine: R$ 1,50", True))

    def test_a_refusal_raises_the_alarm_and_leaves_the_shelf_alone(self):
        self.presenter.on_lend("B1", "bia")
        self.presenter.on_lend("B2", "bia")
        before = self.view.shelf
        self.presenter.on_lend("B3", "bia")
        self.assertEqual(self.view.messages[-1], ("bia already has 2 loans", True))
        self.assertIs(self.view.shelf, before)


if __name__ == "__main__":
    unittest.main()
```

```
ana@laptop:~/patterns/presentation$ python3 -m unittest -v test_presenter.py
test_a_late_return_shows_the_fine_in_reais (test_presenter.PresenterTest.test_a_late_return_shows_the_fine_in_reais) ... ok
test_a_refusal_raises_the_alarm_and_leaves_the_shelf_alone (test_presenter.PresenterTest.test_a_refusal_raises_the_alarm_and_leaves_the_shelf_alone) ... ok

----------------------------------------------------------------------
Ran 2 tests in 0.000s

OK
```

O tempo na linha `Ran 2 tests` muda de uma execução para outra; o resto não. O primeiro teste confere
uma multa de três dias, 150 centavos, do jeito que vai aparecer na tela, `R$ 1,50`, e que ela é um
alarme. O segundo confere que uma recusa dispara o alarme e deixa a estante exatamente como estava:
`assertIs` afirma que é o mesmíssimo objeto lista, então o presenter nem chegou a redesenhá-la.

**`FakeView` é um dublê de teste do tipo que a lição 2 de `testing-cicd` chama de spy**: ele grava as
chamadas para o teste poder conferi-las depois. Compare com o que testar o mesmo comportamento
exigiria em `mvc.py`, onde a linha da estante é formatada dentro de `ShelfView.render` e impressa:
capturar a saída padrão e comparar texto. No MVP, o único código que um teste não alcança é
`ConsoleView`, e nele não há nada além de `print`.

## O que custa

**A interface da view ganha um método para cada coisa que a tela pode mostrar.** Dois métodos são
fáceis. Um formulário de verdade tem dezenas de campos, cada um com um valor, um estado de
habilitado e uma mensagem de erro, e o protocolo vira `show_member_name`, `enable_lend_button`,
`show_code_error` e o resto, cada um implementado uma vez na view real e outra na falsa. Esse
código repetitivo é a principal queixa contra o MVP, e é o que o MVVM, a próxima seção, elimina com
data binding.

Há uma segunda variante, mais branda, que Fowler chamou de *supervising controller*, em que a view
pode ligar campos simples ao modelo por conta própria e o presenter cuida só da lógica complicada.
Ela troca um pouco de testabilidade por menos código. A forma passiva daqui é a que mostra a ideia
com mais clareza.

## Na sua linguagem

O MVP não tem suporte embutido em lugar nenhum, o que faz parte do seu apelo: são três classes
comuns e uma interface. Em **Java** ele foi o jeito padrão de escrever telas Android antes de o
Google lançar o `ViewModel` em 2017, e aplicações GWT também o usavam; a interface da view é uma
`interface` Java que uma `Activity` implementa. Em **TypeScript** a view é uma `interface` e um
componente a implementa. Em **Go**, que raramente desenha telas, a mesma forma aparece em programas
de terminal: um presenter escrevendo num `io.Writer` através de uma interface pequena é MVP sem o
nome.
