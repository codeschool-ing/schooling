---
title: "Testes com fakes: a recompensa"
version: 1
---

**É no teste que a injeção se paga: uma classe que recebe os colaboradores pode receber
colaboradores pequenos e previsíveis, e o teste não precisa de patch, de rede nem de calendário.**
Tudo nesta lição até aqui foi um argumento sobre projeto. Esta seção é a evidência, porque um teste
é o segundo cliente que toda classe tem, e uma classe difícil de testar é difícil pelo mesmo motivo
que vai ser difícil de mudar.

A lição 2 de `testing-cicd` deu nome aos tipos de dublê de teste: dummies, stubs, spies, mocks e
fakes. Esse vocabulário é assumido aqui. O que esta seção acrescenta é como o projeto decide quais
dublês são possíveis.

## Um teste que entrega à tarefa o mundo dela

```schooling-example
{"language": "python", "file": "test_overdue.py", "parts": [
 {"code": "# test_overdue.py\nimport unittest\nfrom datetime import date\n\nfrom overdue import FixedClock, ListedLoans, Loan, OverdueNotices", "note": "O teste importa a tarefa e as duas implementações simples de `overdue.py`. Ele não precisa de nada de `main.py`: a raiz de composição não faz parte do que é testado."},
 {"code": "\n\nclass RecordingNotifier:\n    def __init__(self):\n        self.sent = []\n\n    def send(self, member: str, text: str) -> None:\n        self.sent.append((member, text))", "note": "Um spy, nos termos de `testing-cicd`: um notificador que anota o que pediram para ele mandar, em vez de mandar. São seis linhas e nenhuma biblioteca."},
 {"code": "\n\nclass OverdueNoticesTest(unittest.TestCase):\n    def setUp(self):\n        self.notifier = RecordingNotifier()\n        loans = ListedLoans([\n            Loan(\"Bia\", \"Dom Casmurro\", date(2026, 3, 16)),\n            Loan(\"Caio\", \"Vidas Secas\", date(2026, 3, 20)),\n        ])\n        self.notices = OverdueNotices(loans, self.notifier, FixedClock(date(2026, 3, 20)))", "note": "Todo teste parte do mesmo mundo: dois empréstimos, um dia fixo, um notificador novo. A tarefa não consegue distinguir isso da produção."},
 {"code": "\n    def test_only_late_loans_get_a_notice(self):\n        self.assertEqual(self.notices.send_all(), 1)\n        self.assertEqual([member for member, _ in self.notifier.sent], [\"Bia\"])\n\n    def test_the_fine_is_fifty_cents_a_day(self):\n        self.notices.send_all()\n        self.assertIn(\"fine 200 cents\", self.notifier.sent[0][1])\n\n    def test_due_today_is_not_late(self):\n        self.notices.send_all()\n        self.assertNotIn(\"Caio\", [member for member, _ in self.notifier.sent])\n\n\nif __name__ == \"__main__\":\n    unittest.main()", "note": "Cada teste afirma uma regra da tarefa. O empréstimo de Caio vence no próprio dia, que é o limite que alguém erra."}
]}
```

```
ana@laptop:~/patterns/injection$ python3 -m unittest -v test_overdue.py
test_due_today_is_not_late (test_overdue.OverdueNoticesTest.test_due_today_is_not_late) ... ok
test_only_late_loans_get_a_notice (test_overdue.OverdueNoticesTest.test_only_late_loans_get_a_notice) ... ok
test_the_fine_is_fifty_cents_a_day (test_overdue.OverdueNoticesTest.test_the_fine_is_fifty_cents_a_day) ... ok

----------------------------------------------------------------------
Ran 3 tests in 0.000s

OK
```

O tempo na linha `Ran` muda de uma execução para outra; os três `ok` não mudam. Nada no teste fala
da data de hoje, de servidor de e-mail ou de banco de dados, então ele dá a mesma resposta em
qualquer máquina, em qualquer dia, com o cabo de rede desligado.

## O mesmo teste sem injeção

Volte ao primeiro rascunho da seção do construtor, aquele que chamava `date.today()` e construía o
próprio `SmtpNotifier`. Ele ainda pode ser testado em Python, com `unittest.mock.patch`:

```python
with patch("overdue_draft.date") as fake_date, \
     patch("overdue_draft.SmtpNotifier") as fake_smtp:
    fake_date.today.return_value = date(2026, 3, 20)
    OverdueNotices().send_all()
    fake_smtp.return_value.send.assert_called_once()
```

Funciona, e vale ver do que depende. As strings `"overdue_draft.date"` e
`"overdue_draft.SmtpNotifier"` são os nomes de importação do módulo: renomeie um import, ou mova a
tarefa para outro arquivo, e o patch passa a não substituir nada, sem aviso, enquanto o servidor de
e-mail de verdade é chamado. **Um patch amarra o teste a como o código está escrito; um fake
injetado o amarra só ao que o código precisa.** O Java tem a mesma divisão entre o `@InjectMocks` do
Mockito, numa classe com construtor, e o PowerMock entrando em chamadas estáticas; e o Go, sem patch
nenhum, deixa a injeção como o único caminho.

O `patch` continua sendo uma boa ferramenta para código que não é seu e que você não pode mudar.
Nas suas próprias classes, precisar de patch é um recado sobre o projeto: alguma coisa lá dentro
está construindo um colaborador que devia ter sido entregue.

## O que falsificar, e o que deixar real

Falsifique o que é lento, não determinístico ou fica fora do processo: o relógio, a rede, o servidor
de e-mail, um gateway de pagamento. Deixe real o que é rápido e seu: `Loan` e `ListedLoans` são
reais no teste acima, porque falsificar uma dataclass congelada não testaria nada. Um teste que
falsifica todos os colaboradores só confere que a classe chama métodos numa certa ordem, e quebra a
cada refatoração que preserva o comportamento. A lição 13 inverte a ordem e escreve o teste antes da
classe, e lá os dublês chegam porque um teste pediu por eles.
