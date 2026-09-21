---
title: `tests/`, `conftest.py`, e o import que falha
version: 1
---

```sh
projeto/
  pyproject.toml
  conftest.py            <- vazio, e sustentando o prédio
  app/
    __init__.py
    rates.py
  tests/
    test_rates.py
```

```python
# tests/test_rates.py
from app.rates import total
```

```sh
E   ModuleNotFoundError: No module named 'app'
=========================== short test summary info ============================
ERROR tests/test_rates.py
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
```

**Sem o `conftest.py` na raiz, esse import falha.** Com ele — vazio, zero byte — tudo passa. O
`pytest` trata o diretório que contém o `conftest.py` mais alto como a raiz e o põe no `sys.path`,
então `app` fica importável.

Esta é a primeira hora mais comum com o `pytest`, e o conserto parece superstição até você saber
para que o arquivo serve.

## O que o `conftest.py` é de fato

É onde moram as fixtures de que mais de um arquivo de teste precisa. Um `conftest.py` em `tests/`
é visível para tudo sob `tests/`; um em `tests/api/` é visível só para aquele subdiretório. Nada o
importa — o `pytest` o acha pelo nome e o aplica pela posição.

```python
# tests/conftest.py
import pytest

@pytest.fixture
def taxas():
    return {"BRL": 1.0, "USD": 5.4}
```

Todo teste sob `tests/` pode agora receber `taxas` como argumento sem importar nada.

## Testes fora do pacote, e a questão do `__init__.py`

`tests/` fica ao lado de `app/` e não dentro dele, então a suíte não é publicada com a aplicação e
a importa do jeito que um usuário importa. Deixe o `__init__.py` de fora de `tests/` e dois
arquivos de teste não podem compartilhar um nome de base — `tests/api/test_rates.py` e
`tests/db/test_rates.py` colidem. Ponha, e podem.

## Configuração no `pyproject.toml`

```toml
[tool.pytest.ini_options]
testpaths = ["tests"]
addopts = "-q --strict-markers"
```

`testpaths` faz um `pytest` pelado não andar pelo seu ambiente virtual. `--strict-markers`
transforma um `@pytest.mark.slwo` escrito errado num erro em vez de um marcador que ninguém
registrou e nada seleciona.
