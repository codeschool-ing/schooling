"""Lesson 13: src/contrast.ts annotated, the colour pairs of both themes, and what 24 pixels means."""
from fig import Fig

CONTRAST = [
    ('// src/contrast.ts\nexport function luminance(hex: string): number {\n  const [r, g, b] = [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16) / 255);\n',
     "A colour written `#rrggbb` holds three channels of two hex digits each. Each is read and divided by 255, so that it runs from 0 to 1.",
     "Uma cor escrita `#rrggbb` guarda três canais de dois dígitos hexadecimais cada. Cada um é lido e dividido por 255, para ir de 0 a 1."),
    ('  const light = (c: number) => (c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);\n',
     "A screen stores a channel encoded, not as the light it makes; this undoes the encoding. WCAG 2.2 writes the threshold as 0.04045, where older versions wrote 0.03928, and no 8-bit colour falls between the two.",
     "Uma tela guarda um canal codificado, não como a luz que ele faz; isto desfaz a codificação. A WCAG 2.2 escreve o limite como 0.04045, onde versões antigas escreviam 0.03928, e nenhuma cor de 8 bits cai entre os dois."),
    ('  return 0.2126 * light(r) + 0.7152 * light(g) + 0.0722 * light(b);\n}\n',
     "The three are weighted by how sensitive the eye is to each: green most, blue least. White gives 1 and black 0.",
     "Os três são pesados pela sensibilidade do olho a cada um: verde mais, azul menos. Branco dá 1 e preto 0."),
    ('export function contrast(a: string, b: string): number {\n  const [lighter, darker] = [luminance(a), luminance(b)].sort((x, y) => y - x);\n  return (lighter + 0.05) / (darker + 0.05);\n}',
     "The lighter over the darker, whichever order they come in, with 0.05 added to both for the light the screen reflects. Black on white is (1 + 0.05) / (0 + 0.05), which is 21.",
     "A mais clara sobre a mais escura, em qualquer ordem que venham, com 0.05 somado às duas pela luz que a tela reflete. Preto sobre branco é (1 + 0.05) / (0 + 0.05), que dá 21."),
]
EXAMPLES = {"contrast": [{"language": "typescript", "file": "src/contrast.ts", "parts": CONTRAST}]}

T = {
    "en": dict(
        pairs_aria="Four colour pairs, each drawn as a swatch of the text colour on its background, with its ratio. Light theme: #aaaaaa on white, 2.32 to 1, fails; #6b6b6b on white, 5.33 to 1, passes. Dark theme: the light theme's green #2f6f4e on #161616, 3.02 to 1, fails; #6fc596 on #161616, 8.71 to 1, passes. A note says that AA asks 4.5 to 1 for text.",
        sample="Done", fail="fails", pass_="passes", bar="AA for text: 4.5:1",
        light="light theme", dark="dark theme",
        pairs_cap="The two failures this course found and the two colours that replaced them. A colour that passes on one background can fail on the other: the green is the same in both failures and passes.",
        target_aria="Two drawings at the same scale. On the left, a dashed square of 24 by 24 CSS pixels beside the planner's Done button before the fix, 39 by 18: the button is shorter than the square. On the right, the same square beside the button after the fix, at least 24 pixels high, as tall as the square. A note says that a target smaller than 24 pixels still passes if a circle of 24 pixels around its centre touches no other target.",
        before="before: 39 × 18", after="after: at least 24 high",
        square="24 × 24 CSS px",
        note="smaller still passes if a 24 px circle around it touches no other target",
        target_cap="2.5.8 Target Size (Minimum), level AA. The rule is about the box the person has to hit, not about the size of the text inside it.",
    ),
    "pt": dict(
        pairs_aria="Quatro pares de cores, cada um desenhado como uma amostra da cor do texto sobre o seu fundo, com a sua razão. Tema claro: #aaaaaa sobre branco, 2,32 para 1, falha; #6b6b6b sobre branco, 5,33 para 1, passa. Tema escuro: o verde do tema claro, #2f6f4e, sobre #161616, 3,02 para 1, falha; #6fc596 sobre #161616, 8,71 para 1, passa. Uma nota diz que o AA pede 4,5 para 1 para texto.",
        sample="Done", fail="falha", pass_="passa", bar="AA para texto: 4,5:1",
        light="tema claro", dark="tema escuro",
        pairs_cap="As duas falhas que este curso encontrou e as duas cores que as substituíram. Uma cor que passa num fundo pode falhar no outro: o verde é o mesmo numa falha e num acerto.",
        target_aria="Dois desenhos na mesma escala. À esquerda, um quadrado tracejado de 24 por 24 pixels CSS ao lado do botão Done do planner antes da correção, 39 por 18: o botão é mais baixo que o quadrado. À direita, o mesmo quadrado ao lado do botão depois da correção, com pelo menos 24 pixels de altura, tão alto quanto o quadrado. Uma nota diz que um alvo menor que 24 pixels ainda passa se um círculo de 24 pixels em volta do centro dele não tocar outro alvo.",
        before="antes: 39 × 18", after="depois: pelo menos 24 de altura",
        square="24 × 24 px CSS",
        note="menor ainda passa se um círculo de 24 px em volta não tocar outro alvo",
        target_cap="O 2.5.8 Tamanho do alvo (Mínimo), nível AA. A regra é sobre a caixa que a pessoa precisa acertar, não sobre o tamanho do texto dentro dela.",
    ),
}
PAIRS = [("light", "#aaaaaa", "#ffffff", "2.32:1", False), ("light", "#6b6b6b", "#ffffff", "5.33:1", True),
         ("dark", "#2f6f4e", "#161616", "3.02:1", False), ("dark", "#6fc596", "#161616", "8.71:1", True)]


def figures(lang):
    t = T[lang]
    f = Fig("l13-pairs", 720, 200, t["pairs_aria"])
    f.text(190, 20, t["light"], size=10, italic=True, fill="paper-dim")
    f.text(530, 20, t["dark"], size=10, italic=True, fill="paper-dim")
    for i, (theme, fg, bg, ratio, ok) in enumerate(PAIRS):
        x = 30 + i * 172
        f.out.append(f'<rect x="{x}" y="36" width="150" height="64" rx="4" fill="{bg}" stroke="var(--wire)" stroke-width="1.4"></rect>')
        # The text colour as a swatch rather than as text: a figure may not draw words below AA,
        # and two of these four pairs are below it on purpose.
        f.out.append(f'<rect x="{x + 40}" y="58" width="70" height="20" rx="3" fill="{fg}"></rect>')
        f.text(x + 75, 116, f"{fg} / {bg}", mono=True, size=9, fill="paper-dim")
        r = ratio.replace(".", ",") if lang == "pt" else ratio
        f.text(x + 75, 140, r, size=13, bold=True, fill="phosphor" if ok else "amber")
        f.text(x + 75, 162, t["pass_"] if ok else t["fail"], size=10, italic=True, fill="phosphor" if ok else "amber")
    f.text(690, 190, t["bar"], size=9, anchor="end", italic=True, fill="paper-dim")
    pairs = f.json(t["pairs_cap"])

    g = Fig("l13-target", 720, 220, t["target_aria"])
    s = 4  # pixels drawn per CSS pixel
    for x0, w, h, label in ((40, 39, 18, t["before"]), (390, 47, 24, t["after"])):
        g.rect(x0, 40, 24 * s, 24 * s, stroke="paper-dim", fill="ink", dashed=True, rx=0)
        bx = x0 + 24 * s + 16
        g.box(bx, 40 + (24 - h) * s, w * s, h * s, ["Done"], size=11, stroke="amber" if h < 24 else "phosphor")
        g.text(x0 + (24 * s + 16 + w * s) / 2, 158, label, size=10, fill="amber" if h < 24 else "phosphor", italic=True)
        g.text(x0 + 12 * s, 88, t["square"], size=9, fill="paper-dim", italic=True)
    g.text(360, 196, t["note"], size=9, fill="paper-dim", italic=True)
    target = g.json(t["target_cap"], same=["Done"] if lang == "pt" else None)
    return {"l13-pairs": pairs, "l13-target": target}
