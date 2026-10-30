---
title: Contraste, medido em vez de julgado
version: 1
---

**Se um texto pode ser lido contra o fundo é aritmética, e é a única pergunta de acessibilidade que
você responde em qualquer computador.** As Web Content Accessibility Guidelines definem uma razão de
contraste entre duas cores, de 1:1 para a mesma cor duas vezes até 21:1 para preto no branco. A
WCAG 2.2 no nível AA pede **4,5:1 para texto comum** e **3:1 para texto grande** e para as partes de
um controle que a pessoa precisa ver. As Human Interface Guidelines da Apple, lidas em 30 de outubro
de 2026, apontam os mesmos limites. Esta plataforma segura as suas próprias telas no AA, e um app
feito neste curso deveria cumprir a mesma régua.

A crença a largar é que uma cor que parece boa na sua tela é boa. A sua tela é clara, os olhos são
seus, e você sabe o que o texto diz. A razão não sabe nada disso.

## A fórmula

A **luminância relativa** de cada cor é calculada a partir dos canais vermelho, verde e azul: cada
canal vai para a escala de 0 a 1, sai da curva do sRGB e recebe um peso, o verde mais que todos
porque o olho é mais sensível a ele. A razão é `(mais clara + 0,05) / (mais escura + 0,05)`. Salve
isto como `contrast.swift` em `~/contrast`:

```schooling-example
{"language": "swift", "file": "contrast.swift", "parts": [{"code": "// contrast.swift: WCAG contrast ratios for the planner's colours\nimport Foundation\n\nfunc luminance(_ hex: String) -> Double {\n    let v = Int(hex.dropFirst(), radix: 16)!\n    let channels = [(v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF].map { Double($0) / 255 }\n    let linear = channels.map { c in c <= 0.04045 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }\n    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]\n}\n", "note": "A luminância relativa da WCAG. O `pow` desfaz a curva do sRGB, que guarda os tons escuros com mais precisão que os claros; os três pesos são o quanto vermelho, verde e azul contribuem para o brilho aparente de uma cor."}, {"code": "func ratio(_ a: String, _ b: String) -> Double {\n    let (x, y) = (luminance(a), luminance(b))\n    return (max(x, y) + 0.05) / (min(x, y) + 0.05)\n}\n", "note": "A ordem das duas cores não importa: a mais clara fica sempre em cima. O `0.05` representa a luz que uma tela real reflete, e é por isso que preto no branco dá 21 e não infinito."}, {"code": "let pairs = [\n    (\"title on white\", \"#1C1C1E\", \"#FFFFFF\"),\n    (\"minutes, grey on white\", \"#6E6E73\", \"#FFFFFF\"),\n    (\"placeholder, light grey\", \"#AEAEB2\", \"#FFFFFF\"),\n    (\"done tick, green on white\", \"#34C759\", \"#FFFFFF\"),\n    (\"done tick, darker green\", \"#248A3D\", \"#FFFFFF\"),\n    (\"minutes, grey on dark\", \"#98989D\", \"#1C1C1E\"),\n]\nfor (name, fg, bg) in pairs {\n    let r = ratio(fg, bg)\n    let verdict = r >= 4.5 ? \"text ok\" : r >= 3 ? \"large text and icons only\" : \"fails\"\n    print(name.padding(toLength: 27, withPad: \" \", startingAt: 0), String(format: \"%5.2f:1\", r), verdict)\n}\n", "note": "As cores do planner, claras e escuras. Cada veredito é o do AA: 4,5 para texto, 3 para texto grande e para as partes visíveis de um controle, como o visto que diz que uma sessão foi feita."}]}
```

```
ana@vm:~/contrast$ swift contrast.swift
title on white              17.01:1 text ok
minutes, grey on white       5.07:1 text ok
placeholder, light grey      2.21:1 fails
done tick, green on white    2.22:1 fails
done tick, darker green      4.40:1 large text and icons only
minutes, grey on dark        5.93:1 text ok
```

**Duas das seis falham, e as duas pareciam boas na tela em que foram escolhidas.** O cinza claro de um
placeholder num campo de texto é comum, e importa mais do que parece, porque às vezes um placeholder é
a única pista que um campo tem. O verde vivo do visto falha até como ícone, com 2,22:1. O verde mais
escuro chega a 4,40:1, o que basta para um visto e não para texto, então a palavra *done* ao lado dele
é desenhada no cinza que passou. E o cinza que funciona no branco é outro cinza no tema escuro: o par
de cada tema é medido por conta própria.

## No app

Dois recursos do sistema mudam esses números sem ajuda do app, e um app tem de continuar funcionando
com os dois. O **Aumentar Contraste**, nos ajustes de acessibilidade, deixa as cores do próprio iOS
mais escuras ou mais claras, e o SwiftUI o entrega a uma view como
`@Environment(\.colorSchemeContrast)`. O **Modo Escuro** troca a paleta inteira. Cores de um catálogo
de assets podem ter uma variante para cada um, e cores do sistema como `Color.secondary` já se
adaptam. Uma cor digitada no código como números, como as seis de cima, não se adapta a nada, e por
isso medir cada uma em cada tema é o trabalho.
