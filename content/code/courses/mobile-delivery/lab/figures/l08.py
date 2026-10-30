"""Lesson 8: the rollout script, and the day it halts."""
from fig import Fig

P = [
    ("// rollout.ts: a staged rollout simulated day by day, and the rule that halts it\nconst STAGES = [1, 2, 5, 10, 20, 50, 100];\nconst INSTALLS = 20_000;\nconst MIN_USERS = 500;\nconst MAX_DROP = 0.5;",
     "Apple's seven daily steps, twenty thousand installs, and the rule's two numbers: say nothing below 500 people, halt on a drop of more than half a point.",
     "Os sete passos diários da Apple, vinte mil instalações, e os dois números da regra: não dizer nada abaixo de 500 pessoas, interromper numa queda de mais de meio ponto."),
    ("function hash(text: string): number {\n  let h = 0x811c9dc5;\n  for (let i = 0; i < text.length; i++) h = Math.imul(h ^ text.charCodeAt(i), 0x01000193) >>> 0;\n  return h;\n}\nconst installs = Array.from({ length: INSTALLS }, (_, i) => `install-${i}`);\nconst bucket = (id: string) => hash(`rollout:${id}`) % 10_000;",
     "FNV-1a, a small hash that gives the same number for the same text on every run. Each install falls in one of 10,000 buckets, forever.",
     "FNV-1a, um hash pequeno que dá o mesmo número para o mesmo texto em toda execução. Cada instalação cai num de 10.000 baldes, para sempre."),
    ("const crashes = (id: string, version: \"1.4.0\" | \"1.5.0\") => {\n  const roll = hash(`crash:${version}:${id}`) % 1000;\n  const oldAndroid = hash(`os:${id}`) % 100 < 8;\n  return version === \"1.5.0\" && oldAndroid ? roll < 250 : roll < 5;\n};\nfunction crashFree(ids: string[], version: \"1.4.0\" | \"1.5.0\"): number {\n  return (100 * ids.filter((id) => !crashes(id, version)).length) / ids.length;\n}",
     "The invented bug: half a per cent of people crash on any version, and on 1.5.0 a quarter of the 8% with older Android do. Crash-free users is the share that saw no crash.",
     "O bug inventado: meio por cento das pessoas quebra em qualquer versão, e na 1.5.0 um quarto dos 8% com Android antigo quebra. Usuários sem crash é a fração que não viu nenhum."),
    ("console.log(\"day  stage  on 1.5.0  crash-free 1.5.0  crash-free 1.4.0  decision\");\nfor (const [day, stage] of STAGES.entries()) {\n  const onNew = installs.filter((id) => bucket(id) < stage * 100);\n  const onOld = installs.filter((id) => bucket(id) >= stage * 100);\n  const fresh = crashFree(onNew, \"1.5.0\");\n  const old = onOld.length ? crashFree(onOld, \"1.4.0\") : NaN;",
     "Each day, the installs below the day's percentage are on 1.5.0, and the rest are still on 1.4.0.",
     "A cada dia, as instalações abaixo da porcentagem do dia estão na 1.5.0, e o resto ainda na 1.4.0."),
    ("  let decision = \"continue\";\n  if (onNew.length < MIN_USERS) decision = `wait: fewer than ${MIN_USERS} users`;\n  else if (old - fresh > MAX_DROP) decision = \"HALT\";\n  console.log(`${String(day + 1).padStart(3)}  ${String(stage).padStart(4)}%  ${String(onNew.length).padStart(8)}  ${fresh.toFixed(2).padStart(15)}%  ${old.toFixed(2).padStart(15)}%  ${decision}`);\n  if (decision === \"HALT\") {\n    console.log(`halted on day ${day + 1}: ${onNew.length} installs keep 1.5.0 until a fix reaches them`);\n    break;\n  }\n}",
     "The rule, in the order a person would apply it: first is there enough to judge, then is the new version worse.",
     "A regra, na ordem em que uma pessoa a aplicaria: primeiro, há o bastante para julgar; depois, a versão nova é pior."),
]
EXAMPLES = {"deciding-to-halt": [{"language": "typescript", "file": "rollout.ts", "parts": P}]}

T = {
    "en": dict(aria="A chart of crash-free users by day of the rollout, from 95% to 100%. Version 1.4.0 stays at 99.46% on days 1 to 3. Version 1.5.0 is 97.95% on day 1 and 98.21% on day 2, both in a shaded zone marked too few users to judge, and 96.24% on day 3, where the rule halts the rollout. Days 4 to 7 are never reached.",
               y="crash-free users", day="day", wait="too few users to judge", halt="halt", never="never reached",
               cap="Days 1 and 2 already look worse, and the rule still waits: with a few hundred people, a handful of crashes moves the rate by a point. Day 3 has a thousand, and the gap is three points."),
    "pt": dict(aria="Um gráfico de usuários sem crash por dia da liberação, de 95% a 100%. A versão 1.4.0 fica em 99,46% nos dias 1 a 3. A versão 1.5.0 tem 97,95% no dia 1 e 98,21% no dia 2, os dois numa faixa sombreada marcada como poucos usuários para julgar, e 96,24% no dia 3, quando a regra interrompe a liberação. Os dias 4 a 7 nunca chegam.",
               y="usuários sem crash", day="dia", wait="poucos usuários para julgar", halt="interrompe", never="nunca chegam",
               cap="Os dias 1 e 2 já parecem piores, e a regra ainda espera: com poucas centenas de pessoas, um punhado de crashes move a taxa em um ponto. O dia 3 tem mil, e a diferença é de três pontos."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l08-halt", 720, 300, t["aria"])
    x0, x1, y0, y1 = 90, 680, 250, 30
    def X(d): return x0 + (d - 1) * (x1 - x0) / 6
    def Y(v): return y0 - (v - 95) * (y0 - y1) / 5
    f.arrow([(X(2) + 25, y1 - 6), (X(2) + 25, y0)], color="wire", head=False, dashed=True)
    f.text((X(1) + X(2)) / 2, y1 + 14, t["wait"], size=9, fill="paper-dim", italic=True)
    f.arrow([(X(4) - 20, y1 - 6), (X(4) - 20, y0)], color="wire", head=False, dashed=True)
    f.text((X(4) + X(7)) / 2, y1 + 14, t["never"], size=9, fill="paper-dim", italic=True)
    for v in (95, 96, 97, 98, 99, 100):
        f.arrow([(x0 - 30, Y(v)), (x1 + 10, Y(v))], color="wire", head=False, width=0.6)
        f.text(x0 - 36, Y(v), f"{v}%", anchor="end", mono=True, size=9, fill="paper-dim")
    for d in range(1, 8):
        f.text(X(d), y0 + 16, str(d), mono=True, size=9, fill="paper-dim")
    f.text((x0 + x1) / 2, y0 + 34, t["day"], size=9.5, fill="paper-dim")
    f.text(20, 12, t["y"], anchor="start", size=9.5, fill="paper-dim")
    old = [(X(d), Y(99.46)) for d in (1, 2, 3)]
    new = [(X(1), Y(97.95)), (X(2), Y(98.21)), (X(3), Y(96.24))]
    f.arrow(old, color="phosphor", head=False, width=2)
    f.arrow(new, color="amber", head=False, width=2)
    f.text(X(3) + 12, Y(99.46), "1.4.0  99.46%", anchor="start", mono=True, size=9, fill="phosphor")
    f.text(X(1) + 10, Y(97.95) + 14, "97.95%", anchor="start", mono=True, size=9, fill="amber")
    f.text(X(2), Y(98.21) - 12, "98.21%", mono=True, size=9, fill="amber")
    f.text(X(3) + 12, Y(96.24), "1.5.0  96.24%", anchor="start", mono=True, size=9, fill="amber")
    f.text(X(3), Y(96.24) + 22, t["halt"], size=10, bold=True, fill="amber")
    return {"l08-halt": f.json(t["cap"])}
