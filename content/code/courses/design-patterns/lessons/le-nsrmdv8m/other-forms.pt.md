---
title: Setters, métodos e funções simples
version: 1
---

**Uma dependência também pode chegar depois da construção, a cada chamada ou como argumento de
função, e cada uma dessas formas tem um caso em que vence o construtor.** O erro comum é tratá-las
como alternativas equivalentes e escolher por gosto. Elas não são equivalentes: cada uma muda o
momento em que a dependência chega e, com ele, o momento em que a falta dela é percebida.

O programa abaixo usa o `overdue.py` da seção anterior para `Loan` e `PrintNotifier`, então
mantenha-o no mesmo diretório.

```schooling-example
{"language": "python", "file": "forms.py", "parts": [
 {"code": "# forms.py\nfrom datetime import date\nfrom functools import partial\n\nfrom overdue import Loan, PrintNotifier", "note": "Só o empréstimo e o notificador que imprime vêm do arquivo anterior. Cada forma abaixo ocupa poucas linhas."},
 {"code": "\n\nclass Reminder:\n    notifier = None  # set after construction\n\n    def remind(self, loan: Loan) -> None:\n        self.notifier.send(loan.member, f\"'{loan.title}' is due on {loan.due}\")", "note": "Isto é injeção por setter: o objeto nasce vazio e recebe o notificador depois, pela atribuição de um atributo. Entre os dois passos ele existe e está quebrado."},
 {"code": "\n\nclass Receipt:\n    def issue(self, loan: Loan, notifier) -> None:\n        notifier.send(loan.member, f\"you borrowed '{loan.title}' until {loan.due}\")", "note": "Isto é injeção por método. O recibo não guarda notificador nenhum; cada chamada diz qual usar. O balcão pode imprimir um recibo e mandar o próximo por e-mail."},
 {"code": "\n\ndef fine_for(loan: Loan, today: date, daily: int = 50) -> int:\n    return max((today - loan.due).days, 0) * daily", "note": "E isto é um parâmetro de função. Em Python, a menor injeção possível é um argumento. O dia é passado de fora, então a função não tem relógio para trocar."},
 {"code": "\n\nfine_on_the_20th = partial(fine_for, today=date(2026, 3, 20))", "note": "`partial` fixa alguns argumentos de antemão e devolve uma função nova. É a versão em forma de função de um construtor que guarda os colaboradores."},
 {"code": "\n\nif __name__ == \"__main__\":\n    loan = Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16))\n    try:\n        Reminder().remind(loan)\n    except AttributeError as err:\n        print(\"forgot the setter:\", err)\n    reminder = Reminder()\n    reminder.notifier = PrintNotifier()\n    reminder.remind(loan)\n    Receipt().issue(loan, PrintNotifier())\n    print(\"fine:\", fine_for(loan, date(2026, 3, 20)))\n    print(\"fine:\", fine_on_the_20th(loan))", "note": "A primeira chamada mostra quanto custa a injeção por setter quando alguém esquece o segundo passo: o erro chega no primeiro uso, longe da linha que devia ter feito a atribuição."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 forms.py
forgot the setter: 'NoneType' object has no attribute 'send'
to Bia: 'Dom Casmurro' is due on 2026-03-16
to Bia: you borrowed 'Dom Casmurro' until 2026-03-16
fine: 200
fine: 200
```

A primeira linha resume todo o argumento contra setters. `Reminder()` funcionou, e o objeto parecia
bom até ser usado. A mensagem do Python fala de `NoneType` e de `send`, e não diz nada sobre
`Reminder` nem sobre a atribuição que nunca aconteceu.

## Quando cada uma serve

| forma | a dependência chega | a falta é percebida | serve quando |
|---|---|---|---|
| construtor | uma vez, quando o objeto é construído | na construção | o objeto não funciona sem ela: o padrão |
| setter | a qualquer momento depois da construção | no primeiro uso | ela é opcional e tem um padrão razoável, ou um framework constrói o objeto por você |
| método | a cada chamada | naquela chamada | ela muda de uma chamada para outra, como o canal de um recibo |
| parâmetro de função | a cada chamada, ou fixada por `partial` | naquela chamada | o código é uma função e não um objeto |

**Prefira a forma que faz a falta de uma dependência falhar mais cedo.** Essa ordem é a tabela lida
de cima para baixo, com o parâmetro de função ao lado do construtor e não abaixo do setter: o Python
confere os argumentos no instante em que a função é chamada.

A injeção por setter tem um uso respeitável. Uma configuração com valor padrão, digamos um logger
que não escreve em lugar nenhum até alguém definir um, é um setter que não tem como ser esquecido de
um jeito que importe. Alguns frameworks também constroem os objetos sozinhos e só conseguem
preenchê-los depois; código Java antigo, escrito para JavaBeans, está cheio de setters por esse
motivo. No código que você mesmo constrói, um setter para algo sem o qual o objeto não funciona é um
argumento de construtor que perdeu a garantia.

## Funções já são injetáveis

Quem vem do Java às vezes cria uma classe com um método e um construtor só para injetar um relógio.
Em Python, Go, JavaScript e TypeScript uma função é um valor, então uma função que recebe `today`
como argumento já recebeu a sua dependência. **Um argumento de função é injeção de dependência sem
cerimônia nenhuma**, e `partial`, uma closure ou uma arrow function em TypeScript fazem o que um
construtor faz quando o mesmo valor é passado toda vez.

A classe merece o lugar quando várias funções compartilham os mesmos colaboradores:
`OverdueNotices` passaria o repositório, o notificador e o relógio para cada função auxiliar que
tivesse. É aí que guardá-los em campos dá menos ruído do que passá-los de mão em mão, e a lição 15
volta à mesma escolha pelo lado funcional.
