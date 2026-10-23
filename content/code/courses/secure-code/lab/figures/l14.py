"""Lesson 14: the figure, and the annotated app.py of "the-uploads"."""
from fig import Fig

APP = [
    ("# app.py\nimport base64\nimport pickle\nfrom pathlib import Path\n\nfrom flask import Flask, jsonify, request, send_from_directory\n\napp = Flask(__name__)\napp.config[\"UPLOADS\"] = Path(\"static/uploads\")\n\n",
     "Uploads go to `static/uploads`, inside the folder Flask serves to anybody at `/static/…`.",
     "Os envios vão para `static/uploads`, dentro da pasta que o Flask serve a qualquer um em `/static/…`."),
    ("@app.post(\"/exams\")\ndef upload():\n    exam = request.files[\"exam\"]\n    folder = app.config[\"UPLOADS\"]\n    folder.mkdir(parents=True, exist_ok=True)\n    exam.save(folder / exam.filename)\n    return jsonify(id=exam.filename), 201\n\n",
     "The upload keeps the file under the name the browser sent, as a path inside the folder.",
     "O envio guarda o arquivo com o nome que o navegador mandou, como caminho dentro da pasta."),
    ("@app.get(\"/exams/<name>\")\ndef download(name):\n    return send_from_directory(app.config[\"UPLOADS\"], name)\n\n",
     "The download serves the file by that same name, with whatever type Flask guesses from it.",
     "O download serve o arquivo por esse mesmo nome, com o tipo que o Flask deduzir dele."),
    ("@app.post(\"/preferences\")\ndef save_preferences():\n    prefs = {\"text_size\": request.form.get(\"text_size\", \"normal\")}\n    response = jsonify(prefs)\n    response.set_cookie(\"prefs\", base64.b64encode(pickle.dumps(prefs)).decode())\n    return response\n\n\n@app.get(\"/preferences\")\ndef read_preferences():\n    raw = request.cookies.get(\"prefs\")\n    prefs = pickle.loads(base64.b64decode(raw)) if raw else {\"text_size\": \"normal\"}\n    return jsonify(prefs)",
     "The text size, kept in a cookie as a pickled dictionary, and unpickled from whatever cookie the browser sends back.",
     "O tamanho do texto, guardado num cookie como dicionário em pickle, e reconstruído de qualquer cookie que o navegador mande de volta."),
]
EXAMPLES = {"the-uploads": [{"language": "python", "file": "app.py", "parts": APP}]}

T = {
    "en": dict(
        aria="Two features that accept a whole object from outside the portal. Above, a preferences cookie: read with pickle, the bytes decide which objects are rebuilt and which functions run; read as JSON and validated, the bytes can only become strings, numbers, lists and dictionaries, and only the allowed values pass. Below, an exam upload: the sender chooses the name, the declared type and the size; the portal instead chooses the name, reads the type from the first bytes, limits the size, stores outside the served folder and hands the file back as a download.",
        r1="a cookie from the browser", r1a="pickle.loads", r1b="the bytes decide what is built",
        r1c="json.loads + allowlist", r1d="only data, only allowed values",
        r2="an uploaded file", r2a="the sender's name, type, size", r2b="trusted as given",
        r2c="the portal's name, the bytes' type,", r2d="a limit, stored outside static/",
        before="before", after="after",
        cap="In both features the fix is the same move: the portal decides what the outside is allowed to make it build.",
    ),
    "pt": dict(
        aria="Dois recursos que aceitam um objeto inteiro de fora do portal. Em cima, um cookie de preferências: lido com pickle, os bytes decidem que objetos são reconstruídos e que funções rodam; lido como JSON e validado, os bytes só viram strings, números, listas e dicionários, e só os valores permitidos passam. Embaixo, um envio de exame: quem envia escolhe o nome, o tipo declarado e o tamanho; o portal passa a escolher o nome, ler o tipo pelos primeiros bytes, limitar o tamanho, guardar fora da pasta servida e devolver o arquivo como download.",
        r1="um cookie do navegador", r1a="pickle.loads", r1b="os bytes decidem o que é construído",
        r1c="json.loads + lista de permissão", r1d="só dados, só valores permitidos",
        r2="um arquivo enviado", r2a="nome, tipo e tamanho de quem envia", r2b="aceitos como vieram",
        r2c="nome do portal, tipo pelos bytes,", r2d="um limite, guardado fora de static/",
        before="antes", after="depois",
        cap="Nos dois recursos a correção é o mesmo movimento: o portal decide o que o lado de fora pode fazê-lo construir.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l14-two", 720, 240, t["aria"])
    f.text(370, 18, t["before"], bold=True, size=10)
    f.text(600, 18, t["after"], bold=True, size=10)
    f.box(20, 34, 180, 70, [t["r1"]], stroke="wire", size=10)
    f.box(240, 34, 250, 70, [t["r1a"], t["r1b"]], stroke="amber", size=9.5)
    f.box(510, 34, 190, 70, [t["r1c"], t["r1d"]], stroke="phosphor", size=9)
    f.arrow([(200, 69), (240, 69)])
    f.box(20, 140, 180, 70, [t["r2"]], stroke="wire", size=10)
    f.box(240, 140, 250, 70, [t["r2a"], t["r2b"]], stroke="amber", size=9.5)
    f.box(510, 140, 190, 70, [t["r2c"], t["r2d"]], stroke="phosphor", size=9)
    f.arrow([(200, 175), (240, 175)])
    out["l14-two"] = f.json(t["cap"], same=(["pickle.loads"] if lang == "pt" else None))
    return out
