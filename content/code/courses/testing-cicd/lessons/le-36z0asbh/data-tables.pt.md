---
title: Uma tabela de casos, guardada como dado
version: 1
---

Algumas regras se conferem melhor como tabela: entradas nas colunas, a resposta esperada na última,
uma linha por caso. A loja publica uma tabela de frete para os clientes, e o `shipquote` guarda os
mesmos casos em `tests/data/quotes.csv`:

```
cep,weight_g,subtotal_cents,cents
01310-100,300,5000,1290
01310-100,1200,5000,2190
20040-002,300,5000,1590
40010-000,2600,5000,4740
69005-010,300,5000,2990
69005-010,5000,5000,7040
70040-010,800,5000,2640
80010-000,300,19900,0
```

O teste lê o arquivo e transforma cada linha num caso de teste:

```python
"""The price table the shop publishes, one row per case, checked as data."""
import csv
from pathlib import Path

import pytest

from shipquote.quote import freight

ROWS = list(csv.DictReader(open(Path(__file__).parent / "data" / "quotes.csv")))


@pytest.mark.parametrize("row", ROWS, ids=lambda r: f"{r['cep']}-{r['weight_g']}g")
def test_the_published_table(row):
    cents = freight(row["cep"], int(row["weight_g"]), int(row["subtotal_cents"]))
    assert cents == int(row["cents"])
```

`ids=` dá nome a cada caso a partir da própria linha, e é isso que deixa a execução legível:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_quote_table.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 8 items

tests/test_quote_table.py::test_the_published_table[01310-100-300g] PASSED [ 12%]
tests/test_quote_table.py::test_the_published_table[01310-100-1200g] PASSED [ 25%]
tests/test_quote_table.py::test_the_published_table[20040-002-300g] PASSED [ 37%]
tests/test_quote_table.py::test_the_published_table[40010-000-2600g] PASSED [ 50%]
tests/test_quote_table.py::test_the_published_table[69005-010-300g] PASSED [ 62%]
tests/test_quote_table.py::test_the_published_table[69005-010-5000g] PASSED [ 75%]
tests/test_quote_table.py::test_the_published_table[70040-010-800g] PASSED [ 87%]
tests/test_quote_table.py::test_the_published_table[80010-000-300g] PASSED [100%]

============================== 8 passed in 0.16s ===============================
```

## Por que um arquivo e não uma lista no teste

`parametrize` com uma lista, como na aula 1, basta enquanto a tabela é curta e só programadores a
mudam. Um CSV justifica o lugar quando **outra pessoa é dona dos números**. A equipe comercial lê
uma planilha; não dá para esperar que leia Python. Quando a tabela é a promessa publicada da loja,
um arquivo que a equipe abre, revisa e muda num pull request mantém o código e a promessa no mesmo
lugar.

## O que uma tabela pega

Aqui a base da zona N sobe de 2990 para 3090 no código, como alguém poderia fazer depois de um
contrato novo com a transportadora, e ninguém mexe no CSV:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_quote_table.py -q --tb=line
....FF..                                                                 [100%]
=================================== FAILURES ===================================
E   AssertionError: assert 3090 == 2990
     +  where 2990 = int('2990')
/home/ana/shipquote/tests/test_quote_table.py:15: AssertionError: assert 3090 == 2990
E   AssertionError: assert 7140 == 7040
     +  where 7040 = int('7040')
/home/ana/shipquote/tests/test_quote_table.py:15: AssertionError: assert 7140 == 7040
=========================== short test summary info ============================
FAILED tests/test_quote_table.py::test_the_published_table[69005-010-300g] - ...
FAILED tests/test_quote_table.py::test_the_published_table[69005-010-5000g]
2 failed, 6 passed in 0.15s
```

As duas linhas da zona N falham, 3090 contra 2990 e 7140 contra 7040, e as outras seis passam. **O
teste não tem como saber qual lado está certo.** Talvez a mudança de preço fosse intencional e a
tabela precise ser atualizada; talvez o código tenha mudado por acidente. O que o teste garante é
que os dois não se afastam em silêncio: quem muda um precisa olhar o outro, no mesmo pull request,
onde quem revisa vê os dois.

Essa é a propriedade geral de testes contra uma saída esperada guardada, muitas vezes chamados de
**arquivos dourados** (*golden files*) ou **snapshots**: os valores esperados são dados, guardados ao
lado do código, e uma mudança de comportamento aparece como uma diferença a revisar. O perigo é o
hábito de regerá-los automaticamente sempre que falham. Um snapshot aceito sem leitura não confere
nada; registra o que o código faz hoje e chama isso de certo.

## As linhas que escolher

O CSV é curto de propósito. As oito linhas incluem uma por zona que importa, um peso que cruza
várias faixas (2600 g, cinco faixas extras), o maior peso da tabela e a borda do frete grátis. Uma
tabela com quinhentas linhas de casos comuns acrescenta tempo de execução e de revisão e não pega
nada que as oito não peguem; as bordas da aula 1 seção 10 é que merecem uma linha.
