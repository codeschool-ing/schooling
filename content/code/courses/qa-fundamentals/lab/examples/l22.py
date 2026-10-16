# lesson 22: three numbers from a file of defect records

example('metrics', 'metrics.py', [
    ('# metrics.py\nimport csv\n\nwith open("defects.csv") as f:\n    rows = list(csv.DictReader(line for line in f if not line.startswith("#")))\n',
     'Python’s `csv` module reads the file into one dictionary per row, keyed by the header. The line starting with '
     '`#` is skipped, because it names the file and is not a record.',
     'O módulo `csv` do Python lê o arquivo num dicionário por linha, com as chaves do cabeçalho. A linha que começa '
     'com `#` é pulada, porque nomeia o arquivo e não é um registro.'),
    ('\nbefore = [r for r in rows if r["found"] == "before"]\nafter = [r for r in rows if r["found"] == "after"]\n',
     'The defects split in two by one question: found before the release, or after it.',
     'Os defeitos divididos em dois por uma pergunta: achados antes da entrega, ou depois.'),
    ('print("defects:", len(rows))\nprint("found before release:", len(before))\nprint("found after release:", len(after))\nprint(f"detection percentage: {len(before) / len(rows):.0%}")\n',
     'The counts, and the detection percentage: found before, divided by all. `:.0%` prints a fraction as a whole '
     'percentage.',
     'As contagens, e o percentual de detecção: achados antes, dividido por todos. `:.0%` imprime uma fração como '
     'porcentagem inteira.'),
    ('print("escaped, by area:", ", ".join(r["area"] for r in after))\nprint("still open:", ", ".join("defect " + r["id"] for r in rows if r["days_to_fix"] == "open"))\n',
     'And the two lists a number should never be shown without: where the escaped defects were, and which defects are '
     'still open.',
     'E as duas listas sem as quais um número nunca deveria ser mostrado: onde estavam os defeitos que escaparam, e '
     'quais continuam abertos.'),
])
