"""Lesson 13: the figure, and the annotated app.py of "the-portal"."""
from fig import Fig

APP = [
    ("# app.py\nimport secrets\nimport sqlite3\n\nfrom flask import Flask, abort, g, jsonify, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\napp.config[\"DATABASE\"] = \"exams.db\"\n",
     "The database is a file, `exams.db`, named in the app's configuration so a test can point it somewhere else.",
     "O banco é um arquivo, `exams.db`, nomeado na configuração da aplicação para um teste poder apontá-lo para outro lugar."),
    ("SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS exams (\n    id INTEGER PRIMARY KEY,\n    patient TEXT NOT NULL,\n    title TEXT NOT NULL,\n    taken TEXT NOT NULL\n)\n\"\"\"\nSAMPLE = [\n    (\"lucia\", \"Knee MRI\", \"2026-10-28\"),\n    (\"marta\", \"Lumbar spine X-ray\", \"2026-10-30\"),\n    (\"rafael\", \"Shoulder ultrasound\", \"2026-11-02\"),\n]\n\n",
     "One table. `id` is an `INTEGER PRIMARY KEY`, so SQLite numbers the exams 1, 2, 3 in the order they arrive. Each row knows its patient.",
     "Uma tabela. `id` é `INTEGER PRIMARY KEY`, então o SQLite numera os exames 1, 2, 3 na ordem em que chegam. Cada linha sabe de que paciente é."),
    ("def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(app.config[\"DATABASE\"])\n        g.db.row_factory = sqlite3.Row\n    return g.db\n\n\n@app.teardown_appcontext\ndef close_db(error):\n    connection = g.pop(\"db\", None)\n    if connection is not None:\n        connection.close()\n\n\ndef init_db():\n    with app.app_context():\n        db().execute(SCHEMA)\n        if db().execute(\"SELECT count(*) FROM exams\").fetchone()[0] == 0:\n            db().executemany(\"INSERT INTO exams (patient, title, taken) VALUES (?, ?, ?)\", SAMPLE)\n        db().commit()\n\n",
     "Flask's usual pattern: one connection per request, kept in `g` and closed when the request ends. `init_db` creates the table and the three sample exams if the table is empty.",
     "O padrão de sempre do Flask: uma conexão por requisição, guardada em `g` e fechada quando a requisição termina. `init_db` cria a tabela e os três exames de exemplo se a tabela estiver vazia."),
    ("def signed_in():\n    name = session.get(\"patient\")\n    if name is None:\n        abort(401)\n    return name\n\n",
     "The session check of lesson 1: somebody is signed in, and this is their name.",
     "A verificação de sessão da aula 1: alguém está logado, e este é o nome."),
    ("@app.get(\"/exams\")\ndef list_exams():\n    name = request.args.get(\"patient\", signed_in())\n    rows = db().execute(\"SELECT id, title, taken FROM exams WHERE patient = ?\", (name,))\n    return jsonify([dict(row) for row in rows])\n\n",
     "The list: the signed-in patient's exams, unless the request names another patient. The staff console wanted to reuse this route.",
     "A lista: os exames do paciente logado, a não ser que a requisição nomeie outro. O console da equipe queria reaproveitar esta rota."),
    ("@app.get(\"/exams/<int:exam_id>\")\ndef read_exam(exam_id):\n    signed_in()\n    row = db().execute(\"SELECT id, title, taken FROM exams WHERE id = ?\", (exam_id,)).fetchone()\n    if row is None:\n        abort(404)\n    return jsonify(dict(row))\n\n\n@app.delete(\"/exams/<int:exam_id>\")\ndef delete_exam(exam_id):\n    signed_in()\n    db().execute(\"DELETE FROM exams WHERE id = ?\", (exam_id,))\n    db().commit()\n    return \"\", 204",
     "One exam, read or deleted by its id. Both ask that somebody be signed in. Read the queries and look for the patient.",
     "Um exame, lido ou apagado pelo id. As duas rotas exigem que alguém esteja logado. Leia as consultas e procure o paciente."),
]
EXAMPLES = {"the-portal": [{"language": "python", "file": "app.py", "parts": APP}]}

T = {
    "en": dict(
        aria="An insecure direct object reference drawn as two requests from lucia's browser, both carrying her valid session cookie. The first asks for GET /exams/1, her own knee MRI, and the server answers 200 with it. The second differs by one character, GET /exams/2, which is marta's lumbar spine X-ray, and the flawed server answers 200 with marta's exam, because it checked only that somebody was signed in. After the fix, the second request is answered 404, the same answer as for an exam that does not exist.",
        who="lucia's browser, signed in", srv="the portal",
        r1="GET /exams/1", r2="GET /exams/2", ck="Cookie: lucia's session",
        a1="200: Knee MRI (lucia's)", a2="200: Lumbar spine X-ray (marta's)",
        fixed="after the fix: 404, as for an exam that does not exist",
        one="one character apart",
        cap="Both requests are lucia's and both are valid. Only the server can tell that the second asks for somebody else's record.",
    ),
    "pt": dict(
        aria="Uma referência direta insegura a objeto desenhada como duas requisições do navegador da lucia, ambas com o cookie de sessão válido dela. A primeira pede GET /exams/1, a ressonância do joelho dela, e o servidor responde 200 com ela. A segunda difere num caractere, GET /exams/2, que é o raio X da coluna da marta, e o servidor com a falha responde 200 com o exame da marta, porque só conferiu que alguém estava logado. Depois da correção, a segunda requisição recebe 404, a mesma resposta de um exame que não existe.",
        who="o navegador da lucia, logada", srv="o portal",
        r1="GET /exams/1", r2="GET /exams/2", ck="Cookie: a sessão da lucia",
        a1="200: Knee MRI (da lucia)", a2="200: Lumbar spine X-ray (da marta)",
        fixed="depois da correção: 404, como um exame que não existe",
        one="um caractere de diferença",
        same=["GET /exams/1", "GET /exams/2"],
        cap="As duas requisições são da lucia e as duas são válidas. Só o servidor consegue saber que a segunda pede o registro de outra pessoa.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l13-two", 720, 250, t["aria"])
    f.text(120, 22, t["who"], bold=True)
    f.text(600, 22, t["srv"], bold=True)
    f.rect(520, 36, 160, 170, stroke="wire")
    for i, (req, ans, colour) in enumerate(((t["r1"], t["a1"], "phosphor"), (t["r2"], t["a2"], "amber"))):
        y = 44 + i * 86
        f.box(20, y, 200, 52, [req, t["ck"]], stroke="wire", size=9.5)
        f.arrow([(220, y + 18), (520, y + 18)])
        f.arrow([(520, y + 40), (220, y + 40)], color=colour)
        f.text(370, y + 52, ans, size=9.5, fill=colour)
    f.text(120, 112, t["one"], size=9, italic=True, fill="paper-dim")
    f.text(370, 226, t["fixed"], size=9.5, italic=True, fill="phosphor")
    out["l13-two"] = f.json(t["cap"], same=t.get("same"))
    return out
