"""Lesson 14: what a persisted query cache does at launch."""
from fig import Fig

T = {
 "en": dict(aria="At launch the persister reads the stored cache from AsyncStorage and puts the plan back into the query cache, so the screen draws it at once. Then the query fetches the plan from the server. If the server answers, the fresh plan replaces the stored one on screen and is written to AsyncStorage again. If it does not, the stored plan stays on screen.",
   launch="the app starts", restore="the stored plan is restored", draw="the screen draws it at once", fetch="the plan is requested",
   ok="answer: fresh plan shown,", ok2="and stored again", fail="no answer: the stored", fail2="plan stays on screen", store="AsyncStorage",
   cap="Restoring first and fetching second is what makes the first screen instant, online or not."),
 "pt": dict(aria="Na abertura o persister lê o cache guardado no AsyncStorage e devolve o plano ao cache de consultas, e a tela o desenha na hora. Depois a consulta busca o plano no servidor. Se o servidor responde, o plano novo substitui o guardado na tela e é escrito no AsyncStorage de novo. Se não responde, o plano guardado fica na tela.",
   launch="o app abre", restore="o plano guardado volta", draw="a tela o desenha na hora", fetch="o plano é pedido",
   ok="resposta: plano novo na tela,", ok2="e guardado de novo", fail="sem resposta: o plano", fail2="guardado fica na tela", store="AsyncStorage",
   cap="Restaurar primeiro e buscar depois é o que torna a primeira tela instantânea, com rede ou sem."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l14-restore", 720, 230, t["aria"])
    f.box(20, 40, 120, 36, [t["launch"]])
    f.box(170, 40, 170, 36, [t["restore"]], stroke="phosphor")
    f.box(370, 40, 160, 36, [t["draw"]], stroke="phosphor")
    f.box(560, 40, 140, 36, [t["fetch"]], stroke="amber")
    f.arrow([(140, 58), (170, 58)])
    f.arrow([(340, 58), (370, 58)])
    f.arrow([(530, 58), (560, 58)])
    f.box(185, 130, 140, 30, [t["store"]], mono=True, size=9.5, stroke="wire")
    f.arrow([(255, 130), (255, 76)], dashed=True)
    f.box(400, 150, 150, 44, [t["ok"], t["ok2"]], stroke="phosphor")
    f.box(570, 150, 140, 44, [t["fail"], t["fail2"]], stroke="amber", dashed=True)
    f.arrow([(600, 76), (480, 150)])
    f.arrow([(650, 76), (640, 150)])
    f.arrow([(400, 172), (325, 150)], dashed=True)
    return {"l14-restore": f.json(caption=t["cap"])}
