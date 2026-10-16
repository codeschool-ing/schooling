---
title: "Injeção pelo construtor: peça o que precisa"
version: 1
---

**Injeção pelo construtor quer dizer que uma classe recebe cada objeto de que depende como
argumento do construtor, e não constrói nenhum deles.** A técnica inteira é essa. Ela não precisa
de biblioteca, de decorador nem de framework, o que surpreende quem conheceu o termo ao lado do
Spring ou do Angular e concluiu que era algo que essas ferramentas fazem. As ferramentas
automatizam; a ideia é uma lista de parâmetros.

Comece pela versão em que a maior parte do código nasce. A biblioteca manda um aviso para cada
empréstimo atrasado, e o primeiro rascunho dessa tarefa vai buscar sozinho tudo o que precisa:

```python
class OverdueNotices:
    def send_all(self) -> int:
        today = date.today()
        notifier = SmtpNotifier("smtp.example.org")
        loans = LoanTable(sqlite3.connect("library.db"))
        for loan in loans.open_loans():
            ...
```

Três decisões estão enterradas nesse método: que dia é hoje, como os membros são avisados e onde
ficam os empréstimos. Nenhuma delas é assunto da tarefa, e cada uma deixa a classe mais difícil de
usar. Não dá para rodá-la contra um banco de testes, não dá para ver o que ela mandaria em 20 de
março sem esperar até 20 de março, e toda execução conversa com um servidor de e-mail. A classe
fica presa aos colaboradores pelo `new` ou, em Python, pela chamada à classe.

## A mesma tarefa, recebendo os colaboradores

```schooling-example
{"language": "python", "file": "overdue.py", "parts": [
 {"code": "# overdue.py\nfrom dataclasses import dataclass\nfrom datetime import date\nfrom typing import Protocol\n\n\n@dataclass(frozen=True)\nclass Loan:\n    member: str\n    title: str\n    due: date", "note": "Aqui um empréstimo carrega só o que esta tarefa lê. Ele é congelado, então nada que a tarefa faça consegue alterá-lo."},
 {"code": "\n\nclass LoanStore(Protocol):\n    def open_loans(self) -> list[Loan]: ...\n\n\nclass Notifier(Protocol):\n    def send(self, member: str, text: str) -> None: ...\n\n\nclass Clock(Protocol):\n    def today(self) -> date: ...", "note": "Três protocolos, um para cada decisão que o primeiro rascunho enterrou. O relógio é um deles: \"que dia é hoje\" é uma dependência como outra qualquer, e a mais esquecida."},
 {"code": "\n\nclass OverdueNotices:\n    DAILY_FINE = 50  # cents\n\n    def __init__(self, loans: LoanStore, notifier: Notifier, clock: Clock):\n        self._loans = loans\n        self._notifier = notifier\n        self._clock = clock", "note": "O construtor é a injeção. Ele guarda o que recebeu e não faz mais nada: nenhuma conexão aberta, nenhum arquivo lido."},
 {"code": "\n    def send_all(self) -> int:\n        today = self._clock.today()\n        sent = 0\n        for loan in self._loans.open_loans():\n            late = (today - loan.due).days\n            if late > 0:\n                fine = late * self.DAILY_FINE\n                self._notifier.send(\n                    loan.member, f\"'{loan.title}' is {late} days late, fine {fine} cents\")\n                sent += 1\n        return sent", "note": "A tarefa agora se lê como a regra e nada além: empréstimos atrasados recebem um aviso com a multa em centavos."},
 {"code": "\n\nclass ListedLoans:\n    def __init__(self, loans: list[Loan]):\n        self._loans = list(loans)\n\n    def open_loans(self) -> list[Loan]:\n        return list(self._loans)\n\n\nclass FixedClock:\n    def __init__(self, day: date):\n        self._day = day\n\n    def today(self) -> date:\n        return self._day\n\n\nclass PrintNotifier:\n    def send(self, member: str, text: str) -> None:\n        print(f\"to {member}: {text}\")", "note": "Três implementações pequenas, uma por protocolo. Nenhuma delas sabe que `OverdueNotices` existe."},
 {"code": "\n\nif __name__ == \"__main__\":\n    loans = ListedLoans([\n        Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16)),\n        Loan(\"Caio\", \"Vidas Secas\", date(2026, 3, 25)),\n        Loan(\"Duda\", \"Central do Brasil\", date(2026, 3, 11)),\n    ])\n    notices = OverdueNotices(loans, PrintNotifier(), FixedClock(date(2026, 3, 20)))\n    print(\"sent:\", notices.send_all())", "note": "Quem constrói a tarefa escolhe os colaboradores. Aqui é o bloco no fim do arquivo, e ele escolhe um dia fixo para a saída ser a mesma toda vez que rodar."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 overdue.py
to Bia: 'Dom Casmurro' is 4 days late, fine 200 cents
to Duda: 'Central do Brasil' is 9 days late, fine 450 cents
sent: 2
```

O livro de Bia vencia em 16 de março, então no dia 20 ele está quatro dias atrasado e custa 200
centavos. O de Caio ainda não venceu. O filme de Duda vencia no dia 11: nove dias e 450 centavos. A
tarefa não decidiu essa data: ela foi informada.

## O que o construtor compra

**A lista de parâmetros do construtor passa a ser uma lista completa e honesta do que a classe
precisa.** Quem lê vê três colaboradores sem abrir o método. Quem chama não consegue esquecer um,
porque o Python se recusa a construir `OverdueNotices` com dois argumentos. E o objeto pode ser
usado no instante em que existe: não há um estado meio construído em que ele tem um repositório mas
não tem notificador.

Essa última propriedade é o motivo de a injeção pelo construtor ser a forma padrão, e as formas da
próxima seção são para os casos em que ela não serve. Ela também dá um sinal de alerta de graça. Um
construtor que recebe sete colaboradores não é um problema de injeção: é uma classe fazendo sete
coisas, e o princípio da responsabilidade única da lição 3 é a conversa a ter sobre ela.

## O mesmo movimento na sua linguagem

| | como a tarefa pede o relógio |
|---|---|
| Python | `clock: Clock`, um protocolo; ou uma função simples, como mostra a próxima seção |
| Java | `java.time.Clock` no construtor, com `Clock.fixed(...)` nos testes |
| Go | um campo `now func() time.Time` preenchido por uma função `NewOverdueNotices(...)` |
| TypeScript | `constructor(private readonly clock: Clock)` com uma interface `Clock` |

A biblioteca padrão do Java traz a abstração de relógio porque essa necessidade é muito comum: todo
`LocalDate.now()` tem uma sobrecarga `LocalDate.now(clock)`. O Go não tem construtores, então a
convenção é uma função chamada `New…` que recebe as dependências e devolve a struct; a ideia é a
mesma.
