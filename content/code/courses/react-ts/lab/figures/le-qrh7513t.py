from fig import Fig

ss = Fig("server-state", 720, 220,
         {"en": "Two kinds of state. Client state, such as the chosen week or the open course, lives in the browser and "
                "only this app changes it. Server state, the courses and sessions, lives on the server; the browser holds "
                "a cached copy, which other people and other tabs can make stale at any moment.",
          "pt": "Dois tipos de estado. O estado do cliente, como a semana escolhida ou o curso aberto, mora no navegador "
                "e só este app o muda. O estado do servidor, os cursos e as sessões, mora no servidor; o navegador guarda "
                "uma cópia em cache, que outras pessoas e outras abas podem deixar velha a qualquer momento."},
         {"en": "Client state is owned; server state is a copy, and a copy can go stale.",
          "pt": "O estado do cliente tem dono; o do servidor é uma cópia, e uma cópia pode ficar velha."})
ss.box(20, 30, 300, 160, (), tone="phosphor", fill="panel")
ss.text(170, 52, {"en": "the browser", "pt": "o navegador"}, anchor="middle", tone="phosphor", size=11.5)
ss.box(40, 70, 260, 44, [{"en": "client state", "pt": "estado do cliente"}, "monday · openId"], tone="phosphor", size=10.5)
ss.box(40, 128, 260, 44, [{"en": "a cached copy", "pt": "uma cópia em cache"}, "['planner']"], tone="amber", dashed=True, size=10.5)
ss.box(420, 90, 280, 80, [{"en": "the server", "pt": "o servidor"}, "data/planner.json"], tone="amber", size=11)
ss.arrow(418, 140, 302, 150, tone="amber")
ss.text(360, 132, "GET", mono=True, tone="amber", anchor="middle", size=10)
ss.text(560, 196, {"en": "anyone with access may change it", "pt": "qualquer um com acesso pode mudá-lo"}, anchor="middle", tone="dim", size=10.5)

inv = Fig("invalidate", 720, 150,
          {"en": "A timeline of ticking a session. The checkbox calls toggleDone; the mutation sends PATCH to the "
                 "server; when it answers, onSuccess invalidates the planner key; the query fetches GET /api/planner "
                 "again; every component reading the key renders with the new data.",
           "pt": "Uma linha do tempo de marcar uma sessão. A caixa chama o toggleDone; a mutação manda PATCH ao "
                 "servidor; quando ele responde, o onSuccess invalida a key do planejador; a query busca GET "
                 "/api/planner de novo; todo componente que lê a key renderiza com os dados novos."},
          {"en": "Change on the server, mark the copy stale, fetch it again.",
           "pt": "Mude no servidor, marque a cópia como velha, busque de novo."})
steps = [("toggleDone(id)", "phosphor"), (["PATCH", "/api/sessions/s2"], "amber"), ("invalidateQueries", "phosphor"),
         (["GET", "/api/planner"], "amber"), ({"en": "readers render", "pt": "leitores renderizam"}, "phosphor")]
for i, (label, tone) in enumerate(steps):
    x = 10 + i * 142
    mono = not isinstance(label, dict)
    inv.box(x, 20, 130, 44, label, mono=mono, tone=tone, size=9.5 if mono else 11)
    if i < len(steps) - 1:
        inv.arrow(x + 131, 42, x + 141, 42)
inv.text(225, 90, {"en": "the server changes", "pt": "o servidor muda"}, anchor="middle", tone="amber", size=10.5)
inv.text(507, 90, {"en": "the copy is fetched again", "pt": "a cópia é buscada de novo"}, anchor="middle", tone="amber", size=10.5)

FIGS = [ss, inv]
