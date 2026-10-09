---
title: Uma decisão num arquivo
version: 2
---

A candidata que uma equipe poria no ar, a 2026.10.3 da aula 14, pelo mesmo portão:

```
ana@dev:~/obs$ CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests
FFFF......                                                               [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: 2026.10.3 breaks ['e12', 'e29'] against 2026.10.1: read each one, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e12', 'e29']
/home/ana/obs/tests/test_regression.py:23: AssertionError: 2026.10.3 breaks ['e12', 'e29'] against 2026.10.1: read each one, then fix the candidate or accept the case in gate.json with the reason
E   AssertionError: 2026.10.3 newly fails a check on ['e02', 'e13', 'e14', 'e30']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e02', 'e13', 'e14', 'e30']
/home/ana/obs/tests/test_regression.py:30: AssertionError: 2026.10.3 newly fails a check on ['e02', 'e13', 'e14', 'e30']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
E   AssertionError: cost 0.00876128 -> 0.0130408, +49%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 0.48845602469045624 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: cost 0.00876128 -> 0.0130408, +49%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
E   AssertionError: median_ms 2486.21 -> 3354.84, +35%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
    assert 0.3493795226594898 <= 0.25
/home/ana/obs/tests/test_regression.py:43: AssertionError: median_ms 2486.21 -> 3354.84, +35%, over the +25% budget: make it cheaper, or accept it in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_no_case_that_production_answers_is_broken
FAILED tests/test_regression.py::test_no_check_newly_fails - AssertionError: ...
FAILED tests/test_regression.py::test_within_budget[cost] - AssertionError: c...
FAILED tests/test_regression.py::test_within_budget[median_ms] - AssertionErr...
4 failed, 6 passed in 186.37s (0:03:06)
```

**Quatro falhas, e o portão tem razão em todas.** Os dois casos que o piso consertou, e12 e e29, quebram
de novo. Quatro respostas, certas pelos seus fatos, agora trazem uma frase que não cita nada. E em
relação à produção ela é 49% mais cara e 35% mais lenta. Os orçamentos são medidos contra a versão em
produção, e a versão em produção é a quebrada: era barata e rápida porque recusava. O portão não tem
como saber disso. Uma pessoa tem, e o trabalho do portão é fazer a pessoa dizer isso onde vai ser lido.

Então as decisões vão para o `gate.json`, sob o nome da candidata: cada caso pelo seu id com o motivo de
ser aceitável, e cada orçamento com um teto e um motivo. Substitua o arquivo por:

```json
{
  "set": "data/eval-v2.jsonl",
  "manifest": "data/eval-v2.manifest.json",
  "budgets": {"cost": 0.25, "median_ms": 0.25},
  "accepted": {
    "2026.10.3": {
      "broken": {
        "e12": "refused with the Kindle chunk among three, as 2026.09.4 did; the next release looks at it",
        "e29": "refused with the return-window chunk among three, as 2026.09.4 did; the same"
      },
      "checks": {
        "e02": "right; a second sentence draws a conclusion and cites nothing",
        "e13": "right; a second sentence draws a conclusion and cites nothing",
        "e14": "right; the first sentence answers yes and cites nothing",
        "e30": "right; it repeats the customer's 12 working days, which no source says"
      },
      "cost": {"up_to": 0.75, "why": "answers the seven questions 2026.10.1 refused; costs what 2026.09.4 did"},
      "median_ms": {"up_to": 0.75, "why": "the same: 2026.10.1 was fast because it refused"}
    }
  }
}
```

```
ana@dev:~/obs$ CANDIDATE=2026.10.3 python -m pytest -q --tb=line -p no:cacheprovider tests
..........                                                               [100%]Running teardown with pytest sessionfinish...

10 passed in 180.68s (0:03:00)
```

O mesmo comando agora passa. Três propriedades tornam isso melhor do que subir os orçamentos ou apagar os
casos:

- **A exceção pertence a uma candidata.** A próxima versão volta a ser medida pelos 25% e por todos os
  casos, e ninguém herda uma exceção concedida por um motivo que não vale mais.
- **O motivo está escrito ao lado do caso ou do número**, no repositório, e mudanças nele chegam num pull
  request como código. Quem revisa lê "refused with the Kindle chunk among three, as 2026.09.4 did" e
  pode discordar.
- **O teto continua sendo um teto, e a lista continua sendo uma lista.** O custo pode subir até 75%, não
  qualquer coisa. Um terceiro caso quebrando, ou uma quinta resposta falhando uma verificação, reprova o
  portão de novo.

Um caso quebrado aceito assim foi lido, que é a regra da aula 14; um que não está no arquivo não foi, e o
portão diz isso.
