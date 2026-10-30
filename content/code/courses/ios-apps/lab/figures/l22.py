"""Lesson 22 figures."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from fig import Fig, lesson

L = "le-x25kwtnf"
f = Fig("l22-pipeline", 720, 300,
        "The path from an archive to the store. The archive is uploaded to App Store Connect and processed. It reaches internal testers at once. The first build for external testers goes to App Review first. When the version is submitted, App Review reads the app and its listing against the guidelines. An approved build is released. A rejected one comes back with a guideline number, for a reply, a fix and a new build, or once for an appeal.",
        "O caminho de um arquivo até a loja. O arquivo é enviado ao App Store Connect e processado. Ele chega aos testadores internos na hora. O primeiro build para testadores externos passa antes pela App Review. Quando a versão é enviada, a App Review lê o app e a listagem contra as diretrizes. Um build aprovado é lançado. Um rejeitado volta com o número de uma diretriz, para uma resposta, uma correção e um build novo, ou uma vez para um recurso.")
steps = [(20, "upload", "envio", "the archive, lesson 21", "o arquivo, aula 21"),
         (160, "processing", "processamento", "minutes or longer", "minutos ou mais"),
         (300, "TestFlight", "TestFlight", "internal at once", "internos na hora"),
         (440, "App Review", "App Review", "against the guidelines", "contra as diretrizes"),
         (580, "released", "lançado", "at once or on a date", "na hora ou numa data")]
for x, en, pt, sen, spt in steps:
    col = "phosphor" if en == "released" else "amber" if en == "App Review" else "wire"
    f.box(x, 40, 120, 60, stroke=col)
    f.text(x + 60, 62, en, pt, size=11, fill="paper", weight="600")
    f.text(x + 60, 82, sen, spt, size=9, fill="paper-dim")
for x in (140, 280, 420, 560):
    f.line(x, 70, x + 18, 70, color="wire")
f.box(300, 150, 120, 56, stroke="wire", dashed=True)
f.text(360, 170, "external testers", "testadores externos", size=10, fill="paper")
f.text(360, 188, "first build reviewed", "o primeiro build revisado", size=9, fill="paper-dim")
f.line(360, 100, 360, 148, color="wire", dashed=True)
f.box(440, 200, 260, 70, stroke="amber", fill="ink")
f.text(570, 220, "rejected: a guideline number", "rejeitado: o número de uma diretriz", size=10, fill="amber", weight="600")
f.text(570, 240, "reply, fix, new build", "responder, corrigir, build novo", size=10, fill="paper")
f.text(570, 258, "or one appeal", "ou um recurso", size=10, fill="paper-dim")
f.line(500, 100, 500, 198, color="amber")
f.path("M440 250 C 120 260, 60 200, 70 102", color="paper-dim", dashed=True)
f.text(180, 236, "a higher build number", "um número de build maior", size=10, fill="paper-dim")
f.write(lesson(L, "app-store-connect"),
        "Every build passes through App Store Connect, and every way back from a rejection is a new build with a higher number.",
        "Todo build passa pelo App Store Connect, e todo caminho de volta de uma rejeição é um build novo com número maior.")
