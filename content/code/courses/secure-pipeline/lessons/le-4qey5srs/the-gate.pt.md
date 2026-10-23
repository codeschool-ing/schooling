---
title: Um gate para dependências, e falhar fechado
version: 1
---

O pip-audit tem uma opinião só sobre um relatório: sai com 1 se achou qualquer aviso. Isso não
distingue os dois casos que esta aula separa, um aviso com versão corrigida e um sem nenhuma, e ele
não tem noção de uma exceção que termina. `--ignore-vuln` existe, e ignora um aviso para sempre, que
é o gate desligado numa flag. **Então a decisão vai para um programa curto do próprio projeto**, que lê
o relatório JSON do pip-audit e responde com um código de saída.

### O gate

Salve como `ci/gate.py`:

```schooling-example
{"language": "python", "file": "ci/gate.py", "parts": [{"code": "\"\"\"The composition gate: pip-audit's JSON on stdin, ci/exceptions.txt beside\nit, and one verdict as the exit status.\n\n    1  an advisory with a fixed version, and no exception in force for it\n    3  a warning: an advisory nobody can fix yet, or an exception that\n       expires within a week\n    0  nothing to report\n\"\"\"", "note": "Os três vereditos, escritos no topo, onde a próxima pessoa que mudar o gate os lê antes do código."}, {"code": "import datetime\nimport json\nimport sys\nfrom pathlib import Path\n"}, {"code": "BREAK, WARN, PASS = 1, 3, 0\n\n", "note": "Os códigos de saída como nomes, para que nenhuma linha abaixo compare com um número solto. Um crash deste programa sai com 1, que é BREAK: o gate falha fechado sem uma linha de código para isso."}, {"code": "def judge(audit, exceptions, today):\n    \"\"\"The verdict and one line per advisory, for a pip-audit report.\"\"\"", "note": "`today` é um parâmetro em vez de uma chamada ao relógio, para que os testes fixem o dia e confiram cada lado da data de uma exceção."}, {"code": "    until = {}\n    for line in exceptions.splitlines():\n        if line.strip() and not line.startswith(\"#\"):\n            advisory, day, _why = line.split(maxsplit=2)\n            until[advisory] = datetime.date.fromisoformat(day)", "note": "Cada exceção tem três campos: o aviso, o último dia em que vale e o motivo. Uma linha sem motivo não se divide em três, o Python levanta um erro e o build quebra: uma exceção que ninguém explicou é recusada."}, {"code": "    verdict, lines = PASS, []\n    for dep in audit[\"dependencies\"]:\n        for vuln in dep.get(\"vulns\", []):\n            what = f\"{dep['name']} {dep['version']} {vuln['id']}\"\n            if any(what in line for line in lines):\n                continue", "note": "O pip-audit lê os dois arquivos de requisitos e pode apontar o mesmo aviso duas vezes; cada um é julgado uma vez só."}, {"code": "            day = until.get(vuln[\"id\"])\n            if day is not None and day >= today:\n                lines.append(f\"excepted until {day}: {what}\")\n                if (day - today).days < 7 and verdict == PASS:\n                    verdict = WARN", "note": "Uma exceção em vigor deixa o aviso passar, e vira alerta na última semana, para que a data seja vista antes de chegar."}, {"code": "            elif vuln[\"fix_versions\"]:\n                lines.append(f\"BREAKS: {what}, fixed in {', '.join(vuln['fix_versions'])}\")\n                verdict = BREAK", "note": "Existe versão corrigida e ninguém abriu exceção para o aviso: quem fez o push pode mudar o pin, então o build quebra. A linha diz qual versão corrige."}, {"code": "            else:\n                lines.append(f\"warns: {what}, no fixed version yet\")\n                if verdict == PASS:\n                    verdict = WARN", "note": "Nenhuma versão corrigida em lugar nenhum: ninguém pode agir mudando um pin, então é um alerta, contado e mostrado."}, {"code": "    return verdict, lines\n\n"}, {"code": "if __name__ == \"__main__\":\n    verdict, lines = judge(json.load(sys.stdin), Path(\"ci/exceptions.txt\").read_text(),\n                           datetime.date.today())\n    print(\"\\n\".join(lines) or \"no advisories\")\n    sys.exit(verdict)", "note": "Rodado como programa: o relatório na entrada padrão, as exceções do arquivo, a data de hoje. Ele imprime uma linha por aviso, e o veredito é o código de saída."}]}
```

As exceções moram ao lado dele, uma por linha, e começam vazias. Salve como `ci/exceptions.txt`:

```
# Exceptions to the composition gate, one per line: the advisory, the last
# day the exception holds, and why. Past that day the line is ignored and
# the finding breaks the build again, until somebody decides afresh.
```

### Os testes dele

Um gate é código que decide se outro código vai para produção, então ganha testes como qualquer
outro: um por veredito, e dois para as bordas da data de uma exceção. Salve como
`tests/test_gate.py`:

```python
import datetime

from ci.gate import BREAK, PASS, WARN, judge

DAY = datetime.date(2026, 10, 14)
FIXED = {"id": "PYSEC-1", "fix_versions": ["1.1"]}
UNFIXED = {"id": "PYSEC-2", "fix_versions": []}


def verdict(vulns, exceptions=""):
    audit = {"dependencies": [{"name": "pkg", "version": "1.0", "vulns": vulns}]}
    return judge(audit, exceptions, DAY)[0]


def test_a_fix_nobody_applied_breaks_the_build():
    assert verdict([FIXED]) == BREAK


def test_an_advisory_with_no_fix_warns():
    assert verdict([UNFIXED]) == WARN


def test_an_exception_holds_until_its_date():
    assert verdict([FIXED], "PYSEC-1 2026-12-31 the vendor's fix is due in November") == PASS


def test_an_exception_close_to_its_date_warns():
    assert verdict([FIXED], "PYSEC-1 2026-10-16 the vendor's fix is due in November") == WARN


def test_an_expired_exception_breaks_the_build_again():
    assert verdict([FIXED], "PYSEC-1 2026-10-13 the vendor's fix is due in November") == BREAK
```

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q tests/test_gate.py
.....                                                                    [100%]
5 passed in 0.02s
```

**Os testes fixam o dia em 14 de outubro**, então passam em qualquer dia em que forem rodados. Um gate
que chamasse o relógio dentro de `judge` só poderia ser testado no dia em que as datas dele estivessem
certas.

### O estágio

Salve como `ci/sca.sh`:

```sh
# Composition analysis: every dependency the two requirements files pin,
# against the advisories PyPI publishes, judged by ci/gate.py. If pip-audit
# produced no report at all, the gate has nothing to judge and the build
# breaks: a scanner that did not run is not a scanner that found nothing.
# The report goes to a file made empty for this run, so a report left over
# from an earlier run can never stand in for one that was not written.
set -uo pipefail
report=$(mktemp)
trap 'rm -f "$report"' EXIT
pip-audit --strict -r requirements.txt -r requirements-dev.txt -f json -o "$report"
[ -s "$report" ] || exit 1
python3 ci/gate.py <"$report"
```

O código de saída do pip-audit é ignorado, de propósito: é 1 para qualquer aviso, e quem decide é o
gate. O que não é ignorado é se ele produziu um relatório. **O relatório vai para um arquivo criado
vazio para esta execução**, e esse detalhe apareceu enquanto esta aula era gravada. A primeira versão
escrevia `audit.json` dentro do projeto e conferia que não estava vazio. No laptop, uma execução em
que o pip-audit falhou passou, com um relatório que uma execução anterior tinha deixado. No clone
limpo da CI ela teria falhado corretamente, e é exatamente por isso que ninguém teria notado: a
checagem funcionava onde estava sendo observada.

### Falhando fechado, na tela

Dois jeitos de o estágio ficar sem nada para julgar. Primeiro, o gate sem relatório nenhum: a última
linha dele, e o código de saída.

```
ana@vm:~/linkbox$ python3 ci/gate.py </dev/null 2>&1 | tail -n 1; echo "exit ${PIPESTATUS[0]}"
json.decoder.JSONDecodeError: Expecting value: line 1 column 1 (char 0)
exit 1
```

O módulo `json` levantou um erro, o Python saiu com 1, e 1 é BREAK. Ninguém escreveu uma linha de
código para que um relatório vazio quebrasse o build; escolher 1 para BREAK fez isso.

Segundo, um arquivo de requisitos que não pode ser instalado. Volte o `werkzeug` para 3.0.1, a versão
que a aula 1 herdou, enquanto o `flask` fica em 3.1.3, que precisa de uma mais nova:

```
ana@vm:~/linkbox$ sed -i s/werkzeug==3.1.9/werkzeug==3.0.1/ requirements.txt
ana@vm:~/linkbox$ bash ci/sca.sh; echo "exit $?"
ERROR:pip_audit._virtual_env:internal pip failure: ERROR: Cannot install -r requirements.txt (line 1) and werkzeug==3.0.1 because these package versions have conflicting dependencies.
ERROR: ResolutionImpossible: for help visit https://pip.pypa.io/en/latest/topics/dependency-resolution/#dealing-with-dependency-conflicts

ERROR:pip_audit._cli:Failed to install packages: ['/tmp/tmp_tustqwi/bin/python3.13', '-m', 'pip', 'install', '--no-input', '--keyring-provider=subprocess', '--dry-run', '--report', '/tmp/tmpxjf394f0/tmpbe7emzb7', '-r', 'requirements.txt', '-r', 'requirements-dev.txt']
exit 1
ana@vm:~/linkbox$ git checkout -q requirements.txt
```

**O pip-audit não conseguiu resolver as dependências, então não auditou nada e não escreveu nada**, e
o estágio quebrou. Um arquivo de requisitos que ninguém consegue instalar não é um arquivo de
requisitos sem avisos. Antes de `[ -s "$report" ]` existir, o gate teria lido um relatório vazio e o
estágio teria quebrado do mesmo jeito, com um traceback no lugar de um motivo; com um relatório
esquecido de outra execução, teria passado.

### A primeira execução

Faça o commit de tudo e o push:

```
ana@vm:~/linkbox$ git add -A
ana@vm:~/linkbox$ git commit -q -m "a gate that breaks, warns or passes, and exceptions that expire"
9:52AM INF 0 commits scanned.
9:52AM INF scanned ~4958 bytes (4.96 KB) in 187ms
9:52AM INF no leaks found
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at 80c87e1        
remote: secrets: passed in 0s        
remote: test: passed in 2s        
remote: sast: passed in 3s        
remote: sca: passed in 9s        
remote: build: passed in 1s        
remote: pipeline passed with 0 warning(s)        
remote: run 1: passed        
To /home/ana/ci/linkbox.git
   8ab3d2a..80c87e1  main -> main
```

**`pipeline passed with 0 warning(s)`** é a nova última linha, e neste commit ela é verdadeira: o
histórico não tem segredo vivo, os pins não têm avisos e o código não tem achado de severidade
nenhuma. As duas próximas seções enviam branches que mudam uma coisa cada, e observam o veredito.
