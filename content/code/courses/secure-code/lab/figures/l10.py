"""Lesson 10: the figures, and the annotated app.py of "the-portal"."""
from fig import Fig

APP = [
    ("# app.py\nimport hashlib\nfrom datetime import datetime\n\nfrom flask import Flask, abort, jsonify, make_response, request\n\napp = Flask(__name__)\nSESSIONS = {}\n\n",
     "The session table: each id the server has issued, mapped to what it knows about that session. A dictionary here; a database table or Redis in production.",
     "A tabela de sessões: cada id que o servidor emitiu, ligado ao que ele sabe daquela sessão. Aqui um dicionário; em produção, uma tabela de banco ou o Redis."),
    ("def now():\n    return datetime.now()\n\n\ndef check_password(name, password):\n    # Lesson 11 replaces this with a real password store.\n    return (name, password) in {(\"lucia\", \"lucia-pw\"), (\"rafael\", \"rafael-pw\")}\n\n",
     "The clock is a function of its own so a test can move it, as in lesson 1. The password check is a stand-in: storing passwords is lesson 11, and here it would only be in the way.",
     "O relógio é uma função própria para que um teste possa movê-lo, como na aula 1. A verificação de senha é provisória: guardar senhas é a aula 11, e aqui só atrapalharia."),
    ("def new_session_id(name):\n    return hashlib.md5(f\"{name}{now():%Y%m%d%H%M}\".encode()).hexdigest()\n\n",
     "The id: a hash of the name and the minute. It looks random. Keep that impression in mind for the next section.",
     "O id: um hash do nome e do minuto. Parece aleatório. Guarde essa impressão para a próxima seção."),
    ("def current_patient():\n    record = SESSIONS.get(request.cookies.get(\"sid\"))\n    if record is None or record[\"patient\"] is None:\n        abort(401)\n    return record[\"patient\"]\n\n",
     "Every route that needs a patient asks this function. An id the table does not know, or a session nobody has signed in to, is `401`.",
     "Toda rota que precisa de um paciente pergunta a esta função. Um id que a tabela não conhece, ou uma sessão em que ninguém entrou, é `401`."),
    ("@app.get(\"/\")\ndef home():\n    response = make_response(\"Vereda patient portal\\n\")\n    if request.cookies.get(\"sid\") not in SESSIONS:\n        sid = new_session_id(\"visitor\")\n        SESSIONS[sid] = {\"patient\": None}\n        response.set_cookie(\"sid\", sid)\n    return response\n\n",
     "A visitor gets a session before signing in, to remember a language choice or, in lesson 9, a form token. It is anonymous: `patient` is `None`.",
     "Um visitante recebe uma sessão antes de entrar, para lembrar a escolha de idioma ou, na aula 9, um token de formulário. Ela é anônima: `patient` é `None`."),
    ("@app.post(\"/sign-in\")\ndef sign_in():\n    name = request.form.get(\"name\", \"\")\n    if not check_password(name, request.form.get(\"password\", \"\")):\n        abort(401)\n    sid = request.cookies.get(\"sid\")\n    if sid not in SESSIONS:\n        sid = new_session_id(name)\n    SESSIONS[sid] = {\"patient\": name}\n    response = jsonify(patient=name)\n    response.set_cookie(\"sid\", sid)\n    return response\n\n",
     "Sign-in: if the browser already has a session, write the patient into it; otherwise issue one. Ask yourself which id lucia ends up with.",
     "Login: se o navegador já tem uma sessão, grava o paciente nela; senão emite uma. Pergunte-se com qual id a lucia fica."),
    ("@app.get(\"/bookings\")\ndef bookings():\n    return jsonify(patient=current_patient(), bookings=[])\n\n",
     "One page that needs a signed-in patient. The bookings themselves are not this lesson's subject, so the list is empty.",
     "Uma página que exige paciente autenticado. Os agendamentos não são o assunto desta aula, então a lista vem vazia."),
    ("@app.post(\"/sign-out\")\ndef sign_out():\n    response = jsonify(signed_out=True)\n    response.delete_cookie(\"sid\")\n    return response",
     "Sign-out tells the browser to forget the cookie. Notice what it does not touch.",
     "O logout manda o navegador esquecer o cookie. Repare no que ele não toca."),
]
EXAMPLES = {"the-portal": [{"language": "python", "file": "app.py", "parts": APP}]}

T = {
    "en": dict(
        life_aria="The four moments of a session, left to right. Born: on the first visit the server issues a random id and keeps a row for it; the browser keeps the id in a cookie marked HttpOnly, Secure and SameSite. Rotated: at sign-in the old id is deleted and a new one is issued. Expired: on every request the server checks the idle limit of 15 minutes and the absolute limit of 8 hours. Ended: sign-out, a password change or the team deletes the row on the server. Underneath, a note: the cookie carries only the id, and the server holds everything else.",
        steps=[("born", ["random id, 256 bits", "cookie: HttpOnly,", "Secure, SameSite"]),
               ("rotated", ["at sign-in:", "old id deleted,", "new id issued"]),
               ("expired", ["every request checks", "idle: 15 min", "absolute: 8 h"]),
               ("ended", ["sign-out, password", "change, the team:", "row deleted on server"])],
        note="the cookie carries only the id; the server holds everything else",
        life_cap="Four moments, each with one rule. Every rule is checked on the server, where a copied id cannot argue.",
        clocks_aria="Two limits on one working day, from 09:00 to 17:30. The first row, the idle limit of 15 minutes: requests arrive every few minutes, then a gap of 16 minutes with no request, and the session ends at the end of the gap. The second row, the absolute limit of 8 hours: requests arrive every ten minutes all day, never idle, and the session still ends at 17:00, eight hours after sign-in.",
        idle="idle limit, 15 min", absolute="absolute limit, 8 h",
        gap="16 min with no request", ended="ended", ended2="ended, however busy",
        signin="sign-in 09:00",
        clocks_cap="The idle limit ends a session nobody is using; the absolute limit ends one somebody is using too long.",
    ),
    "pt": dict(
        life_aria="Os quatro momentos de uma sessão, da esquerda para a direita. Nasce: na primeira visita o servidor emite um id aleatório e guarda uma linha para ele; o navegador guarda o id num cookie marcado HttpOnly, Secure e SameSite. Renovada: no login o id antigo é apagado e um novo é emitido. Expira: a cada requisição o servidor confere o limite de inatividade de 15 minutos e o limite absoluto de 8 horas. Termina: logout, troca de senha ou a equipe apaga a linha no servidor. Embaixo, uma nota: o cookie leva só o id, e o servidor guarda todo o resto.",
        steps=[("nasce", ["id aleatório, 256 bits", "cookie: HttpOnly,", "Secure, SameSite"]),
               ("renovada", ["no login:", "id antigo apagado,", "id novo emitido"]),
               ("expira", ["toda requisição confere", "inatividade: 15 min", "absoluto: 8 h"]),
               ("termina", ["logout, troca de", "senha, a equipe:", "linha apagada no servidor"])],
        note="o cookie leva só o id; o servidor guarda todo o resto",
        life_same=["cookie: HttpOnly,", "Secure, SameSite"],
        life_cap="Quatro momentos, cada um com uma regra. Toda regra é conferida no servidor, onde um id copiado não tem argumento.",
        clocks_aria="Dois limites num dia de trabalho, das 09:00 às 17:30. A primeira linha, o limite de inatividade de 15 minutos: requisições chegam a cada poucos minutos, depois um intervalo de 16 minutos sem requisição, e a sessão termina no fim do intervalo. A segunda linha, o limite absoluto de 8 horas: requisições chegam a cada dez minutos o dia todo, sem nunca ficar inativa, e mesmo assim a sessão termina às 17:00, oito horas depois do login.",
        idle="inatividade, 15 min", absolute="limite absoluto, 8 h",
        gap="16 min sem requisição", ended="termina", ended2="termina, mesmo em uso",
        signin="login 09:00",
        clocks_cap="O limite de inatividade encerra a sessão que ninguém usa; o absoluto encerra a que alguém usa por tempo demais.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l10-life", 720, 230, t["life_aria"])
    colours = ["phosphor", "wire", "amber", "phosphor"]
    for i, (head, lines) in enumerate(t["steps"]):
        x = 20 + i * 176
        f.text(x + 74, 26, head, bold=True)
        f.box(x, 44, 148, 96, lines, stroke=colours[i], size=9.5)
        if i < 3:
            f.arrow([(x + 148, 92), (x + 176, 92)])
    f.rect(20, 168, 676, 36, stroke="wire", dashed=True)
    f.text(358, 186, t["note"], fill="paper-dim", italic=True)
    out["l10-life"] = f.json(t["life_cap"], same=t.get("life_same"))

    g = Fig("l10-clocks", 720, 240, t["clocks_aria"])
    x0, x1 = 120, 690          # 09:00 .. 17:30
    def X(h):                  # hours after 09:00
        return round(x0 + (x1 - x0) * h / 8.5, 1)
    for h, lab in ((0, "09:00"), (4, "13:00"), (8, "17:00")):
        g.text(X(h), 222, lab, mono=True, size=9, fill="paper-dim")
    # row 1: idle
    g.text(20, 60, t["idle"], anchor="start", size=9.5, bold=True)
    g.arrow([(x0, 80), (x1, 80)], head=False, color="wire")
    ticks = [0, 0.1, 0.2, 0.3, 0.4, 0.5]
    for h in ticks:
        g.arrow([(X(h), 72), (X(h), 88)], head=False, color="phosphor", width=2)
    g.arrow([(X(0.5), 100), (X(0.5 + 16 / 60), 100)], color="amber", both=True)
    g.text(X(0.6) + 70, 112, t["gap"], size=9, fill="paper-dim", italic=True)
    g.rect(X(0.5 + 16 / 60) - 2, 66, 4, 28, stroke="amber", fill="amber", rx=1)
    g.text(X(0.5 + 16 / 60) + 6, 60, t["ended"], anchor="start", size=9, fill="amber")
    # row 2: absolute
    g.text(20, 150, t["absolute"], anchor="start", size=9.5, bold=True)
    g.arrow([(x0, 170), (x1, 170)], head=False, color="wire")
    for k in range(0, 49):
        g.arrow([(X(k / 6), 164), (X(k / 6), 176)], head=False, color="phosphor", width=1)
    g.rect(X(8) - 2, 156, 4, 28, stroke="amber", fill="amber", rx=1)
    g.text(X(8) - 6, 196, t["ended2"], anchor="end", size=9, fill="amber")
    g.text(X(0) + 4, 196, t["signin"], anchor="start", size=9, fill="paper-dim")
    out["l10-clocks"] = g.json(t["clocks_cap"])
    return out
