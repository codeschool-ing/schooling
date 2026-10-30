from fig import Fig

rt = Fig("round-trip", 720, 190,
         {"en": "One press of a session's button. The browser posts the form to the page's address. On the server, "
                "setDone sends PATCH to the API, then refresh renders the page again, which sends GET to the API. "
                "The answer to the POST carries the new page, and the browser fits it in.",
          "pt": "Um toque no botão de uma sessão. O navegador envia o formulário ao endereço da página. No servidor, o "
                "setDone manda PATCH à API, depois o refresh renderiza a página de novo, o que manda GET à API. A "
                "resposta ao POST traz a página nova, e o navegador a encaixa."},
         {"en": "One request from the browser; the server does the rest and answers with the page.",
          "pt": "Uma requisição do navegador; o servidor faz o resto e responde com a página."})
rt.box(20, 60, 140, 60, [{"en": "the browser", "pt": "o navegador"}, "POST /?week=…"], tone="phosphor", size=10.5)
rt.box(240, 30, 220, 120, (), tone="amber", fill="panel")
rt.text(350, 48, {"en": "the Next.js server", "pt": "o servidor Next.js"}, anchor="middle", tone="amber", size=11)
rt.box(256, 62, 188, 30, "setDone('s2', true)", mono=True, tone="amber", size=10)
rt.box(256, 104, 188, 30, "refresh() → Planner", mono=True, tone="amber", size=10)
rt.box(560, 60, 140, 60, ["API :3001", "PATCH · GET"], mono=True, tone="wire", text_tone="paper", size=10)
rt.arrow(162, 80, 238, 80, tone="phosphor")
rt.arrow(446, 77, 558, 77, tone="amber")
rt.arrow(446, 119, 558, 103, tone="amber")
rt.arrow(238, 104, 162, 104, tone="amber")
rt.text(200, 124, {"en": "the new page", "pt": "a página nova"}, anchor="middle", tone="amber", size=10)
rt.text(360, 176, {"en": "the browser makes one request; the API is asked twice, by the server",
                   "pt": "o navegador faz uma requisição; a API é consultada duas vezes, pelo servidor"},
        anchor="middle", tone="dim", size=10.5)

op = Fig("optimistic", 720, 230,
         {"en": "Two timelines of the button's pressed state. Success: at the click the shown value becomes pressed, "
                "while the server value is still not pressed; after four seconds the server says pressed and the "
                "shown value follows it, unchanged. Failure: the shown value becomes pressed at the click; when the "
                "Action ends with nothing saved, the shown value returns to the server's, not pressed, and an alert "
                "says why.",
          "pt": "Duas linhas do tempo do estado pressionado do botão. Sucesso: no clique o valor mostrado vira pressionado, "
                "enquanto o valor do servidor ainda é não pressionado; depois de quatro segundos o servidor diz "
                "pressionado e o valor mostrado o acompanha, sem mudar. Falha: o valor mostrado vira pressionado no "
                "clique; quando a Action termina sem nada salvo, o valor mostrado volta ao do servidor, não "
                "pressionado, e um alerta diz por quê."},
         {"en": "During the Action the copy shows; after it, the server's value does.",
          "pt": "Durante a Action aparece a cópia; depois dela, o valor do servidor."})
for row, (title, end_label, end_tone) in enumerate([
        ({"en": "it worked", "pt": "deu certo"}, {"en": "server: pressed", "pt": "servidor: pressionado"}, "phosphor"),
        ({"en": "it failed", "pt": "falhou"}, {"en": "server: not pressed + alert", "pt": "servidor: não pressionado + alerta"}, "amber")]):
    y = 40 + row * 95
    op.text(20, y + 18, title, tone=end_tone, size=11)
    op.box(120, y, 130, 36, {"en": "not pressed", "pt": "não pressionado"}, tone="wire", text_tone="paper", size=10.5)
    op.arrow(252, y + 18, 278, y + 18)
    op.box(280, y, 210, 36, {"en": "pressed · saving…", "pt": "pressionado · saving…"}, tone="phosphor", size=10.5, dashed=True)
    op.arrow(492, y + 18, 518, y + 18)
    op.box(520, y, 180, 36, end_label, tone=end_tone, size=10.5)
    op.text(385, y + 52, {"en": "the optimistic copy, during the Action", "pt": "a cópia otimista, durante a Action"},
            anchor="middle", tone="dim", size=10)
op.text(185, 32, {"en": "click", "pt": "clique"}, anchor="middle", tone="dim", size=10)

FIGS = [rt, op]
