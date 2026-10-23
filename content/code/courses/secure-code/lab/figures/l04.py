"""Lesson 4: the figures and annotated examples."""
from fig import Fig

V = 'Lu "B" <3 & co'
OUT = [
    ("html", "<p>…</p>", "Lu &#34;B&#34; &lt;3 &amp; co", "escape()"),
    ("attr", 'value="…"', "Lu &#34;B&#34; &lt;3 &amp; co", "escape()"),
    ("js", "<script>…</script>", '"Lu \\"B\\" \\u003c3 \\u0026 co"', "|tojson"),
    ("url", "/search?q=…", "Lu+%22B%22+%3C3+%26+co", "quote_plus()"),
]
T = {
    "en": dict(
        aria='The same value, Lu "B" <3 & co, written into four places in a page, with what it must become in each. In the text of an HTML element it becomes Lu &#34;B&#34; &lt;3 &amp; co. In a quoted attribute it becomes the same, and the quotes around the attribute are what make that enough. Inside a script it becomes a JavaScript string literal written by tojson, with the angle bracket and the ampersand as \\u003c and \\u0026. In a URL query it becomes Lu+%22B%22+%3C3+%26+co.',
        value="one value", heads=["HTML text", "quoted attribute", "inside <script>", "URL query"],
        by="written by",
        cap="One value, four places, four encodings. The place decides the encoding, and nothing about the value does.",
        layers_aria="A URL inside an HTML attribute needs two encodings, applied from the inside out. First the value is URL-encoded to go into the query string. Then the whole URL is HTML-escaped to go into the attribute. Reading the page, the browser undoes them in the opposite order: it decodes the attribute first, then the URL.",
        l1="the value", l2="URL-encoded: goes into the query", l3="HTML-escaped: goes into href=\"…\"",
        writes="the server writes, inside out", reads="the browser reads, outside in",
        layers_cap="Contexts nest. Each layer gets its own encoding, innermost first.",
    ),
    "pt": dict(
        aria='O mesmo valor, Lu "B" <3 & co, escrito em quatro lugares de uma página, com o que ele precisa virar em cada um. No texto de um elemento HTML vira Lu &#34;B&#34; &lt;3 &amp; co. Num atributo entre aspas vira o mesmo, e são as aspas em volta do atributo que tornam isso suficiente. Dentro de um script vira um literal de string JavaScript escrito pelo tojson, com o sinal de menor e o e comercial como \\u003c e \\u0026. Numa query de URL vira Lu+%22B%22+%3C3+%26+co.',
        value="um valor", heads=["texto HTML", "atributo entre aspas", "dentro de <script>", "query de URL"],
        by="escrito por",
        cap="Um valor, quatro lugares, quatro codificações. O lugar decide a codificação, e nada no valor decide.",
        layers_aria="Uma URL dentro de um atributo HTML precisa de duas codificações, aplicadas de dentro para fora. Primeiro o valor é codificado para URL, para entrar na query string. Depois a URL inteira é escapada para HTML, para entrar no atributo. Lendo a página, o navegador desfaz na ordem contrária: decodifica o atributo primeiro, depois a URL.",
        l1="o valor", l2="codificado para URL: entra na query", l3="escapado para HTML: entra em href=\"…\"",
        writes="o servidor escreve, de dentro para fora", reads="o navegador lê, de fora para dentro",
        layers_cap="Contextos se aninham. Cada camada recebe a própria codificação, a mais interna primeiro.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l04-four", 720, 300, t["aria"])
    f.box(260, 14, 200, 34, [V], stroke="phosphor", mono=True, bold=True)
    for i, (k, where, enc, by) in enumerate(OUT):
        y = 80 + i * 52
        f.box(20, y, 150, 40, [t["heads"][i]], stroke="wire")
        f.box(200, y, 300, 40, [enc], stroke="amber", mono=True, size=9.5)
        f.text(515, y + 20, t["by"], anchor="start", size=9.5, fill="paper-dim")
        f.text(590, y + 20, by, anchor="start", mono=True, size=9.5, fill="paper")
        f.arrow([(170, y + 20), (200, y + 20)])
    out["l04-four"] = f.json(t["cap"], same=None)

    f = Fig("l04-layers", 720, 230, t["layers_aria"])
    f.rect(140, 20, 440, 150, stroke="amber")
    f.text(360, 38, t["l3"], fill="paper")
    f.rect(190, 52, 340, 100, stroke="phosphor")
    f.text(360, 70, t["l2"], fill="paper")
    f.box(260, 90, 200, 40, [t["l1"]], stroke="wire")
    f.arrow([(40, 190), (330, 190)], color="paper-dim")
    f.text(185, 210, t["writes"], fill="paper-dim", italic=True)
    f.arrow([(680, 190), (390, 190)], color="paper-dim")
    f.text(535, 210, t["reads"], fill="paper-dim", italic=True)
    out["l04-layers"] = f.json(t["layers_cap"])
    return out


FIXED = [
    ("from urllib.parse import urlsplit\n\nfrom flask import Flask, render_template_string\n\nfrom profiles import PROFILES\n\napp = Flask(__name__)\n",
     "The data moves to `profiles.py`, unchanged, so the diff shows only the page.",
     "Os dados vão para `profiles.py`, sem mudança, para o diff mostrar só a página."),
    ("PAGE = \"\"\"<h1>{{ p.name }}</h1>\n<input name=\"nickname\" value=\"{{ p.nickname }}\">\n{% if website %}<a href=\"{{ website }}\">website</a>{% endif %}\n<a href=\"{{ url_for('search', q=p.name) }}\">bookings of {{ p.name }}</a>\n<script>const note = {{ p.note|tojson }};</script>\n\"\"\"\n",
     "One template, four contexts. Jinja escapes `{{ … }}` for HTML in the text and in the **quoted** attribute; `url_for` builds the query; `tojson` writes a JavaScript literal safe inside `<script>`.",
     "Um template, quatro contextos. O Jinja escapa `{{ … }}` para HTML no texto e no atributo **entre aspas**; `url_for` monta a query; `tojson` escreve um literal JavaScript seguro dentro de `<script>`."),
    ("\ndef web_link(url):\n    return url if urlsplit(url).scheme in (\"http\", \"https\") else None\n",
     "Escaping makes a link's text harmless and says nothing about where it goes. Only web addresses become links.",
     "O escape torna inofensivo o texto de um link e não diz nada sobre para onde ele vai. Só endereços web viram links."),
    ("\n@app.get(\"/patients/<user>\")\ndef profile(user):\n    p = PROFILES[user]\n    return render_template_string(PAGE, p=p, website=web_link(p[\"website\"]))\n\n\n@app.get(\"/search\")\ndef search():\n    return \"\"",
     "`/search` exists so `url_for` has a route to name; what it does is lesson 5's.",
     "`/search` existe para o `url_for` ter uma rota para nomear; o que ela faz é assunto da aula 5."),
]

EXAMPLES = {"the-fix": [{"language": "python", "file": "app.py", "parts": FIXED}]}
