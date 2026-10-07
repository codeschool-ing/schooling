---
title: Conferindo os stubs contra o real
version: 2
---

Todo stub é uma afirmação: *a transportadora responde assim*. `StubCarrier(cents=1999)` supõe que a
transportadora manda um objeto JSON com uma chave `cents` contendo um número inteiro. Se a
transportadora mudar a resposta, os stubs continuam dizendo a coisa antiga, e todo teste que os usa
fica verde enquanto a produção falha. Nada nos dublês tem como perceber; eles são o que ficou velho.

Um **teste de contrato** fecha o ciclo perguntando ao colaborador real as perguntas que os dublês
respondem. O `shipquote` tem dois. Salve como `tests/test_carrier_contract.py`:

```python
"""The questions the stubs answer, asked of a real carrier endpoint.

Runs only when CARRIER_URL says where one is; CARRIER_TOKEN is its key.
"""
import os

import pytest

from shipquote.carrier import CarrierClient, CarrierError

URL = os.environ.get("CARRIER_URL")
pytestmark = [pytest.mark.contract,
              pytest.mark.skipif(not URL, reason="CARRIER_URL is not set")]


@pytest.fixture
def client():
    return CarrierClient(URL, os.environ.get("CARRIER_TOKEN", ""))


def test_a_rate_is_a_whole_number_of_cents(client):
    cents = client.rate("01310100", 1200)
    assert isinstance(cents, int) and cents > 0


def test_a_wrong_token_is_a_carrier_error_not_a_crash():
    with pytest.raises(CarrierError, match="401"):
        CarrierClient(URL, "not-the-token").rate("01310100", 1200)
```

Eles têm o marcador `contract`, que o `pyproject.toml` da aula 1 não declara, e o
`--strict-markers` recusa um marcador que ninguém declarou. Então a lista ganha uma linha, e o
arquivo fica assim, inteiro. Salve como `pyproject.toml`:

```toml
[project]
name = "shipquote"
version = "0"
requires-python = ">=3.11"

[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "--strict-markers"
markers = [
    "integration: talks to a real SQLite file",
    "functional: starts the HTTP server",
    "acceptance: a promise the shop makes, checked from outside",
    "contract: asks the real carrier the questions the stubs answer",
]

[tool.coverage.run]
branch = true
source = ["shipquote"]

[tool.coverage.report]
show_missing = true
```

Os testes **são pulados se `CARRIER_URL` não disser onde há uma transportadora**, porque precisam
de uma. Rode num notebook sem nada configurado e é isto que sai:

```
ana@laptop:~/shipquote$ python -m pytest -m contract -v -rs
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
testpaths: tests
plugins: hypothesis-6.168.5
collecting ... collected 33 items / 31 deselected / 2 selected

tests/test_carrier_contract.py::test_a_rate_is_a_whole_number_of_cents SKIPPED [ 50%]
tests/test_carrier_contract.py::test_a_wrong_token_is_a_carrier_error_not_a_crash SKIPPED [100%]

=========================== short test summary info ============================
SKIPPED [1] tests/test_carrier_contract.py:21: CARRIER_URL is not set
SKIPPED [1] tests/test_carrier_contract.py:26: CARRIER_URL is not set
====================== 2 skipped, 31 deselected in 0.22s =======================
```

Dois `SKIPPED`, com o motivo. `-rs` pede ao pytest que imprima os motivos, e sem ele a execução
termina num `2 skipped` discreto, fácil de ler como "tudo bem". **Um teste pulado não é um teste
aprovado.** Se o pipeline nunca definir `CARRIER_URL`, o contrato nunca é conferido, e a suíte
reporta sucesso para sempre. A aula 9 trata de dar ao pipeline o endereço e o token sem pôr o token
no repositório.

## Contra uma transportadora

O laboratório não alcança uma transportadora real, então usa a simulada da seção 04, de novo no
segundo terminal, desta vez sem o atraso:

```sh
CARRIER_TOKEN=lab-token-not-a-secret python3 ~/carrier/server.py
```

Ela escuta em 127.0.0.1:9090 e aceita o token que o laboratório inventou. Apontados para ela, os
dois testes de contrato passam:

```
ana@laptop:~/shipquote$ CARRIER_URL=http://127.0.0.1:9090 CARRIER_TOKEN=lab-token-not-a-secret python -m pytest -m contract -q
..                                                                       [100%]
2 passed, 31 deselected in 0.19s
```

Agora a transportadora muda a resposta, como um fornecedor real faria numa versão nova da API.
Pare a simulada com Ctrl-C, faça-a mandar `price_cents` em vez de `cents` e suba-a de novo:

```sh
sed -i 's/{"cents": 1500/{"price_cents": 1500/' ~/carrier/server.py
CARRIER_TOKEN=lab-token-not-a-secret python3 ~/carrier/server.py
```

Depois, no primeiro terminal, os testes dos stubs e os do contrato:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_carrier.py -q
....                                                                     [100%]
4 passed in 0.14s
ana@laptop:~/shipquote$ CARRIER_URL=http://127.0.0.1:9090 CARRIER_TOKEN=lab-token-not-a-secret python -m pytest -m contract -q --tb=line
F.                                                                       [100%]
=================================== FAILURES ===================================
E   KeyError: 'cents'

The above exception was the direct cause of the following exception:
E   shipquote.carrier.CarrierError: 'cents'
/home/ana/shipquote/shipquote/carrier.py:29: shipquote.carrier.CarrierError: 'cents'
=========================== short test summary info ============================
FAILED tests/test_carrier_contract.py::test_a_rate_is_a_whole_number_of_cents
1 failed, 1 passed, 31 deselected in 0.19s
```

Os quatro testes com stub continuam verdes: nunca falam com a transportadora. O teste de contrato
falha com `CarrierError: 'cents'`, a chave que não existe mais. Em produção, a reserva cotaria pela
tabela em silêncio a cada requisição, e só a linha de log da seção 05 diria isso. Ponha a simulada
de volta como era, `sed -i 's/{"price_cents": 1500/{"cents": 1500/' ~/carrier/server.py`, porque
as aulas seguintes pedem preços a ela de novo, e faça o commit dos testes de contrato com o
marcador.

## Contratos na prática

Rodar testes de contrato contra a API real de um fornecedor a cada push muitas vezes é impossível:
custa dinheiro por chamada, tem limite de taxa, ou a sandbox está fora do ar. O meio-termo usual é
rodá-los **num agendamento**, toda noite, contra o ambiente de teste do fornecedor, e tratar uma
falha como "nossos stubs estão desatualizados". A aula 5 configura execuções agendadas. Algumas
equipes vão além com *contratos guiados pelo consumidor*, em que o consumidor publica as requisições
de que depende e o pipeline do próprio fornecedor as roda antes de cada release; o Pact é a
ferramenta mais conhecida para isso.
