"""Lesson 1: the two ways to a store."""
from fig import Fig

T = {
    "en": dict(
        aria="Two ways from a web app to a store. Top row, the wrapper: the built site, dist, is copied into a native app whose whole screen is a WebView, and the browser engine draws the screen; Capacitor does this for Android and iOS, Electron and Tauri for the desktop. Bottom row, the native path: the screens are written again as components, React Native turns them into the platform's own views, and the platform draws the screen. The planner's rules, src/planner.ts, have no DOM in them and go into both.",
        top="the wrapper", bot="the native path",
        a1=["the built site", "dist/"], a2=["a native app whose", "screen is a WebView"], a3=["a browser engine", "draws the screen"],
        t1="Capacitor · Electron · Tauri",
        b1=["the screens, written", "again as components"], b2=["React Native turns", "them into native views"], b3=["the platform's own", "controls draw it"],
        t2="React Native · Flutter · Swift and Kotlin",
        rules=["the rules, src/planner.ts:", "no DOM, so they go into both"],
        cap="Nothing converts a web app into a native one. Either a browser engine still draws it, or the screens are written again for the platform to draw.",
    ),
    "pt": dict(
        aria="Dois caminhos de uma aplicação web até uma loja. Na linha de cima, o embrulho: o site construído, dist, é copiado para um app nativo cuja tela inteira é uma WebView, e um motor de navegador desenha a tela; o Capacitor faz isso para Android e iOS, o Electron e o Tauri para o desktop. Na linha de baixo, o caminho nativo: as telas são escritas de novo como componentes, o React Native as transforma nas views da própria plataforma, e a plataforma desenha a tela. As regras do planner, src/planner.ts, não têm DOM e entram nos dois.",
        top="o embrulho", bot="o caminho nativo",
        a1=["o site construído", "dist/"], a2=["um app nativo cuja", "tela é uma WebView"], a3=["um motor de navegador", "desenha a tela"],
        t1="Capacitor · Electron · Tauri",
        b1=["as telas, escritas de", "novo como componentes"], b2=["o React Native as", "torna views nativas"], b3=["os controles da própria", "plataforma a desenham"],
        t2="React Native · Flutter · Swift e Kotlin",
        rules=["as regras, src/planner.ts:", "sem DOM, entram nos dois"],
        cap="Nada converte uma aplicação web numa nativa. Ou um motor de navegador ainda a desenha, ou as telas são escritas de novo para a plataforma desenhar.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l01-two-ways", 720, 270, t["aria"])
    f.text(20, 22, t["top"], anchor="start", bold=True, size=10.5, fill="phosphor")
    f.text(20, 152, t["bot"], anchor="start", bold=True, size=10.5, fill="amber")
    xs = [20, 260, 500]
    for x, lines, s in zip(xs, [t["a1"], t["a2"], t["a3"]], ["wire", "phosphor", "wire"]):
        f.box(x, 36, 200, 50, lines, stroke=s, size=10)
    for x, lines, s in zip(xs, [t["b1"], t["b2"], t["b3"]], ["wire", "amber", "wire"]):
        f.box(x, 166, 200, 50, lines, stroke=s, size=10)
    for y in (61, 191):
        f.arrow([(220, y), (260, y)])
        f.arrow([(460, y), (500, y)])
    f.text(360, 102, t["t1"], size=9.5, fill="paper-dim", italic=True)
    f.text(360, 232, t["t2"], size=9.5, fill="paper-dim", italic=True)
    f.box(20, 112, 200, 34, t["rules"], stroke="wire", size=9, dashed=True, fill="paper-dim")
    f.arrow([(120, 112), (120, 88)], dashed=True)
    f.arrow([(120, 146), (120, 164)], dashed=True)
    return {"l01-two-ways": f.json(t["cap"], same=None if lang == "en" else ["Capacitor · Electron · Tauri", "dist/"])}
