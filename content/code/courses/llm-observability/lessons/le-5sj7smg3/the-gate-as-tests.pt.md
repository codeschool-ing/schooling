---
title: O portão como testes
version: 1
---

O portão são três arquivos de testes e um arquivo de decisões:

```
ana@lab:~/obs$ find tests -name "*.py" | sort; cat gate.json
tests/conftest.py
tests/test_regression.py
tests/test_set.py
{
  "set": "data/eval-v2.jsonl",
  "manifest": "data/eval-v2.manifest.json",
  "budgets": {"cost": 0.25, "median_ms": 0.25},
  "accepted": {}
}
```

O `gate.json` guarda o que uma pessoa decide e um programa aplica: qual conjunto, o seu manifesto, os
orçamentos de custo e de latência mediana como parcela dos da produção, e uma lista vazia de exceções
aceitas, que a próxima seção preenche.

O `tests/conftest.py` guarda o que todo teste de regressão precisa. A candidata precisa ser nomeada, pela
variável `CANDIDATE`. A produção é a versão no ar agora, a não ser que `PRODUCTION` nomeie outra. E as
duas respondem ao conjunto **na mesma execução**, então um modelo que mudou durante a noite, ou um preço
que mudou, aparece nas duas e se anula:

```python
"""The gate's shared pieces: the gate file, the set, and the two runs every regression test compares.

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
```

O `tests/test_set.py` é a verificação da aula 13, um teste por propriedade, cada um falhando com uma frase
que diz o que fazer:

```python
"""The evaluation set itself: lesson 13's checks, as tests. No model is called."""
import hashlib
import json
import logging
import re

from presidio_analyzer import AnalyzerEngine

import docs
import redact
from conftest import GATE

logging.disable(logging.WARNING)   # tldextract warns that it could not fetch a list; it uses its own copy
MANIFEST = json.load(open(GATE["manifest"]))
SHOP = docs.load()


def test_the_set_is_the_version_the_manifest_pins():
    digest = hashlib.sha256(open(GATE["set"], "rb").read()).hexdigest()
    assert digest == MANIFEST["sha256"], (
        f"{GATE['set']} is not the version its manifest pins: build it with buildset.py and commit both")


def test_no_id_is_used_twice(cases):
    ids = [line["id"] for line in map(json.loads, open(GATE["set"]))]
    assert len(ids) == len(set(ids)) == len(cases)


def test_every_fact_is_in_its_gold_section(cases):
    squash = lambda t: re.sub(r"\s+", " ", re.sub(r"[^\w\s.]", " ", t.lower())).strip()
    false = [i for i, c in cases.items() if c["facts"]
             and not any(squash(f) in squash(" ".join(SHOP[d][1].get(h, "") for d, h in c["gold"])) for f in c["facts"])]
    assert not false, f"no longer true of the documents: {false}. Retire them and write new cases"


def test_every_document_is_at_the_pinned_version():
    moved = [d for d, v in MANIFEST["documents"].items() if SHOP[d][0]["version"] != v]
    assert not moved, f"changed since the set was checked: {moved}. Re-check the cases that rest on them"


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
"""The candidate against production on the set: lesson 14's rules, as tests."""
import statistics

import pytest

import checks
import costs
from conftest import GATE
from facts import normalised


def right(r, cases):
    return normalised(r["reply"], cases[r["id"]]["facts"])


def failing(r):
    return {n for n, ok, _ in checks.run(r["reply"], r["sources"]) if not ok}


def test_no_case_that_production_answers_is_broken(runs, cases, releases):
    accepted = GATE["accepted"].get(releases[1], {}).get("broken", {})
    broken = [i for i in cases if right(runs["production"][i], cases) and not right(runs["candidate"][i], cases)]
    unread = [i for i in broken if i not in accepted]
    assert not unread, (f"{releases[1]} breaks {unread} against {releases[0]}: read each one, then fix the "
                        "candidate or accept the case in gate.json with the reason")


def test_no_check_newly_fails(runs, cases):
    new = {i: sorted(failing(runs["candidate"][i]) - failing(runs["production"][i])) for i in cases}
    new = {i: n for i, n in new.items() if n}
    assert not new, f"checks the candidate newly fails: {new}"


@pytest.mark.parametrize("measure", ["cost", "median_ms"])
def test_within_budget(runs, releases, measure):
    spent = {r["trace"]: r for r in costs.requests("eval-spans.jsonl")}
    total = {"cost": lambda run: sum(spent[r["trace"]]["cost"] for r in run.values()),
             "median_ms": lambda run: statistics.median(spent[r["trace"]]["ms"] for r in run.values())}[measure]
    before, after = float(total(runs["production"])), float(total(runs["candidate"]))
    accepted = GATE["accepted"].get(releases[1], {}).get(measure)
    ceiling = accepted["up_to"] if accepted else GATE["budgets"][measure]
    change = (after - before) / before
    assert change <= ceiling, (f"{measure} {before:.6g} -> {after:.6g}, {change:+.0%}, over the {ceiling:+.0%} "
                               "budget: make it cheaper, or accept it in gate.json with the reason")
```

## O teste que ninguém rodou em 2 de outubro

Rodado com a produção de volta em 2026.09.4 e a versão do piso como candidata:

```
ana@lab:~/obs$ PRODUCTION=2026.09.4 CANDIDATE=2026.10.1 python -m pytest -q --tb=line -p no:cacheprovider tests
F........                                                                [100%]Running teardown with pytest sessionfinish...

=================================== FAILURES ===================================
E   AssertionError: 2026.10.1 breaks ['e07', 'e17', 'e24', 'e38', 'e42'] against 2026.09.4: read each one, then fix the candidate or accept the case in gate.json with the reason
    assert not ['e07', 'e17', 'e24', 'e38', 'e42']
/home/ana/obs/tests/test_regression.py:24: AssertionError: 2026.10.1 breaks ['e07', 'e17', 'e24', 'e38', 'e42'] against 2026.09.4: read each one, then fix the candidate or accept the case in gate.json with the reason
=========================== short test summary info ============================
FAILED tests/test_regression.py::test_no_case_that_production_answers_is_broken
1 failed, 8 passed in 71.66s (0:01:11)
```

**Um teste falha, e a mensagem dele é a decisão.** Ela nomeia os cinco casos, as duas versões, e as duas
saídas: consertar a candidata, ou aceitar cada caso por escrito. É o formato que o próprio
`validate-content` deste repositório usa nos seus erros, e pela mesma razão: uma falha que diz o que
fazer é corrigida, e uma que diz só "falhou" é rodada de novo.

A linha sobre um teardown depois dos pontos não é do portão. Ela vem do DeepEval, que a aula 12
instalou: o pacote dele registra um plugin de pytest, e toda execução de pytest neste ambiente o carrega.
Aqui isso é inofensivo e vale saber: uma biblioteca de avaliação pode entrar numa suíte de testes sem
ninguém tê-la acrescentado a uma.
