"""Lesson 9: the figures, and the annotated app.py of "the-portal"."""
from fig import Fig

APP = [
    ("# app.py\nimport secrets\n\nfrom flask import Flask, abort, redirect, render_template_string, request, session\n\napp = Flask(__name__)\napp.secret_key = secrets.token_bytes(32)\nACCOUNTS = {\"lucia\": {\"email\": \"lucia@mail.example\", \"phone\": \"+55 11 5555-0101\"}}\n",
     "One account, held in memory. The e-mail address and the phone number are where a password reset is sent, which is what makes them worth forging a change to.",
     "Uma conta, guardada em memória. O e-mail e o telefone são para onde vai uma recuperação de senha, e é isso que faz valer forjar uma mudança neles."),
    ("PAGE = \"\"\"<h1>Your account</h1>\n<form method=\"post\" action=\"/account/email\">\n  <input name=\"email\" value=\"{{ account.email }}\">\n  <button>Change e-mail</button>\n</form>\n<form method=\"post\" action=\"/account/phone\">\n  <input name=\"phone\" value=\"{{ account.phone }}\">\n  <button>Change phone</button>\n</form>\n\"\"\"\n\n",
     "Two forms. Every field in them is something the sender chooses; nothing in either form is a value only the portal knows.",
     "Dois formulários. Todo campo neles é algo que quem envia escolhe; nada em nenhum dos dois é um valor que só o portal conhece."),
    ("def signed_in():\n    name = session.get(\"patient\")\n    if name is None:\n        abort(401)\n    return name\n\n",
     "The session check. It is right, and it is not enough: a forged request carries a valid session.",
     "A verificação de sessão. Está certa, e não basta: uma requisição forjada leva uma sessão válida."),
    ("@app.get(\"/account\")\ndef account():\n    return render_template_string(PAGE, account=ACCOUNTS[signed_in()])\n\n\n@app.post(\"/account/email\")\ndef change_email():\n    ACCOUNTS[signed_in()][\"email\"] = request.form[\"email\"]\n    return redirect(\"/account\", 303)\n\n\n@app.post(\"/account/phone\")\ndef change_phone():\n    ACCOUNTS[signed_in()][\"phone\"] = request.form[\"phone\"]\n    return redirect(\"/account\", 303)",
     "The page, and two changes. Each change answers `303 See Other`, which sends the browser back to the page with a `GET`, so reloading it does not post the form again.",
     "A página, e duas mudanças. Cada mudança responde `303 See Other`, que manda o navegador de volta à página com um `GET`, para que recarregar não envie o formulário de novo."),
]
EXAMPLES = {"the-portal": [{"language": "python", "file": "app.py", "parts": APP}]}

T = {
    "en": dict(
        cross_aria="How a forged request reaches the portal. lucia's browser has two tabs: in one she is signed in to the portal, in the other she is reading a page on another site. That page contains a form addressed to the portal's change-e-mail route. When the form is submitted, the browser sends the request to the portal and attaches the portal's session cookie, because it attaches a site's cookies to every request to that site. The portal sees a valid session and a well-formed change, and cannot tell that lucia never saw the form.",
        browser="lucia's browser", tab1="tab 1: the portal, signed in", tab2="tab 2: a page on another site",
        tab2b="holds a form aimed at the portal", req="POST /account/email",
        ck="+ the portal's cookie, attached by the browser", portal="the portal",
        p1="valid session", p2="well-formed change", p3="whose intention?",
        cross_cap="The browser attaches the portal's cookie to every request to the portal, whichever page started it.",
        tok_aria="The synchroniser token pattern in three steps. One: lucia's browser asks for GET /account; the portal draws a random token, keeps it in her session and writes it into a hidden field of each form. Two: she submits the form; the request carries the token, the portal compares it with the one in her session, they match, and the change is made. Three: a request started by a page on another site arrives with her cookie but without the token, because that page cannot read the portal's pages; the portal answers 403 and changes nothing.",
        s1a="GET /account", s1b="token drawn, kept in the session,", s1c="written into each form",
        s2a="POST with the token", s2b="matches the session's: 303, changed",
        s3a="POST from another site", s3b="no token: 403, nothing changed",
        tok_cap="Another site can make the browser send a request; it cannot read the portal's page, so it cannot know the token.",
    ),
    "pt": dict(
        cross_aria="Como uma requisição forjada chega ao portal. O navegador da lucia tem duas abas: numa ela está logada no portal, na outra lê uma página de outro site. Essa página contém um formulário endereçado à rota de troca de e-mail do portal. Quando o formulário é enviado, o navegador manda a requisição ao portal e anexa o cookie de sessão do portal, porque anexa os cookies de um site a toda requisição para esse site. O portal vê uma sessão válida e uma mudança bem formada, e não tem como saber que a lucia nunca viu o formulário.",
        browser="o navegador da lucia", tab1="aba 1: o portal, logada", tab2="aba 2: uma página de outro site",
        tab2b="tem um formulário apontado para o portal", req="POST /account/email",
        ck="+ o cookie do portal, anexado pelo navegador", portal="o portal",
        p1="sessão válida", p2="mudança bem formada", p3="intenção de quem?",
        cross_cap="O navegador anexa o cookie do portal a toda requisição para o portal, seja qual for a página que a iniciou.",
        tok_aria="O padrão do token sincronizador em três passos. Um: o navegador da lucia pede GET /account; o portal sorteia um token, guarda na sessão dela e escreve num campo oculto de cada formulário. Dois: ela envia o formulário; a requisição leva o token, o portal o compara com o da sessão, eles batem, e a mudança é feita. Três: uma requisição iniciada por uma página de outro site chega com o cookie dela mas sem o token, porque aquela página não consegue ler as páginas do portal; o portal responde 403 e não muda nada.",
        s1a="GET /account", s1b="token sorteado, guardado na sessão,", s1c="escrito em cada formulário",
        s2a="POST com o token", s2b="bate com o da sessão: 303, mudou",
        s3a="POST de outro site", s3b="sem token: 403, nada mudou",
        tok_cap="Outro site consegue fazer o navegador mandar uma requisição; não consegue ler a página do portal, então não conhece o token.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l09-cross", 720, 250, t["cross_aria"])
    f.text(150, 22, t["browser"], bold=True)
    f.rect(20, 34, 260, 180, stroke="wire", dashed=True)
    f.box(36, 48, 228, 40, [t["tab1"]], stroke="phosphor", size=9.5)
    f.box(36, 108, 228, 52, [t["tab2"], t["tab2b"]], stroke="amber", size=9.5)
    f.text(600, 22, t["portal"], bold=True)
    f.box(520, 70, 170, 100, [t["p1"], t["p2"], "", t["p3"]], stroke="wire", size=10)
    f.arrow([(264, 134), (520, 134)], color="amber")
    f.text(392, 120, t["req"], mono=True, size=9.5)
    f.text(392, 152, t["ck"], size=9, italic=True, fill="paper-dim")
    out["l09-cross"] = f.json(t["cross_cap"])

    g = Fig("l09-token", 720, 250, t["tok_aria"])
    rows = [((t["s1a"],), (t["s1b"], t["s1c"]), "phosphor"),
            ((t["s2a"],), (t["s2b"],), "phosphor"),
            ((t["s3a"],), (t["s3b"],), "amber")]
    for i, (left, right, colour) in enumerate(rows):
        y = 24 + i * 76
        g.text(30, y + 24, str(i + 1), bold=True, size=12, fill=colour)
        g.box(50, y, 220, 48, list(left), stroke="wire", size=9.5)
        g.arrow([(270, y + 24), (380, y + 24)], color=colour)
        g.box(380, y, 310, 48, list(right), stroke=colour, size=9.5)
    out["l09-token"] = g.json(t["tok_cap"], same=(["GET /account"] if lang == "pt" else None))
    return out
