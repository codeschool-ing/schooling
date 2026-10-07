---
title: Testes unitários
version: 1
---

Um **teste unitário** exercita um pedaço pequeno de comportamento sem nada real em volta: sem banco
de dados, sem rede, sem relógio, sem outro processo. O erro comum é ler "unidade" como "uma função"
ou "uma classe". Quer dizer **um comportamento, isolado de tudo o que é lento ou compartilhado**. Um
teste unitário de uma regra de preço pode chamar três funções; o que o torna unitário é não tocar
em nada fora do processo.

`freight`, em `shipquote/quote.py`, é aritmética pura sobre os argumentos, o que faz dela o
assunto ideal:

```python
"""What it costs to send a parcel, in cents."""

# The first digit of a CEP says which region of Brazil it is in.
ZONES = {"0": "SP", "1": "SP", "2": "SE", "3": "SE", "4": "NE",
         "5": "NE", "6": "N", "7": "CO", "8": "S", "9": "S"}
BASE = {"SP": 1290, "SE": 1590, "S": 1890, "CO": 2190, "NE": 2490, "N": 2990}
EXTRA_PER_500G = 450      # every 500 g started after the first
FREE_FROM = 19900         # an order of R$ 199,00 or more ships free


def normalise_cep(cep: str) -> str:
    digits = cep.replace("-", "")
    if len(digits) != 8 or not digits.isdigit():
        raise ValueError(f"not a CEP: {cep!r}")
    return digits


def zone_of(cep: str) -> str:
    return ZONES[normalise_cep(cep)[0]]


def freight(cep: str, weight_g: int, subtotal_cents: int) -> int:
    if weight_g <= 0:
        raise ValueError(f"weight must be positive, got {weight_g}")
    zone = zone_of(cep)
    if subtotal_cents >= FREE_FROM:
        return 0
    extra = (weight_g - 1) // 500
    return BASE[zone] + extra * EXTRA_PER_500G
```

## Muitas entradas, um teste

A regra de peso tem bordas: os primeiros 500 g estão no preço base, e cada 500 g **começados**
depois disso custam R$ 4,50 a mais. Escrever cinco funções quase iguais para cinco pesos enterraria
a regra na repetição. O `parametrize` do pytest roda um corpo de teste uma vez por linha de uma
tabela:

```schooling-example
{
  "language": "python",
  "file": "tests/test_quote.py",
  "parts": [
    {
      "code": "@pytest.mark.parametrize(\"weight_g, cents\", [\n    (1, 1290),\n    (500, 1290),\n    (501, 1740),\n    (1000, 1740),\n    (1001, 2190),\n])",
      "note": "A tabela: cada linha é um peso e o preço que ele precisa produzir. As linhas ficam nas bordas: 1 g e 500 g estão na primeira faixa, 501 g é o primeiro grama da segunda, 1000 g o último dela, e 1001 g abre a terceira."
    },
    {
      "code": "def test_every_500_g_started_after_the_first_costs_extra(weight_g, cents):\n    assert freight(\"01310-100\", weight_g, 5000) == cents",
      "note": "Um corpo, rodado uma vez por linha com `weight_g` e `cents` preenchidos. Uma falha diz qual linha quebrou, então a tabela é tão precisa quanto cinco testes separados."
    }
  ]
}
```

Com `-v`, cada linha vira uma linha própria, com os parâmetros entre colchetes:

```
ana@laptop:~/shipquote$ python -m pytest tests/test_quote.py -v
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.6.0 -- /home/ana/shipquote/.venv/bin/python
cachedir: .pytest_cache
hypothesis profile 'default'
rootdir: /home/ana/shipquote
configfile: pyproject.toml
plugins: hypothesis-6.168.5
collecting ... collected 11 items

tests/test_quote.py::test_a_cep_in_the_city_of_sao_paulo_is_zone_sp PASSED [  9%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[1-1290] PASSED [ 18%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[500-1290] PASSED [ 27%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[501-1740] PASSED [ 36%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[1000-1740] PASSED [ 45%]
tests/test_quote.py::test_every_500_g_started_after_the_first_costs_extra[1001-2190] PASSED [ 54%]
tests/test_quote.py::test_an_order_of_199_reais_or_more_ships_free[19899-1290] PASSED [ 63%]
tests/test_quote.py::test_an_order_of_199_reais_or_more_ships_free[19900-0] PASSED [ 72%]
tests/test_quote.py::test_an_order_of_199_reais_or_more_ships_free[19901-0] PASSED [ 81%]
tests/test_quote.py::test_a_weight_of_zero_is_refused PASSED             [ 90%]
tests/test_quote.py::test_a_cep_with_a_letter_in_it_is_refused PASSED    [100%]

============================== 11 passed in 0.16s ==============================
```

Onze testes em 0,16 segundo. **Essa velocidade é o objetivo da camada.** Uma suíte unitária roda a
cada salvamento sem que ninguém perceba o custo, então é o lugar de toda regra que dá para testar
sem o mundo de fora: arredondamento, bordas, formatação, a recusa de um CEP inválido.

## O que um teste unitário não vê

Cada teste acima passa os argumentos que `freight` espera. Nenhum pergunta se a camada HTTP passa o
peso em gramas ou em quilos, se a coluna do banco que guarda o preço o aceita, ou se o servidor
sobe. Essas falhas moram **entre** as unidades, e uma suíte feita só de testes unitários fica verde
enquanto todas elas estão quebradas. As três próximas seções sobem para fora, uma fronteira de cada
vez, até os testes que conseguem vê-las.

Uma regra útil para decidir onde um teste fica: **teste cada regra na camada mais baixa que
consegue observá-la.** O limite do frete grátis é aritmética, então suas bordas são testadas aqui,
três linhas, em milissegundos. Se o cliente vê de fato "R$ 0,00" na página é outra pergunta, e a
seção 11 a faz uma vez, no topo.
