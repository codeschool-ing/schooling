"""Lesson 5: the figure, and the annotated app.py and orm.py."""
from fig import Fig

APP = [
    ("# app.py\nimport sqlite3\n\nfrom flask import Flask, abort, g, jsonify, request\n\napp = Flask(__name__)\napp.config[\"DATABASE\"] = \"patients.db\"\n",
     "The database is a file named in the configuration, so a test can point it at a temporary folder, as in lesson 13.",
     "O banco é um arquivo nomeado na configuração, para um teste poder apontá-lo para uma pasta temporária, como na aula 13."),
    ("SCHEMA = \"\"\"\nCREATE TABLE IF NOT EXISTS patients (\n    id INTEGER PRIMARY KEY,\n    first_name TEXT NOT NULL,\n    surname TEXT NOT NULL,\n    clinic TEXT NOT NULL\n)\n\"\"\"\nSAMPLE = [\n    (\"Lucia\", \"D'Ávila\", \"Pinheiros\"),\n    (\"Rafael\", \"Souza\", \"Moema\"),\n    (\"Marta\", \"Avelar\", \"Pinheiros\"),\n    (\"Bruno\", \"O'Neill\", \"Santana\"),\n]\n\n",
     "Four patients. Two of the surnames have an apostrophe, as real surnames do.",
     "Quatro pacientes. Dois sobrenomes têm apóstrofo, como sobrenomes reais têm."),
    ("def db():\n    if \"db\" not in g:\n        g.db = sqlite3.connect(app.config[\"DATABASE\"])\n        g.db.row_factory = sqlite3.Row\n    return g.db\n\n\n@app.teardown_appcontext\ndef close_db(error):\n    connection = g.pop(\"db\", None)\n    if connection is not None:\n        connection.close()\n\n\ndef init_db():\n    with app.app_context():\n        db().execute(SCHEMA)\n        if db().execute(\"SELECT count(*) FROM patients\").fetchone()[0] == 0:\n            db().executemany(\n                \"INSERT INTO patients (first_name, surname, clinic) VALUES (?, ?, ?)\", SAMPLE\n            )\n        db().commit()\n\n",
     "One connection per request, as in lesson 13. Notice that the sample rows go in with `?` placeholders: the author knew the safe call, and used it where the values were hers.",
     "Uma conexão por requisição, como na aula 13. Repare que as linhas de exemplo entram com marcadores `?`: a autora conhecia a chamada segura, e a usou onde os valores eram dela."),
    ("@app.get(\"/patients\")\ndef search():\n    term = request.args.get(\"surname\", \"\")\n    order = request.args.get(\"sort\", \"surname\")\n    rows = db().execute(\n        f\"SELECT first_name, surname, clinic FROM patients \"\n        f\"WHERE surname LIKE '%{term}%' ORDER BY {order}\"\n    )\n    return jsonify([dict(row) for row in rows])\n\n",
     "The search. The surname and the sort come from the address and are written into the SQL text with an f-string. Read the quotes around `{term}` as the database will.",
     "A busca. O sobrenome e a ordenação vêm do endereço e são escritos no texto do SQL com uma f-string. Leia as aspas em volta de `{term}` como o banco vai ler."),
    ("@app.cli.command(\"init-db\")\ndef init_db_command():\n    init_db()",
     "`flask --app app init-db` creates the table and the four patients in `patients.db`.",
     "`flask --app app init-db` cria a tabela e os quatro pacientes em `patients.db`."),
]

ORM = [
    ("# orm.py\nfrom sqlalchemy import String, create_engine, select, text\nfrom sqlalchemy.orm import DeclarativeBase, Mapped, Session, mapped_column\n\n\nclass Base(DeclarativeBase):\n    pass\n\n\nclass Patient(Base):\n    __tablename__ = \"patients\"\n    id: Mapped[int] = mapped_column(primary_key=True)\n    first_name: Mapped[str] = mapped_column(String(50))\n    surname: Mapped[str] = mapped_column(String(50))\n    clinic: Mapped[str] = mapped_column(String(50))\n\n\nengine = create_engine(\"sqlite:///patients.db\")\nname = \"D'Ávila\"\n",
     "A class for the `patients` table, in SQLAlchemy 2's typed style, and the same database file the portal uses.",
     "Uma classe para a tabela `patients`, no estilo tipado do SQLAlchemy 2, e o mesmo arquivo de banco que o portal usa."),
    ("with Session(engine) as session:\n    query = select(Patient.surname).where(Patient.surname == name)\n    print(query)\n    print(session.scalars(query).all())\n",
     "The query built from objects. `print(query)` shows the SQL the ORM will send, before it sends it.",
     "A consulta montada com objetos. `print(query)` mostra o SQL que o ORM vai mandar, antes de mandar."),
    ("    bound = text(\"SELECT surname FROM patients WHERE surname = :surname\")\n    print(session.scalars(bound, {\"surname\": name}).all())\n",
     "Raw SQL through `text()`, with a named placeholder and the value in a dictionary.",
     "SQL cru pelo `text()`, com um marcador nomeado e o valor num dicionário."),
    ("    built = text(f\"SELECT surname FROM patients WHERE surname = '{name}'\")\n    print(session.scalars(built).all())",
     "Raw SQL built with an f-string: the way back, used the wrong way.",
     "SQL cru montado com f-string: o caminho de volta, usado do jeito errado."),
]
EXAMPLES = {"the-search": [{"language": "python", "file": "app.py", "parts": APP}],
            "orm": [{"language": "python", "file": "orm.py", "parts": ORM}]}

T = {
    "en": dict(
        aria="The same search sent to the database two ways. Above, the surname D'Ávila is written into the SQL text: the parser reads the apostrophe as the end of the string, then tries to read Ávila as SQL, and fails with a syntax error. Below, the SQL text has a placeholder and the value travels beside it: the database parses the text first, with a hole where the placeholder is, and then compares each surname with the value, apostrophe included. No character of the value is ever parsed.",
        built="built into the text", sent="sent beside the text",
        t1="… WHERE surname LIKE '%D'Ávila%'", t1a="string ends here", t1b="read as SQL: syntax error",
        t2="… WHERE surname LIKE ?", v2="value: %D'Ávila%", t2a="parsed first, with a hole", t2b="then compared, as data",
        cap="A placeholder keeps the program and the data in two channels, so no value is ever parsed as SQL.",
    ),
    "pt": dict(
        aria="A mesma busca mandada ao banco de dois jeitos. Em cima, o sobrenome D'Ávila é escrito no texto do SQL: o interpretador lê o apóstrofo como o fim da string, tenta ler Ávila como SQL, e falha com erro de sintaxe. Embaixo, o texto do SQL tem um marcador e o valor viaja ao lado: o banco interpreta o texto primeiro, com um buraco onde está o marcador, e depois compara cada sobrenome com o valor, apóstrofo incluído. Nenhum caractere do valor é interpretado.",
        built="escrito no texto", sent="mandado ao lado do texto",
        t1="… WHERE surname LIKE '%D'Ávila%'", t1a="a string termina aqui", t1b="lido como SQL: erro de sintaxe",
        t2="… WHERE surname LIKE ?", v2="valor: %D'Ávila%", t2a="interpretado antes, com um buraco", t2b="depois comparado, como dado",
        cap="Um marcador mantém o programa e os dados em dois canais, então nenhum valor é interpretado como SQL.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l05-split", 720, 250, t["aria"])
    f.text(20, 22, t["built"], anchor="start", bold=True)
    f.box(20, 36, 380, 36, [t["t1"]], stroke="amber", mono=True, size=10, anchor="start")
    f.arrow([(400, 54), (440, 54)], color="amber")
    f.box(440, 36, 260, 36, [t["t1b"]], stroke="amber", size=9.5)
    f.arrow([(177, 90), (177, 74)], color="amber")
    f.text(186, 92, t["t1a"], anchor="start", size=9, italic=True, fill="amber")
    f.text(20, 128, t["sent"], anchor="start", bold=True)
    f.box(20, 142, 380, 36, [t["t2"]], stroke="phosphor", mono=True, size=10, anchor="start")
    f.box(20, 188, 380, 36, [t["v2"]], stroke="wire", mono=True, size=10, anchor="start")
    f.arrow([(400, 160), (440, 160)], color="phosphor")
    f.box(440, 142, 260, 36, [t["t2a"]], stroke="phosphor", size=9.5)
    f.arrow([(400, 206), (440, 206)], color="phosphor")
    f.box(440, 188, 260, 36, [t["t2b"]], stroke="phosphor", size=9.5)
    out["l05-split"] = f.json(t["cap"])
    return out
