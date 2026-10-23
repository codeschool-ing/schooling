"""Lesson 7: the figure, and the annotated app.py of "the-inbox"."""
from fig import Fig

APP = [
    ("# app.py\nfrom flask import Flask, render_template_string, request\n\napp = Flask(__name__)\nMESSAGES = [\n    {\"patient\": \"lucia\", \"text\": \"Knee <b>much</b> better since Monday.\\nSee you Thursday.\"},\n    {\"patient\": \"rafael\", \"text\": \"Can I move Tuesday's session?\"},\n]\n",
     "Two messages, held in memory. lucia's has a line break and, from the e-mail editor she copied it from, a pair of bold tags.",
     "Duas mensagens, guardadas em memória. A da lucia tem uma quebra de linha e, do editor de e-mail de onde ela copiou, um par de tags de negrito."),
    ("INBOX = \"\"\"<!doctype html>\n<html lang=\"en\">\n<head><meta charset=\"utf-8\"><title>Inbox</title></head>\n<body>\n<h1 id=\"reply\">Inbox</h1>\n<form action=\"/search\"><input name=\"q\"><button>Search</button></form>\n{% for m in messages %}\n<p class=\"message\"><strong>{{ m.patient }}</strong>: {{ m.text|replace(\"\\\\n\", \"<br>\")|safe }}</p>\n{% endfor %}\n<script src=\"/static/inbox.js\"></script>\n</body>\n</html>\n\"\"\"\n\n",
     "The inbox page. Each message's line breaks become `<br>`, and the result is marked `safe` so the `<br>` tags survive. Read what else survives with them.",
     "A página da caixa de entrada. As quebras de linha de cada mensagem viram `<br>`, e o resultado é marcado `safe` para as tags `<br>` sobreviverem. Leia o que mais sobrevive junto."),
    ("@app.get(\"/inbox\")\ndef inbox():\n    return render_template_string(INBOX, messages=MESSAGES)\n\n",
     "The inbox, rendered from the template, with the messages as a variable.",
     "A caixa de entrada, desenhada pelo template, com as mensagens como variável."),
    ("@app.get(\"/search\")\ndef search():\n    term = request.args.get(\"q\", \"\")\n    found = [m for m in MESSAGES if term.lower() in m[\"text\"].lower()]\n    if not found:\n        return f\"<p>No messages match {term}.</p>\"\n    return render_template_string(INBOX, messages=found)",
     "The search shows the matching messages in the same template, and a sentence when nothing matches. Look at how that sentence is built.",
     "A busca mostra as mensagens encontradas no mesmo template, e uma frase quando nada é encontrado. Repare em como essa frase é montada."),
]
EXAMPLES = {"the-inbox": [{"language": "python", "file": "app.py", "parts": APP}]}

T = {
    "en": dict(
        aria="The three kinds of cross-site scripting, by where the text comes from. Reflected: the text arrives in a request, a search term, and the response echoes it to the same person. Stored: the text is saved first, a patient's message, and shown later to everybody who opens the inbox. DOM-based: the text is in the address after the hash sign, never reaches the server, and the page's own script writes it into the page. In each case the defence is to keep the text as text where it is written.",
        h=("where the text comes from", "what writes it into the page", "who sees it"),
        rows=[("reflected", "a search term in the request", "the response, at once", "the person who sent it"),
              ("stored", "a message, saved earlier", "the inbox, later", "every receptionist"),
              ("DOM-based", "the address, after #", "the page's own script", "whoever opens the link")],
        cap="Three sources, three places the defence can go missing. The fix in each is the one lesson 4 taught: the text stays text.",
    ),
    "pt": dict(
        aria="Os três tipos de cross-site scripting, conforme de onde vem o texto. Refletido: o texto chega numa requisição, um termo de busca, e a resposta o devolve à mesma pessoa. Armazenado: o texto é salvo antes, a mensagem de um paciente, e mostrado depois a todos que abrem a caixa de entrada. Baseado no DOM: o texto está no endereço depois do sinal de cerquilha, nunca chega ao servidor, e o próprio script da página o escreve na página. Em todos os casos a defesa é manter o texto como texto onde ele é escrito.",
        h=("de onde vem o texto", "o que o escreve na página", "quem vê"),
        rows=[("refletido", "um termo de busca na requisição", "a resposta, na hora", "quem a mandou"),
              ("armazenado", "uma mensagem, salva antes", "a caixa de entrada, depois", "toda a recepção"),
              ("baseado no DOM", "o endereço, depois do #", "o próprio script da página", "quem abre o link")],
        cap="Três origens, três lugares onde a defesa pode faltar. A correção em cada um é a que a aula 4 ensinou: o texto continua texto.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l07-kinds", 720, 230, t["aria"])
    xs = [20, 150, 360, 550]
    ws = [110, 190, 170, 150]
    for x, w, h in zip(xs[1:], ws[1:], t["h"]):
        f.text(x + w / 2, 22, h, bold=True, size=9.5)
    colours = ["amber", "amber", "amber"]
    for i, (kind, src, writer, who) in enumerate(t["rows"]):
        y = 40 + i * 60
        f.box(xs[0], y, ws[0], 42, [kind], stroke="phosphor", bold=True, size=10)
        f.box(xs[1], y, ws[1], 42, [src], stroke="wire", size=9.5)
        f.box(xs[2], y, ws[2], 42, [writer], stroke=colours[i], size=9.5)
        f.box(xs[3], y, ws[3], 42, [who], stroke="wire", size=9.5)
        f.arrow([(xs[1] + ws[1], y + 21), (xs[2], y + 21)])
        f.arrow([(xs[2] + ws[2], y + 21), (xs[3], y + 21)])
    out["l07-kinds"] = f.json(t["cap"])
    return out
