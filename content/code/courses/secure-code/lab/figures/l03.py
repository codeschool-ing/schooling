"""Lesson 3: the figures and annotated examples."""
from fig import Fig

T = {
    "en": dict(
        paths_aria="Three ways a sign-up reaches Vereda's server, and which checks each one passes through. A patient in a browser passes the browser's checks, required, maxlength, type email, before the request leaves. A script using curl, and an old version of the mobile app, send the request straight to the server and pass no browser check at all. All three arrive at the same route, so only the server's checks see every request.",
        browser="patient, browser", curl="a script with curl", app="an old mobile app",
        bchecks="browser checks:", b2="required, maxlength,", b3="type=email",
        server="the server's checks", route="POST /signup",
        note="the only checks every request passes",
        paths_cap="The browser's checks sit on one of the paths in. The server's sit on all of them.",
        one_aria="One set of rules, FIELDS, written once on the server. An arrow goes from it to the HTML form, where it becomes the attributes maxlength, type and max. Another arrow goes to the validate function, where it becomes the checks. Because both come from the same place, the form and the server cannot disagree about a limit.",
        rules="FIELDS (one place)", form="the form's attributes", form2="maxlength, type, max",
        val="validate()", val2="the same limits, enforced",
        one_cap="Write each limit once, on the server, and generate the form from it.",
    ),
    "pt": dict(
        paths_aria="Três jeitos de um cadastro chegar ao servidor da Vereda, e por quais verificações cada um passa. Um paciente no navegador passa pelas verificações do navegador, required, maxlength, type email, antes de a requisição sair. Um script com curl e uma versão antiga do aplicativo enviam a requisição direto ao servidor e não passam por verificação de navegador nenhuma. Os três chegam à mesma rota, então só as verificações do servidor veem toda requisição.",
        browser="paciente, navegador", curl="um script com curl", app="um app antigo",
        bchecks="verificações do navegador:", b2="required, maxlength,", b3="type=email",
        server="as verificações do servidor", route="POST /signup",
        note="as únicas que toda requisição atravessa",
        paths_cap="As verificações do navegador ficam num dos caminhos de entrada. As do servidor ficam em todos.",
        one_aria="Um conjunto de regras, FIELDS, escrito uma vez no servidor. Uma seta vai dele para o formulário HTML, onde vira os atributos maxlength, type e max. Outra seta vai para a função validate, onde vira as verificações. Como os dois saem do mesmo lugar, o formulário e o servidor não têm como discordar sobre um limite.",
        rules="FIELDS (um lugar)", form="os atributos do formulário", form2="maxlength, type, max",
        val="validate()", val2="os mesmos limites, aplicados",
        one_cap="Escreva cada limite uma vez, no servidor, e gere o formulário a partir dele.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l03-paths", 720, 290, t["paths_aria"])
    ys = [40, 130, 210]
    for y, who in zip(ys, (t["browser"], t["curl"], t["app"])):
        f.box(20, y, 160, 40, [who])
    f.box(230, 30, 170, 60, [t["bchecks"], t["b2"], t["b3"]], stroke="paper-dim", size=9.5)
    f.arrow([(180, 60), (230, 60)])
    f.box(470, 110, 140, 44, [t["route"]], mono=True)
    f.box(470, 180, 230, 44, [t["server"]], stroke="phosphor", bold=True)
    f.arrow([(400, 60), (440, 60), (440, 125), (470, 125)])
    f.arrow([(180, 150), (470, 140)])
    f.arrow([(180, 230), (440, 230), (440, 145), (470, 145)])
    f.arrow([(540, 154), (540, 180)])
    f.text(585, 250, t["note"], fill="paper-dim", italic=True)
    out["l03-paths"] = f.json(t["paths_cap"], same=["required, maxlength,", "type=email"] if lang == "pt" else None)

    f = Fig("l03-one", 720, 200, t["one_aria"])
    f.box(30, 70, 180, 50, [t["rules"]], stroke="phosphor", bold=True)
    f.box(330, 20, 250, 54, [t["form"], t["form2"]])
    f.box(330, 120, 250, 54, [t["val"], t["val2"]])
    f.arrow([(210, 85), (270, 85), (270, 47), (330, 47)])
    f.arrow([(210, 105), (270, 105), (270, 147), (330, 147)])
    out["l03-one"] = f.json(t["one_cap"], same=["maxlength, type, max", "validate()"] if lang == "pt" else None)
    return out


FLAWED = [
    ("from flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nPATIENTS = []\n",
     None, None),
    ("PAGE = \"\"\"<form method=\"post\" action=\"/signup\">\n  <label>Name <input name=\"name\" required maxlength=\"60\"></label>\n  <label>E-mail <input name=\"email\" type=\"email\" required maxlength=\"120\"></label>\n  <label>Birth date <input name=\"birth\" type=\"date\" required max=\"2026-11-01\"></label>\n  <button>Sign up</button>\n</form>\"\"\"\n\n",
     "Every rule is in the HTML: three required fields, two lengths, an e-mail type, a latest birth date. A browser enforces them before it sends anything.",
     "Toda regra está no HTML: três campos obrigatórios, dois tamanhos, um tipo e-mail, uma data de nascimento máxima. O navegador as aplica antes de enviar qualquer coisa."),
    ("@app.get(\"/signup\")\ndef form():\n    return render_template_string(PAGE)\n\n\n@app.post(\"/signup\")\ndef signup():\n    PATIENTS.append(dict(request.form))\n    return \"Welcome\", 201",
     "The server stores whatever fields arrived, all of them, because the form already checked. That sentence is the flaw.",
     "O servidor guarda os campos que chegaram, todos eles, porque o formulário já verificou. Essa frase é a falha."),
]

FIXED = [
    ("import re\nfrom datetime import date\n\nfrom flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nPATIENTS = []\nTODAY = date(2026, 11, 1)\nEMAIL = re.compile(r\"[^@\\s]+@[^@\\s]+\\.[^@\\s]+\")\n",
     "`TODAY` is fixed so the transcripts repeat; a real portal uses `date.today()`. The e-mail pattern checks the shape and no more.",
     "`TODAY` é fixo para as transcrições se repetirem; um portal de verdade usa `date.today()`. O padrão de e-mail verifica a forma e mais nada."),
    ("FIELDS = {\n    \"name\": {\"label\": \"Name\", \"type\": \"text\", \"maxlength\": 60},\n    \"email\": {\"label\": \"E-mail\", \"type\": \"email\", \"maxlength\": 120},\n    \"birth\": {\"label\": \"Birth date\", \"type\": \"date\", \"max\": TODAY.isoformat()},\n}\n",
     "Every limit, written once. The form and the check both read this dictionary, so they cannot disagree.",
     "Todo limite, escrito uma vez. O formulário e a verificação leem os dois este dicionário, então não têm como discordar."),
    ("PAGE = \"\"\"<form method=\"post\" action=\"/signup\">\n{%- for name, f in fields.items() %}\n  <label>{{ f.label }} <input name=\"{{ name }}\" type=\"{{ f.type }}\" required\n    {%- if f.maxlength %} maxlength=\"{{ f.maxlength }}\"{% endif %}\n    {%- if f.max %} max=\"{{ f.max }}\"{% endif %}></label>\n  {%- if name in errors %} <strong>{{ errors[name] }}</strong>{% endif %}\n{%- endfor %}\n  <button>Sign up</button>\n</form>\"\"\"\n\n",
     "The form is generated from `FIELDS`. An error is shown beside the field it is about, which helps the person; the refusal itself is the server's.",
     "O formulário é gerado a partir de `FIELDS`. Um erro aparece ao lado do campo a que se refere, o que ajuda a pessoa; a recusa em si é do servidor."),
    ("def validate(form):\n    errors, patient = {}, {}\n    for name, f in FIELDS.items():\n        value = form.get(name, \"\").strip()\n        if not value:\n            errors[name] = \"required\"\n        elif len(value) > f.get(\"maxlength\", 10):\n            errors[name] = \"too long\"\n        elif f[\"type\"] == \"email\" and not EMAIL.fullmatch(value):\n            errors[name] = \"not an e-mail address\"\n        elif f[\"type\"] == \"date\":\n            try:\n                if not date(1900, 1, 1) <= date.fromisoformat(value) <= TODAY:\n                    errors[name] = \"out of range\"\n            except ValueError:\n                errors[name] = \"not a date\"\n        patient[name] = value\n    return errors, patient\n\n",
     "The same limits, enforced. `patient` is built from the names in `FIELDS` and nothing else, so a field the form never had is never stored. A date has no `maxlength`, so 10 characters, the length of `YYYY-MM-DD`, stands in.",
     "Os mesmos limites, aplicados. `patient` é montado com os nomes de `FIELDS` e mais nada, então um campo que o formulário nunca teve nunca é guardado. Uma data não tem `maxlength`, então 10 caracteres, o tamanho de `AAAA-MM-DD`, fazem as vezes."),
    ("@app.get(\"/signup\")\ndef form():\n    return render_template_string(PAGE, fields=FIELDS, errors={})\n\n\n@app.post(\"/signup\")\ndef signup():\n    errors, patient = validate(request.form)\n    if errors:\n        return render_template_string(PAGE, fields=FIELDS, errors=errors), 400\n    PATIENTS.append(patient)\n    return \"Welcome\", 201",
     "A refusal is the same page with the errors in it and status 400, so a browser shows it and a script can tell it failed.",
     "Uma recusa é a mesma página com os erros e status 400, então o navegador a mostra e um script consegue saber que falhou."),
]

EXAMPLES = {
    "any-client": [{"language": "python", "file": "app.py", "parts": FLAWED}],
    "one-source": [{"language": "python", "file": "app.py", "parts": FIXED}],
}
