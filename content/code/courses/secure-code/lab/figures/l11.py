"""Lesson 11: the figures, and the annotated app.py of "the-portal"."""
from fig import Fig

APP = [
    ("# app.py\nimport hashlib\nimport secrets\n\nfrom flask import Flask, abort, jsonify, request\n\napp = Flask(__name__)\nUSERS = {}\nSESSIONS = {}\n\n",
     "Two tables: what is stored for each patient's password, and the sessions, mapped from a random id to a name as in lesson 10.",
     "Duas tabelas: o que fica guardado da senha de cada paciente, e as sessões, de um id aleatório para um nome, como na aula 10."),
    ("def set_password(name, password):\n    USERS[name] = hashlib.sha256(password.encode()).hexdigest()\n\n\ndef password_is_right(name, password):\n    return USERS[name] == hashlib.sha256(password.encode()).hexdigest()\n\n",
     "Stored as a SHA-256, and checked by hashing the candidate the same way. One-way, and it looks like nothing. Keep both impressions for the first test.",
     "Guardada como SHA-256, e conferida aplicando o mesmo hash à tentativa. É de mão única, e não parece nada. Guarde as duas impressões para o primeiro teste."),
    ("def policy_problem(password):\n    if len(password) < 8:\n        return \"use at least 8 characters\"\n    if not any(c.isupper() for c in password):\n        return \"add an uppercase letter\"\n    if not any(c.isdigit() for c in password):\n        return \"add a digit\"\n    if password.isalnum():\n        return \"add a symbol\"\n    return None\n\n",
     "The policy answers `None` for an acceptable password and a sentence for the patient otherwise. These are the composition rules many sites still use.",
     "A política responde `None` para uma senha aceitável e uma frase para o paciente nos outros casos. São as regras de composição que muitos sites ainda usam."),
    ("def current_patient():\n    name = SESSIONS.get(request.cookies.get(\"sid\"))\n    if name is None:\n        abort(401)\n    return name\n\n",
     "Lesson 10's session check, without the two clocks.",
     "A conferência de sessão da aula 10, sem os dois relógios."),
    ("@app.post(\"/sign-in\")\ndef sign_in():\n    name = request.form.get(\"name\", \"\")\n    if name not in USERS:\n        return jsonify(error=\"no such patient\"), 404\n    if not password_is_right(name, request.form.get(\"password\", \"\")):\n        return jsonify(error=\"wrong password\"), 401\n    sid = secrets.token_urlsafe(32)\n    SESSIONS[sid] = name\n    response = jsonify(patient=name)\n    response.set_cookie(\"sid\", sid, httponly=True, secure=True, samesite=\"Lax\")\n    return response\n\n",
     "Two helpful error messages. Read them as a stranger would: one of them says whether a name belongs to a patient.",
     "Duas mensagens de erro prestativas. Leia como um estranho leria: uma delas diz se um nome é de um paciente."),
    ("@app.get(\"/me\")\ndef me():\n    return jsonify(patient=current_patient())\n\n",
     "The smallest page that needs a session, so a test can ask whether one still works.",
     "A menor página que exige sessão, para um teste perguntar se uma ainda vale."),
    ("@app.post(\"/password\")\ndef change_password():\n    name = current_patient()\n    if not password_is_right(name, request.form.get(\"current\", \"\")):\n        return jsonify(error=\"wrong password\"), 401\n    new = request.form.get(\"new\", \"\")\n    problem = policy_problem(new)\n    if problem:\n        return jsonify(error=problem), 400\n    set_password(name, new)\n    return jsonify(changed=True)",
     "Changing a password asks for the current one, checks the new one against the policy and stores it. Ask what happens to the patient's other sessions.",
     "Trocar a senha pede a atual, confere a nova com a política e a guarda. Pergunte o que acontece com as outras sessões da paciente."),
]
EXAMPLES = {"the-portal": [{"language": "python", "file": "app.py", "parts": APP}]}

T = {
    "en": dict(
        leak_aria="The same two rows of the password table, as a leaked copy would show them, stored three ways. Plain text: lucia and rafael both show lilac river morning tea, readable at once. A fast hash without salt, SHA-256: both rows show the same hexadecimal string, so equal passwords are visible, and a graphics card tests billions of guesses a second. Argon2id with a salt: the two rows are different strings, each guess costs tens of milliseconds and 64 MiB of memory, and has to be repeated for each patient.",
        cols=[("plain text", "readable at once", "amber"),
              ("SHA-256, no salt", "billions of guesses a second", "amber"),
              ("Argon2id, salted", "each guess: ms and MiB, per patient", "phosphor")],
        rows=[["lilac river morning tea", "lilac river morning tea"],
              ["e57256…fa0c", "e57256…fa0c"],
              ["$argon2id$…$Qm3x…", "$argon2id$…$Zr8k…"]],
        same_note="equal rows: equal passwords",
        leak_cap="What a leaked copy is worth depends only on how the column was written.",
        phc_aria="An Argon2id hash in the PHC string format, split into its parts. argon2id is the algorithm. v=19 is the version of Argon2. m=65536 is the memory in KiB, 64 MiB. t=3 is the number of passes over that memory. p=4 is the number of lanes run in parallel. Then the salt, random and different for every hash, and last the hash itself. Everything needed to check a password is in the string.",
        parts=[("argon2id", "algorithm"), ("v=19", "version"), ("m=65536", "memory, KiB"),
               ("t=3", "passes"), ("p=4", "lanes"), ("salt", "random, per hash"), ("hash", "the result")],
        phc_cap="The parameters travel with the hash, so the cost can be raised later without breaking a single stored password.",
    ),
    "pt": dict(
        leak_aria="As mesmas duas linhas da tabela de senhas, como uma cópia vazada as mostraria, guardadas de três jeitos. Texto puro: lucia e rafael mostram lilac river morning tea, legível na hora. Um hash rápido sem sal, SHA-256: as duas linhas mostram a mesma string hexadecimal, então senhas iguais ficam visíveis, e uma placa de vídeo testa bilhões de palpites por segundo. Argon2id com sal: as duas linhas são strings diferentes, cada palpite custa dezenas de milissegundos e 64 MiB de memória, e precisa ser repetido para cada paciente.",
        cols=[("texto puro", "legível na hora", "amber"),
              ("SHA-256, sem sal", "bilhões de palpites por segundo", "amber"),
              ("Argon2id, com sal", "cada palpite: ms e MiB, por paciente", "phosphor")],
        rows=[["lilac river morning tea", "lilac river morning tea"],
              ["e57256…fa0c", "e57256…fa0c"],
              ["$argon2id$…$Qm3x…", "$argon2id$…$Zr8k…"]],
        same_note="linhas iguais: senhas iguais",
        leak_same=["lucia", "rafael"],
        leak_cap="O que uma cópia vazada vale depende só de como a coluna foi escrita.",
        phc_aria="Um hash Argon2id no formato de string PHC, separado em partes. argon2id é o algoritmo. v=19 é a versão do Argon2. m=65536 é a memória em KiB, 64 MiB. t=3 é o número de passadas sobre essa memória. p=4 é o número de faixas rodando em paralelo. Depois o sal, aleatório e diferente para cada hash, e por último o próprio hash. Tudo o que é preciso para conferir uma senha está na string.",
        parts=[("argon2id", "algoritmo"), ("v=19", "versão"), ("m=65536", "memória, KiB"),
               ("t=3", "passadas"), ("p=4", "faixas"), ("salt", "aleatório, por hash"), ("hash", "o resultado")],
        phc_cap="Os parâmetros viajam com o hash, então o custo pode subir depois sem quebrar nenhuma senha guardada.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l11-leak", 720, 250, t["leak_aria"])
    for i, (head, sub, colour) in enumerate(t["cols"]):
        x = 20 + i * 232
        f.text(x + 106, 22, head, bold=True)
        f.rect(x, 40, 212, 120, stroke=colour)
        f.text(x + 12, 64, "lucia", anchor="start", size=9, fill="paper-dim")
        f.text(x + 12, 80, t["rows"][i][0], anchor="start", mono=True, size=9.5)
        f.text(x + 12, 112, "rafael", anchor="start", size=9, fill="paper-dim")
        f.text(x + 12, 128, t["rows"][i][1], anchor="start", mono=True, size=9.5)
        f.text(x + 106, 182, sub, size=9.5, italic=True, fill="paper-dim")
    f.text(126 + 232, 210, t["same_note"], size=9.5, fill="amber")
    out["l11-leak"] = f.json(t["leak_cap"], same=t.get("leak_same"))

    g = Fig("l11-phc", 720, 140, t["phc_aria"])
    xs = [20, 120, 190, 290, 350, 410, 560]
    ws = [92, 62, 92, 52, 52, 142, 140]
    g.text(20, 30, "$argon2id$v=19$m=65536,t=3,p=4$<salt>$<hash>", anchor="start", mono=True, size=10)
    for (seg, lab), x, w in zip(t["parts"], xs, ws):
        g.box(x, 60, w, 34, [seg], stroke="wire", mono=True, size=9.5)
        g.text(x + w / 2, 116, lab, size=9, fill="paper-dim")
    out["l11-phc"] = g.json(t["phc_cap"])
    return out
