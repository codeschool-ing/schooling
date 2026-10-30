"""Lesson 13: where data can go, and inventory.ts as an annotated example."""
from fig import Fig

T = {
    "en": dict(
        aria="Data flowing from the app to the three places it can go, and what each means for the store's declaration. Left, the device only: not collected, nothing to declare; the planner's courses, sessions and reminder times stay here. Middle, your own server: collected, declared with its purpose. Right, a third-party SDK's company: collected and shared, declared even though the code is not yours.",
        app="the app",
        dev=["the device only"], srv=["your own server"], sdk=["a third-party", "SDK's company"],
        d1="not collected", d2="nothing to declare",
        s1="collected", s2="declared, with its purpose",
        t1="collected and shared", t2="declared, though the", t3="code is not yours",
        planner="the planner: courses, sessions,", planner2="reminder times",
        cap="Where the data goes decides what the form says. The planner keeps everything in the left-hand box.",
    ),
    "pt": dict(
        aria="Dados saindo do app para os três lugares aonde podem ir, e o que cada um significa para a declaração da loja. À esquerda, só o aparelho: não coletado, nada a declarar; os cursos, as sessões e os horários de lembrete do planner ficam aqui. No meio, o seu próprio servidor: coletado, declarado com a finalidade. À direita, a empresa de um SDK de terceiros: coletado e compartilhado, declarado mesmo o código não sendo seu.",
        app="o app",
        dev=["só o aparelho"], srv=["o seu servidor"], sdk=["a empresa de um", "SDK de terceiros"],
        d1="não coletado", d2="nada a declarar",
        s1="coletado", s2="declarado, com a finalidade",
        t1="coletado e compartilhado", t2="declarado, embora o", t3="código não seja seu",
        planner="o planner: cursos, sessões,", planner2="horários de lembrete",
        cap="Para onde os dados vão decide o que o formulário diz. O planner guarda tudo na caixa da esquerda.",
    ),
}


def where(t):
    f = Fig("l13-where", 720, 260, t["aria"])
    f.box(300, 14, 120, 34, [t["app"]], stroke="paper", bold=True)
    xs = [30, 270, 510]
    strokes = ["phosphor", "wire", "amber"]
    for x, lab, s in zip(xs, [t["dev"], t["srv"], t["sdk"]], strokes):
        f.box(x, 90, 180, 44, lab, stroke=s, size=10, bold=True)
    f.arrow([(330, 48), (120, 90)], color="phosphor")
    f.arrow([(360, 48), (360, 90)])
    f.arrow([(390, 48), (600, 90)], color="amber")
    f.text(120, 154, t["d1"], size=9.5, fill="phosphor")
    f.text(120, 170, t["d2"], size=9.5, fill="paper-dim")
    f.text(360, 154, t["s1"], size=9.5)
    f.text(360, 170, t["s2"], size=9.5, fill="paper-dim")
    f.text(600, 154, t["t1"], size=9.5, fill="amber")
    f.text(600, 170, t["t2"], size=9.5, fill="paper-dim")
    f.text(600, 184, t["t3"], size=9.5, fill="paper-dim")
    f.box(30, 200, 180, 44, [t["planner"], t["planner2"]], stroke="phosphor", size=9, dashed=True)
    return f


def figures(lang):
    t = T[lang]
    return {"l13-where": where(t).json(t["cap"])}


EXAMPLES = {
    "the-inventory": [
        {"language": "typescript", "file": "inventory.ts", "parts": [
            ('// inventory.ts: every kind of data the planner touches, and where each one goes\nexport type Goes = "device" | "our server" | "third party";\nexport type Purpose = "App Functionality" | "Analytics" | "Product Personalization" | "Third-Party Advertising";\nexport type Item = {\n  what: string; // the kind of data, as a person would name it\n  why: string; // the reason, in a sentence; an entry without one is refused\n  purpose: Purpose; // the store\'s word for the reason\n  goes: Goes; // the furthest place it travels\n  optional: boolean; // can the student use the app without giving it?\n};\n',
             "One entry per kind of data. `purpose` uses four of the names on Apple's list of purposes, and `goes` has the three places of the figure above. `why` is a sentence for a person; `purpose` is the word for the form.",
             "Uma entrada por tipo de dado. `purpose` usa quatro dos nomes da lista de finalidades da Apple, e `goes` tem os três lugares da figura acima. `why` é uma frase para uma pessoa; `purpose` é a palavra para o formulário."),
            ('// The check: every entry says why, before anything is declared.\nexport function check(items: Item[]): void {\n  const bare = items.filter((i) => i.why.trim() === "").map((i) => i.what);\n  if (bare.length > 0) throw new Error(`no reason given for: ${bare.join(", ")}`);\n}\n',
             "The refusal. An entry whose reason is empty, or only spaces, stops everything, and the message names every such entry at once rather than the first.",
             "A recusa. Uma entrada com o motivo vazio, ou só com espaços, para tudo, e a mensagem nomeia todas essas entradas de uma vez, não só a primeira."),
            ("// The answers a store form asks for, worked out from the inventory. Data that\n// never leaves the device is not collected; data that reaches a third party,\n// an SDK's company included, is collected and shared.\nexport function declare(items: Item[]): string[] {\n  check(items);\n  const away = items.filter((i) => i.goes !== \"device\");\n  if (away.length === 0) return [\"collected: nothing\", \"shared: nothing\"];\n  return away.map((i) => {\n    const shared = i.goes === \"third party\" ? \"shared\" : \"not shared\";\n    const opt = i.optional ? \"optional\" : \"required\";\n    return `collected: ${i.what} (${i.purpose}; ${shared}; ${opt})`;\n  });\n}",
             "The definitions of the previous section, as code. Only what leaves the device is listed; reaching a third party is what makes it shared. `declare` calls `check` first, so no answer is ever printed from an inventory with a hole in it.",
             "As definições da seção anterior, em código. Só o que sai do aparelho é listado; chegar a um terceiro é o que o torna compartilhado. `declare` chama `check` primeiro, então nenhuma resposta sai de um inventário com um buraco."),
        ]},
    ],
}
