---
title: Mock
version: 2
---

Um **mock** é um dublê que carrega expectativas sobre como vai ser chamado, e as confere. Em Python
a palavra também dá nome à biblioteca, `unittest.mock`, cujo objeto `Mock` é ao mesmo tempo stub,
spy e mock: responde qualquer chamada, registra toda chamada e oferece métodos de verificação.

Dois testes do `shipquote` usam um. O primeiro afirma que algo **não** aconteceu:

```python
def test_a_free_order_never_asks_the_carrier():
    carrier = mock.Mock()
    assert price(carrier, "01310-100", 1200, 19900) == 0
    carrier.rate.assert_not_called()
```

Um pedido de R$ 199,00 tem frete grátis, então `price` não deveria gastar uma chamada paga à API
perguntando à transportadora. O valor devolvido sozinho não diz isso: volta 0 de qualquer jeito. Só
um dublê que registra chamadas diz, e `assert_not_called` é a conferência.

O segundo afirma que algo aconteceu exatamente uma vez, com exatamente estes argumentos. Ele
precisa do mailer real, que o projeto não tinha até agora: desde a aula 1, `place` manda o e-mail
por qualquer `mailer` que recebeu. O real fala SMTP. Salve como `shipquote/mailer.py`:

```python
"""E-mail through an SMTP server."""
import smtplib
from email.message import EmailMessage


class SmtpMailer:
    def __init__(self, host, port=25):
        self.host = host
        self.port = port

    def send(self, to, subject, body):
        msg = EmailMessage()
        msg["From"] = "pedidos@livraria.example"
        msg["To"] = to
        msg["Subject"] = subject
        msg.set_content(body)
        with smtplib.SMTP(self.host, self.port, timeout=5) as smtp:
            smtp.send_message(msg)
```

e faça o commit, `git add shipquote/mailer.py && git commit -m "Send e-mail over SMTP"`, porque o
experimento abaixo o altera e é o git que o põe de volta. O teste:

```python
def test_placing_an_order_sends_exactly_one_confirmation():
    mailer = mock.create_autospec(SmtpMailer, instance=True)
    order_id = place(FakeOrders(), mailer, "bia@example.org", 8990)
    mailer.send.assert_called_once_with(
        to="bia@example.org", subject=f"Order {order_id} confirmed",
        body="Total: R$ 89,90")
```

Um e-mail de confirmação, para o endereço certo, com o assunto e o total certos. **A chamada é o
comportamento aqui**: `place` devolve um id, e o e-mail é um efeito colateral que ninguém veria no
valor devolvido.

## Um Mock concorda com tudo

A mesma liberdade que deixa o `Mock` conveniente o deixa perigoso. Um `Mock` simples aceita qualquer
nome de método, com erro de digitação ou inventado:

```
ana@laptop:~/shipquote$ python3 -c '
from unittest import mock
mailer = mock.Mock()
mailer.sned(to="bia@example.org")
print(mailer.sned.call_args)
print(mailer.anything.at.all())
'
call(to='bia@example.org')
<Mock name='mock.anything.at.all()' id='139716095751376'>
```

`mailer.sned(...)` funcionou e foi registrado, e `mailer.anything.at.all()` devolveu outro mock. Um
erro de digitação no código de produção chamando um `Mock` simples não levanta nada no teste.

`create_autospec` constrói o mock a partir da classe real, e recusa o que a classe não tem:

```
ana@laptop:~/shipquote$ python3 -c '
from unittest import mock
from shipquote.mailer import SmtpMailer
mailer = mock.create_autospec(SmtpMailer, instance=True)
mailer.sned(to="bia@example.org")
'
Traceback (most recent call last):
  File "<string>", line 5, in <module>
    mailer.sned(to="bia@example.org")
    ^^^^^^^^^^^
  File "/usr/lib/python3.13/unittest/mock.py", line 690, in __getattr__
    raise AttributeError("Mock object has no attribute %r" % name)
AttributeError: Mock object has no attribute 'sned'
```

## O que acontece quando a classe real muda

É aqui que deixa de ser sobre erros de digitação. Suponha que alguém renomeie `SmtpMailer.send` para
`deliver` e esqueça `orders.place`, que continua chamando `send`. A produção passa a falhar em todo
pedido. Faça você mesmo essa troca, `def send` para `def deliver` em `shipquote/mailer.py`. Depois
rode `tests/test_orders.py` duas vezes: primeiro como a aula 1 o escreveu, com um `mock.Mock()`
simples, e depois com as duas linhas que esta seção muda, de modo que o arquivo fique, inteiro,
como abaixo. Salve como `tests/test_orders.py`:

```python
from unittest import mock

import pytest

from shipquote.mailer import SmtpMailer
from shipquote.orders import place
from tests.fakes import FakeOrders


def test_placing_an_order_sends_exactly_one_confirmation():
    mailer = mock.create_autospec(SmtpMailer, instance=True)
    order_id = place(FakeOrders(), mailer, "bia@example.org", 8990)
    mailer.send.assert_called_once_with(
        to="bia@example.org", subject=f"Order {order_id} confirmed",
        body="Total: R$ 89,90")


def test_an_order_of_nothing_is_refused_before_anything_is_written():
    orders = FakeOrders()
    with pytest.raises(ValueError, match="must cost something"):
        place(orders, mailer=None, email="bia@example.org", cents=0)
    assert orders.rows == []
```

A troca de nome, o teste antigo e o novo:

```
ana@laptop:~/shipquote$ git diff --stat
 shipquote/mailer.py | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)
ana@laptop:~/shipquote$ python -m pytest tests/test_orders.py -q
..                                                                       [100%]
2 passed in 0.15s
ana@laptop:~/shipquote$ python -m pytest tests/test_orders.py -q --tb=line
F.                                                                       [100%]
=================================== FAILURES ===================================
E   AttributeError: Mock object has no attribute 'send'
/usr/lib/python3.13/unittest/mock.py:690: AttributeError: Mock object has no attribute 'send'
=========================== short test summary info ============================
FAILED tests/test_orders.py::test_placing_an_order_sends_exactly_one_confirmation
1 failed, 1 passed in 0.16s
```

**O mock simples passou. O mock com autospec falhou**, com `Mock object has no attribute 'send'`, o
mesmo erro que a produção levantaria. É por isso que o projeto fica com a segunda versão. Um mock
que não conhece a forma do que substitui confere o código contra um colaborador imaginário, e o
imaginário nunca muda. Ponha o `send` de volta com `git checkout shipquote/mailer.py` e faça o
commit do teste novo.

A regra prática: **faça o mock pela especificação, a partir da classe real**, e use mock só onde a
chamada é o que você precisa conferir. Para todo o resto, um stub ou um fake mantém o teste falando
de resultados.
