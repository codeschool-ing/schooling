---
title: Uma decisão num arquivo
version: 1
---

A candidata que uma equipe lançaria, a 2026.10.3 da aula 14, pelo mesmo portão:

```
ana@lab:~/obs$ CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests
..FF.....                                                                [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: cost 0.00944242 -> 0.0182159, +93%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 0.9291579912776597 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: cost 0.00944242 -> 0.0182159, +93%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
E   AssertionError: median_ms 91.8558 -> 644.412, +602%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 6.015471020630091 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: median_ms 91.8558 -> 644.412, +602%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_within_budget[cost] - AssertionError: c...
FAILED tests/test_regression.py::test_within_budget[median_ms] - AssertionErr...
2 failed, 7 passed in 68.03s (0:01:08)
```

**Ela falha, e o portão tem razão de reprová-la.** Contra a produção ela é 93% mais cara e seis vezes mais
lenta. Os dois orçamentos são medidos contra a versão em produção, e a versão em produção é a quebrada:
ela era barata e rápida porque recusava. O portão não tem como saber disso. Uma pessoa tem, e o trabalho
do portão é fazê-la dizer isso onde vai ser lido.

Então a decisão vai para o `gate.json`, sob o nome da candidata, com um teto e um motivo:

```
ana@lab:~/obs$ cat gate.json
{
  "set": "data/eval-v2.jsonl",
  "manifest": "data/eval-v2.manifest.json",
  "budgets": {"cost": 0.25, "median_ms": 0.25},
  "accepted": {
    "2026.10.3": {
      "cost": {"up_to": 1.0, "why": "answers the five questions 2026.10.1 refused; costs what 2026.09.4 did"},
      "median_ms": {"up_to": 7.0, "why": "the same: 2026.10.1 was fast because it refused"}
    }
  }
}
```

O mesmo comando agora passa:

```
ana@lab:~/obs$ CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests
.........                                                                [100%]Running teardown with pytest sessionfinish...

9 passed in 76.90s (0:01:16)
```

Três propriedades tornam isso melhor do que subir o orçamento:

- **A exceção pertence a uma candidata.** A próxima versão volta a ter 25%; ninguém herda um orçamento
  que subiu por um motivo que não vale mais.
- **O motivo fica escrito ao lado do número**, no repositório, e mudanças nele chegam num pull request
  como código. Quem revisa lê "answers the five questions 2026.10.1 refused" e pode discordar.
- **O teto continua sendo um teto.** O custo pode subir até 100%, não qualquer coisa; uma candidata que
  acabasse custando três vezes mais voltaria a falhar.

O mesmo arquivo aceita um caso quebrado, em `broken`, com o id do caso e o motivo de ele ser aceitável. Um
caso quebrado aceito assim foi lido, que é a regra da aula 14; um que não está no arquivo não foi, e o
portão diz isso.
