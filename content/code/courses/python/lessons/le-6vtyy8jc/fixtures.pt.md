---
title: Uma fixture é pedida pelo nome
version: 1
---

```python
import pytest

@pytest.fixture
def taxas():
    return {"BRL": 1.0, "USD": 5.4}

def test_conversao(taxas):
    assert taxas["USD"] == 5.4
```

**O nome do argumento é o pedido.** O `pytest` procura uma fixture chamada `taxas`, roda, e passa
o que ela devolveu. Isso soa esquisito por mais ou menos um dia e depois para, e é o que torna as
dependências de um teste visíveis na assinatura dele.

## Desmontar depois do `yield`

```python
@pytest.fixture
def conn():
    c = conectar()
    yield c
    c.close()
```

Tudo antes do `yield` é montar, o valor entregue é o que o teste recebe, e tudo depois dele é
desmontar. **Roda tendo o teste passado ou falhado**, que é a parte que um `try`/`finally` em cada
teste erraria uma hora.

## Escopo

```python
@pytest.fixture(scope="module")
def conn():
    ...
```

`function` é o padrão e dá a cada teste a sua. `class`, `module`, `package` e `session` alargam:
uma montagem compartilhada por tudo naquele escopo, desmontada no fim dele.

Um escopo mais largo é mais rápido e quer dizer que **um teste pode deixar estado para o
seguinte** — uma linha inserida, um arquivo escrito, um contador avançado. Pegue o escopo mais
estreito que seja rápido o bastante, e quando alargar, zere o estado no teste em vez de confiar na
ordem em que eles rodam.

## As que você não escreveu

```python
def test_escreve_um_arquivo(tmp_path):
    p = tmp_path / "taxas.csv"
    p.write_text("BRL,1.0\n")
    assert p.read_text().startswith("BRL")
```

`tmp_path` é um diretório novo por teste, com o nome dele — `/tmp/pytest-of-voce/pytest-0/
test_escreve_um_arquivo0/`. `capsys` captura o que foi impresso, `monkeypatch` desfaz o que
mudou, `caplog` recolhe registros de log. `pytest --fixtures` lista toda fixture disponível onde
você está.

## Fixtures que usam fixtures

```python
@pytest.fixture
def conta(db):
    return db.insert_account("a@b.c")
```

Uma fixture pede outra do mesmo jeito que um teste pede. É assim que uma cadeia de montagem é
construída uma vez e reaproveitada, e o `pytest` descobre a ordem.
