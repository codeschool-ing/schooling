from fig import Fig

sc = Fig("server-client", 720, 250,
         {"en": "Where each part of the Next.js planner runs. On the server: page, Planner and getPlanner, which fetches "
                "from the API on port 3001. They send HTML and a description of the result to the browser. In the "
                "browser: WeekKeys, the one Client Component, which receives the string monday as a prop. The API's "
                "address never leaves the server.",
          "pt": "Onde cada parte do planejador em Next.js roda. No servidor: page, Planner e getPlanner, que busca da API "
                "na porta 3001. Eles mandam HTML e uma descrição do resultado ao navegador. No navegador: WeekKeys, o "
                "único Client Component, que recebe a string monday como prop. O endereço da API nunca sai do servidor."},
         {"en": "Server Components send results; only the Client Component's code travels.",
          "pt": "Server Components mandam resultados; só o código do Client Component viaja."})
sc.box(20, 20, 330, 200, (), tone="amber", fill="panel")
sc.text(185, 42, {"en": "the server", "pt": "o servidor"}, anchor="middle", tone="amber", size=11.5)
sc.box(40, 60, 130, 30, "page.tsx", mono=True, tone="amber", size=10)
sc.box(40, 110, 130, 30, "Planner.tsx", mono=True, tone="amber", size=10)
sc.box(40, 160, 130, 30, "getPlanner()", mono=True, tone="amber", size=10)
sc.line(105, 90, 105, 110, tone="amber")
sc.line(105, 140, 105, 160, tone="amber")
sc.box(210, 160, 120, 30, ":3001 API", mono=True, tone="wire", text_tone="paper", size=10)
sc.arrow(172, 175, 208, 175, tone="amber")
sc.box(390, 20, 310, 200, (), tone="phosphor", fill="panel")
sc.text(545, 42, {"en": "the browser", "pt": "o navegador"}, anchor="middle", tone="phosphor", size=11.5)
sc.box(410, 70, 270, 50, [{"en": "the page, as HTML", "pt": "a página, em HTML"}, "80 of 195 minutes done"], tone="wire",
       text_tone="paper", size=10.5)
sc.box(410, 150, 270, 40, "WeekKeys  'use client'", mono=True, tone="phosphor", size=10)
sc.arrow(352, 95, 408, 95, tone="amber")
sc.text(380, 86, "HTML", mono=True, tone="amber", anchor="middle", size=9.5)
sc.arrow(172, 125, 408, 168, tone="phosphor", dashed=True)
sc.text(270, 116, "monday=\"2026-10-19\"", mono=True, tone="phosphor", anchor="middle", size=9.5)
sc.text(360, 240, {"en": "the fetch and the API's address stay on the server",
                   "pt": "o fetch e o endereço da API ficam no servidor"},
        anchor="middle", tone="dim", size=10.5)

FIGS = [sc]
