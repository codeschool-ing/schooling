"""Lesson 1: the figures and annotated examples."""
from fig import Fig

T = {
    "en": dict(
        births_aria="Three places a flaw is born, left to right in the order a feature is made. In the requirement: nobody wrote that a patient may cancel only their own booking. In the design: the staff console was designed to answer from the internet. In the implementation: the search joins the patient's text into SQL. Under each, the cheapest place to catch it: reading the requirement, a threat model, a code review or a test. An arrow along the bottom says the cost of a fix grows the later the flaw is found.",
        req="requirement", des="design", imp="implementation",
        req1="“a patient may cancel", req2="a booking” — whose?",
        des1="the staff console", des2="answers from the internet",
        imp1="the search joins", imp2="text into SQL",
        caught="caught cheapest by",
        c1="reading the requirement", c2="a threat model", c3="a review, a test",
        cost="the later it is found, the more the fix costs",
        births_cap="The same portal, three flaws, born in three different places. Each is cheapest to catch where it was born.",
        method_aria="The loop every lesson of this course follows, drawn as four steps in a circle. One: write the test that states the requirement. Two: run it and watch it fail, which proves the flaw is there. Three: fix the code. Four: run it and watch it pass, then commit both. The test stays in the folder, so the flaw cannot come back unnoticed.",
        m1a="write the test that", m1b="states the requirement",
        m2a="watch it fail:", m2b="the flaw is real",
        m3a="fix the code", m4a="watch it pass,", m4b="commit both",
        stays="the test stays, so the flaw cannot come back unnoticed",
        method_cap="Four steps, in every lesson. A fix with no failing test before it is a fix nobody can show worked.",
        ws_aria="The workspace this course builds. A folder called sc in your home directory holds a Python virtual environment, .venv, with Flask 3.1.3 and pytest 9.1.1 installed in it, and one folder per lesson. Each lesson folder is a git repository of its own with an app.py and a test_app.py. Lesson 1's folder is cancel.",
        venv_note="Flask 3.1.3 and pytest 9.1.1, pinned",
        lesson_note="one folder per lesson, each a git repository",
        later="… and one more per lesson",
        ws_cap="One environment shared by every lesson, and one small application per lesson that you can break and reset.",
    ),
    "pt": dict(
        births_aria="Três lugares onde uma falha nasce, da esquerda para a direita na ordem em que uma funcionalidade é feita. No requisito: ninguém escreveu que um paciente só pode cancelar o próprio agendamento. No projeto: o console da equipe foi projetado para responder pela internet. Na implementação: a busca junta o texto do paciente ao SQL. Embaixo de cada uma, o lugar mais barato para pegá-la: lendo o requisito, num modelo de ameaças, numa revisão de código ou num teste. Uma seta embaixo diz que o custo da correção cresce quanto mais tarde a falha é encontrada.",
        req="requisito", des="projeto", imp="implementação",
        req1="“o paciente pode cancelar", req2="um agendamento” — de quem?",
        des1="o console da equipe", des2="responde pela internet",
        imp1="a busca junta o", imp2="texto ao SQL",
        caught="pega mais barato por",
        c1="ler o requisito", c2="um modelo de ameaças", c3="uma revisão, um teste",
        cost="quanto mais tarde for encontrada, mais cara a correção",
        births_cap="O mesmo portal, três falhas, nascidas em três lugares diferentes. Cada uma sai mais barata de pegar onde nasceu.",
        method_aria="O ciclo que toda aula deste curso segue, desenhado como quatro passos em círculo. Um: escrever o teste que enuncia o requisito. Dois: rodar e ver falhar, o que prova que a falha existe. Três: corrigir o código. Quatro: rodar e ver passar, e então fazer o commit dos dois. O teste fica na pasta, então a falha não volta sem que ninguém perceba.",
        m1a="escrever o teste que", m1b="enuncia o requisito",
        m2a="ver falhar:", m2b="a falha é real",
        m3a="corrigir o código", m4a="ver passar,", m4b="commit dos dois",
        stays="o teste fica, então a falha não volta sem ninguém perceber",
        method_cap="Quatro passos, em toda aula. Uma correção sem um teste falhando antes dela é uma correção que ninguém consegue mostrar que funcionou.",
        ws_aria="O espaço de trabalho que este curso monta. Uma pasta chamada sc no seu diretório pessoal guarda um ambiente virtual Python, .venv, com Flask 3.1.3 e pytest 9.1.1 instalados, e uma pasta por aula. Cada pasta de aula é um repositório git próprio, com um app.py e um test_app.py. A pasta da aula 1 é cancel.",
        venv_note="Flask 3.1.3 e pytest 9.1.1, com versão fixa",
        lesson_note="uma pasta por aula, cada uma um repositório git",
        later="… e mais uma por aula",
        ws_cap="Um ambiente compartilhado por todas as aulas, e uma aplicação pequena por aula, que você pode quebrar e restaurar.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}

    f = Fig("l01-births", 720, 290, t["births_aria"])
    xs = [30, 260, 490]
    heads = [t["req"], t["des"], t["imp"]]
    ex = [(t["req1"], t["req2"]), (t["des1"], t["des2"]), (t["imp1"], t["imp2"])]
    caught = [t["c1"], t["c2"], t["c3"]]
    for i, x in enumerate(xs):
        f.box(x, 30, 200, 36, [heads[i]], stroke="phosphor", bold=True, size=11)
        f.box(x, 86, 200, 54, list(ex[i]), stroke="wire", size=10)
        f.text(x + 100, 168, t["caught"], fill="paper-dim", italic=True)
        f.box(x, 182, 200, 36, [caught[i]], stroke="amber", size=10)
        if i < 2:
            f.arrow([(x + 200, 48), (xs[i + 1], 48)])
    f.arrow([(30, 256), (690, 256)], color="amber", width=1.6)
    f.text(360, 274, t["cost"], fill="paper-dim", italic=True)
    out["l01-births"] = f.json(t["births_cap"])

    f = Fig("l01-method", 720, 300, t["method_aria"])
    f.box(260, 20, 200, 50, [t["m1a"], t["m1b"]], stroke="phosphor")
    f.box(500, 110, 190, 50, [t["m2a"], t["m2b"]], stroke="amber")
    f.box(260, 200, 200, 50, [t["m3a"]], stroke="wire")
    f.box(30, 110, 190, 50, [t["m4a"], t["m4b"]], stroke="phosphor")
    f.arrow([(460, 45), (595, 45), (595, 110)])
    f.arrow([(595, 160), (595, 225), (460, 225)])
    f.arrow([(260, 225), (125, 225), (125, 160)])
    f.arrow([(125, 110), (125, 45), (260, 45)], dashed=True)
    f.text(360, 280, t["stays"], fill="paper-dim", italic=True)
    out["l01-method"] = f.json(t["method_cap"])

    f = Fig("l01-workspace", 720, 250, t["ws_aria"])
    f.box(30, 100, 140, 44, ["~/sc"], stroke="paper-dim", mono=True, bold=True, size=11)
    f.rect(240, 20, 450, 60)
    f.text(256, 40, ".venv", anchor="start", mono=True, bold=True, size=10.5)
    f.text(256, 62, t["venv_note"], anchor="start")
    f.rect(240, 100, 450, 130, stroke="phosphor")
    f.text(256, 120, "cancel/", anchor="start", mono=True, bold=True, size=10.5)
    f.text(256, 142, "app.py   test_app.py   .git/", anchor="start", mono=True, size=9.5, fill="paper-dim")
    f.text(256, 172, t["lesson_note"], anchor="start")
    f.text(256, 204, t["later"], anchor="start", fill="paper-dim", italic=True)
    f.arrow([(170, 116), (205, 116), (205, 50), (240, 50)])
    f.arrow([(170, 128), (240, 128)])
    out["l01-workspace"] = f.json(t["ws_cap"])
    return out


APP_V1 = [
    ("import secrets\nfrom datetime import datetime, timedelta\n\nfrom flask import Flask, abort, jsonify, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\n",
     "Flask signs the session cookie with `secret_key`. A random one at every start is enough for a program that only runs on your machine; lesson 16 is about keeping a real one.",
     "O Flask assina o cookie de sessão com a `secret_key`. Uma aleatória a cada início basta para um programa que só roda na sua máquina; a aula 16 trata de guardar uma de verdade."),
    ("BOOKINGS = {\n    101: {\"patient\": \"lucia\", \"starts\": datetime(2026, 11, 3, 9, 0), \"status\": \"booked\"},\n    102: {\"patient\": \"rafael\", \"starts\": datetime(2026, 11, 3, 10, 0), \"status\": \"booked\"},\n}\n\n",
     "Two bookings held in memory instead of a database, so the whole program fits on the page. Lesson 5 brings in SQLite.",
     "Dois agendamentos guardados na memória em vez de um banco de dados, para o programa inteiro caber na página. A aula 5 traz o SQLite."),
    ("def now():\n    return datetime.now()\n\n\ndef can_cancel(booking, at):\n    return booking[\"starts\"] - at >= timedelta(hours=24)\n\n",
     "The clock is a function of its own, so a test can replace it. The rule is the requirement word for word: at least 24 hours before the session.",
     "O relógio é uma função separada, para que um teste possa substituí-lo. A regra é o requisito palavra por palavra: pelo menos 24 horas antes da sessão."),
    ("@app.post(\"/bookings/<int:booking_id>/cancel\")\ndef cancel(booking_id):\n    if \"patient\" not in session:\n        abort(401)\n    booking = BOOKINGS.get(booking_id)\n    if booking is None:\n        abort(404)\n    if not can_cancel(booking, now()):\n        abort(409)\n    booking[\"status\"] = \"cancelled\"\n    return jsonify(id=booking_id, status=booking[\"status\"])",
     "Signed in, the booking exists, still in time: cancel it. Each check answers one sentence of the requirement. Read them and ask which sentence was never written.",
     "Entrou, o agendamento existe, ainda dá tempo: cancela. Cada verificação responde a uma frase do requisito. Leia todas e pergunte qual frase nunca foi escrita."),
]

EXAMPLES = {"first-flaw": [{"language": "python", "file": "app.py", "parts": APP_V1}]}
