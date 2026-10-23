"""Lesson 6: the figure, and the annotated app.py of "the-console"."""
from fig import Fig

APP = [
    ("# app.py\nimport subprocess\nfrom pathlib import Path\n\nfrom flask import Flask, jsonify, render_template_string, request\nfrom ldap3 import MOCK_SYNC, Connection, Server\n\napp = Flask(__name__)\nEXAMS = Path(\"exams\")\nSTAFF = [(\"bruno\", \"reception\"), (\"carla\", \"physio\"), (\"ana\", \"admin\")]\n\n",
     "Exams live in a folder called `exams`; the directory holds the three members of staff of lesson 12.",
     "Os exames ficam numa pasta chamada `exams`; o diretório guarda as três pessoas da equipe da aula 12."),
    ("def directory():\n    connection = Connection(\n        Server(\"ldap.vereda.example\"),\n        user=\"cn=portal,ou=apps,dc=vereda,dc=example\",\n        password=\"test-only\",\n        client_strategy=MOCK_SYNC,\n    )\n    for name, role in STAFF:\n        connection.strategy.add_entry(\n            f\"cn={name},ou=staff,dc=vereda,dc=example\",\n            {\"objectClass\": \"person\", \"cn\": name, \"sn\": name, \"title\": role},\n        )\n    connection.bind()\n    return connection\n\n",
     "`MOCK_SYNC` makes `ldap3` answer from entries added here, in memory. The code that searches is the code that would search a real directory; only this function would change.",
     "O `MOCK_SYNC` faz o `ldap3` responder a partir de entradas acrescentadas aqui, em memória. O código que busca é o que buscaria num diretório de verdade; só esta função mudaria."),
    ("@app.get(\"/exams/<path:name>/type\")\ndef exam_type(name):\n    result = subprocess.run(\n        f\"file --brief --mime-type exams/{name}\", shell=True, capture_output=True, text=True\n    )\n    return jsonify(name=name, type=result.stdout.strip())\n\n",
     "The file type of an exam, from the `file` command. The command line is built with an f-string and given to the shell.",
     "O tipo de arquivo de um exame, pelo comando `file`. A linha de comando é montada com f-string e entregue ao shell."),
    ("@app.get(\"/staff\")\ndef find_staff():\n    connection = directory()\n    connection.search(\n        \"ou=staff,dc=vereda,dc=example\", f\"(cn={request.args['name']})\", attributes=[\"cn\", \"title\"]\n    )\n    return jsonify([{\"name\": str(e.cn), \"role\": str(e.title)} for e in connection.entries])\n\n",
     "A staff lookup by name. The LDAP filter `(cn=…)` is built with an f-string.",
     "Uma busca de pessoa da equipe pelo nome. O filtro LDAP `(cn=…)` é montado com f-string."),
    ("@app.post(\"/reminders/preview\")\ndef preview():\n    note = request.form.get(\"note\", \"\")\n    page = render_template_string(\n        \"<p>Hello {{ patient }}, see you on {{ day }}.</p><p>\" + note + \"</p>\",\n        patient=\"lucia\",\n        day=\"Monday 16 November\",\n    )\n    return page",
     "The reminder preview. `patient` and `day` are template variables; the note is joined into the template's text.",
     "A prévia do lembrete. `patient` e `day` são variáveis do template; o recado é emendado no texto do template."),
]
EXAMPLES = {"the-console": [{"language": "python", "file": "app.py", "parts": APP}]}

T = {
    "en": dict(
        aria="Three interpreters, three ordinary values, one mistake. The exam name knee scan.pdf, written into a command line, is split by the shell into two arguments; the fix is a list of arguments with no shell. The name star, written into an LDAP filter, is read as the wildcard and matches everybody; the fix is the library's filter escaping. The note please bring double-brace the referral, joined into a Jinja template, is parsed as an expression; the fix is to pass the note as a template variable.",
        h=("the value", "read by", "as", "the separate channel"),
        rows=[("knee scan.pdf", "the shell", "two arguments", "a list, no shell"),
              ("*", "an LDAP filter", "everybody", "escape_filter_chars"),
              ("{{ the referral }}", "Jinja", "an expression", "a template variable")],
        cap="The characters differ from one interpreter to the next. The mistake and the fix do not.",
    ),
    "pt": dict(
        aria="Três interpretadores, três valores comuns, um erro. O nome de exame knee scan.pdf, escrito numa linha de comando, é dividido pelo shell em dois argumentos; a correção é uma lista de argumentos sem shell. O nome estrela, escrito num filtro LDAP, é lido como curinga e corresponde a todo mundo; a correção é o escape de filtro da biblioteca. O recado com chaves duplas em volta de the referral, emendado num template Jinja, é interpretado como expressão; a correção é passar o recado como variável do template.",
        h=("o valor", "lido por", "como", "o canal separado"),
        rows=[("knee scan.pdf", "o shell", "dois argumentos", "uma lista, sem shell"),
              ("*", "um filtro LDAP", "todo mundo", "escape_filter_chars"),
              ("{{ the referral }}", "o Jinja", "uma expressão", "uma variável do template")],
        cap="Os caracteres mudam de um interpretador para outro. O erro e a correção, não.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l06-three", 720, 220, t["aria"])
    xs = [20, 200, 340, 500]
    ws = [160, 120, 140, 200]
    for x, w, h in zip(xs, ws, t["h"]):
        f.text(x + w / 2, 22, h, bold=True, size=10)
    for i, (value, who, read, fix) in enumerate(t["rows"]):
        y = 40 + i * 58
        f.box(xs[0], y, ws[0], 40, [value], stroke="wire", mono=True, size=10)
        f.box(xs[1], y, ws[1], 40, [who], stroke="wire", size=10)
        f.box(xs[2], y, ws[2], 40, [read], stroke="amber", size=10)
        f.box(xs[3], y, ws[3], 40, [fix], stroke="phosphor", mono=(fix == "escape_filter_chars"), size=10)
        f.arrow([(xs[0] + ws[0], y + 20), (xs[1], y + 20)])
        f.arrow([(xs[1] + ws[1], y + 20), (xs[2], y + 20)], color="amber")
    out["l06-three"] = f.json(t["cap"], same=t.get("same"))
    return out
