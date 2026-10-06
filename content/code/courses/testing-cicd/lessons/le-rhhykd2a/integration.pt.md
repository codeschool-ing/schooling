---
title: Testes de integração
version: 1
---

Um **teste de integração** roda seu código contra um colaborador real que os testes unitários
deixaram de fora: um banco de dados, o sistema de arquivos, uma fila de mensagens, outro serviço.
Ele responde a pergunta que os unitários não respondem: **os dois lados concordam?** Seu SQL contra
o dialeto do motor real, seus tipos de coluna contra o esquema real, sua restrição contra a
restrição real.

O `shipquote` guarda cotações no SQLite, para o cliente poder voltar a uma delas. O store é
pequeno:

```python
"""Quotes kept in SQLite, so a customer can come back to one."""
import sqlite3

SCHEMA = """
CREATE TABLE IF NOT EXISTS quotes (
    id INTEGER PRIMARY KEY,
    cep TEXT NOT NULL CHECK (length(cep) = 8),
    weight_g INTEGER NOT NULL CHECK (weight_g > 0),
    cents INTEGER NOT NULL CHECK (cents >= 0),
    created_at TEXT NOT NULL
)
"""
COLUMNS = ("id", "cep", "weight_g", "cents", "created_at")


class Store:
    def __init__(self, path):
        self.db = sqlite3.connect(path)
        self.db.execute(SCHEMA)

    def save(self, cep, weight_g, cents, created_at):
        with self.db:
            cur = self.db.execute(
                "INSERT INTO quotes (cep, weight_g, cents, created_at)"
                " VALUES (?, ?, ?, ?)",
                (cep, weight_g, cents, created_at))
        return cur.lastrowid

    def get(self, quote_id):
        row = self.db.execute(
            "SELECT id, cep, weight_g, cents, created_at FROM quotes"
            " WHERE id = ?", (quote_id,)).fetchone()
        return None if row is None else dict(zip(COLUMNS, row))

    def recent(self, n):
        rows = self.db.execute(
            "SELECT id FROM quotes ORDER BY created_at DESC, id DESC LIMIT ?",
            (n,)).fetchall()
        return [r[0] for r in rows]

    def close(self):
        self.db.close()
```

Nada disso pode ser conferido sem rodar contra o SQLite. Um erro de digitação no `ORDER BY`, uma
coluna na posição errada, um `CHECK` que recusa o que deveria aceitar: cada um é uma string dentro
da qual o interpretador Python não olha. Os testes abrem um arquivo de banco real num diretório
temporário, que o pytest fornece como `tmp_path`, e a aula 3 explica a fixture que faz isso.

```python
import sqlite3

import pytest

pytestmark = pytest.mark.integration


def test_a_saved_quote_comes_back_by_id(store):
    quote_id = store.save("01310100", 1200, 2190, "2026-10-05T13:30:00-03:00")
    assert store.get(quote_id)["cents"] == 2190


def test_recent_lists_the_newest_first(store):
    first = store.save("01310100", 1200, 2190, "2026-10-05T13:30:00-03:00")
    second = store.save("20040002", 300, 1590, "2026-10-05T13:31:00-03:00")
    assert store.recent(2) == [second, first]


def test_the_database_refuses_a_cep_of_the_wrong_length(store):
    with pytest.raises(sqlite3.IntegrityError, match="CHECK constraint failed"):
        store.save("0131010", 1200, 2190, "2026-10-05T13:30:00-03:00")
```

O terceiro teste é o que um teste unitário jamais escreveria. **Ele afirma que o banco recusa um CEP
de sete dígitos**, uma promessa feita pelo esquema, não por Python algum. Se alguém apagar o
`CHECK`, o Python continua rodando, e só este teste percebe.

`pytestmark = pytest.mark.integration` marca todos os testes do arquivo, para a camada poder rodar
sozinha:

```
ana@laptop:~/shipquote$ python -m pytest -m integration -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
testpaths: tests
plugins: hypothesis-6.168.5
collecting ... collected 31 items / 28 deselected / 3 selected

tests/test_store.py::test_a_saved_quote_comes_back_by_id PASSED          [ 33%]
tests/test_store.py::test_recent_lists_the_newest_first PASSED           [ 66%]
tests/test_store.py::test_the_database_refuses_a_cep_of_the_wrong_length PASSED [100%]

======================= 3 passed, 28 deselected in 0.17s =======================
```

Três de 31 foram selecionados, e levaram 0,17 segundo. O SQLite vive no mesmo processo que o
teste, então aqui a integração quase não custa. **Com um servidor de banco custaria**: subir um
PostgreSQL, criar o esquema e limpar entre os testes transforma milissegundos em segundos. A CI
deste próprio repositório sobe um PostgreSQL real exatamente por isso, e a aula 6 lê esse workflow.

## Real, ou um substituto?

Um atalho comum é rodar os testes de integração num motor mais leve que o de produção: SQLite nos
testes, PostgreSQL em produção. É mais rápido e é uma armadilha. Os dois discordam em tipos, em
`ORDER BY` com empates, no que um `CHECK` pode conter, e o teste passa contra o motor que não está
implantado. **Um teste de integração vale o quanto o seu colaborador se parece com a produção.** O
`shipquote` usa SQLite em produção também, então aqui o teste é honesto. A aula 8 volta a isso como
*paridade* entre ambientes.

O que os testes de integração não veem é a aplicação inteira: como uma requisição chega ao
`Store`, como a resposta é codificada, se o servidor sobe. Essa é a próxima camada.
