---
title: Um portão que falha alto
version: 1
---

A candidata que mudou o modelo e o piso:

```
ana@lab:~/obs$ CANDIDATE=2026.10.4 python -m pytest -q --tb=line -p no:cacheprovider tests
.FFF.....                                                                [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: checks the candidate newly fails: {'e38': ['short_enough']}
    assert not {'e38': ['short_enough']}
/home/ana/obs/tests/test_regression.py:31: AssertionError: checks the candidate newly fails: {'e38': ['short_enough']}
E   AssertionError: cost 0.00944242 -> 0.0416189, +341%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 3.407653970062759 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: cost 0.00944242 -> 0.0416189, +341%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
E   AssertionError: median_ms 94.9369 -> 1037.31, +993%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 9.9262832086127 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: median_ms 94.9369 -> 1037.31, +993%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_no_check_newly_fails - AssertionError: ...
FAILED tests/test_regression.py::test_within_budget[cost] - AssertionError: c...
FAILED tests/test_regression.py::test_within_budget[median_ms] - AssertionErr...
3 failed, 6 passed in 83.29s (0:01:23)
```

Três falhas, cada uma com a sua frase: a verificação do e38 agora falha, o custo subiu 341%, a latência
mediana ficou quase dez vezes maior. Nada no `gate.json` as aceita, então o pull request que propõe esta
versão não pode fazer merge até alguém mudar a candidata ou escrever por que cada uma é aceitável.

## Um portão que não passa por não rodar

O jeito mais comum de um portão parar de proteger qualquer coisa não é um teste fraco: é um teste que, em
silêncio, não rodou. Uma variável faltando num pipeline novo, um skip acrescentado durante uma pane e
nunca tirado, uma condição falsa num branch que ninguém testou. Aqui está o portão sem nenhuma candidata
nomeada:

```
ana@lab:~/obs$ python -m pytest -q --tb=line -p no:cacheprovider tests
EEEE.....                                                                [100%]Running teardown with pytest sessionfinish...

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
5 passed, 4 errors in 4.89s
```

**Quatro erros, não quatro skips.** O pytest relata um erro na preparação como uma falha da execução: o
resumo fica vermelho e o código de saída não é zero, então o pipeline falha. Os testes do próprio conjunto
ainda rodaram e passaram, porque não precisam de candidata. Se o `conftest.py` tivesse chamado
`pytest.skip`, a mesma execução teria impresso um resumo verde sobre quatro testes que não conferiram
nada, e todo pull request depois dele teria feito merge nesse verde.

As regras que isso segue são as que este repositório aplica a si mesmo:

- **Um portão falha quando não consegue rodar.** Uma variável faltando, um conjunto faltando, um manifesto
  que não bate: cada um é um erro que nomeia o que falta.
- **Nenhum teste é pulado para chegar ao verde.** Um teste errado é corrigido; um certo e falhando é o
  portão fazendo o seu trabalho.
- **Uma falha diz o que fazer.** Toda asserção nestes arquivos termina com o próximo passo.
