---
title: Dublês de teste dentro do ciclo
version: 1
---

**Dublê de teste não é invenção do TDD, e o TDD não exige mocks.** A lição 2 de `testing-cicd`
classificou os tipos, dummy, stub, spy, mock e fake, e esse vocabulário é tomado como sabido aqui. O
que esta seção acrescenta é onde os dublês ficam dentro do laço vermelho-verde-refatorar, porque as
duas tradições do TDD discordam exatamente disso, e a discordância aparece no comportamento da suíte
no dia em que você refatora.

## Duas escolas

O estilo **clássico**, às vezes chamado de Detroit ou Chicago por causa de onde trabalhavam os
primeiros praticantes, é o do próprio Beck. Use objetos reais onde forem baratos, e recorra a um
dublê só para o que é incômodo: o relógio, a rede, o disco. Faça asserções sobre resultados e sobre
estado. A lista `sent` da seção anterior é deste estilo: uma lambda que registra, conferida depois.

O estilo **mockista**, ou escola de Londres, vem de *Growing Object-Oriented Software, Guided by
Tests* (2009), de Steve Freeman e Nat Pryce. Trabalhe de fora para dentro: comece pela borda do
sistema e, quando o objeto testado precisar de um colaborador que ainda não existe, faça um mock
dele. As expectativas do mock viram o projeto da interface desse colaborador, que você então
constrói no próprio ciclo dele. Faça asserções sobre as mensagens enviadas.

As duas funcionam, e as duas produziram sistemas grandes e bem testados. **A troca está no que cada
tipo de teste percebe**: um teste baseado em estado percebe quando a resposta muda, um teste baseado
em interação percebe quando a conversa entre objetos muda, inclusive quando a resposta não mudou.

## Um mock que concorda com qualquer coisa

Testes mockistas carregam um risco específico, e o `unittest.mock` do Python o mostra num arquivo só.
O notificador real da biblioteca ganhou um nome de método melhor na semana passada, `deliver` em vez
de `send`, e `remind` não foi atualizado:

```python
# notify.py
from datetime import date


class Notifier:
    def deliver(self, to: str, text: str) -> None:
        raise NotImplementedError("the real one talks to the mail server")


def remind(loans, today: date, notifier) -> int:
    late = [loan for loan in loans if loan.due < today]
    for loan in late:
        notifier.send(loan.email, f"'{loan.title}' was due on {loan.due}")
    return len(late)
```

Dois testes dele, que diferem num argumento. Ele reaproveita o `Loan` de `reminders.py`, no mesmo
diretório:

```schooling-example
{"language": "python", "file": "test_notify.py", "parts": [
 {"code": "# test_notify.py\nimport unittest\nfrom datetime import date\nfrom unittest.mock import Mock\n\nfrom notify import Notifier, remind\nfrom reminders import Loan\n\nLOANS = [Loan(\"Dom Casmurro\", \"bia@example.org\", date(2026, 3, 16))]\nTEXT = \"'Dom Casmurro' was due on 2026-03-16\"", "note": "Um empréstimo atrasado e a mensagem que ele deveria produzir."},
 {"code": "\n\nclass RemindTest(unittest.TestCase):\n    def test_with_a_bare_mock(self):\n        notifier = Mock()\n        remind(LOANS, date(2026, 3, 20), notifier)\n        notifier.send.assert_called_once_with(\"bia@example.org\", TEXT)", "note": "Um `Mock()` puro inventa qualquer atributo que lhe pedirem. `notifier.send` existe porque `remind` o chamou, e o teste foi escrito para bater com o código."},
 {"code": "\n\n    def test_with_a_mock_that_knows_the_class(self):\n        notifier = Mock(spec=Notifier)\n        remind(LOANS, date(2026, 3, 20), notifier)\n        notifier.deliver.assert_called_once_with(\"bia@example.org\", TEXT)", "note": "`spec=Notifier` faz o mock recusar qualquer atributo que a classe real não tenha."},
 {"code": "\n\nif __name__ == \"__main__\":\n    unittest.main()"}
]}
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_notify.py
test_with_a_bare_mock (test_notify.RemindTest.test_with_a_bare_mock) ... ok
test_with_a_mock_that_knows_the_class (test_notify.RemindTest.test_with_a_mock_that_knows_the_class) ... ERROR

======================================================================
ERROR: test_with_a_mock_that_knows_the_class (test_notify.RemindTest.test_with_a_mock_that_knows_the_class)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_notify.py", line 22, in test_with_a_mock_that_knows_the_class
    remind(LOANS, date(2026, 3, 20), notifier)
  File "/home/ana/patterns/tdd/notify.py", line 13, in remind
    notifier.send(loan.email, f"'{loan.title}' was due on {loan.due}")
    ^^^^^^^^^^^^^
  File "/usr/lib/python3.12/unittest/mock.py", line 658, in __getattr__
    raise AttributeError("Mock object has no attribute %r" % name)
AttributeError: Mock object has no attribute 'send'

----------------------------------------------------------------------
Ran 2 tests in 0.002s

FAILED (errors=1)
```

O mock puro está verde. Em produção, `remind` lançaria `AttributeError` no primeiro empréstimo
atrasado, porque o `Notifier` real não tem `send`. O mock com spec falha com esse mesmo erro, aqui,
na execução dos testes. Agora corrija a palavra em `notify.py`:

```python
# notify.py
from datetime import date


class Notifier:
    def deliver(self, to: str, text: str) -> None:
        raise NotImplementedError("the real one talks to the mail server")


def remind(loans, today: date, notifier) -> int:
    late = [loan for loan in loans if loan.due < today]
    for loan in late:
        notifier.deliver(loan.email, f"'{loan.title}' was due on {loan.due}")
    return len(late)
```

```
ana@laptop:~/patterns/tdd$ python3 -m unittest -v test_notify.py
test_with_a_bare_mock (test_notify.RemindTest.test_with_a_bare_mock) ... FAIL
test_with_a_mock_that_knows_the_class (test_notify.RemindTest.test_with_a_mock_that_knows_the_class) ... ok

======================================================================
FAIL: test_with_a_bare_mock (test_notify.RemindTest.test_with_a_bare_mock)
----------------------------------------------------------------------
Traceback (most recent call last):
  File "/home/ana/patterns/tdd/test_notify.py", line 17, in test_with_a_bare_mock
    notifier.send.assert_called_once_with("bia@example.org", TEXT)
  File "/usr/lib/python3.12/unittest/mock.py", line 955, in assert_called_once_with
    raise AssertionError(msg)
AssertionError: Expected 'send' to be called once. Called 0 times.

----------------------------------------------------------------------
Ran 2 tests in 0.002s

FAILED (failures=1)
```

**O mock puro estava verde enquanto o código estava quebrado e está vermelho agora que funciona.**
Ele nunca testou `remind` contra o notificador; testou `remind` contra uma cópia das próprias
suposições de `remind`. A versão com spec acompanhou a verdade nas duas vezes.

## Regras que mantêm os dublês honestos no ciclo

- Faça dublê só do que tem uma interface sua, ou embrulhe o que não é seu. Fazer mock de `smtplib`
  direto amarra os testes à sequência de chamadas de uma biblioteca; um `Notifier` seu, com um
  método, é uma costura que você controla.
- Dê um spec a todo mock: `Mock(spec=Notifier)`, ou `create_autospec(Notifier)`, que também confere
  os argumentos de cada chamada. O Mockito do Java e as interfaces do Go ganham isso de graça do
  sistema de tipos; mocks em Python e em JavaScript puro não.
- Faça mock de comandos, stub de consultas. Afirmar que `send` foi chamado é conferir um efeito que
  importa a alguém. Afirmar que uma consulta foi chamada duas vezes é conferir como o código
  funciona hoje, e isso quebra numa refatoração inofensiva.
- Quando os dublês são mais numerosos que os objetos reais num teste, a unidade testada
  provavelmente tem colaboradores demais, que é a pressão da seção anterior chegando por outro
  caminho.
