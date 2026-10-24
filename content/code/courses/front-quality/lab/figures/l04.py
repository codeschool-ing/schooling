"""Lesson 4: where a Playwright test runs, and where a Cypress test runs."""
from fig import Fig

T = {
    "en": dict(
        aria="Two arrangements side by side. Playwright: the test runs in Node, outside the browser, and sends commands over a connection to Chromium, where the planner runs in a tab of its own. Cypress: the browser holds both the test and the planner, side by side in one tab, and a Node process beside the browser serves the test and handles what the browser cannot, such as files.",
        pw="Playwright", cy="Cypress",
        node="Node", test="your test", browser="Chromium", tab="a tab: the planner",
        proto="commands over a connection",
        cy_browser="the browser, one tab", cy_test="your test", cy_app="the planner",
        cy_node="Node: serves the test,", cy_node2="reads files, the network",
        cap="Outside or inside. Playwright's test can open tabs and browsers at will; Cypress's test sits beside the page and sees it directly.",
    ),
    "pt": dict(
        aria="Duas organizações lado a lado. Playwright: o teste roda no Node, fora do navegador, e manda comandos por uma conexão para o Chromium, onde o planner roda numa aba só dele. Cypress: o navegador guarda o teste e o planner, lado a lado numa aba, e um processo Node ao lado do navegador serve o teste e cuida do que o navegador não consegue, como arquivos.",
        pw="Playwright", cy="Cypress",
        node="Node", test="o seu teste", browser="Chromium", tab="uma aba: o planner",
        proto="comandos por uma conexão",
        cy_browser="o navegador, uma aba", cy_test="o seu teste", cy_app="o planner",
        cy_node="Node: serve o teste,", cy_node2="lê arquivos, a rede",
        cap="Fora ou dentro. O teste do Playwright abre abas e navegadores à vontade; o do Cypress fica ao lado da página e a vê diretamente.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l04-where", 720, 240, t["aria"])
    f.text(170, 20, t["pw"], bold=True)
    f.text(540, 20, t["cy"], bold=True)
    # Playwright
    f.rect(20, 50, 120, 110, stroke="wire")
    f.text(80, 66, t["node"], size=9.5, fill="paper-dim")
    f.box(32, 90, 96, 40, [t["test"]], stroke="phosphor", size=9.5)
    f.rect(200, 50, 150, 110, stroke="wire")
    f.text(275, 66, t["browser"], size=9.5, fill="paper-dim")
    f.box(212, 90, 126, 40, [t["tab"]], stroke="amber", size=9.5)
    f.arrow([(128, 110), (212, 110)])
    f.text(170, 182, t["proto"], size=9, fill="paper-dim", italic=True)
    # Cypress
    f.rect(400, 40, 300, 120, stroke="wire")
    f.text(550, 56, t["cy_browser"], size=9.5, fill="paper-dim")
    f.box(420, 80, 120, 50, [t["cy_test"]], stroke="phosphor", size=9.5)
    f.box(560, 80, 120, 50, [t["cy_app"]], stroke="amber", size=9.5)
    f.arrow([(540, 105), (560, 105)], both=True)
    f.box(450, 180, 200, 44, [t["cy_node"], t["cy_node2"]], stroke="wire", size=9)
    f.arrow([(550, 160), (550, 180)], both=True)
    return {"l04-where": f.json(t["cap"], same=["Playwright", "Cypress", "Node", "Chromium"] if lang == "pt" else None)}
