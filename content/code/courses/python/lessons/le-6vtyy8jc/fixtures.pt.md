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

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 268\" role=\"img\" aria-label=\"Um teste pede um fixture nomeando-o como argumento. O pytest acha o fixture com aquele nome, roda e devolve o que ele retornou. Com um yield, tudo antes dele roda antes do teste e tudo depois roda quando o teste termina.\"> <defs><marker id=\"ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs> <defs><marker id=\"ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs> <rect x=\"20\" y=\"34\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"170\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--paper)\">def test_conversao(taxas):</text> <path d=\"M326 52 L394 52\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-phosphor)\"></path> <text x=\"360\" y=\"26\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">o nome do argumento é o pedido</text> <rect x=\"400\" y=\"34\" width=\"300\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"550\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">@pytest.fixture  def taxas():</text> <path d=\"M394 84 L326 84\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"360\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e o que ele retornou chega como o argumento</text> <text x=\"20\" y=\"148\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper-dim)\">e com um yield dentro</text> <rect x=\"20\" y=\"160\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"132\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tudo antes do yield</text> <text x=\"132\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">antes do teste</text> <rect x=\"256\" y=\"160\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"368\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o teste roda</text> <path d=\"M246 178 L252 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <rect x=\"492\" y=\"160\" width=\"224\" height=\"36\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\"0.2\" stroke=\"var(--phosphor)\"></rect> <text x=\"604\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tudo depois do yield</text> <path d=\"M482 178 L488 178\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#ah-paper-dim)\"></path> <text x=\"604\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">depois dele, termine como terminar</text> </svg>", "caption": "Um teste diz o que precisa na própria assinatura, e nada tem de ser preparado por quem lembrou."}
```

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
