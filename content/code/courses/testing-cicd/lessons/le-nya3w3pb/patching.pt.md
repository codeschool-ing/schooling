---
title: Patch, e onde um nome é consultado
version: 1
---

Quando o código não tem costura, um teste ainda consegue trocar um colaborador com um **patch**:
substituir o objeto ao qual um nome se refere, durante o teste, e devolvê-lo depois. Em Python isso
é o `unittest.mock.patch`, ou o `monkeypatch` do pytest. É a ferramenta para código que você não
pode mudar. Também tem uma armadilha que pega quase todo mundo uma vez, e o `shipquote` cai nela de
propósito.

Eis um arquivo de teste escrito para esta seção. Os dois testes querem que `CarrierClient.rate`
receba uma resposta pronta de 1999 centavos sem tocar a rede:

```python
import io
from unittest import mock

from shipquote.carrier import CarrierClient


def test_patching_the_module_after_the_default_was_taken():
    answer = mock.MagicMock()
    answer.__enter__.return_value = io.BytesIO(b'{"cents": 1999}')
    with mock.patch("urllib.request.urlopen", return_value=answer):
        client = CarrierClient("http://127.0.0.1:9", "t")
        assert client.rate("01310100", 1200) == 1999


def test_handing_the_double_in_through_the_seam():
    answer = mock.MagicMock()
    answer.__enter__.return_value = io.BytesIO(b'{"cents": 1999}')
    client = CarrierClient("http://127.0.0.1:9", "t",
                           opener=mock.Mock(return_value=answer))
    assert client.rate("01310100", 1200) == 1999
```

O primeiro aplica o patch em `urllib.request.urlopen`, a função que o cliente usa por padrão. O
segundo passa o dublê pelo parâmetro `opener`. Na porta 9 de 127.0.0.1 não há nada escutando, então
qualquer requisição que saia de verdade seria recusada.

```
ana@laptop:~/shipquote$ python -m pytest tests/test_patch_trap.py -q --tb=line
F.                                                                       [100%]
=================================== FAILURES ===================================
E   ConnectionRefusedError: [Errno 111] Connection refused

During handling of the above exception, another exception occurred:
E   urllib.error.URLError: <urlopen error [Errno 111] Connection refused>

The above exception was the direct cause of the following exception:
E   shipquote.carrier.CarrierError: <urlopen error [Errno 111] Connection refused>
/home/ana/shipquote/shipquote/carrier.py:29: shipquote.carrier.CarrierError: <urlopen error [Errno 111] Connection refused>
=========================== short test summary info ============================
FAILED tests/test_patch_trap.py::test_patching_the_module_after_the_default_was_taken
1 failed, 1 passed in 0.17s
```

**O patch não teve efeito.** O primeiro teste fez uma conexão real com a porta 9 e foi recusado; o
segundo passou. O motivo está numa linha de `carrier.py`:

```python
    def __init__(self, base_url, token, timeout=2.0,
                 opener=urllib.request.urlopen):
```

Um argumento padrão é avaliado **uma vez, quando a função é definida**, ou seja, quando o módulo é
importado. Naquele momento o padrão de `opener` virou a função `urlopen` real. Trocar depois o nome
`urllib.request.urlopen` muda para onde o nome aponta, e o padrão continua segurando o objeto
original.

## Faça o patch onde o nome é usado

A mesma coisa acontece com `from urllib.request import urlopen` no topo de um módulo: essa linha
copia a referência para o espaço de nomes do próprio módulo, e um patch em `urllib.request.urlopen`
depois disso não alcança a cópia. A regra está na documentação do `unittest.mock`: **faça o patch
no nome onde ele é consultado, não onde é definido.** Para código que faz
`from urllib.request import urlopen` em `shipquote/carrier.py`, o alvo é
`"shipquote.carrier.urlopen"`.

Repare também em como a falha apareceu. O teste não falhou com "o patch não foi aplicado"; falhou
com um erro de conexão três exceções abaixo. **Um patch que erra o alvo falha como outra coisa**,
ou, pior, passa contra um serviço real que por acaso respondeu. Esse é o motivo mais forte para
preferir uma costura: o segundo teste não tem como errar, porque o dublê é entregue à vista.
