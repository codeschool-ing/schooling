"""Lesson 9: cross-site request forgery, and where each defence stops it."""
from fig import Fig

T = {
    "en": dict(
        aria="A page on another site, open in the person's browser, makes the browser send a POST to the planner's API. Three checks stand on the way. First, SameSite=Lax: the browser leaves the planner's cookie off a request another site started. Second, the preflight: a JSON POST from another origin is announced with OPTIONS, and the API's allowlist refuses it. Third, on the server, the Origin header names the other site, which is not on the list, and the API answers 403. Only a request that passes all three reaches the code that signs a person out.",
        other="a page on another site", browser="the person's browser", api="the planner's API",
        req="POST /api/logout",
        checks=[("1", "SameSite=Lax", "cookie left off"), ("2", "preflight, allowlist", "JSON POST refused"),
                ("3", "Origin check", "403 on the server")],
        cap="Three defences in a row, two of them the browser's and one the server's own. The third is the one that holds when the other two do not apply.",
    ),
    "pt": dict(
        aria="Uma página de outro site, aberta no navegador da pessoa, faz o navegador mandar um POST para a API do planner. Três checagens ficam no caminho. Primeira, o SameSite=Lax: o navegador deixa o cookie do planner fora de uma requisição que outro site começou. Segunda, o preflight: um POST JSON de outra origem é anunciado com OPTIONS, e a lista de permissão da API o recusa. Terceira, no servidor, o cabeçalho Origin nomeia o outro site, que não está na lista, e a API responde 403. Só uma requisição que passa pelas três chega ao código que desloga uma pessoa.",
        other="uma página de outro site", browser="o navegador da pessoa", api="a API do planner",
        req="POST /api/logout",
        checks=[("1", "SameSite=Lax", "cookie fica de fora"), ("2", "preflight, lista", "POST JSON recusado"),
                ("3", "checagem do Origin", "403 no servidor")],
        cap="Três defesas em fila, duas do navegador e uma do próprio servidor. A terceira é a que segura quando as outras duas não se aplicam.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l09-csrf", 720, 210, t["aria"])
    f.box(10, 20, 150, 40, [t["other"]], stroke="amber", size=9.5)
    f.box(10, 130, 150, 40, [t["browser"]], stroke="wire", size=9.5)
    f.box(580, 75, 130, 40, [t["api"]], stroke="phosphor", size=9.5)
    f.arrow([(85, 60), (85, 130)], color="amber")
    f.text(92, 95, t["req"], anchor="start", mono=True, size=8.5, fill="amber")
    for i, (n, name, what) in enumerate(t["checks"]):
        x = 200 + i * 125
        f.box(x, 120, 112, 52, [f"{n}  {name}", what], size=8.5, stroke="wire")
    f.arrow([(160, 150), (200, 150)])
    f.arrow([(312, 146), (325, 146)])
    f.arrow([(437, 146), (450, 146)])
    f.arrow([(562, 146), (645, 146), (645, 115)])
    return {"l09-csrf": f.json(t["cap"], same=["SameSite=Lax"] if lang == "pt" else None)}
