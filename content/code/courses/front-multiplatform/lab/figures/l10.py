"""Lesson 10: who draws the screen."""
from fig import Fig

T = {
 "en": dict(aria="Three answers to who draws the screen, from left to right. A WebView: Capacitor and Ionic, and on the desktop Electron and Tauri; it reuses the whole web app. The platform's own views: React Native and NativeScript; they reuse the rules, in TypeScript. Its own engine: Flutter paints every pixel itself; it reuses nothing of a web app. The further right, the less of the web app comes along.",
   cols=[("a WebView", ["Capacitor, Ionic", "Electron, Tauri"], "the whole web app"),
         ("the platform's views", ["React Native", "NativeScript"], "the rules, in TypeScript"),
         ("its own engine", ["Flutter"], "nothing of the web app")],
   reuse="what comes along", arrow="less of the web app comes along",
   cap="The question from lesson 1, answered three ways. Each step to the right reuses less, and has to buy something for it."),
 "pt": dict(aria="Três respostas a quem desenha a tela, da esquerda para a direita. Uma WebView: Capacitor e Ionic, e no desktop Electron e Tauri; reaproveita a aplicação web inteira. As views da própria plataforma: React Native e NativeScript; reaproveitam as regras, em TypeScript. Um motor próprio: o Flutter pinta cada pixel sozinho; não reaproveita nada de uma aplicação web. Quanto mais à direita, menos da aplicação web vem junto.",
   cols=[("uma WebView", ["Capacitor, Ionic", "Electron, Tauri"], "a aplicação web inteira"),
         ("as views da plataforma", ["React Native", "NativeScript"], "as regras, em TypeScript"),
         ("um motor próprio", ["Flutter"], "nada da aplicação web")],
   reuse="o que vem junto", arrow="menos da aplicação web vem junto",
   cap="A pergunta da aula 1, respondida de três jeitos. Cada passo para a direita reaproveita menos, e tem que comprar algo com isso."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l10-who-draws", 720, 210, t["aria"])
    for i, (head, tools, reuse) in enumerate(t["cols"]):
        x = 20 + i * 235
        f.text(x + 105, 24, head, bold=True, size=10.5, fill=["phosphor", "amber", "paper"][i])
        f.box(x, 40, 210, 60, tools, stroke=["phosphor", "amber", "wire"][i], size=10)
        f.box(x, 120, 210, 36, [reuse], stroke="wire", size=9.5, dashed=True, fill="paper-dim")
    f.arrow([(20, 186), (700, 186)])
    f.text(360, 200, t["arrow"], size=9, fill="paper-dim", italic=True)
    same = None if lang == "en" else ["Capacitor, Ionic", "Electron, Tauri", "React Native", "NativeScript", "Flutter"]
    return {"l10-who-draws": f.json(t["cap"], same=same)}
