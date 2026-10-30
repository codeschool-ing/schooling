"""Lesson 2: the approaches as layers, and the border a device feature is behind."""
from fig import Fig

T = {
    "en": dict(
        aria1="Five columns, one per approach, each in three layers. Your code: native is Kotlin and Swift, two apps; React Native is JavaScript or TypeScript; Flutter is Dart; Kotlin Multiplatform is shared Kotlin plus each platform's interface; a web wrapper is HTML, CSS and JavaScript. What draws the screen: native and React Native use the platform's own views, React Native creating them from JavaScript; Flutter uses its own engine, shipped in the app; Kotlin Multiplatform uses native views or Compose Multiplatform; a wrapper uses a WebView, a browser engine. Under all five, the same system: Android or iOS.",
        cols=["native", "React Native", "Flutter", "Kotlin Multiplatform", "web wrapper"],
        rows=["your code", "what draws", "the system"],
        code=[["Kotlin; Swift", "(two apps)"], ["JavaScript or", "TypeScript"], ["Dart"],
              ["shared Kotlin, plus", "each platform's UI"], ["HTML, CSS and", "JavaScript"]],
        draw=[["the platform's", "own views"], ["the platform's views,", "created from JS"],
              ["its own engine,", "shipped in the app"], ["native views, or", "Compose Multiplatform"],
              ["a WebView:", "a browser engine"]],
        os="Android or iOS: the system, its views, the camera and everything else",
        cap1="Every approach runs on the same system. What changes is the middle layer: the platform's own views, an engine the app carries, or a browser engine.",
        aria2="Five rows, one per approach, with a dashed border between shared code on the left and platform code on the right. React Native's JavaScript crosses it through a native module, Flutter's Dart through a platform channel, common Kotlin through expect and actual, and a wrapped page's JavaScript through a plugin. On the right of each crossing is the Android API in Kotlin and the iOS API in Swift. A native app has nothing shared: Kotlin calls Android and Swift calls iOS directly.",
        h_left="shared code", h_mid="the border", h_right="platform code",
        left=[["React Native", "JavaScript or TypeScript"], ["Flutter", "Dart"],
              ["Kotlin Multiplatform", "common Kotlin"], ["web wrapper", "the page's JavaScript"],
              ["native", "nothing shared"]],
        mech=["native module", "platform channel", "expect / actual", "plugin", ""],
        right="Android API in Kotlin, iOS API in Swift",
        right_native="Kotlin calls Android, Swift calls iOS",
        cap2="Shared code reaches the camera across a border, and the far side is always Kotlin and Swift. A native app has no border because it has nothing shared.",
    ),
    "pt": dict(
        aria1="Cinco colunas, uma por abordagem, cada uma em três camadas. Seu código: o nativo é Kotlin e Swift, dois apps; o React Native é JavaScript ou TypeScript; o Flutter é Dart; o Kotlin Multiplatform é Kotlin compartilhado mais a interface de cada plataforma; um embrulho web é HTML, CSS e JavaScript. O que desenha a tela: o nativo e o React Native usam as views da própria plataforma, que o React Native cria a partir do JavaScript; o Flutter usa o próprio motor, embarcado no app; o Kotlin Multiplatform usa views nativas ou o Compose Multiplatform; um embrulho usa uma WebView, um motor de navegador. Embaixo das cinco, o mesmo sistema: Android ou iOS.",
        cols=["nativo", "React Native", "Flutter", "Kotlin Multiplatform", "embrulho web"],
        rows=["seu código", "o que desenha", "o sistema"],
        code=[["Kotlin; Swift", "(dois apps)"], ["JavaScript ou", "TypeScript"], ["Dart"],
              ["Kotlin compartilhado,", "mais a UI de cada um"], ["HTML, CSS e", "JavaScript"]],
        draw=[["as views da", "própria plataforma"], ["views da plataforma,", "criadas pelo JS"],
              ["o próprio motor,", "embarcado no app"], ["views nativas, ou", "Compose Multiplatform"],
              ["uma WebView: um", "motor de navegador"]],
        os="Android ou iOS: o sistema, as views dele, a câmera e todo o resto",
        cap1="Toda abordagem roda sobre o mesmo sistema. O que muda é a camada do meio: as views da própria plataforma, um motor que o app carrega, ou um motor de navegador.",
        aria2="Cinco linhas, uma por abordagem, com uma fronteira tracejada entre o código compartilhado, à esquerda, e o código da plataforma, à direita. O JavaScript do React Native a atravessa por um native module, o Dart do Flutter por um platform channel, o Kotlin comum por expect e actual, e o JavaScript de uma página embrulhada por um plugin. À direita de cada travessia está a API do Android em Kotlin e a do iOS em Swift. Um app nativo não tem nada compartilhado: o Kotlin chama o Android e o Swift chama o iOS diretamente.",
        h_left="código compartilhado", h_mid="a fronteira", h_right="código da plataforma",
        left=[["React Native", "JavaScript ou TypeScript"], ["Flutter", "Dart"],
              ["Kotlin Multiplatform", "Kotlin comum"], ["embrulho web", "o JavaScript da página"],
              ["nativo", "nada compartilhado"]],
        mech=["native module", "platform channel", "expect / actual", "plugin", ""],
        right="API do Android em Kotlin, do iOS em Swift",
        right_native="Kotlin chama o Android, Swift o iOS",
        cap2="O código compartilhado chega à câmera atravessando uma fronteira, e o outro lado é sempre Kotlin e Swift. Um app nativo não tem fronteira porque não tem nada compartilhado.",
    ),
}


def layers(t):
    f = Fig("l02-layers", 780, 222, t["aria1"])
    x0, w, gap = 104, 128, 8
    for i, (lab, y) in enumerate(zip(t["rows"], (59, 127, 191))):
        f.text(16, y, lab, anchor="start", size=9.5, fill="paper-dim", italic=True)
    strokes = ["phosphor", "phosphor", "amber", "wire", "wire"]
    for i in range(5):
        x = x0 + i * (w + gap)
        f.text(x + w / 2, 20, t["cols"][i], bold=True, size=9.5)
        f.box(x, 36, w, 46, t["code"][i], size=9)
        f.arrow([(x + w / 2, 82), (x + w / 2, 102)])
        f.box(x, 104, w, 46, t["draw"][i], size=9, stroke=strokes[i], dashed=(i == 4))
        f.arrow([(x + w / 2, 150), (x + w / 2, 174)])
    f.box(x0, 176, 5 * w + 4 * gap, 30, [t["os"]], size=9.5, stroke="wire")
    return f


def border(t):
    f = Fig("l02-border", 720, 272, t["aria2"])
    f.text(110, 18, t["h_left"], bold=True, size=9.5)
    f.text(330, 18, t["h_mid"], bold=True, size=9.5, fill="amber")
    f.text(580, 18, t["h_right"], bold=True, size=9.5)
    f.arrow([(330, 30), (330, 262)], color="amber", head=False, dashed=True)
    for i in range(5):
        y = 34 + i * 46
        native = i == 4
        f.box(20, y, 180, 38, t["left"][i], size=9, dashed=native,
              fill="paper-dim" if native else "paper")
        if native:
            f.box(450, y, 260, 38, [t["right_native"]], size=9, stroke="phosphor")
        else:
            f.arrow([(200, y + 19), (448, y + 19)])
            f.text(265, y + 11, t["mech"][i], mono=True, size=9, fill="phosphor")
            f.box(450, y, 260, 38, [t["right"]], size=9)
    return f


def figures(lang):
    t = T[lang]
    same = None
    if lang == "pt":
        same1 = ["React Native", "Flutter", "Kotlin Multiplatform", "Kotlin; Swift", "Dart", "TypeScript", "JavaScript",
                 "Compose Multiplatform"]
        same2 = ["React Native", "Flutter", "Kotlin Multiplatform", "Dart"]
    else:
        same1 = same2 = None
    return {
        "l02-layers": layers(t).json(t["cap1"], same=same1),
        "l02-border": border(t).json(t["cap2"], same=same2),
    }
