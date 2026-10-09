---
title: Um portão que falha alto
version: 2
---

A candidata que mudou o modelo e o piso:

```
ana@dev:~/obs$ CANDIDATE=2026.10.4 python -m pytest -q --tb=line -p no:cacheprovider tests
FF........                                                               [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: 2026.10.4 breaks ['e03', 'e09', 'e10', 'e11', 'e13', 'e18', 'e31'] against 2026.10.1: read each one, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e03', 'e09', 'e10', 'e11', 'e13', 'e18', ...]
/home/ana/obs/tests/test_regression.py:23: AssertionError: 2026.10.4 breaks ['e03', 'e09', 'e10', 'e11', 'e13', 'e18', 'e31'] against 2026.10.1: read each one, then fix the candidate or accept the case in gate.json with the reason
E   AssertionError: 2026.10.4 newly fails a check on ['e02', 'e03', 'e04', 'e05', 'e06', 'e07', 'e08', 'e10', 'e11', 'e12', 'e13', 'e15', 'e16', 'e17', 'e18', 'e19', 'e26', 'e28', 'e29', 'e32']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e02', 'e03', 'e04', 'e05', 'e06', 'e07', ...]
/home/ana/obs/tests/test_regression.py:30: AssertionError: 2026.10.4 newly fails a check on ['e02', 'e03', 'e04', 'e05', 'e06', 'e07', 'e08', 'e10', 'e11', 'e12', 'e13', 'e15', 'e16', 'e17', 'e18', 'e19', 'e26', 'e28', 'e29', 'e32']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_no_case_that_production_answers_is_broken
FAILED tests/test_regression.py::test_no_check_newly_fails - AssertionError: ...
2 failed, 8 passed in 190.92s (0:03:10)
```

Duas falhas, e a segunda é uma linha nomeando vinte casos. É o quanto uma mensagem de teste deve
carregar. Qual verificação cada caso falha é pergunta para o `regress.py`, que lê as duas execuções que o
portão acabou de fazer:

```
ana@dev:~/obs$ python regress.py production candidate | head -12
data/eval-v2.jsonl sha256 8763ed310b27: 2026.10.1 -> 2026.10.4
               both right  both wrong  fixed  broken
  dev                  8           6      4       4
  held-out             5           2      0       3
exact McNemar p = 0.5488 on 11 changed verdicts
  broken e10 dev      How long does a pickup point keep my parcel?
  broken e11 dev      On how many devices can I read my e-books?
  broken e13 dev      Can I listen to an audiobook without an internet connect
  broken e31 dev      Order MG-00000003 - I want to return it. Who pays for th
  broken e03 held-out How long after my return arrives will I get the refund?
  broken e09 held-out When is a standard parcel considered lost?
  broken e18 held-out What happens if my order costs more than my gift card ho
EXIT 0
```

Nada no `gate.json` aceita nada disso, então o pull request que propõe esta versão não pode ser mesclado
até alguém mudar a candidata ou escrever, caso a caso, por que cada um é aceitável. Vinte e sete frases
seriam uma coisa estranha de escrever para uma versão, e é esse o ponto: o esforço de aceitar uma mudança
cresce com o quanto ela quebra.

**Os orçamentos passaram**, porque a 2026.10.4 é mais barata que a produção e, nesta execução, no máximo
25% mais lenta. Na aula 14 a mesma comparação a mediu 17% mais lenta, e uma execução anterior deste
mesmo portão mediu 30%, e reprovou. Uma mediana de 32 respostas numa máquina varia isso de execução para
execução, então um orçamento de latência posto perto do ruído passa e reprova ao acaso. Ou o orçamento é
mais largo que o ruído, ou a medida é feita de mais requisições.

## Um portão que não pode passar por não rodar

O jeito mais comum de um portão parar de proteger qualquer coisa não é um teste fraco: é um teste que
silenciosamente não rodou. Uma variável faltando num pipeline novo, um skip acrescentado durante uma
queda e nunca removido, uma condição que é falsa num branch que ninguém testou. Eis o portão sem
candidata nomeada:

```
ana@dev:~/obs$ python -m pytest -q --tb=line -p no:cacheprovider tests
EEEE......                                                               [100%]Running teardown with pytest sessionfinish...

==================================== ERRORS ====================================
_______ ERROR at setup of test_no_case_that_production_answers_is_broken _______
E   pytest.UsageError: CANDIDATE is not set: name the release this change would ship
_________________ ERROR at setup of test_no_check_newly_fails __________________
E   pytest.UsageError: CANDIDATE is not set: name the release this change would ship
__________________ ERROR at setup of test_within_budget[cost] __________________
E   pytest.UsageError: CANDIDATE is not set: name the release this change would ship
_______________ ERROR at setup of test_within_budget[median_ms] ________________
E   pytest.UsageError: CANDIDATE is not set: name the release this change would ship
=========================== short test summary info ============================
ERROR tests/test_regression.py::test_no_case_that_production_answers_is_broken
ERROR tests/test_regression.py::test_no_check_newly_fails - pytest.UsageError...
ERROR tests/test_regression.py::test_within_budget[cost] - pytest.UsageError:...
ERROR tests/test_regression.py::test_within_budget[median_ms] - pytest.UsageE...
6 passed, 4 errors in 6.21s
```

**Quatro erros, não quatro skips.** O pytest relata um erro no setup como uma falha da execução: o resumo
fica vermelho e o código de saída é diferente de zero, então o pipeline falha. Os testes do próprio
conjunto rodaram e passaram, porque não precisam de candidata. Se o `conftest.py` tivesse chamado
`pytest.skip`, a mesma execução teria impresso um resumo verde sobre quatro testes que não verificaram
nada, e todo pull request depois dele teria sido mesclado naquele verde.

As regras que isto segue são as que este repositório cobra de si mesmo:

- **Um portão falha quando não consegue rodar.** Uma variável faltando, um conjunto faltando, um
  manifesto que não bate: cada um é um erro que nomeia o que falta.
- **Nenhum teste é pulado para chegar ao verde.** Um teste errado é consertado; um certo que falha é o
  portão fazendo o seu trabalho.
- **Uma falha diz o que fazer.** Toda asserção nestes arquivos termina com o próximo passo.
