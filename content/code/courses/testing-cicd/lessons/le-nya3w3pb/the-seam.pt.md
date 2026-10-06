---
title: A costura por onde o dublê entra
version: 1
---

A aula 1 testou código que só fazia aritmética. A maior parte do código também conversa com coisas
que um teste não deveria tocar: a API de uma transportadora que cobra por chamada, um servidor SMTP
que manda e-mail de verdade, um relógio que anda. Um **dublê de teste** é um objeto que fica no
lugar de um desses colaboradores durante o teste, como um dublê de cinema fica no lugar do ator. Os
cinco tipos que esta aula nomeia, dummy, stub, spy, mock e fake, diferem no que o substituto faz.

Nenhum deles serve se o código não tiver uma **costura** (*seam*): um lugar onde o colaborador é
entregue de fora em vez de buscado lá dentro. Compare duas formas de `price` obter a transportadora:

```python
def price(cep, weight_g, subtotal_cents):            # reaches for it
    carrier = CarrierClient("https://api.carrier.example", TOKEN)
    ...

def price(carrier, cep, weight_g, subtotal_cents):   # is handed it
    ...
```

A primeira constrói o próprio cliente dentro da função, então cada chamada vai à rede, e um teste
não tem como dizer "finja que a transportadora respondeu 1999". A segunda recebe a transportadora
como argumento, e o teste passa qualquer coisa que tenha um método `rate`. Esse é o truque todo, e
ele tem um nome pomposo, **injeção de dependência**, para algo tão simples quanto um parâmetro a
mais.

## As costuras do shipquote

`shipquote/carrier.py` tem três, e cada uma está lá por causa de um teste:

```schooling-example
{
  "language": "python",
  "file": "shipquote/carrier.py",
  "parts": [
    {
      "code": "class CarrierClient:\n    def __init__(self, base_url, token, timeout=2.0,\n                 opener=urllib.request.urlopen):\n        self.base_url = base_url.rstrip(\"/\")\n        self.token = token\n        self.timeout = timeout\n        self.opener = opener",
      "note": "`opener` é como o cliente manda uma requisição. Em produção é `urllib.request.urlopen`; um teste passa uma função que devolve uma resposta pronta sem abrir socket."
    },
    {
      "code": "def price(carrier, cep, weight_g, subtotal_cents, log=print):\n    \"\"\"The carrier's price when it answers, the table's when it does not.\"\"\"\n    if subtotal_cents >= quote.FREE_FROM:\n        return 0\n    try:\n        return carrier.rate(quote.normalise_cep(cep), weight_g)\n    except CarrierError as e:\n        log(f\"carrier unavailable, using the table: {e}\")\n        return quote.freight(cep, weight_g, subtotal_cents)",
      "note": "`price` recebe a `carrier` como primeiro argumento, então o teste escolhe o que a transportadora diz. `log` tem `print` como padrão, e um teste passa algo que coleta as linhas."
    }
  ]
}
```

`orders.place` é construído do mesmo jeito: recebe `orders`, onde o pedido é guardado, e `mailer`,
que manda a confirmação. Nenhum dos dois é criado lá dentro.

## O custo de uma costura

Um parâmetro que só os testes usam é um preço pequeno, e compra mais do que testes. **Uma costura
também é onde a produção troca uma implementação**: o mesmo `price` funciona com uma transportadora
real, uma segunda transportadora ou uma com cache, sem ser editado. Código difícil de testar porque
busca os próprios colaboradores costuma ser difícil de mudar pelo mesmo motivo.

A alternativa, quando falta uma costura e não dá para criá-la, é o **patch**: trocar um nome dentro
de um módulo enquanto o teste roda. Funciona e tem uma armadilha, que a seção 09 dispara de
propósito. Prefira a costura; use patch quando não puder mudar o código.
