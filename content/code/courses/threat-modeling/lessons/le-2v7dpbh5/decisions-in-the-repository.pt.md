---
title: Decisões no repositório
version: 1
---

Os registros de decisão da Vereda moram numa pasta ao lado do modelo, um arquivo Markdown cada:

```
(.venv) ana@vm:~/tm/portal-model$ ls decisions
DR-001-second-factor.md
RA-001-crafted-pdf.md
RA-002-cancellation-record.md
```

O aceite da T14, completo:

```
(.venv) ana@vm:~/tm/portal-model$ cat decisions/RA-001-crafted-pdf.md
---
id: RA-001
threat: T14
decision: accept
owner: daniel
decided: 2026-10-01
review by: 2027-04-01
---

# Accept T14, a crafted PDF attacking a clinic computer, until April 2027

## The risk

A patient uploads a PDF built to exploit the viewer a physiotherapist opens it in, and code runs on
a clinic computer. Expected loss R$ 9,000 a year; in a bad year, one in a hundred, about R$ 390,000.

## Why it is accepted

The only control proposed, an isolated viewer (C6), costs R$ 18,000 a year and removes about
R$ 7,200. Vereda will not buy it now.

## What is in place instead

- Staff open exams only in the console's viewer, never in a desktop program.
- The clinic computers are updated automatically every week.
- The backups of the clinic computers were restored in a test on 2026-09-12.
- An insurance quote covering losses above R$ 50,000 has been requested.

## When this is looked at again

By 2027-04-01, or before that if any of these happens: a viewer flaw is published that affects the
console's viewer; the insurance quote arrives; a clinic computer is infected by anything.
```

### Quais decisões estão vencendo

Uma data de revisão que ninguém confere é enfeite. O `acceptances.py` lê o front matter de cada
registro em `decisions/` e compara cada data de revisão com um dia, por padrão o de hoje:

```schooling-example
{"language": "python", "file": "acceptances.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"List the decisions in decisions/, and which ones are due or overdue for review.\n\n    python3 acceptances.py              against today's date\n    python3 acceptances.py 2026-10-07   against another date\n\"\"\"\nimport datetime\nimport pathlib\nimport sys\n\ntoday = datetime.date.fromisoformat(sys.argv[1]) if len(sys.argv) > 1 else datetime.date.today()\n", "note": "O dia contra o qual comparar: o de hoje, ou uma data dada na linha de comando, que é como uma captura ou um relatório continua repetível."}, {"code": "\ndef front_matter(path):\n    lines = path.read_text().split(\"\\n\")\n    end = lines.index(\"---\", 1)\n    return dict(line.split(\": \", 1) for line in lines[1:end])\n\n", "note": "O front matter são as linhas entre o primeiro --- e o seguinte, cada uma uma chave, dois-pontos e espaço, e um valor."}, {"code": "print(f\"{'':7} {'threat':6} {'decision':9} {'owner':7} {'review by':10}  status\")\nfor path in sorted(pathlib.Path(\"decisions\").glob(\"*.md\")):\n    d = front_matter(path)\n    days = (datetime.date.fromisoformat(d[\"review by\"]) - today).days\n    status = f\"OVERDUE by {-days} days\" if days < 0 else f\"due in {days} days\" if days <= 30 else \"ok\"\n    print(f\"{d['id']:7} {d['threat']:6} {d['decision']:9} {d['owner']:7} {d['review by']:10}  {status}\")", "note": "Uma linha por registro. Dias negativos estão atrasados; trinta dias ou menos estão perto, para a revisão poder ser marcada a tempo."}]}
```

Rodado no dia em que esta aula foi gravada:

```
(.venv) ana@vm:~/tm/portal-model$ python3 acceptances.py 2026-10-07
        threat decision  owner   review by   status
DR-001  T03    mitigate  daniel  2027-09-30  ok
RA-001  T14    accept    daniel  2027-04-01  ok
RA-002  T06    accept    daniel  2026-10-02  OVERDUE by 5 days
```

**O RA-002 está atrasado.** O daniel aceitou a T06, pacientes contestando cancelamentos, em abril, por
seis meses, até uma mudança no código de agendamento prevista para o segundo semestre. A data passou
há cinco dias e ninguém percebeu, que é exatamente como um aceite vira permanente sem ninguém decidir
isso. O R09 da aula 8, registrar quem cancelou e quando, é essa mudança. A linha atrasada é o aviso
para conferir se o R09 já entrou: se entrou, o RA-002 é fechado por um registro novo dizendo que a T06
agora está mitigada; se não, o daniel renova o aceite com uma data nova, ou antecipa o R09.

O programa diz *due in N days* para o que estiver a menos de um mês, para que uma revisão seja marcada
antes de atrasar, e não depois.

### O histórico é parte do registro

```
(.venv) ana@vm:~/tm/portal-model$ git log --format="%h %ad %s" --date=short -- decisions
7060908 2026-10-01 Record the first decisions
```

Quando o auditor da aula 14 perguntar quando a T14 foi aceita e por quem, a resposta é o arquivo e
este log: o que foi decidido, por quem, em que dia, e que nada foi mudado nele desde então.
