---
title: Fábricas de dados de teste
version: 1
---

Um teste do store precisa de uma cotação para gravar: um CEP, um peso, um preço e um timestamp.
Escritos em todo teste, esses quatro valores são ruído, e escondem o único valor de que cada teste
de fato trata. Uma **fábrica** (*factory*) constrói um objeto válido com padrões razoáveis e deixa o
teste sobrescrever só os campos que importam para ele.

A fábrica do `shipquote`, do passo 7 do projeto, é uma função em `tests/factories.py`:

```schooling-example
{
  "language": "python",
  "file": "tests/factories.py",
  "parts": [
    {
      "code": "\"\"\"Test data with sensible defaults: a test names only what it is about.\"\"\"\nfrom itertools import count\n\n_ids = count(1)",
      "note": "Um contador compartilhado por todas as chamadas, então cada cotação que a fábrica monta é diferente da anterior."
    },
    {
      "code": "def a_quote(**overrides):\n    \"\"\"A valid quote row; override the fields the test cares about.\"\"\"\n    n = next(_ids)\n    quote = {\n        \"cep\": \"01310100\",\n        \"weight_g\": 1200,\n        \"cents\": 2190,\n        \"created_at\": f\"2026-10-05T13:{n % 60:02d}:00-03:00\",\n    }",
      "note": "Os padrões descrevem uma cotação comum e válida: um CEP em São Paulo, 1,2 kg, R$ 21,90. O timestamp usa o contador para duas cotações montadas em sequência nunca dividirem um `created_at`, o que importa para um store que ordena por ele."
    },
    {
      "code": "    quote.update(overrides)\n    return quote",
      "note": "As sobrescritas do teste substituem os padrões. Todo o resto continua válido."
    }
  ]
}
```

E os testes do store, reescritos para usá-la:

```python
import sqlite3

import pytest

from tests.factories import a_quote

pytestmark = pytest.mark.integration


def test_a_saved_quote_comes_back_by_id(store):
    quote_id = store.save(**a_quote(cents=2190))
    assert store.get(quote_id)["cents"] == 2190


def test_recent_lists_the_newest_first(store):
    first = store.save(**a_quote(created_at="2026-10-05T13:30:00-03:00"))
    second = store.save(**a_quote(created_at="2026-10-05T13:31:00-03:00"))
    assert store.recent(2) == [second, first]


def test_the_database_refuses_a_cep_of_the_wrong_length(store):
    with pytest.raises(sqlite3.IntegrityError, match="CHECK constraint failed"):
        store.save(**a_quote(cep="0131010"))
```

Cada teste agora nomeia aquilo de que trata e nada mais. O primeiro é sobre centavos, então diz
`cents=2190`. O segundo é sobre ordenar por tempo, então define dois `created_at`. O terceiro é
sobre um CEP que o banco precisa recusar, então passa `cep="0131010"`, e quem lê vê que tem sete
dígitos sem procurar entre outros três argumentos.

```
ana@laptop:~/shipquote$ python -m pytest tests/test_store.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 3 items

tests/test_store.py::test_a_saved_quote_comes_back_by_id PASSED          [ 33%]
tests/test_store.py::test_recent_lists_the_newest_first PASSED           [ 66%]
tests/test_store.py::test_the_database_refuses_a_cep_of_the_wrong_length PASSED [100%]

============================== 3 passed in 0.20s ===============================
```

## Por que não literais

Literais servem quando todo valor neles importa. Deixam de servir quando o objeto cresce.
Acrescente uma coluna `carrier` às cotações no mês que vem, e todo teste que escreve uma cotação por
extenso precisa mudar, inclusive os que não têm nada a ver com transportadoras. Com uma fábrica,
muda um padrão.

Há um segundo benefício, mais discreto: **os padrões de uma fábrica são válidos por construção**. Um
teste que digita `weight_g=0` por engano falha com um erro de CHECK e parece um defeito do store. O
peso padrão de uma fábrica é um peso real, então um teste só encontra um valor inválido quando pede
um.

## Builders e bibliotecas

A função acima é a forma mais simples. Projetos maiores usam bibliotecas que fazem o mesmo com mais
estrutura: `factory_boy` em Python, `FactoryBot` em Ruby, `Fishery` em TypeScript. Elas acrescentam
sequências para valores únicos, objetos relacionados montados sob demanda e integração com ORMs.
Seja qual for a ferramenta, a ideia é a mostrada aqui: **padrões válidos, sobrescritas explícitas,
e nada no teste que não seja o assunto dele.**
