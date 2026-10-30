"""Lesson 20: the release path on both stores; version numbers over three releases; version.ts."""
from fig import Fig

T = {
    "en": dict(
        aria1="The path from a build to every user, on both stores, in five stages left to right. A signed build; review; testing tracks; a staged release; everyone. Top row, Google Play: an app bundle signed for Play, Google Play review, internal then closed then open testing, a staged rollout to a percentage the team chooses, and production. Bottom row, the App Store: a build signed through Apple, App Review, TestFlight with internal and external testers, a phased release over seven days, and all users. Under the stages, a note that review comes before the public on both, and that external TestFlight builds are reviewed too.",
        stages=["a signed build", "review", "testing tracks", "staged release", "everyone"],
        play="Google Play", apple="App Store",
        p=[["app bundle,", "signed"], ["Google Play", "review"], ["internal, closed,", "open testing"], ["staged rollout,", "% you choose"], ["production"]],
        a=[["build signed", "through Apple"], ["App Review"], ["TestFlight:", "internal, external"], ["phased release,", "7 days"], ["all users"]],
        note="external TestFlight builds go through review as well",
        cap1="The same five stages on both stores. The names differ; the order does not. Nothing here was run against either store.",
        aria2="Version numbers over three releases of the planner, as a timeline. Release 1.9.2, build 41, shipped. Then 1.10.0, build 42, rejected in review and never shipped, drawn dashed. Then 1.10.0 again, build 43, shipped. Then 1.10.1, build 44, shipped. The name people read repeats when a build is redone; the build number never repeats and only grows.",
        reads="the name people read", compares="the number the store compares",
        rej="rejected in review", shipped="shipped",
        cap2="Three releases and four builds. The name 1.10.0 appears twice, because the rejected build was fixed and sent again; the build number moved on and 42 is gone for good.",
    ),
    "pt": dict(
        aria1="O caminho de um build até todos os usuários, nas duas lojas, em cinco etapas da esquerda para a direita. Um build assinado; revisão; faixas de teste; uma liberação gradual; todo mundo. Na linha de cima, o Google Play: um app bundle assinado para o Play, a revisão do Google Play, teste interno, depois fechado, depois aberto, uma liberação gradual para uma porcentagem que a equipe escolhe, e produção. Na de baixo, a App Store: um build assinado pela Apple, o App Review, o TestFlight com testadores internos e externos, uma liberação em fases ao longo de sete dias, e todos os usuários. Abaixo das etapas, uma nota de que a revisão vem antes do público nas duas, e de que builds externos do TestFlight também são revisados.",
        stages=["um build assinado", "revisão", "faixas de teste", "liberação gradual", "todo mundo"],
        play="Google Play", apple="App Store",
        p=[["app bundle,", "assinado"], ["revisão do", "Google Play"], ["teste interno,", "fechado, aberto"], ["liberação gradual,", "% que você escolhe"], ["produção"]],
        a=[["build assinado", "pela Apple"], ["App Review"], ["TestFlight:", "interno, externo"], ["liberação em", "fases, 7 dias"], ["todos os usuários"]],
        note="builds externos do TestFlight também passam por revisão",
        cap1="As mesmas cinco etapas nas duas lojas. Os nomes mudam; a ordem não. Nada aqui foi executado contra nenhuma das lojas.",
        aria2="Números de versão ao longo de três versões do planner, numa linha do tempo. A versão 1.9.2, build 41, publicada. Depois 1.10.0, build 42, recusada na revisão e nunca publicada, desenhada tracejada. Depois 1.10.0 de novo, build 43, publicada. Depois 1.10.1, build 44, publicada. O nome que as pessoas leem se repete quando um build é refeito; o número de build nunca se repete e só cresce.",
        reads="o nome que as pessoas leem", compares="o número que a loja compara",
        rej="recusado na revisão", shipped="publicado",
        cap2="Três versões e quatro builds. O nome 1.10.0 aparece duas vezes, porque o build recusado foi corrigido e enviado de novo; o número de build seguiu em frente e o 42 se foi para sempre.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l20-path", 720, 280, t["aria1"])
    xs = [100, 224, 348, 472, 596]
    for x, s in zip(xs, t["stages"]):
        f.text(x + 56, 22, s, bold=True, size=10, fill="phosphor")
    f.text(12, 76, t["play"], anchor="start", bold=True, size=10, fill="paper")
    f.text(12, 166, t["apple"], anchor="start", bold=True, size=10, fill="paper")
    for row, y in ((t["p"], 50), (t["a"], 140)):
        for i, (x, lines) in enumerate(zip(xs, row)):
            last = i == 4
            f.box(x, y, 112, 52, lines, stroke="phosphor" if last else ("amber" if i == 1 else "wire"), size=9.5)
            if not last:
                f.arrow([(x + 112, y + 26), (x + 124, y + 26)])
    f.text(404, 214, t["note"], size=9.5, italic=True, fill="paper-dim")
    f.arrow([(404, 204), (404, 194)], dashed=True)
    out = {"l20-path": f.json(t["cap1"], same=None if lang == "en" else ["Google Play", "App Store", "App Review", "app bundle,", "TestFlight:"])}

    g = Fig("l20-numbers", 720, 230, t["aria2"])
    g.text(20, 80, t["reads"], anchor="start", size=9.5, italic=True, fill="paper-dim")
    g.text(20, 150, t["compares"], anchor="start", size=9.5, italic=True, fill="paper-dim")
    g.arrow([(190, 196), (700, 196)], color="wire")
    rel = [("1.9.2", "41", False), ("1.10.0", "42", True), ("1.10.0", "43", False), ("1.10.1", "44", False)]
    for i, (name, build, rejected) in enumerate(rel):
        x = 200 + i * 125
        st = "wire" if rejected else "phosphor"
        g.box(x, 60, 100, 40, [name], mono=True, size=12, stroke=st, dashed=rejected)
        g.box(x, 130, 100, 40, [build], mono=True, size=12, stroke="amber" if not rejected else "wire", dashed=rejected)
        g.text(x + 50, 210, t["rej"] if rejected else t["shipped"], size=9, italic=True,
               fill="paper-dim" if rejected else "paper")
        if i < 3:
            g.arrow([(x + 100, 150), (x + 125, 150)], color="paper-dim")
    out["l20-numbers"] = g.json(t["cap2"])
    return out


EXAMPLES = {
    "versions": [
        {"language": "typescript", "file": "version.ts", "parts": [
            ('// version.ts: is this release candidate newer than what the store already has?\ntype Release = { name: string; build: number }; // versionName + versionCode, or the two iOS keys\n',
             "One shape for both platforms: `name` is `versionName` or `CFBundleShortVersionString`, `build` is `versionCode` or `CFBundleVersion`. The build is a plain integer here, as Android's is.",
             'Uma forma para as duas plataformas: `name` é o `versionName` ou o `CFBundleShortVersionString`, `build` é o `versionCode` ou o `CFBundleVersion`. Aqui o build é um inteiro simples, como o do Android.'),
            ('// "1.10.0" -> [1, 10, 0]; a missing part counts as 0, so "1.10" equals "1.10.0".\nfunction parts(name: string): number[] {\n  if (!/^\\d+(\\.\\d+){0,2}$/.test(name)) throw new Error(`not a version: ${name}`);\n  const p = name.split(".").map(Number);\n  while (p.length < 3) p.push(0);\n  return p;\n}\n',
             'A version is up to three numbers separated by dots, and anything else is refused loudly. Padding with zeros is Apple\'s rule for `CFBundleVersion`: "10.5 specifies 10.5.0".',
             'Uma versão é até três números separados por pontos, e qualquer outra coisa é recusada com erro. Completar com zeros é a regra da Apple para o `CFBundleVersion`: "10.5 especifica 10.5.0".'),
            ('// Negative if a is older, 0 if the same, positive if a is newer: part by part, as numbers.\nexport function compare(a: string, b: string): number {\n  const [x, y] = [parts(a), parts(b)];\n  for (let i = 0; i < 3; i++) if (x[i] !== y[i]) return x[i] - y[i];\n  return 0;\n}\n',
             'The comparison that text cannot do: 10 against 9 as numbers, part by part, stopping at the first difference.',
             'A comparação que o texto não consegue fazer: 10 contra 9 como números, parte por parte, parando na primeira diferença.'),
            ("// Why the candidate must not ship; an empty list means it may. The build rule is the stores';\n// the name rule is ours, because the name is the number people read.\nexport function problems(candidate: Release, published: Release): string[] {\n  const out: string[] = [];\n  if (!Number.isInteger(candidate.build) || candidate.build < 1 || candidate.build > 2100000000) { // Play's ceiling\n    out.push(`build ${candidate.build} is not an integer from 1 to 2100000000`);\n  } else if (candidate.build <= published.build) {\n    out.push(`build ${candidate.build} is not higher than the published ${published.build}`);\n  }\n  if (compare(candidate.name, published.name) < 0) {\n    out.push(`version ${candidate.name} goes back from the published ${published.name}`);\n  }\n  return out;\n}\n",
             "Every reason at once, not just the first, so one run says everything wrong with a candidate. The ceiling of 2100000000 is Play's; the comment says whose rule each check is.",
             'Todos os motivos de uma vez, não só o primeiro, para que uma execução diga tudo o que está errado num candidato. O teto de 2100000000 é do Play; o comentário diz de quem é cada regra.'),
            ('const published: Release = { name: "1.9.2", build: 41 };\nconsole.log(`as text, "1.10.0" > "1.9.2" is ${"1.10.0" > "1.9.2"}`);\nconsole.log(`as versions, compare("1.10.0", "1.9.2") is ${compare("1.10.0", "1.9.2")}`);\nfor (const c of [\n  { name: "1.10.0", build: 42 },\n  { name: "1.10.0", build: 41 },\n  { name: "1.9.1", build: 43 },\n  { name: "1.9.2", build: 43 },\n]) {\n  const p = problems(c, published);\n  console.log(`${c.name} (${c.build}): ${p.length === 0 ? "ok" : "REFUSED, " + p.join("; ")}`);\n}',
             'The published release, the text comparison that goes wrong, and four candidates: one fine, one reusing a build number, one counting down, and one rebuild.',
             'A versão publicada, a comparação de texto que dá errado, e quatro candidatos: um certo, um que reusa o número de build, um que conta para trás e uma recompilação.'),
        ]},
    ],
}
