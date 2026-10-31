"""Lesson 7: the window of rendered rows."""
from fig import Fig

T = {
 "en": dict(aria="A list of 1000 items. Only the items inside a window around the screen exist as views: the screen itself, and some screens' worth above and below it. Items above and below the window are not rendered. As the person scrolls, new items are rendered at the leading edge of the window and old ones unmounted at the trailing edge.",
   data="data: 1000 items", win="rendered window", scr="the screen", none="not rendered", made="rendered as it comes into the window",
   gone="unmounted as it leaves", scroll="scrolling", cap="Only the window exists as native views, so the list costs about the same at a thousand items as at thirty."),
 "pt": dict(aria="Uma lista de 1000 itens. Só os itens dentro de uma janela em volta da tela existem como views: a própria tela, e algumas telas de altura acima e abaixo dela. Os itens acima e abaixo da janela não são renderizados. Quando a pessoa rola, itens novos são renderizados na borda da frente da janela e os antigos desmontados na borda de trás.",
   data="dados: 1000 itens", win="janela renderizada", scr="a tela", none="não renderizado", made="renderizado ao entrar na janela",
   gone="desmontado ao sair", scroll="rolando", cap="Só a janela existe como views nativas, então a lista custa mais ou menos o mesmo com mil itens e com trinta."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l07-window", 720, 300, t["aria"])
    f.text(110, 18, t["data"], size=10, fill="paper-dim", bold=True)
    for i in range(14):
        y = 30 + i * 18
        inside = 4 <= i <= 10
        f.rect(40, y, 140, 14, stroke="phosphor" if inside else "wire", fill="panel" if inside else "ink", dashed=not inside, rx=2)
    f.rect(30, 30 + 4 * 18 - 4, 160, 7 * 18 + 4, stroke="amber", fill="ink", width=1.6, dashed=True)
    f.rect(36, 30 + 6 * 18 - 2, 148, 3 * 18, stroke="phosphor", fill="ink", width=2)
    f.text(320, 30 + 7 * 18 + 6, t["scr"], anchor="start", size=10, fill="phosphor", bold=True)
    f.arrow([(310, 30 + 7 * 18 + 6), (190, 30 + 7 * 18 + 6)], color="phosphor")
    f.text(320, 30 + 4 * 18 + 4, t["win"], anchor="start", size=10, fill="amber", bold=True)
    f.arrow([(310, 30 + 4 * 18 + 4), (196, 30 + 4 * 18 + 4)], color="amber")
    f.text(320, 48, t["none"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    f.text(320, 30 + 12 * 18 + 6, t["none"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    f.arrow([(560, 250), (560, 70)], color="paper-dim")
    f.text(580, 160, t["scroll"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    f.text(320, 30 + 11 * 18 + 6, t["made"], anchor="start", size=9.5, fill="paper")
    f.text(320, 30 + 3 * 18 + 6 - 18, t["gone"], anchor="start", size=9.5, fill="paper")
    return {"l07-window": f.json(caption=t["cap"])}
