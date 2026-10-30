"""Lesson 5: the main axis, in a column and in a row."""
from fig import Fig

T = {
 "en": dict(aria="Two flex containers. On the left, the default: flexDirection column, so the main axis runs top to bottom, justifyContent moves children along it and alignItems across it, and children stretch across by default. On the right, flexDirection row, as the planner's header uses: the main axis runs left to right, and alignItems center centres the icon and the title vertically.",
   col="flexDirection: column (default)", row="flexDirection: row", main="main axis", cross="cross axis",
   jc="justifyContent", ai="alignItems", a="child A", b="child B", c="child C", icon="icon", title="Study planner",
   cap="The same two properties, turned through a right angle: in a column, justifyContent works vertically; in a row, horizontally."),
 "pt": dict(aria="Dois contêineres flex. À esquerda, o padrão: flexDirection column, então o eixo principal vai de cima para baixo, o justifyContent move os filhos ao longo dele e o alignItems através dele, e os filhos se esticam na largura por padrão. À direita, flexDirection row, como o cabeçalho do planner usa: o eixo principal vai da esquerda para a direita, e alignItems center centraliza o ícone e o título na vertical.",
   col="flexDirection: column (padrão)", row="flexDirection: row", main="eixo principal", cross="eixo cruzado",
   jc="justifyContent", ai="alignItems", a="filho A", b="filho B", c="filho C", icon="ícone", title="Study planner",
   cap="As mesmas duas propriedades, giradas em ângulo reto: numa coluna, o justifyContent trabalha na vertical; numa linha, na horizontal."),
}


def figures(lang):
    t = T[lang]
    f = Fig("l05-axes", 720, 270, t["aria"])
    f.text(160, 18, t["col"], mono=True, size=9.5, fill="phosphor")
    f.rect(60, 34, 200, 190, stroke="wire", fill="ink")
    for i, k in enumerate(("a", "b", "c")):
        f.box(76, 50 + i * 54, 168, 40, [t[k]], size=9.5)
    f.arrow([(40, 40), (40, 220)], color="amber")
    f.text(30, 244, t["main"] + " · " + t["jc"], anchor="start", size=9, fill="amber", italic=True)
    f.arrow([(60, 236), (260, 236)], color="paper-dim")
    f.text(160, 258, t["cross"] + " · " + t["ai"], size=9, fill="paper-dim", italic=True)
    f.text(540, 18, t["row"], mono=True, size=9.5, fill="phosphor")
    f.rect(400, 80, 290, 80, stroke="wire", fill="ink")
    f.box(416, 100, 40, 40, [t["icon"]], size=8.5)
    f.box(468, 106, 150, 28, [t["title"]], size=9.5)
    f.arrow([(400, 180), (690, 180)], color="amber")
    f.text(545, 198, t["main"] + " · " + t["jc"], size=9, fill="amber", italic=True)
    f.arrow([(706, 80), (706, 160)], color="paper-dim")
    f.text(690, 60, t["cross"] + " · " + t["ai"], anchor="end", size=9, fill="paper-dim", italic=True)
    return {"l05-axes": f.json(caption=t["cap"], same=None if lang == "en" else ["Study planner"])}
