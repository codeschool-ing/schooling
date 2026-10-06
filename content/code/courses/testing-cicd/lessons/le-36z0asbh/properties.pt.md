---
title: Deixando a máquina escolher as entradas
version: 1
---

Todo teste até aqui confere exemplos que alguém escolheu: 1205 centavos, 501 g, 19.900. Escolher
bem é a habilidade que a aula 1 seção 10 ensinou, e ela tem um limite: você só testa os casos em que
pensou. **Testes baseados em propriedades** invertem isso. Você declara uma regra que precisa valer
para toda entrada, e uma biblioteca gera entradas, centenas delas, procurando uma que a quebre.

`split` tem duas regras assim. Seja qual for o total e quantas forem as parcelas, as parcelas somam
de volta o total, e nenhuma difere de outra em mais de um centavo. Em
`tests/test_money_properties.py`, escritas com a biblioteca Hypothesis:

```python
"""Properties of split that hold for every total and every number of parts."""
from hypothesis import given
from hypothesis import strategies as st

from shipquote.money import split

totals = st.integers(min_value=0, max_value=10_000_000)
parts = st.integers(min_value=1, max_value=24)


@given(totals, parts)
def test_the_instalments_add_back_up(cents, n):
    assert sum(split(cents, n)) == cents


@given(totals, parts)
def test_no_instalment_is_more_than_a_cent_from_another(cents, n):
    instalments = split(cents, n)
    assert max(instalments) - min(instalments) <= 1
```

`st.integers(...)` descreve as entradas: totais de zero a cem mil reais, de uma a 24 parcelas.
`@given` pede ao Hypothesis que chame o teste com valores tirados dessas faixas.

```
ana@laptop:~/shipquote$ python -m pytest tests/test_money_properties.py -v --hypothesis-show-statistics | grep -E "passed|examples|PASSED"
tests/test_money_properties.py::test_the_instalments_add_back_up PASSED  [ 50%]
tests/test_money_properties.py::test_no_instalment_is_more_than_a_cent_from_another PASSED [100%]
  - Stopped because settings.max_examples=100
  - Stopped because settings.max_examples=100
============================== 2 passed in 0.21s ===============================
```

Cada teste rodou cem exemplos, o padrão, e passou. O `split` atual é a versão com `divmod` da aula
1, e cumpre as duas propriedades.

## Uma propriedade pegando um defeito plausível

Aqui o `split` é trocado por uma versão que alguém escreveria com pressa: dividir, arredondar, e
deixar a última parcela absorver o que sobrar.

```
ana@laptop:~/shipquote$ git diff shipquote/money.py
diff --git a/shipquote/money.py b/shipquote/money.py
index 4c66e52..463f189 100644
--- a/shipquote/money.py
+++ b/shipquote/money.py
@@ -12,5 +12,5 @@ def split(cents: int, parts: int) -> list[int]:
     """Split a total into instalments that add back up; odd cents go first."""
     if parts < 1:
         raise ValueError(f"parts must be at least 1, got {parts}")
-    base, rest = divmod(cents, parts)
-    return [base + 1 if i < rest else base for i in range(parts)]
+    each = round(cents / parts)
+    return [each] * (parts - 1) + [cents - each * (parts - 1)]
ana@laptop:~/shipquote$ python -m pytest tests/test_money_properties.py -q --hypothesis-seed=0 2>&1 | grep -E "^(Falsifying|test_|    [a-z]|E  |FAILED|[0-9]+ (failed|passed))"
    def test_no_instalment_is_more_than_a_cent_from_another(cents, n):
E       assert (2 - 0) <= 1
E        +  where 2 = max([0, 0, 0, 2])
E        +  and   0 = min([0, 0, 0, 2])
E       Failing test case: test_no_instalment_is_more_than_a_cent_from_another(
E           cents=2,
E           n=4,
E       )
FAILED tests/test_money_properties.py::test_no_instalment_is_more_than_a_cent_from_another
1 failed, 1 passed in 0.24s
```

A primeira propriedade continua passando: a última parcela faz a soma bater por construção. A
segunda falha, e o Hypothesis relata **a menor entrada que conseguiu achar** que a quebra: 2 centavos
em 4 parcelas. `round(0.5)` é `0` em Python, que arredonda metades para o número par, então as três
primeiras parcelas são 0 e a última é 2. O Hypothesis não parou na primeira falha que encontrou;
**encolheu** (*shrinking*) a entrada com falha em direção à mais simples que ainda falha, e por isso
o exemplo é pequeno o bastante para conferir à mão.

Um exemplo escolhido à mão teria achado? `split(10000, 3)`, da aula 1, dá 3333, 3333, 3334 nesta
versão, e o teste existente, que espera `[3334, 3333, 3333]`, falha pela ordem. Mas um teste escrito
para esta versão teria usado o mesmo tipo de exemplo e passado. A propriedade não precisou de
nenhuma intuição sobre onde o arredondamento erra; precisou da regra.

## Repetindo uma falha

`--hypothesis-seed=0` fixou a semente desta captura para a execução poder ser repetida. Sem isso, o
Hypothesis ainda guarda os exemplos com falha num banco local, `.hypothesis/`, e os tenta primeiro
na execução seguinte, então uma falha achada uma vez continua falhando até ser corrigida.

## Onde propriedades se encaixam

Propriedades combinam com código cujas regras são fáceis de declarar e difíceis de enumerar:
aritmética como `split`, leitura e formatação que deveriam ir e voltar sem perda, ordenação,
qualquer coisa com uma inversa. Elas não substituem exemplos. Um exemplo diz que *esta* entrada dá
*aquela* saída, o que uma propriedade raramente fixa, e exemplos são de onde quem lê aprende o
comportamento. Os dois juntos são mais fortes que cada um: exemplos para os casos que você conhece,
propriedades para os que não passaram pela sua cabeça.
