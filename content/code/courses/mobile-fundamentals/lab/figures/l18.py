"""Lesson 18: one planner screen in Material and in the HIG; where the actions live; tokens.ts."""
from fig import Fig

T = {
    "en": dict(
        aria1="Two diagrams of the same planner screen, regions only. Left, Material 3: a top app bar holding the title This week, the content area with the week's sessions and the line 120 of 180 minutes done, a floating action button at the bottom right above the content, and a navigation bar along the bottom with Week, Courses and Settings. Right, the Human Interface Guidelines: a toolbar at the top with a plus button at the trailing end, a large title This week below it, the same content area, and a tab bar along the bottom with Week, Courses and Settings. The main action is highlighted in both: bottom right on the left, top right on the right.",
        m="Material 3", h="Human Interface Guidelines",
        appbar="top app bar: This week", content=["the week's sessions", "120 of 180 min done"], fab="+ FAB",
        navbar=["navigation bar", "Week · Courses · Settings"],
        toolbar="toolbar", plus="+", large="large title: This week", tabbar=["tab bar", "Week · Courses · Settings"],
        same="the content is the same on both",
        cap1="The same screen in two guides. The content does not move; the title, the main action and the bar of sections take each platform's places. The main action, outlined in the warm colour, sits at opposite corners.",
        aria2="One phone outline with five places marked. Top left: the back button a pushed screen gets on iOS. Left edge: the system back gesture on Android. Top right: the plus button in the iOS toolbar. Bottom right, above the bar: Material's floating action button. Along the bottom: the bar of sections, a navigation bar or a tab bar, on both.",
        l1=["back button on a", "pushed screen (iOS)"], l2=["back gesture from", "the edge (Android)"], l3=["sections: navigation bar", "or tab bar (both)"],
        r1=["+ in the toolbar", "(iOS)"], r2=["floating action", "button (Material)"],
        cap2="Where each kind of action lives. The main action takes opposite corners; the sections share the bottom; going back is a gesture on one platform and a button on the other.",
    ),
    "pt": dict(
        aria1="Dois diagramas da mesma tela do planner, só as regiões. À esquerda, Material 3: uma top app bar com o título This week, a área de conteúdo com as sessões da semana e a linha 120 de 180 minutos concluídos, um botão de ação flutuante no canto inferior direito sobre o conteúdo, e uma barra de navegação embaixo com Week, Courses e Settings. À direita, as Human Interface Guidelines: uma toolbar no alto com um botão de mais na ponta final, um título grande This week abaixo dela, a mesma área de conteúdo, e uma tab bar embaixo com Week, Courses e Settings. A ação principal está destacada nas duas: embaixo à direita numa, no alto à direita na outra.",
        m="Material 3", h="Human Interface Guidelines",
        appbar="top app bar: This week", content=["as sessões da semana", "120 de 180 min feitos"], fab="+ FAB",
        navbar=["barra de navegação", "Week · Courses · Settings"],
        toolbar="toolbar", plus="+", large="título grande: This week", tabbar=["tab bar", "Week · Courses · Settings"],
        same="o conteúdo é o mesmo nas duas",
        cap1="A mesma tela em dois guias. O conteúdo não se mexe; o título, a ação principal e a barra de seções ocupam os lugares de cada plataforma. A ação principal, contornada na cor quente, fica em cantos opostos.",
        aria2="O contorno de um celular com cinco lugares marcados. No alto à esquerda: o botão de voltar que uma tela empilhada ganha no iOS. Na borda esquerda: o gesto de voltar do sistema no Android. No alto à direita: o botão de mais na toolbar do iOS. Embaixo à direita, acima da barra: o botão de ação flutuante do Material. Ao longo da base: a barra de seções, barra de navegação ou tab bar, nas duas.",
        l1=["voltar numa tela", "empilhada (iOS)"], l2=["gesto de voltar pela", "borda (Android)"], l3=["seções: barra de", "navegação ou tab bar"],
        r1=["+ na toolbar", "(iOS)"], r2=["botão de ação", "flutuante (Material)"],
        cap2="Onde vive cada tipo de ação. A ação principal fica em cantos opostos; as seções dividem a base; voltar é gesto numa plataforma e botão na outra.",
    ),
}


def figures(lang):
    t = T[lang]
    f = Fig("l18-two-screens", 720, 410, t["aria1"])
    for x, title in ((60, t["m"]), (430, t["h"])):
        f.text(x + 115, 20, title, bold=True, size=11, fill="phosphor")
        f.rect(x, 34, 230, 350, stroke="wire", fill="ink", rx=18)
    # Material
    f.box(72, 52, 206, 36, [t["appbar"]], size=10)
    f.box(72, 96, 206, 210, t["content"], size=10, stroke="scan")
    f.box(206, 262, 64, 34, [t["fab"]], size=10, stroke="amber", fill="amber")
    f.box(72, 316, 206, 50, t["navbar"], size=10, stroke="phosphor")
    # HIG
    f.box(442, 52, 206, 30, [t["toolbar"]], size=9.5, anchor="start", fill="paper-dim")
    f.box(606, 55, 36, 24, [t["plus"]], size=12, stroke="amber", fill="amber")
    f.box(442, 88, 206, 36, [t["large"]], size=11, bold=True, anchor="start")
    f.box(442, 132, 206, 174, t["content"], size=10, stroke="scan")
    f.box(442, 316, 206, 50, t["tabbar"], size=10, stroke="phosphor")
    f.arrow([(278, 200), (442, 220)], dashed=True, both=True)
    f.text(360, 196, t["same"], size=9, italic=True, fill="paper-dim")
    out = {"l18-two-screens": f.json(t["cap1"], same=None if lang == "en" else
                                     ["Material 3", "Human Interface Guidelines", "top app bar: This week", "+ FAB", "Week · Courses · Settings", "toolbar", "tab bar"])}

    g = Fig("l18-action-places", 720, 380, t["aria2"])
    g.rect(250, 20, 220, 340, stroke="wire", fill="ink", rx=18)
    g.box(262, 40, 30, 26, ["‹"], size=14, stroke="paper-dim", dashed=True)
    g.box(428, 40, 30, 26, ["+"], size=13, stroke="amber", fill="amber")
    g.box(258, 300, 204, 44, ["Week · Courses · Settings"], size=9.5, stroke="phosphor")
    g.box(404, 240, 54, 40, ["+"], size=14, stroke="amber", fill="amber")
    g.arrow([(252, 170), (300, 170)], dashed=True)
    # callouts, left
    for (lines, y, tx, ty) in ((t["l1"], 53, 262, 53), (t["l2"], 170, 252, 170), (t["l3"], 322, 258, 322)):
        g.text(230, y - 7, lines[0], anchor="end", size=10)
        g.text(230, y + 7, lines[1], anchor="end", size=10)
        g.arrow([(234, y), (tx - 2, ty)], head=False, color="wire")
    for (lines, y, tx, ty) in ((t["r1"], 53, 458, 53), (t["r2"], 260, 458, 260)):
        g.text(490, y - 7, lines[0], anchor="start", size=10)
        g.text(490, y + 7, lines[1], anchor="start", size=10)
        g.arrow([(486, y), (tx + 2, ty)], head=False, color="wire")
    out["l18-action-places"] = g.json(t["cap2"], same=None if lang == "en" else ["Week · Courses · Settings", "(iOS)"])
    return out


EXAMPLES = {
    "tokens": [
        {"language": "typescript", "file": "tokens.ts", "parts": [
            ('// tokens.ts: the planner\'s design decisions, written once\ntype Palette = { primary: string; onPrimary: string; surface: string; onSurface: string; muted: string };\n\nexport const brand = {\n  light: { primary: "#2F6F4E", onPrimary: "#FFFFFF", surface: "#FFFFFF", onSurface: "#1C1B1F", muted: "#8A8A8A" },\n  dark: { primary: "#8FD3AE", onPrimary: "#00391F", surface: "#1C1B1F", onSurface: "#E6E1E5", muted: "#938F99" },\n  space: { s: 8, m: 16, l: 24 }, // dp on Android, pt on iOS\n  text: { body: 16, title: 22 }, // the brand\'s sizes; iOS keeps its own text styles\n};\n',
             "The brand, and nothing else. Five colours by role, once for light and once for dark; three spacing steps; two text sizes. `muted` is the grey of the date under a session. No platform word appears here.",
             "A marca, e nada além dela. Cinco cores por papel, uma vez para o claro e outra para o escuro; três passos de espaçamento; dois tamanhos de texto. `muted` é o cinza da data embaixo de uma sessão. Nenhuma palavra de plataforma aparece aqui."),
            ('// Material 3: colour roles by name, sizes in dp and sp, Roboto, the action in a FAB.\nexport function materialTheme(mode: "light" | "dark") {\n  const c: Palette = brand[mode];\n  return {\n    colorScheme: { primary: c.primary, onPrimary: c.onPrimary, surface: c.surface, onSurface: c.onSurface, onSurfaceVariant: c.muted },\n    spacingDp: brand.space,\n    typography: { bodyLarge: `Roboto ${brand.text.body}sp`, titleLarge: `Roboto ${brand.text.title}sp` },\n    primaryAction: "floating action button",\n    sections: "navigation bar",\n  };\n}\n',
             "Material's theme takes the brand's values into Material's own names: the grey becomes `onSurfaceVariant`, the body size becomes `bodyLarge` in `sp`. The last two fields are not values at all: they are the conventions the previous section drew.",
             "O tema do Material leva os valores da marca para os nomes do próprio Material: o cinza vira `onSurfaceVariant`, o tamanho do corpo vira `bodyLarge` em `sp`. Os dois últimos campos nem são valores: são as convenções que a seção anterior desenhou."),
            ('// The HIG: the brand colour as the tint, sizes in pt, the system font through text styles.\nexport function iosTheme(mode: "light" | "dark") {\n  const c: Palette = brand[mode];\n  return {\n    tint: c.primary,\n    colors: { background: c.surface, label: c.onSurface, secondaryLabel: c.muted },\n    spacingPt: brand.space,\n    typography: { body: "system font, .body", title: "system font, .largeTitle" },\n    primaryAction: "toolbar button, top trailing",\n    sections: "tab bar",\n  };\n}',
             "The iOS theme takes the same colours under the HIG's names, `tint`, `label`, `secondaryLabel`, and does not pass the brand's text sizes on: it asks for text styles, so Dynamic Type keeps working. Same brand, other conventions.",
             "O tema iOS recebe as mesmas cores com os nomes das HIG, `tint`, `label`, `secondaryLabel`, e não repassa os tamanhos de texto da marca: ele pede estilos de texto, para o Dynamic Type continuar funcionando. Mesma marca, outras convenções."),
        ]},
    ],
}
