"""Lesson 18: the figures."""
from fig import Fig

T = {
    "en": dict(
        order_aria="Where a security review looks first, as five questions in order of priority, each with the lesson of this course that teaches it. One: who may do this, the authorisation of every new route, lessons 1, 12 and 13. Two: what comes in, and is it validated at the boundary, lessons 2 and 3. Three: where does it go out, and is it encoded for that place, lesson 4. Four: what secrets and settings changed, lesson 16. Five: what dependencies changed, lesson 17. Style and naming come last, and the diagram leaves them off.",
        q=["who may do this?", "what comes in?", "where does it go out?", "which secrets and settings changed?", "which dependencies changed?"],
        sub=["every new route", "validated at the boundary", "encoded for that place", "nothing secret in the diff", "pinned, audited"],
        les=["lessons 1, 12, 13", "lessons 2, 3", "lesson 4", "lesson 16", "lesson 17"],
        first="first", last="then",
        order_cap="Five questions, in this order. A diff that passes the first one badly is not saved by passing the others well.",
        marked_aria="The diff of the messages branch, reduced to the six lines that matter, each with a numbered marker. Marker 1, the new route that reads a message by its number: nothing checks whose message it is. Marker 2, the message built from every form field: the sender can choose whose name it carries. Marker 3, the template that adds the safe filter: escaping is switched off for patients' text. Marker 4, the secret key written as a string in the code. Marker 5, the Flask pin loosened to a range. Marker 6, a new feature with no new test.",
        notes=["nothing checks whose message", "the sender chooses the name", "escaping switched off", "a secret in the repository", "the pin became a range", "no test came with it"],
        notest="(nothing changed in any test)",
        marked_cap="The same diff, as a reviewer marks it. Every marker is a question, and each one has a lesson behind it.",
    ),
    "pt": dict(
        order_aria="Onde uma revisão de segurança olha primeiro, como cinco perguntas em ordem de prioridade, cada uma com a aula deste curso que a ensina. Um: quem pode fazer isto, a autorização de cada rota nova, aulas 1, 12 e 13. Dois: o que entra, e se é validado na fronteira, aulas 2 e 3. Três: para onde sai, e se é codificado para aquele lugar, aula 4. Quatro: que segredos e configurações mudaram, aula 16. Cinco: que dependências mudaram, aula 17. Estilo e nomes vêm por último, e o diagrama os deixa de fora.",
        q=["quem pode fazer isto?", "o que entra?", "para onde sai?", "que segredos e configurações mudaram?", "que dependências mudaram?"],
        sub=["cada rota nova", "validado na fronteira", "codificado para o lugar", "nada secreto no diff", "fixadas, auditadas"],
        les=["aulas 1, 12, 13", "aulas 2, 3", "aula 4", "aula 16", "aula 17"],
        first="primeiro", last="depois",
        order_cap="Cinco perguntas, nesta ordem. Um diff que vai mal na primeira não se salva indo bem nas outras.",
        marked_aria="O diff do branch messages, reduzido às seis linhas que importam, cada uma com um marcador numerado. Marcador 1, a rota nova que lê uma mensagem pelo número: nada verifica de quem é a mensagem. Marcador 2, a mensagem montada com todos os campos do formulário: quem envia escolhe em nome de quem ela fica. Marcador 3, o template que acrescenta o filtro safe: o escape é desligado para o texto dos pacientes. Marcador 4, a chave secreta escrita como string no código. Marcador 5, a versão do Flask afrouxada para um intervalo. Marcador 6, uma funcionalidade nova sem teste novo.",
        notes=["nada verifica de quem é", "quem envia escolhe o nome", "escape desligado", "um segredo no repositório", "a versão virou intervalo", "nenhum teste veio junto"],
        notest="(nenhum teste mudou)",
        marked_cap="O mesmo diff, como um revisor o marca. Cada marcador é uma pergunta, e cada um tem uma aula por trás.",
    ),
}
LINES = [
    '+@app.get("/messages/<int:number>")',
    '+    message = dict(request.form)',
    "+ … m.text|replace('\\n', '<br>')|safe …",
    '+app.secret_key = "vereda-dev"',
    '+flask>=3.0',
    None,
]


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l18-order", 720, 300, t["order_aria"])
    for i in range(5):
        y = 20 + i * 54
        f.box(20, y, 40, 40, [str(i + 1)], stroke="phosphor" if i == 0 else "wire", bold=True, size=12)
        f.box(80, y, 300, 40, [t["q"][i]], stroke="phosphor" if i == 0 else "wire", bold=(i == 0))
        f.text(400, y + 13, t["sub"][i], anchor="start", fill="paper")
        f.text(400, y + 29, t["les"][i], anchor="start", fill="paper-dim", italic=True, size=9.5)
    out["l18-order"] = f.json(t["order_cap"])

    f = Fig("l18-marked", 720, 300, t["marked_aria"])
    f.rect(20, 14, 420, 276, stroke="paper-dim")
    for i, line in enumerate(LINES):
        y = 40 + i * 44
        if line is None:
            f.text(36, y, t["notest"], anchor="start", italic=True, fill="paper-dim")
        else:
            f.text(36, y, line, anchor="start", mono=True, size=9.5)
        f.box(456, y - 14, 28, 28, [str(i + 1)], stroke="amber", bold=True, size=11)
        f.text(496, y, t["notes"][i], anchor="start")
    out["l18-marked"] = f.json(t["marked_cap"])
    return out
