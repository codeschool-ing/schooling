---
title: Um modelo que confere a si mesmo
version: 1
---

A aula 14 terminou com um achado cuja causa era "a checagem só roda quando alguém lembra". A
correção para essa causa é o modelo conferir a si mesmo, toda vez que muda e numa agenda, e a
checagem falhar alto o bastante para alguém precisar agir.

Tudo o que é preciso já está no repositório. O `trace.py` sabe quais ameaças não têm requisito, o
`acceptances.py` sabe quais revisões vencem, e o pytm sabe quais elementos o modelo tem. O
`check_model.py` junta os três e devolve um código de saída sobre o qual um sistema de CI consegue
agir:

```schooling-example
{"language": "python", "file": "check_model.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The checks every change to the model has to pass, and the ones it is known to fail.\n\n    python3 check_model.py              against today's date\n    python3 check_model.py 2026-10-12   against another date\n\nA problem listed in baseline.txt is known and reported; any other fails the check. So does a\nline in baseline.txt that is no longer a problem, because a stale exception reads as a real one.\n\"\"\"\nimport csv\nimport datetime\nimport json\nimport pathlib\nimport sys\n\ntoday = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today()\n", "note": "Uma data na linha de comando, como no acceptances.py, para uma execução poder ser repetida e uma data futura ser testada de propósito."}, {"code": "\ndef front_matter(path):\n    lines = path.read_text().split(\"\\n\")\n    end = lines.index(\"---\", 1)\n    return dict(line.split(\": \", 1) for line in lines[1:end])\n\n"}, {"code": "model = json.load(open(\"model.json\"))\nelements = {e[\"name\"] for kind in (\"actors\", \"assets\", \"flows\", \"boundaries\") for e in model[kind]}\nthreats = list(csv.DictReader(open(\"threats.csv\")))\nrequirements = list(csv.DictReader(open(\"requirements.csv\")))\ndecisions = [front_matter(p) for p in sorted(pathlib.Path(\"decisions\").glob(\"*.md\"))]\nsuperseded = {d[\"supersedes\"] for d in decisions if \"supersedes\" in d}\ncurrent = [d for d in decisions if d[\"id\"] not in superseded]\n", "note": "Tudo o que o modelo guarda, lido de novo a cada execução: os elementos que o pytm escreveu em model.json, as ameaças, os requisitos e as decisões. Uma decisão nomeada no campo supersedes de outra deixa de ser vigente."}, {"code": "problems = []\nfor t in threats:\n    if t[\"element\"] not in elements:\n        problems.append(f\"{t['id']}: names {t['element']!r}, which is not in the model\")", "note": "Uma ameaça que nomeia um elemento que o modelo não tem mais. É a junção por nome de que a aula 2 avisou, conferida em vez de confiada."}, {"code": "covered = {tid for r in requirements for tid in r[\"threats\"].split()}\ndecided = {d[\"threat\"] for d in current}\nfor t in threats:\n    if t[\"id\"] not in covered | decided:\n        problems.append(f\"{t['id']}: no requirement and no decision\")", "note": "Uma ameaça sem requisito e sem decisão vigente está aberta: ninguém disse o que acontece com ela."}, {"code": "for r in requirements:\n    if not r[\"verified by\"]:\n        problems.append(f\"{r['id']}: not verified\")", "note": "Um requisito que ninguém verifica é uma promessa."}, {"code": "for d in current:\n    if datetime.date.fromisoformat(d[\"review by\"]) < today:\n        problems.append(f\"{d['id']}: review overdue since {d['review by']}\")\n", "note": "Uma decisão vigente depois da data de revisão. É a única checagem que falha sem mudança nenhuma, só com uma data."}, {"code": "baseline = [line for line in open(\"baseline.txt\").read().split(\"\\n\") if line]\nnew = [p for p in problems if p not in baseline]\nstale = [b for b in baseline if b not in problems]\nfor p in problems:\n    print((\"known  \" if p in baseline else \"NEW    \") + p)\nfor b in stale:\n    print(f\"STALE  {b}: fixed, so remove it from baseline.txt\")\nprint(f\"{len(threats)} threats, {len(requirements)} requirements, {len(current)} current decisions:\"\n      f\" {len(new)} new, {len(stale)} stale, {len(problems) - len(new)} known\")\nsys.exit(1 if new or stale else 0)", "note": "Compara com o baseline nos dois sentidos. Um problema novo falha; uma linha do baseline que já não é problema também, porque uma exceção de que ninguém precisa mais continua parecendo uma de que alguém precisa."}]}
```

### O baseline

Um modelo nunca está livre de problemas. O R14 e o R17 ainda não têm verificação, e isso se sabe
desde a aula 8. Uma checagem que falhasse por eles falharia em toda execução, e uma checagem que
sempre falha é ignorada antes do fim da primeira semana.

Então os problemas conhecidos ficam escritos, em `baseline.txt`, e a checagem só falha pelos que não
estão:

```
(.venv) ana@vm:~/tm/portal-model$ cat baseline.txt
R14: not verified
R17: not verified
```

**Acrescentar uma linha ao baseline é uma decisão, tomada num pull request onde alguém pode vê-la.**
Essa é a diferença entre um baseline e desligar uma checagem: toda exceção tem uma linha, um commit
e um autor, e a lista não cresce sem ninguém perceber.

A checagem também falha no outro sentido. Uma linha do baseline que não é mais problema está
**velha**, e a checagem falha por ela até a linha ser removida. Sem isso, o R14 poderia ser
verificado no mês que vem e a linha dele ficar no baseline por anos, e alguém lendo o arquivo
acreditaria que o R14 continua sem verificação.

### A primeira execução falha

A ana acrescentou a checagem em 12 de outubro, na mesma manhã em que a T18 e a T19 entraram no
modelo, e a rodou pelo `check.sh`, que constrói o modelo com o pytm antes, para um `model.py`
quebrado também falhar:

```
(.venv) ana@vm:~/tm/portal-model$ cat check.sh
#!/bin/sh
# What CI runs on every change to the model. Any failure stops the merge.
set -e
python3 model.py --json model.json
python3 check_model.py "$@"
(.venv) ana@vm:~/tm/portal-model$ sh check.sh 2026-10-12; echo "exit $?"
NEW    T18: no requirement and no decision
NEW    T19: no requirement and no decision
known  R14: not verified
known  R17: not verified
19 threats, 19 requirements, 3 current decisions: 2 new, 0 stale, 2 known
exit 1
```

Ela falha de propósito. Duas ameaças foram acrescentadas sem resposta, e a checagem diz isso nos
termos que o curso usou o tempo todo: sem requisito, sem decisão. O RA-002 não está na lista, porque o
RA-003 o substitui.

### Fazendo passar, com honestidade

Há três jeitos de responder a um problema novo, e a checagem não se importa com qual, desde que um
seja escolhido: **escrever um requisito**, **escrever uma decisão**, ou **acrescentá-lo ao
baseline** com um motivo no commit. Para a T18 e a T19, a ana escreveu requisitos, o R20 para a
chave da API e o R21 para os logins do painel. O R20 é verificado por revisão da configuração; o R21
é um processo mensal sem nada para verificar ainda, então entrou no baseline no mesmo commit:

```
(.venv) ana@vm:~/tm/portal-model$ tail -2 requirements.csv
R20,T18,The gateway API key is kept only in the portal's secret store and is rotated every 90 days.,review
R21,T19,Access to the gateway's dashboard is reviewed every month and removed on the day a person leaves.,
(.venv) ana@vm:~/tm/portal-model$ cat baseline.txt
R14: not verified
R17: not verified
R21: not verified
(.venv) ana@vm:~/tm/portal-model$ sh check.sh 2026-10-12; echo "exit $?"
known  R14: not verified
known  R17: not verified
known  R21: not verified
19 threats, 21 requirements, 3 current decisions: 0 new, 0 stale, 3 known
exit 0
```

### Dois gatilhos, não um

No CI, `sh check.sh` é um único passo em qualquer sistema que o repositório use, rodado em todo pull
request que mexe no modelo. Isso pega uma mudança que quebra o modelo. Não consegue pegar o
calendário. Nada muda em 16 de dezembro, e nesse dia o RA-003 está atrasado:

```
(.venv) ana@vm:~/tm/portal-model$ python3 check_model.py 2026-12-16; echo "exit $?"
known  R14: not verified
known  R17: not verified
known  R21: not verified
NEW    RA-003: review overdue since 2026-12-15
19 threats, 21 requirements, 3 current decisions: 1 new, 0 stale, 3 known
exit 1
```

Então a mesma checagem também roda **numa agenda**, toda segunda-feira de manhã, e uma falha vai
para o dono da decisão. É a resposta da gestão da aula 14 transformada num job, e é o motivo de o
RA-003 não ser achado uma semana atrasado como o RA-002 foi.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l15-ci\" aria-label=\"A checagem do modelo no CI. Duas coisas a disparam: um pull request que muda o modelo, e uma agenda semanal. O check.sh primeiro constrói o modelo com o pytm, então um model.py quebrado falha; depois o check_model.py compara os problemas que acha com o baseline.txt. Um problema novo ou uma linha velha do baseline falha a checagem e impede o merge; problemas conhecidos são relatados e passam.\"><defs><marker id=\"l15-ci-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um pull request</text><rect x=\"20.0\" y=\"110.0\" width=\"150.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"132.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">toda segunda-feira</text><rect x=\"220.0\" y=\"30.0\" width=\"160.0\" height=\"124.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"300.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">check.sh</text><text x=\"300.0\" y=\"79.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1. model.py constrói</text><text x=\"300.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2. check_model.py</text><text x=\"300.0\" y=\"104.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">contra baseline.txt</text><path d=\"M170.0 52.0 L220.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><path d=\"M170.0 132.0 L220.0 115.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"30.0\" width=\"260.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\"></rect><text x=\"452.0\" y=\"43.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">só conhecidos</text><text x=\"452.0\" y=\"59.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">relatado, passa</text><path d=\"M380.0 92.0 L440.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"80.0\" width=\"260.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"452.0\" y=\"93.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um problema novo</text><text x=\"452.0\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">falha: corrigir, decidir ou baseline</text><path d=\"M380.0 92.0 L440.0 100.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><rect x=\"440.0\" y=\"130.0\" width=\"260.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"452.0\" y=\"143.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">uma linha velha</text><text x=\"452.0\" y=\"159.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">falha: remover</text><path d=\"M380.0 92.0 L440.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l15-ci-tm-ah-paper-dim)\"></path><text x=\"360.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">a agenda é o que pega uma data passando quando nada mudou</text></svg>", "caption": "Uma mudança pode quebrar o modelo, e o calendário também. A checagem precisa rodar pelas duas.", "same": ["2. check_model.py"]}
```
