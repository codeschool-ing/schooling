---
title: Stub
version: 2
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
responde, e esperar. Ver quanto custa essa espera pede uma transportadora, e uma de verdade está a
um contrato e uma chave de API de distância. **Por isso o laboratório tem uma transportadora simulada**: um pequeno
servidor HTTP que responde o mesmo tipo de pergunta que a API de frete de uma transportadora
responderia, na sua própria máquina. Ele não faz parte do `shipquote`, então mora num diretório só
dele. Salve como `~/carrier/server.py`:

```python
"""A stand-in for a carrier's rate API, on 127.0.0.1, for the lab only.

GET /v1/rate?cep=NNNNNNNN&weight=G with "Authorization: Bearer <token>"
answers {"cents": N}. The token it accepts is read from CARRIER_TOKEN.
CARRIER_DELAY makes every answer that many seconds late.
"""
import json
import os
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import parse_qs, urlparse

TOKEN = os.environ["CARRIER_TOKEN"]
DELAY = float(os.environ.get("CARRIER_DELAY", "0"))


class Rate(BaseHTTPRequestHandler):
    def do_GET(self):
        time.sleep(DELAY)
        if self.headers.get("Authorization") != f"Bearer {TOKEN}":
            return self.answer(401, {"error": "bad token"})
        url = urlparse(self.path)
        if url.path != "/v1/rate":
            return self.answer(404, {"error": "not found"})
        q = parse_qs(url.query)
        weight = int(q["weight"][0])
        self.answer(200, {"cents": 1500 + 3 * (weight // 100) * 10})

    def answer(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, fmt, *args):
        pass


ThreadingHTTPServer(("127.0.0.1", int(os.environ.get("CARRIER_PORT", "9090"))),
                    Rate).serve_forever()
```

Ele responde a `GET /v1/rate` com um preço em centavos, recusa um pedido que não traga o token com
que foi iniciado e espera `CARRIER_DELAY` segundos antes de cada resposta. Suba-o num segundo
terminal, três segundos lento, com um token inventado para o laboratório:

```sh
CARRIER_TOKEN=lab-token-not-a-secret CARRIER_DELAY=3 python3 ~/carrier/server.py
```

Ele não imprime nada e fica com esse terminal até um Ctrl-C pará-lo. De volta ao primeiro, eis um
cliente que desiste depois de dois segundos:

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
nenhum, e é por isso que o teste com stub está na camada rápida e esta sessão não. Pare a
simulada com Ctrl-C agora; a seção 10 o sobe de novo sem o atraso.

**Um stub é tão honesto quanto as situações que você dá a ele.** Responde 1999 porque você mandou,
seja o que for que uma transportadora real responderia. Se a transportadora real mudar o que manda,
o stub não muda junto, e a seção 10 é sobre pegar exatamente isso.

## Stubs não conferem nada

Repare que nenhum dos dois testes pergunta se `rate` foi chamado, nem com qual CEP. Um stub alimenta
o código; as verificações são sobre o resultado. Quando *as próprias chamadas* são o que você
precisa conferir, você precisa de algo que as registre, e é disso que tratam as duas próximas
seções.
