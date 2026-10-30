"""Lesson 10: a query's life, fresh, stale, refetched."""
from fig import Fig

T = {
 "en": dict(aria="A timeline of the plan query. At 0 seconds the plan is fetched and is fresh. Until 30 seconds, the staleTime, a screen that asks gets the cached plan with no request. After 30 seconds the plan is stale: a screen that asks gets the cached plan at once and a request in the background, whose answer replaces it. A mutation invalidates the query, making it stale at once.",
   fetch="fetched", fresh="fresh: no request", stale="stale: cached at once, refetched behind", t0="0 s", t30="30 s", ask1="a screen asks", ask2="a screen asks",
   inv="a mutation invalidates: stale now", cap="Stale is not empty: a stale plan is shown at once, and replaced when the background request answers."),
 "pt": dict(aria="Uma linha do tempo da consulta do plano. Em 0 segundos o plano é buscado e está fresco. Até 30 segundos, o staleTime, uma tela que pede recebe o plano em cache sem requisição. Depois de 30 segundos o plano está velho: uma tela que pede recebe o plano em cache na hora e uma requisição em segundo plano, cuja resposta o substitui. Uma mutação invalida a consulta, deixando-a velha na hora.",
   fetch="buscado", fresh="fresco: sem requisição", stale="velho: cache na hora, busca por trás", t0="0 s", t30="30 s", ask1="uma tela pede", ask2="uma tela pede",
   inv="uma mutação invalida: velho já", cap="Velho não é vazio: um plano velho aparece na hora, e é trocado quando a requisição em segundo plano responde."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l10-stale", 720, 200, t["aria"])
    f.arrow([(30, 132), (700, 132)], color="paper-dim")
    f.rect(40, 80, 260, 40, stroke="phosphor", fill="panel")
    f.text(170, 100, t["fresh"], size=9.5, fill="phosphor")
    f.rect(300, 80, 380, 40, stroke="amber", fill="panel", dashed=True)
    f.text(490, 100, t["stale"], size=9.5, fill="amber")
    f.text(40, 146, t["t0"], mono=True, size=9, fill="paper-dim")
    f.text(300, 146, t["t30"], mono=True, size=9, fill="paper-dim")
    f.text(60, 60, t["fetch"], size=9, fill="paper", italic=True)
    f.arrow([(60, 66), (60, 80)])
    f.text(170, 40, t["ask1"], size=9, fill="paper", italic=True)
    f.arrow([(170, 46), (170, 80)])
    f.text(430, 40, t["ask2"], size=9, fill="paper", italic=True)
    f.arrow([(430, 46), (430, 80)])
    f.text(220, 176, t["inv"], size=9, fill="amber", italic=True)
    f.arrow([(220, 164), (220, 120)], color="amber", dashed=True)
    return {"l10-stale": f.json(caption=t["cap"])}
