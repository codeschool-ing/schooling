"""Lesson 2: the bridge, and build-then-sync."""
from fig import Fig

T = {
    "en": dict(
        aria="Inside a Capacitor app on a phone. The WebView shows your built site, served by Capacitor from the app's own files at https://localhost on Android and capacitor://localhost on iOS. When your code calls a plugin, the call crosses the bridge as a message to a native class, in Java or Kotlin on Android and Swift on iOS, which talks to the camera, the files or the notifications, and the answer comes back as the result of a Promise.",
        phone="the app, on the phone", wv="the WebView", site=["your built site, dist/,", "served at https://localhost"],
        call="Preferences.set(…)", bridge="the bridge", native=["a native class:", "Java or Kotlin, or Swift"], os=["the phone's files,", "camera, notifications"],
        back="the answer: a Promise resolves",
        cap="Your files travel inside the app and are served from it. The bridge is the one way out of the WebView, and each plugin is a class on the other side of it.",
        aria2="The loop that puts a change on the phone. You edit src, npm run build writes dist, npx cap sync copies dist into android and ios, and the native build makes the app. Skipping the build copies an old dist; skipping the sync leaves the projects with the copy before.",
        steps=[["edit", "src/"], ["npm run build", "writes dist/"], ["npx cap sync", "copies into android/, ios/"], ["the native build", "Android Studio, Xcode"]],
        skip1="skip it: an old dist/ is copied", skip2="skip it: the projects keep the last copy",
        cap2="Two steps between your code and the phone, always in this order.",
    ),
    "pt": dict(
        aria="Dentro de um app Capacitor num celular. A WebView mostra o seu site construído, servido pelo Capacitor a partir dos arquivos do próprio app em https://localhost no Android e capacitor://localhost no iOS. Quando o seu código chama um plugin, a chamada atravessa a ponte como uma mensagem para uma classe nativa, em Java ou Kotlin no Android e em Swift no iOS, que fala com a câmera, os arquivos ou as notificações, e a resposta volta como o resultado de uma Promise.",
        phone="o app, no celular", wv="a WebView", site=["o seu site construído, dist/,", "servido em https://localhost"],
        call="Preferences.set(…)", bridge="a ponte", native=["uma classe nativa:", "Java ou Kotlin, ou Swift"], os=["os arquivos, a câmera e", "as notificações do celular"],
        back="a resposta: uma Promise se resolve",
        cap="Os seus arquivos viajam dentro do app e são servidos por ele. A ponte é a única saída da WebView, e cada plugin é uma classe do outro lado dela.",
        aria2="O ciclo que leva uma mudança ao celular. Você edita a src, npm run build escreve a dist, npx cap sync copia a dist para android e ios, e o build nativo faz o app. Pular o build copia uma dist antiga; pular o sync deixa os projetos com a cópia anterior.",
        steps=[["editar", "src/"], ["npm run build", "escreve a dist/"], ["npx cap sync", "copia para android/, ios/"], ["o build nativo", "Android Studio, Xcode"]],
        skip1="pulou: copia uma dist/ antiga", skip2="pulou: os projetos ficam com a cópia anterior",
        cap2="Dois passos entre o seu código e o celular, sempre nesta ordem.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l02-bridge", 720, 250, t["aria"])
    f.rect(20, 20, 680, 214, stroke="wire", fill="ink", dashed=True)
    f.text(36, 36, t["phone"], anchor="start", size=9.5, fill="paper-dim", italic=True)
    f.rect(40, 52, 250, 162, stroke="phosphor")
    f.text(165, 70, t["wv"], bold=True, size=10.5, fill="phosphor")
    f.box(60, 86, 210, 46, t["site"], stroke="wire", size=9.5)
    f.box(60, 150, 210, 40, [t["call"]], stroke="amber", mono=True, size=9.5)
    f.text(345, 126, t["bridge"], bold=True, size=10, fill="amber")
    f.arrow([(270, 160), (420, 160)], color="amber")
    f.arrow([(420, 186), (270, 186)], color="paper-dim", dashed=True)
    f.text(345, 200, t["back"], size=8.5, fill="paper-dim", italic=True)
    f.box(420, 146, 120, 50, t["native"], stroke="amber", size=9)
    f.arrow([(540, 171), (565, 171)])
    f.box(565, 146, 120, 50, t["os"], stroke="wire", size=9)
    out["l02-bridge"] = f.json(t["cap"])

    g = Fig("l02-loop", 720, 150, t["aria2"])
    xs = [20, 195, 370, 545]
    for x, (a, b), s in zip(xs, t["steps"], ["wire", "phosphor", "phosphor", "wire"]):
        g.box(x, 30, 155, 52, [a, b], stroke=s, size=9.5)
    for x in xs[:-1]:
        g.arrow([(x + 155, 56), (x + 175, 56)])
    g.text(272, 104, t["skip1"], size=8.5, fill="amber", italic=True)
    g.text(447, 124, t["skip2"], size=8.5, fill="amber", italic=True)
    same = None if lang == "en" else ["src/", "npm run build", "npx cap sync", "Android Studio, Xcode"]
    out["l02-loop"] = g.json(t["cap2"], same=same)
    return out
