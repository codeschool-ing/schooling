"""Lesson 8: the figure, and the annotated app.py of "the-portal"."""
from fig import Fig

APP = [
    ("# app.py\nimport logging\n\nfrom flask import Flask, render_template_string\n\napp = Flask(__name__)\nlog = logging.getLogger(\"portal\")\n",
     "A logger named `portal`, as in lesson 15. Nothing writes to it yet; the reports of the third section will.",
     "Um logger chamado `portal`, como na aula 15. Nada escreve nele ainda; os relatórios da terceira seção vão escrever."),
    ("PAGE = \"\"\"<!doctype html>\n<html lang=\"en\">\n<head><meta charset=\"utf-8\"><title>Vereda</title></head>\n<body>\n<h1>Your next session</h1>\n<p id=\"when\">Monday 16 November, 09:00, with carla</p>",
     "The page's title in the HTML is just `Vereda`. Watch what sets the rest of it.",
     "O título da página no HTML é só `Vereda`. Repare no que define o resto dele."),
    ("<button onclick=\"document.getElementById('when').classList.toggle('large')\">Larger text</button>",
     "An inline event handler: JavaScript inside an attribute, run when the button is clicked. A policy that refuses inline script refuses this too.",
     "Um tratador de evento inline: JavaScript dentro de um atributo, rodado quando o botão é clicado. Uma política que recusa script inline recusa isto também."),
    ("<script>\n  document.title = \"Vereda: \" + document.getElementById(\"when\").textContent;\n</script>\n</body>\n</html>\n\"\"\"\n\n",
     "An inline script, the portal's own, which puts the next session in the browser tab's title.",
     "Um script inline, do próprio portal, que põe a próxima sessão no título da aba do navegador."),
    ("@app.get(\"/\")\ndef home():\n    return render_template_string(PAGE)",
     "One page. In the real portal the session comes from the database; here it is written into the page.",
     "Uma página. No portal de verdade a sessão vem do banco; aqui está escrita na página."),
]
EXAMPLES = {"the-portal": [{"language": "python", "file": "app.py", "parts": APP}]}

T = {
    "en": dict(
        aria="A Content Security Policy at work. The header script-src 'self' reaches the browser with the page. Three scripts try to run. A script loaded from the portal's own file, /static/portal.js, runs. A script written inside the page, whoever put it there, is refused. A script from another host is refused. Each refusal is reported to the portal's /csp-report.",
        header="Content-Security-Policy: script-src 'self'",
        browser="the browser checks each script against the policy",
        rows=[("/static/portal.js", "the portal's own file", "runs", "phosphor"),
              ("<script> inside the page", "whoever put it there", "refused, reported", "amber"),
              ("a script from another host", "a host not in the policy", "refused, reported", "amber")],
        cap="The policy cannot tell good inline script from bad, so it refuses all of it. That is the price, and the protection.",
    ),
    "pt": dict(
        aria="Uma Content Security Policy em ação. O cabeçalho script-src 'self' chega ao navegador com a página. Três scripts tentam rodar. Um script carregado de um arquivo do próprio portal, /static/portal.js, roda. Um script escrito dentro da página, seja quem for que o pôs ali, é recusado. Um script de outro host é recusado. Cada recusa é relatada ao /csp-report do portal.",
        header="Content-Security-Policy: script-src 'self'",
        browser="o navegador confere cada script com a política",
        rows=[("/static/portal.js", "um arquivo do próprio portal", "roda", "phosphor"),
              ("<script> dentro da página", "seja quem for que o pôs ali", "recusado, relatado", "amber"),
              ("um script de outro host", "um host fora da política", "recusado, relatado", "amber")],
        same=["/static/portal.js"],
        cap="A política não distingue script inline bom de ruim, então recusa todos. É esse o preço, e a proteção.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l08-policy", 720, 250, t["aria"])
    f.box(20, 16, 680, 32, [t["header"]], stroke="phosphor", mono=True, size=10)
    f.text(360, 66, t["browser"], size=9.5, italic=True, fill="paper-dim")
    for i, (what, who, verdict, colour) in enumerate(t["rows"]):
        y = 84 + i * 54
        f.box(20, y, 300, 42, [what, who], stroke="wire", size=9.5)
        f.arrow([(320, y + 21), (460, y + 21)], color=colour)
        f.box(460, y, 240, 42, [verdict], stroke=colour, size=10)
    out["l08-policy"] = f.json(t["cap"], same=t.get("same"))
    return out
