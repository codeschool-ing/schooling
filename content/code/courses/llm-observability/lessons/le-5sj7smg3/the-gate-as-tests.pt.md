---
title: O portão em forma de testes
version: 2
---

O portão são testes de pytest: três arquivos numa pasta `tests`, e um arquivo de decisões ao lado deles.
O pytest entrou no ambiente com o DeepEval na aula 12; se você pulou essa aula, instale-o:

```sh
pip install pytest==9.1.1
```

O `gate.json` guarda o que uma pessoa decide e um programa impõe: qual conjunto, o seu manifesto, os
orçamentos de custo e de latência mediana como fração dos da produção, e uma lista vazia de exceções
aceitas, que a próxima seção preenche. Salve-o em `~/obs`:

```json
{
  "set": "data/eval-v2.jsonl",
  "manifest": "data/eval-v2.manifest.json",
  "budgets": {"cost": 0.25, "median_ms": 0.25},
  "accepted": {}
}
```

O `tests/conftest.py` guarda o que todo teste de regressão precisa. A candidata tem de ser nomeada, pela
variável `CANDIDATE`. A produção é a versão no ar agora, a menos que `PRODUCTION` nomeie outra. As duas
respondem ao conjunto **na mesma execução**, então um modelo que mudou durante a noite, ou um preço que
mudou, aparece nas duas e se cancela. E `accepted` lê as decisões do `gate.json` para a candidata:

```python
"""tests/conftest.py: the gate's shared pieces: the gate file, the set, and the two runs every regression test compares.

PRODUCTION is the release live now unless the variable names another; CANDIDATE must be named.
"""
import json
import os
import subprocess
from datetime import datetime

import pytest

import assistant

GATE = json.load(open("gate.json"))


@pytest.fixture(scope="session")
def cases():
    return {c["id"]: c for c in map(json.loads, open(GATE["set"]))}


@pytest.fixture(scope="session")
def releases():
    candidate = os.environ.get("CANDIDATE")
    if not candidate:
        raise pytest.UsageError("CANDIDATE is not set: name the release this change would ship")
    production = os.environ.get("PRODUCTION") or assistant.release_at(datetime.now().isoformat())[0]
    return production, candidate


@pytest.fixture(scope="session")
def runs(releases):
    """Both releases answer the set now, so a drift in the model or the prices shows in both."""
    out = {}
    for role, release in zip(("production", "candidate"), releases):
        subprocess.run(["python", "evalrun.py", role, "--set", GATE["set"], "--release", release],
                       check=True, capture_output=True)
        out[role] = {r["id"]: r for r in map(json.loads, open(f"runs/{role}.jsonl"))}
    return out


def accepted(releases, kind):
    """What gate.json accepts for the candidate under KIND: cases by id for broken and checks, a ceiling for a budget."""
    return GATE["accepted"].get(releases[1], {}).get(kind, {})
```

O `tests/test_set.py` é o `check_set.py` da aula 13, um teste por propriedade, cada um falhando com uma
frase que diz o que fazer:

```python
"""tests/test_set.py: the evaluation set itself, lesson 13's checks as tests. No model is called."""
import hashlib
import json
import logging
import re

from presidio_analyzer import AnalyzerEngine

import docs
import redact
from conftest import GATE

logging.disable(logging.WARNING)   # Presidio warns about every recogniser it loads; none of it is news here
MANIFEST = json.load(open(GATE["manifest"]))
SHOP = docs.load()
CHUNKS = {cid: text for _, found in SHOP.values() for cid, text in found.items()}


def test_the_set_is_the_version_the_manifest_pins():
    digest = hashlib.sha256(open(GATE["set"], "rb").read()).hexdigest()
    assert digest == MANIFEST["sha256"], (
        f"{GATE['set']} is not the version its manifest pins: build it with buildset.py and commit both")


def test_no_id_is_used_twice(cases):
    ids = [line["id"] for line in map(json.loads, open(GATE["set"]))]
    assert len(ids) == len(set(ids)) == len(cases)


def test_every_gold_chunk_exists(cases):
    missing = {i: [g for g in c["gold"] if g not in CHUNKS] for i, c in cases.items()}
    missing = {i: m for i, m in missing.items() if m}
    assert not missing, f"gold chunks no document has any more: {missing}. Point the cases at the new ones"


def test_every_fact_is_in_its_gold_chunks(cases):
    squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.$]", " ", t.lower())).strip()
    false = [i for i, c in cases.items() if c["facts"] and all(g in CHUNKS for g in c["gold"])
             and not any(squash(f) in squash(" ".join(CHUNKS[g] for g in c["gold"])) for f in c["facts"])]
    assert not false, f"no longer true of the documents: {false}. Retire them and write new cases"


def test_no_document_was_updated_after_the_set_was_checked():
    moved = [d for d, updated in MANIFEST["documents"].items() if SHOP[d][0]["updated"] != updated]
    assert not moved, f"updated since the set was checked: {moved}. Re-check the cases that rest on them"


def test_no_question_holds_personal_data(cases):
    analyzer = AnalyzerEngine()
    found = {}
    for i, c in cases.items():
        hits = {c["question"][r.start:r.end] for r in analyzer.analyze(c["question"], language="en",
                                                                         entities=["PERSON", "EMAIL_ADDRESS", "PHONE_NUMBER"])}
        hits |= {m.group() for _, p in redact.PATTERNS for m in p.finditer(c["question"])}
        if hits - set(c.get("synthetic", [])):
            found[i] = sorted(hits - set(c.get("synthetic", [])))
    assert not found, f"personal data in the set: {found}. Replace it, or declare an invented value synthetic"
```

O `tests/test_regression.py` são as regras da aula 14:

```python
"""tests/test_regression.py: the candidate against production on the set, lesson 14's rules as tests."""
import statistics

import pytest

import checks
import costs
from conftest import GATE, accepted
from facts import normalised


def right(r, cases):
    return normalised(r["reply"], cases[r["id"]]["facts"])


def failing(r):
    return {n for n, ok, _ in checks.run(r["reply"], r["sources"]) if not ok}


def test_no_case_that_production_answers_is_broken(runs, cases, releases):
    broken = [i for i in cases if right(runs["production"][i], cases) and not right(runs["candidate"][i], cases)]
    unread = [i for i in broken if i not in accepted(releases, "broken")]
    assert not unread, (f"{releases[1]} breaks {unread} against {releases[0]}: read each one, then fix the "
                        "candidate or accept the case in gate.json with the reason")


def test_no_check_newly_fails(runs, cases, releases):
    new = [i for i in cases if failing(runs["candidate"][i]) - failing(runs["production"][i])]
    unread = [i for i in new if i not in accepted(releases, "checks")]
    assert not unread, (f"{releases[1]} newly fails a check on {unread}: python regress.py production candidate "
                        "names each one. Read each reply, then fix the candidate or accept the case in gate.json "
                        "with the reason")


@pytest.mark.parametrize("measure", ["cost", "median_ms"])
def test_within_budget(runs, releases, measure):
    spent = {r["trace"]: r for r in costs.requests("eval-spans.jsonl")}
    total = {"cost": lambda run: sum(spent[r["trace"]]["cost"] for r in run.values()),
             "median_ms": lambda run: statistics.median(spent[r["trace"]]["ms"] for r in run.values())}[measure]
    before, after = float(total(runs["production"])), float(total(runs["candidate"]))
    ceiling = accepted(releases, measure).get("up_to", GATE["budgets"][measure])
    change = (after - before) / before
    assert change <= ceiling, (f"{measure} {before:.6g} -> {after:.6g}, {change:+.0%}, over the {ceiling:+.0%} "
                               "budget: make it cheaper, or accept it in gate.json with the reason")
```

```
ana@dev:~/obs$ find tests -name "*.py" | sort
tests/conftest.py
tests/test_regression.py
tests/test_set.py
```

## O teste que ninguém rodou em 1º de outubro

Rodado com a produção de volta na 2026.09.4 e a versão do piso como candidata:

```
ana@dev:~/obs$ PRODUCTION=2026.09.4 CANDIDATE=2026.10.1 python -m pytest -q --tb=line -p no:cacheprovider tests
FF........                                                               [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: 2026.10.1 breaks ['e02', 'e04', 'e14', 'e16', 'e19', 'e30', 'e32'] against 2026.09.4: read each one, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e02', 'e04', 'e14', 'e16', 'e19', 'e30', ...]
/home/ana/obs/tests/test_regression.py:23: AssertionError: 2026.10.1 breaks ['e02', 'e04', 'e14', 'e16', 'e19', 'e30', 'e32'] against 2026.09.4: read each one, then fix the candidate or accept the case in gate.json with the reason
E   AssertionError: 2026.10.1 newly fails a check on ['e29']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e29']
/home/ana/obs/tests/test_regression.py:30: AssertionError: 2026.10.1 newly fails a check on ['e29']: python regress.py production candidate names each one. Read each reply, then fix the candidate or accept the case in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_no_case_that_production_answers_is_broken
FAILED tests/test_regression.py::test_no_check_newly_fails - AssertionError: ...
2 failed, 8 passed in 177.28s (0:02:57)
```

**Dois testes falham, e as mensagens deles são a decisão.** O primeiro nomeia os sete casos, as duas
versões, e as duas saídas: consertar a candidata, ou aceitar cada caso por escrito. O segundo nomeia a
e29, a mensagem de pedido que a versão do piso agora responde com uma frase sem citação, e diz onde ver
qual verificação: o `regress.py` da aula 14 lê as duas execuções que o portão acabou de fazer. É o
formato que o próprio `validate-content` deste repositório usa nos seus erros, e pelo mesmo motivo: uma
falha que diz o que fazer é consertada, e uma que diz só "falhou" é rodada de novo.

**Os orçamentos passam.** A versão do piso era mais barata e mais rápida que a anterior, então nenhum
orçamento tinha o que dizer. Só os casos tinham, que é a primeira regra da aula 14 imposta por um
programa.

A linha sobre um teardown depois dos pontos não é do portão. Vem do DeepEval, que a aula 12 instalou: o
pacote dele registra um plugin do pytest, e toda execução do pytest neste ambiente o carrega. Aqui isso é
inofensivo e vale saber: uma biblioteca de avaliação pode entrar numa suíte de testes sem ninguém tê-la
acrescentado.
