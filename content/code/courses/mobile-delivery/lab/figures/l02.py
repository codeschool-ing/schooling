"""Lesson 2: the iOS signing chain, and the expiry script."""
from fig import Fig

T = {
    "en": dict(
        aria="Three inputs feed a provisioning profile. The certificate says who signs, and its private key stays on the Mac that made it. The App ID says which app, by bundle identifier, and with which capabilities. The device list says where a development or ad hoc build may run; an App Store profile has none. The profile, signed by Apple, is embedded in the signed app, and every part of it carries an expiry date except the App ID.",
        cert="certificate", certs=["who signs", "private key on one Mac"],
        appid="App ID", appids=["which app:", "com.example.planner", "and its capabilities"],
        dev="devices", devs=["where it may run", "(none for the App Store)"],
        prof="provisioning profile", profs=["signed by Apple", "embedded in the app"],
        app="the signed app",
        exp="has an expiry date",
        cap="Every box with a dashed edge has a date on it. The App ID is the only link that never expires.",
    ),
    "pt": dict(
        aria="Três entradas alimentam um perfil de provisionamento. O certificado diz quem assina, e a chave privada dele fica no Mac que o criou. O App ID diz qual app, pelo bundle identifier, e com quais recursos. A lista de aparelhos diz onde um build de desenvolvimento ou ad hoc pode rodar; um perfil da App Store não tem nenhum. O perfil, assinado pela Apple, vai embutido no app assinado, e toda parte dele tem data de vencimento, menos o App ID.",
        cert="certificado", certs=["quem assina", "chave privada num Mac"],
        appid="App ID", appids=["qual app:", "com.example.planner", "e os recursos dele"],
        dev="aparelhos", devs=["onde pode rodar", "(nenhum na App Store)"],
        prof="perfil de provisionamento", profs=["assinado pela Apple", "embutido no app"],
        app="o app assinado",
        exp="tem data de vencimento",
        cap="Toda caixa com borda tracejada tem uma data. O App ID é o único elo que nunca vence.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l02-chain", 720, 300, t["aria"])
    rows = [(t["cert"], t["certs"], True), (t["appid"], t["appids"], False), (t["dev"], t["devs"], True)]
    for i, (name, lines, exp) in enumerate(rows):
        y = 20 + i * 88
        f.rect(20, y, 220, 76, stroke="amber" if exp else "wire", fill="panel", dashed=exp)
        f.text(130, y + 18, name, bold=True, size=11, fill="phosphor")
        for j, s in enumerate(lines):
            f.text(130, y + 36 + j * 13, s, size=9.5, mono=s.startswith("com."),
                   fill="paper" if j == 0 else "paper-dim")
        f.arrow([(240, y + 38), (300, 150)])
    f.rect(302, 104, 200, 92, stroke="amber", fill="panel", dashed=True)
    f.text(402, 128, t["prof"], bold=True, size=11, fill="phosphor")
    f.text(402, 150, t["profs"][0], size=9.5)
    f.text(402, 166, t["profs"][1], size=9.5, fill="paper-dim")
    f.arrow([(502, 150), (556, 150)])
    f.box(558, 124, 142, 52, [t["app"]], stroke="phosphor", bold=True)
    f.rect(470, 248, 22, 14, stroke="amber", fill="panel", dashed=True, rx=2)
    f.text(500, 255, t["exp"], anchor="start", size=9.5, fill="amber", italic=True)
    same = None if lang == "en" else ["App ID"]
    return {"l02-chain": f.json(t["cap"], same=same)}

EXPIRY = [
    ("// expiry.ts: which certificates in a folder expire within a month of a date?\nimport { X509Certificate } from \"node:crypto\";\nimport { readdirSync, readFileSync } from \"node:fs\";\nimport { join } from \"node:path\";",
     "Node's own `crypto` module reads X.509 certificates; nothing is installed.",
     "O próprio módulo `crypto` do Node lê certificados X.509; nada é instalado."),
    ("const folder = process.argv[2] ?? \"certs\";\nconst on = process.argv[3] ? new Date(`${process.argv[3]}T12:00:00Z`) : new Date();\nconst warnDays = 30;\nconst day = 24 * 60 * 60 * 1000;\nlet trouble = 0;",
     "The folder, and the day to ask about. With no date it asks about now. Noon UTC keeps a date from sliding to the day before in any time zone.",
     "A pasta, e o dia sobre o qual perguntar. Sem data, ele pergunta sobre agora. Meio-dia UTC impede que uma data escorregue para o dia anterior em qualquer fuso."),
    ("for (const name of readdirSync(folder).filter((f) => f.endsWith(\".pem\")).sort()) {\n  const cert = new X509Certificate(readFileSync(join(folder, name)));\n  const cn = cert.subject.split(\"\\n\").find((l) => l.startsWith(\"CN=\"))?.slice(3) ?? name;",
     "Every `.pem` file, in name order so the output is the same on every run. The subject's `CN=` line is the name Apple writes, such as *Apple Distribution: Study Planner*.",
     "Todo arquivo `.pem`, em ordem de nome para a saída ser a mesma a cada execução. A linha `CN=` do subject é o nome que a Apple escreve, como *Apple Distribution: Study Planner*."),
    ("  const left = Math.floor((cert.validToDate.getTime() - on.getTime()) / day);\n  const state = left < 0 ? \"EXPIRED\" : left < warnDays ? \"RENEW\" : \"ok\";\n  if (state !== \"ok\") trouble++;\n  console.log(`${state.padEnd(7)} ${String(left).padStart(5)} days  ${cert.validToDate.toISOString().slice(0, 10)}  ${cn}`);\n}",
     "Whole days left, rounded down. Under 30 is time to renew; below 0 it has already gone.",
     "Dias inteiros restantes, arredondados para baixo. Menos de 30 é hora de renovar; abaixo de 0 já venceu."),
    ("process.exitCode = trouble ? 1 : 0;",
     "The exit status is the part a pipeline reads: 1 when anything needs attention.",
     "O status de saída é a parte que um pipeline lê: 1 quando algo precisa de atenção."),
]
EXAMPLES = {"watching-the-expiry": [{"language": "typescript", "file": "expiry.ts", "parts": EXPIRY}]}
