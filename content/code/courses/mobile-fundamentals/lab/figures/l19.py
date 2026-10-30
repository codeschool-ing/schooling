"""Lesson 19: what a screen reader announces, in order; a target grown by padding; contrast.ts."""
from fig import Fig

T = {
    "en": dict(
        aria1="The sequence a screen reader speaks when focus arrives on the planner's mark-done row. A swipe moves the focus onto the row. Then four parts in order: the label, SQL, Friday 23 October, 60 minutes, which comes from the text or a label the app sets; the role, checkbox, from the component or a declared role; the state, not checked, from the component's state; and a hint, optional and read after a pause, which this row does not need. A double tap then toggles it and the state is read again as checked.",
        swipe="a swipe right: focus arrives",
        parts=[("label", ["SQL, Fri 23 Oct,", "60 minutes"], "the text, or a label"),
               ("role", ["checkbox"], "the component's role"),
               ("state", ["not checked"], "the component's state"),
               ("hint", ["(none needed)"], "optional, after a pause")],
        tap="a double tap: the row toggles, and the state is read again: checked",
        cap1="What a screen reader says for one row, in order. It is a diagram of the sequence, not a recording: the exact words and pauses differ between TalkBack and VoiceOver and with the user's settings.",
        aria2="Two squares, each a touch target with the drawn tick in its centre. Left, Android: the tick is 24 by 24 dp, the target 48 by 48 dp, with 12 dp of padding on every side. Right, iOS: the tick is 24 by 24 pt, the target 44 by 44 pt, with 10 pt of padding on every side. The drawing stays the same size; only the area that answers a finger grows.",
        and_="Android", ios="iOS", drawn="drawn tick", t48="target 48 × 48 dp", t44="target 44 × 44 pt",
        cap2="The fix targets.ts asked for. The tick is still drawn at 24; the padding around it makes the area a finger can hit reach each platform's minimum.",
    ),
    "pt": dict(
        aria1="A sequência que um leitor de tela fala quando o foco chega à linha de marcar feito do planner. Um deslize leva o foco à linha. Depois quatro partes, em ordem: o rótulo, SQL, sexta 23 de outubro, 60 minutos, que vem do texto ou de um rótulo que o app define; o papel, caixa de seleção, do componente ou de um papel declarado; o estado, não marcada, do estado do componente; e uma dica, opcional e lida depois de uma pausa, de que esta linha não precisa. Um toque duplo então a alterna, e o estado é lido de novo como marcada.",
        swipe="um deslize para a direita: o foco chega",
        parts=[("rótulo", ["SQL, sex 23 out,", "60 minutos"], "o texto, ou um rótulo"),
               ("papel", ["caixa de seleção"], "o papel do componente"),
               ("estado", ["não marcada"], "o estado do componente"),
               ("dica", ["(nenhuma precisa)"], "opcional, após pausa")],
        tap="um toque duplo: a linha alterna, e o estado é lido de novo: marcada",
        cap1="O que um leitor de tela diz para uma linha, em ordem. É um diagrama da sequência, não uma gravação: as palavras exatas e as pausas mudam entre o TalkBack e o VoiceOver e com os ajustes do usuário.",
        aria2="Dois quadrados, cada um uma área de toque com o tique desenhado no centro. À esquerda, Android: o tique tem 24 por 24 dp, a área 48 por 48 dp, com 12 dp de margem interna em cada lado. À direita, iOS: o tique tem 24 por 24 pt, a área 44 por 44 pt, com 10 pt de margem interna em cada lado. O desenho continua do mesmo tamanho; só cresce a área que responde ao dedo.",
        and_="Android", ios="iOS", drawn="tique desenhado", t48="área 48 × 48 dp", t44="área 44 × 44 pt",
        cap2="A correção que targets.ts pediu. O tique continua desenhado em 24; a margem em volta faz a área que o dedo acerta chegar ao mínimo de cada plataforma.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l19-announce", 720, 250, t["aria1"])
    f.text(20, 24, t["swipe"], anchor="start", italic=True, fill="paper-dim")
    f.arrow([(30, 34), (30, 70), (40, 70)], dashed=True)
    x = 44
    for i, (head, lines, src) in enumerate(t["parts"]):
        dashed = i == 3
        f.text(x + 76, 52, head, bold=True, fill="phosphor" if not dashed else "paper-dim")
        f.box(x, 62, 152, 54, lines, stroke="phosphor" if not dashed else "wire", dashed=dashed,
              size=10)
        f.text(x + 76, 132, src, size=9, italic=True, fill="paper-dim")
        if i < 3:
            f.arrow([(x + 152, 89), (x + 168, 89)])
        x += 168
    f.box(44, 168, 656, 40, [t["tap"]], stroke="amber", size=10)
    f.arrow([(370, 146), (370, 166)], dashed=True)
    out = {"l19-announce": f.json(t["cap1"])}

    g = Fig("l19-padding", 720, 300, t["aria2"])
    for (cx, side, label, pad, unit, head) in ((190, 144, t["t48"], 12, "dp", t["and_"]), (530, 132, t["t44"], 10, "pt", t["ios"])):
        top = 150 - side / 2
        g.text(cx, 22, head, bold=True, size=11, fill="phosphor")
        g.rect(cx - side / 2, top, side, side, stroke="phosphor", fill="panel", dashed=True)
        g.box(cx - 36, 114, 72, 72, ["24 × 24"], stroke="amber", size=10, fill="paper")
        g.text(cx, top + side + 16, label, size=10)
        g.text(cx, 200, t["drawn"], size=9, italic=True, fill="paper-dim")
        # padding marks on the left and top
        g.arrow([(cx - side / 2, 150), (cx - 36, 150)], both=True, color="paper-dim")
        g.text(cx - side / 2 - 6, 150, f"{pad} {unit}", anchor="end", size=10, mono=True)
        g.arrow([(cx, top), (cx, 114)], both=True, color="paper-dim")
        g.text(cx + 6, top + (114 - top) / 2, f"{pad} {unit}", anchor="start", size=10, mono=True)
    out["l19-padding"] = g.json(t["cap2"], same=None if lang == "en" else ["Android", "iOS"])
    return out


EXAMPLES = {
    "contrast": [
        {"language": "typescript", "file": "contrast.ts", "parts": [
            ('// contrast.ts: WCAG\'s contrast ratio, checked on the planner\'s colour pairs\nimport { brand } from "./tokens.ts";\n',
             "The program reads the planner's colours from lesson 18's `tokens.ts`, so it checks the colours both themes actually use, not a copy of them.",
             'O programa lê as cores do planner do `tokens.ts` da aula 18, então confere as cores que os dois temas usam de fato, não uma cópia delas.'),
            ('// Relative luminance of an sRGB colour such as "#2F6F4E", as WCAG 2.2 defines it.\nexport function luminance(hex: string): number {\n  const [r, g, b] = [1, 3, 5].map((i) => {\n    const c = parseInt(hex.slice(i, i + 2), 16) / 255;\n    return c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;\n  });\n  return 0.2126 * r + 0.7152 * g + 0.0722 * b;\n}\n',
             "WCAG's relative luminance, line for line: each channel from 0 to 255 becomes 0 to 1, the sRGB curve is undone, and the three are weighted. Green weighs most because the eye is most sensitive to it.",
             'A luminância relativa da WCAG, linha a linha: cada canal de 0 a 255 vira 0 a 1, a curva do sRGB é desfeita, e os três são ponderados. O verde pesa mais porque o olho é mais sensível a ele.'),
            ('// (lighter + 0.05) / (darker + 0.05): 1 for the same colour, 21 for black on white.\nexport function ratio(a: string, b: string): number {\n  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);\n  return (hi + 0.05) / (lo + 0.05);\n}\n',
             'The ratio itself. Sorting puts the lighter colour on top, so the order the pair is written in does not matter.',
             'A razão em si. Ordenar põe a cor mais clara em cima, então a ordem em que o par é escrito não importa.'),
            ('// Each pair the planner draws, and what WCAG asks of it: 4.5 for text, 3 for a control\'s edge.\nconst pairs = [\n  { what: "session title", fg: "onSurface", bg: "surface", need: 4.5 },\n  { what: "date under it", fg: "muted", bg: "surface", need: 4.5 },\n  { what: "button label", fg: "onPrimary", bg: "primary", need: 4.5 },\n  { what: "checkbox edge", fg: "primary", bg: "surface", need: 3 },\n] as const;\n',
             'Four pairs the week screen draws, each with the threshold that applies to it: text needs 4.5, the edge of a control 3. The names are keys of `brand.light` and `brand.dark`.',
             'Quatro pares que a tela da semana desenha, cada um com o limite que vale para ele: texto precisa de 4,5, a borda de um controle de 3. Os nomes são chaves de `brand.light` e `brand.dark`.'),
            ('let failed = 0;\nfor (const mode of ["light", "dark"] as const) {\n  for (const p of pairs) {\n    const fg = brand[mode][p.fg];\n    const bg = brand[mode][p.bg];\n    const r = ratio(fg, bg);\n    const ok = r >= p.need;\n    if (!ok) failed++;\n    console.log(`${mode.padEnd(6)}${p.what.padEnd(15)}${fg} on ${bg}  ${r.toFixed(2).padStart(5)}:1  needs ${p.need}  ${ok ? "pass" : "FAIL"}`);\n  }\n}\nconsole.log(failed === 0 ? "every pair passes" : `${failed} pair(s) fail`);\nprocess.exitCode = failed === 0 ? 0 : 1;',
             'Every pair, in both appearances, with the ratio to two decimals so that a near miss shows as one. A failure also sets the exit code to 1.',
             'Todo par, nas duas aparências, com a razão em duas casas decimais para que um quase acerto apareça como tal. Uma reprovação também põe o código de saída em 1.'),
        ]},
    ],
}
