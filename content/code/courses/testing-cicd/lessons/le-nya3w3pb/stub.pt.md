---
title: Stub
version: 1
---

Um **stub** responde chamadas com valores que o teste escolheu antes. Não tem lógica nem memória. O
trabalho dele é pôr o código testado numa situação específica: a transportadora respondeu 1999, a
transportadora estourou o tempo, o banco não devolveu linhas.

`tests/fakes.py` guarda o stub da transportadora:

```python
class StubCarrier:
    """Answers whatever it was told to answer. No network and no logic."""

    def __init__(self, cents=None, error=None):
        self.cents = cents
        self.error = error

    def rate(self, cep, weight_g):
        if self.error is not None:
            raise self.error
        return self.cents
```

Com centavos, responde centavos; com um erro, levanta o erro. Isso basta para testar os dois ramos
de `price` sem rede:

```python
from unittest import mock

from shipquote.carrier import CarrierError, price
from tests.fakes import StubCarrier


def test_the_carriers_price_wins_when_it_answers():
    assert price(StubCarrier(cents=1999), "01310-100", 1200, 5000) == 1999


def test_the_table_is_used_when_the_carrier_is_down():
    stub = StubCarrier(error=CarrierError("timed out"))
    assert price(stub, "01310-100", 1200, 5000, log=lambda line: None) == 2190
```

O primeiro teste diz *quando a transportadora responde, o preço dela vence*. O segundo diz *quando a
transportadora falha, vale o preço da tabela*, e 2190 é o que a aula 1 mostrou que a tabela cobra
por 1200 g para São Paulo. Nenhum dos dois se importa com como a transportadora é alcançada, só com o
que ela disse.

## Situações que você não conseguiria montar de outro jeito

O segundo teste é o motivo de os stubs existirem. Fazer uma transportadora real estourar o tempo
sob demanda é difícil: seria preciso deixar a rede dela lenta, ou apontar para um endereço que nunca
responde, e esperar. Eis quanto custa esperar, com a transportadora simulada do laboratório
atrasando cada resposta em três segundos e o cliente desistindo depois de dois:

```
ana@laptop:~/shipquote$ time python3 -c '
from shipquote.carrier import CarrierClient, price
client = CarrierClient("http://127.0.0.1:9090", "lab-token-not-a-secret", timeout=2)
print(price(client, "01310-100", 1200, 5000))
'
carrier unavailable, using the table: timed out
2190

real	0m2.091s
user	0m0.065s
sys	0m0.024s
```

A reserva funcionou: a linha de log, depois o 2190 da tabela. Mas a execução levou **2,091
segundos**, e todo teste escrito assim pagaria isso. O stub levanta o mesmo `CarrierError` em tempo
nenhum, e é por isso que o teste com stub está na camada rápida e esta sessão não.

**Um stub é tão honesto quanto as situações que você dá a ele.** Responde 1999 porque você mandou,
seja o que for que uma transportadora real responderia. Se a transportadora real mudar o que manda,
o stub não muda junto, e a seção 10 é sobre pegar exatamente isso.

## Stubs não conferem nada

Repare que nenhum dos dois testes pergunta se `rate` foi chamado, nem com qual CEP. Um stub alimenta
o código; as verificações são sobre o resultado. Quando *as próprias chamadas* são o que você
precisa conferir, você precisa de algo que as registre, e é disso que tratam as duas próximas
seções.
