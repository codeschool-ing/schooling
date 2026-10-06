---
title: Dummy
version: 1
---

Um **dummy** é o dublê mais simples: um valor passado só porque uma assinatura exige, e que o código
testado nunca usa. Não faz nada, e se o código chegasse a usá-lo, o teste com razão explodiria.

`orders.place` recusa um pedido de zero centavos antes de gravar ou enviar qualquer coisa. O teste
dessa recusa ainda precisa passar um mailer, porque `place` recebe um:

```python
def test_an_order_of_nothing_is_refused_before_anything_is_written():
    orders = FakeOrders()
    with pytest.raises(ValueError, match="must cost something"):
        place(orders, mailer=None, email="bia@example.org", cents=0)
    assert orders.rows == []
```

`mailer=None` é o dummy. O teste é sobre a recusa, e a recusa acontece antes de o mailer poder ser
tocado. Passar `None` diz isso: **se esta linha chegar ao mailer, algo está errado**, e
`None.send(...)` falharia alto com um `AttributeError`.

O store de pedidos no mesmo teste não é um dummy: a última linha afirma que `orders.rows` continua
vazio, então o teste o lê. Isso é um fake, que a seção 07 descreve.

## Por que dar nome a isso

Porque a alternativa é comum e cara. Um teste que precisa de um mailer que não usa muitas vezes
constrói um de verdade, `SmtpMailer("smtp.example", 25)`, "só para ter alguma coisa". Esse objeto é
inofensivo até o dia em que a conferência de recusa desce para depois da linha do e-mail. Aí o teste
manda e-mail de verdade, ou trava cinco segundos esperando um servidor que não existe, e ninguém
sabe por que a suíte ficou lenta.

Um dummy deixa visível o que o teste afirma: *este colaborador é irrelevante aqui*. Quem lê vê
`None` e sabe que não precisa procurar o comportamento dele.

## Quando `None` não basta

Algum código confere o tipo do que recebe, ou chama um método nele como parte da preparação. Aí o
dummy precisa ser um objeto com a forma certa que continue sem fazer nada útil, e
`unittest.mock.Mock()` é um: aceita qualquer chamada. Essa conveniência tem um custo, que a seção 06
mostra, então pegue `None` primeiro e um `Mock` só quando a forma for necessária.
