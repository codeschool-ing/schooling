"""Lesson 9: an update over the air, and the runtime version that guards it."""
from fig import Fig

T = {
 "en": dict(aria="How an update over the air reaches an installed app. The store build contains the native code and bundle 1, with runtime version 1.0.0. The update server holds bundle 2, also for runtime 1.0.0, and bundle 3, built for runtime 1.1.0. On launch the app asks the server, downloads bundle 2 and runs it on the next launch. Bundle 3 is not taken, because its runtime version is different: it needs native code the installed app does not have, and reaches people only with a new store build.",
   build=["the store build:", "native code + bundle 1"], rt="runtime 1.0.0", server="the update server",
   b2=["bundle 2", "runtime 1.0.0"], b3=["bundle 3", "runtime 1.1.0"], ask="on launch: anything new for 1.0.0?",
   take="taken, runs on the next launch", refuse="not taken: needs native code it lacks",
   cap="An update changes the JavaScript and the assets. The runtime version is the promise that the native code underneath is the same."),
 "pt": dict(aria="Como uma atualização remota chega a um app instalado. O build da loja contém o código nativo e o bundle 1, com a runtime version 1.0.0. O servidor de atualizações guarda o bundle 2, também para a runtime 1.0.0, e o bundle 3, construído para a runtime 1.1.0. Ao abrir, o app pergunta ao servidor, baixa o bundle 2 e o roda na abertura seguinte. O bundle 3 não é aceito, porque a runtime version é outra: ele precisa de código nativo que o app instalado não tem, e só chega às pessoas com um build novo da loja.",
   build=["o build da loja:", "código nativo + bundle 1"], rt="runtime 1.0.0", server="o servidor de atualizações",
   b2=["bundle 2", "runtime 1.0.0"], b3=["bundle 3", "runtime 1.1.0"], ask="ao abrir: algo novo para a 1.0.0?",
   take="aceito, roda na abertura seguinte", refuse="recusado: precisa de código nativo que falta",
   cap="Uma atualização muda o JavaScript e os recursos. A runtime version é a promessa de que o código nativo por baixo é o mesmo."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l09-updates", 720, 220, t["aria"])
    f.box(20, 70, 200, 56, t["build"], stroke="phosphor", size=9.5)
    f.text(120, 142, t["rt"], size=9, fill="phosphor", mono=True)
    f.rect(440, 20, 260, 180, stroke="wire", dashed=True, fill="ink")
    f.text(570, 36, t["server"], size=9.5, fill="paper-dim", italic=True)
    f.box(470, 52, 200, 46, t["b2"], stroke="phosphor", size=9.5, mono=True)
    f.box(470, 136, 200, 46, t["b3"], stroke="amber", size=9.5, mono=True)
    f.arrow([(220, 88), (470, 75)])
    f.text(330, 70, t["ask"], size=8.5, fill="paper-dim", italic=True)
    f.arrow([(470, 82), (222, 100)], color="phosphor")
    f.text(330, 112, t["take"], size=8.5, fill="phosphor")
    f.arrow([(470, 159), (222, 118)], color="amber", dashed=True)
    f.text(330, 158, t["refuse"], size=8.5, fill="amber")
    return {"l09-updates": f.json(t["cap"])}
