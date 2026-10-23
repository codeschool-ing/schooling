"""Lesson 12: the figure, and the annotated examples of "the-console" and "one-decorator"."""
from fig import Fig

APP = [
    ("# app.py\nimport secrets\n\nfrom flask import Flask, abort, jsonify, render_template_string, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\nSTAFF = {\"bruno\": \"reception\", \"carla\": \"physio\", \"ana\": \"admin\"}\nNOTES = {\"lucia\": [\"Left knee: range of motion improving.\"]}\nAGENDA = [{\"patient\": \"lucia\", \"starts\": \"2026-11-11 09:00\", \"with\": \"carla\"}]\n",
     "`STAFF` is the server's table of who holds which role. Notes and agenda are held in memory so the program fits on the page.",
     "`STAFF` é a tabela do servidor com o papel de cada pessoa. Notas e agenda ficam em memória para o programa caber na página."),
    ("PAGE = \"\"\"<h1>Vereda console</h1>\n<p>Signed in as {{ name }}</p>\n<ul>\n  <li><a href=\"/agenda\">Agenda</a></li>\n  {% if role == \"physio\" %}\n  <li><a href=\"/patients/lucia/notes\">Clinical notes</a></li>\n  {% endif %}\n</ul>\n{% if role == \"physio\" %}\n<form method=\"post\" action=\"/patients/lucia/notes\">\n  <input type=\"hidden\" name=\"role\" value=\"physio\">\n  <textarea name=\"text\"></textarea>\n  <button>Add note</button>\n</form>\n{% endif %}\n\"\"\"\n\n",
     "The console's page. A physiotherapist sees the notes link and a form to add one; everybody else sees neither. Note the hidden field: the form tells the server who is sending it.",
     "A página do console. Uma fisioterapeuta vê o link das notas e um formulário para acrescentar uma; os demais não veem nenhum dos dois. Repare no campo oculto: o formulário diz ao servidor quem o está enviando."),
    ("def signed_in():\n    name = session.get(\"staff\")\n    if name is None:\n        abort(401)\n    return name\n\n",
     "The only check in the program: is somebody signed in? It says nothing about who.",
     "A única verificação do programa: alguém está logado? Não diz nada sobre quem."),
    ("@app.get(\"/console\")\ndef console():\n    name = signed_in()\n    return render_template_string(PAGE, name=name, role=STAFF.get(name))\n\n\n@app.get(\"/agenda\")\ndef agenda():\n    signed_in()\n    return jsonify(AGENDA)\n\n",
     "The console and the agenda, for any member of staff.",
     "O console e a agenda, para qualquer pessoa da equipe."),
    ("@app.get(\"/patients/<name>/notes\")\ndef read_notes(name):\n    signed_in()\n    return jsonify(NOTES.get(name, []))\n\n\n@app.post(\"/patients/<name>/notes\")\ndef add_note(name):\n    signed_in()\n    if request.form.get(\"role\") != \"physio\":\n        abort(403)\n    NOTES.setdefault(name, []).append(request.form[\"text\"])\n    return jsonify(NOTES[name]), 201\n\n",
     "Reading notes asks only `signed_in()`, trusting that the page hid the link. Adding a note does check a role, and takes it from the form.",
     "Ler notas pergunta só `signed_in()`, confiando que a página escondeu o link. Acrescentar uma nota confere um papel, e o tira do formulário."),
    ("@app.get(\"/export\")\ndef export():\n    rows = [f\"{patient},{len(notes)}\" for patient, notes in NOTES.items()]\n    return \"\\n\".join([\"patient,notes\", *rows]) + \"\\n\", {\"Content-Type\": \"text/csv\"}",
     "A CSV for a monthly report, written in an afternoon. Look for its check.",
     "Um CSV para um relatório mensal, escrito numa tarde. Procure a verificação dele."),
]

REQ = [
    ("def requires(*roles):\n    def decorate(view):\n        @wraps(view)\n        def checked(*args, **kwargs):",
     "A decorator that takes the roles a route accepts. `wraps` keeps the view's name, which Flask uses to tell routes apart.",
     "Um decorador que recebe os papéis que uma rota aceita. O `wraps` mantém o nome da view, que o Flask usa para distinguir as rotas."),
    ("            name = session.get(\"staff\")\n            if name not in STAFF:\n                abort(401)",
     "Who is asking comes from the session. A name the server does not know, or none, is `401`.",
     "Quem pergunta vem da sessão. Um nome que o servidor não conhece, ou nenhum, é `401`."),
    ("            if STAFF[name] not in roles:\n                abort(403)\n            return view(*args, **kwargs)\n",
     "What they may do comes from `STAFF`, the server's table, never from the request. The wrong role is `403`, before the view runs a single line.",
     "O que podem fazer vem do `STAFF`, a tabela do servidor, nunca da requisição. O papel errado é `403`, antes de a view rodar uma linha."),
    ("        checked.allowed_roles = roles\n        return checked\n\n    return decorate",
     "The roles are also written on the function, so a test can ask every route what it allows.",
     "Os papéis também ficam escritos na função, para um teste perguntar a cada rota o que ela permite."),
]
EXAMPLES = {"the-console": [{"language": "python", "file": "app.py", "parts": APP}],
            "one-decorator": [{"language": "python", "parts": REQ}]}

T = {
    "en": dict(
        aria="Three places a check can live, and the requests that cross each. On the left, the browser: the page, which hides the notes link from a receptionist, and the form, which carries a hidden field role=physio. Below it, a terminal sending a request with curl, which never shows the page. Both the browser and the terminal send their requests to the server on the right, where the check reads the name from the session and the role from the server's own table. Every request crosses the server; only the honest browser crosses the page.",
        browser="the browser", page="the page: link hidden", form="the form: role=physio",
        term="a terminal, a script", server="the server",
        s1="name from the session", s2="role from STAFF", s3="every request crosses here",
        skip="skips the page entirely",
        cap="The page and the form only ever see the honest browser. The server sees every request, which is why the check lives there.",
    ),
    "pt": dict(
        aria="Três lugares onde uma verificação pode ficar, e as requisições que passam por cada um. À esquerda, o navegador: a página, que esconde o link das notas de um recepcionista, e o formulário, que leva um campo oculto role=physio. Abaixo, um terminal mandando uma requisição com curl, que nunca mostra a página. O navegador e o terminal mandam suas requisições ao servidor à direita, onde a verificação lê o nome na sessão e o papel na tabela do próprio servidor. Toda requisição passa pelo servidor; só o navegador honesto passa pela página.",
        browser="o navegador", page="a página: link oculto", form="o formulário: role=physio",
        term="um terminal, um script", server="o servidor",
        s1="nome vindo da sessão", s2="papel vindo do STAFF", s3="toda requisição passa aqui",
        skip="pula a página por completo",
        cap="A página e o formulário só veem o navegador honesto. O servidor vê toda requisição, e é por isso que a verificação mora lá.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l12-where", 720, 270, t["aria"])
    f.text(150, 22, t["browser"], bold=True)
    f.rect(20, 34, 260, 126, stroke="wire", dashed=True)
    f.box(40, 50, 220, 40, [t["page"]], stroke="amber", size=9.5)
    f.box(40, 104, 220, 40, [t["form"]], stroke="amber", size=9.5)
    f.box(40, 196, 220, 40, [t["term"]], stroke="wire", size=9.5)
    f.text(150, 252, t["skip"], size=9, italic=True, fill="paper-dim")
    f.text(570, 22, t["server"], bold=True)
    f.box(450, 60, 240, 150, [t["s1"], t["s2"], "", t["s3"]], stroke="phosphor", size=10)
    f.arrow([(280, 97), (450, 110)])
    f.arrow([(260, 216), (450, 170)])
    out["l12-where"] = f.json(t["cap"])
    return out
