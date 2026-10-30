"""Lesson 22: where the code runs and who draws, for the three routes."""
from fig import Fig

T = {
 "en": dict(aria="Three columns. React Native: your code is JavaScript run by Hermes, and the platform's own native views draw the screen. Flutter: your code is Dart compiled to machine code, and Flutter's own engine draws every pixel on one canvas. Kotlin Multiplatform: shared logic is Kotlin, compiled for each platform, and each platform's own interface draws the screen, Compose on Android and SwiftUI on iOS; Compose Multiplatform can share the screens too.",
   rn="React Native", fl="Flutter", kmp="Kotlin Multiplatform", code="your code", draws="who draws",
   rncode=["JavaScript", "in Hermes"], flcode=["Dart, compiled", "to machine code"], kmpcode=["shared Kotlin", "(logic)"],
   rndraw=["the platform's", "native views"], fldraw=["Flutter's engine,", "every pixel"], kmpdraw=["Compose / SwiftUI,", "or shared screens"],
   cap="The two questions that separate the three: where your code runs, and whose views end up on the screen."),
 "pt": dict(aria="Três colunas. React Native: o seu código é JavaScript rodado pelo Hermes, e as views nativas da própria plataforma desenham a tela. Flutter: o seu código é Dart compilado para código de máquina, e o motor do próprio Flutter desenha cada pixel numa tela só. Kotlin Multiplatform: a lógica compartilhada é Kotlin, compilado para cada plataforma, e a interface de cada plataforma desenha a tela, Compose no Android e SwiftUI no iOS; o Compose Multiplatform pode compartilhar as telas também.",
   rn="React Native", fl="Flutter", kmp="Kotlin Multiplatform", code="o seu código", draws="quem desenha",
   rncode=["JavaScript", "no Hermes"], flcode=["Dart, compilado", "para máquina"], kmpcode=["Kotlin compartilhado", "(lógica)"],
   rndraw=["as views nativas", "da plataforma"], fldraw=["o motor do Flutter,", "cada pixel"], kmpdraw=["Compose / SwiftUI,", "ou telas compartilhadas"],
   cap="As duas perguntas que separam os três: onde o seu código roda, e de quem são as views que acabam na tela."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l22-routes", 720, 230, t["aria"])
    f.text(20, 92, t["code"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    f.text(20, 172, t["draws"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    for i, (head, code, draw, col) in enumerate([
        (t["rn"], t["rncode"], t["rndraw"], "phosphor"),
        (t["fl"], t["flcode"], t["fldraw"], "amber"),
        (t["kmp"], t["kmpcode"], t["kmpdraw"], "wire"),
    ]):
        x = 130 + i * 200
        f.text(x + 85, 30, head, size=10.5, bold=True, fill="paper")
        f.box(x, 66, 170, 50, code, stroke=col)
        f.box(x, 146, 170, 50, draw, stroke=col)
        f.arrow([(x + 85, 116), (x + 85, 146)])
    same = ["React Native", "Flutter", "Kotlin Multiplatform", "JavaScript", "Compose / SwiftUI,"] if lang == "pt" else None
    return {"l22-routes": f.json(caption=t["cap"], same=same)}
