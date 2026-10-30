---
title: A aritmética da stack, como um modelo que dá para rodar
version: 1
---

**Um `HStack` reparte a largura perguntando a cada filho o quanto ele é flexível e servindo primeiro o
menos flexível.** A documentação da Apple para o `ProposedViewSize` descreve a metade da medição: um
contêiner propõe tamanhos especiais a um filho, zero para o mínimo, infinito para o máximo e nada para
o ideal, e um `HStack` pode usar as respostas para medir o quanto a largura de cada filho é flexível.
A ordem que se segue, o menos flexível primeiro, é a que a sessão *Building Custom Views with SwiftUI*
da WWDC19 da Apple descreve para as stacks.

Esta seção transforma isso em umas cinquenta linhas de Swift puro. **É um modelo, escrito para este
curso, e não é o SwiftUI**: ele deixa de fora a prioridade de layout, o comprimento mínimo de um
spacer, as alturas, e tudo o mais que uma stack de verdade pesa. O que ele mantém é a aritmética dos
três passos da seção 02, que é a parte que as pessoas erram. Salve-o como `layout.swift` em `~/l04`:

```schooling-example
{"language": "swift", "file": "layout.swift", "parts": [{"code": "// layout.swift: a model of how a horizontal stack shares out its width\nimport Foundation\n\n/// What a parent offers: a width, or nil for \"whatever you would like\".\nstruct Proposal { var width: Double? }\n\nprotocol Child {\n    var name: String { get }\n    func width(for proposal: Proposal) -> Double\n}\n", "note": "O passo um e o passo dois da seção 02, como tipos. Uma `Proposal` é a oferta do pai, e todo filho responde a ela com a largura que escolhe. Só a largura, para manter a aritmética legível."}, {"code": "/// Stands for Text: its ideal width, or less when offered less.\nstruct Label: Child {\n    let name: String\n    let ideal: Double\n    func width(for p: Proposal) -> Double { min(ideal, p.width ?? ideal) }\n}\n\n/// Stands for Spacer(minLength: 0): all the width it is offered.\nstruct Gap: Child {\n    let name = \"Spacer\"\n    func width(for p: Proposal) -> Double { p.width ?? 0 }\n}\n\n/// Stands for .frame(width:): its own width, whatever it is offered.\nstruct Fixed: Child {\n    let name: String\n    let fixed: Double\n    func width(for p: Proposal) -> Double { fixed }\n}\n", "note": "Três tipos de filho. Um rótulo fica com a largura ideal ou menos, nunca mais; um intervalo fica com tudo; um frame fixo ignora a oferta. As larguras ideais dadas aos rótulos abaixo são números escolhidos para o modelo: um texto de verdade é medido na sua fonte."}, {"code": "/// How much a child's width moves between being offered nothing and everything.\nfunc flexibility(_ c: Child) -> Double {\n    c.width(for: Proposal(width: .infinity)) - c.width(for: Proposal(width: 0))\n}\n", "note": "As duas propostas especiais da documentação da Apple, infinito e zero, e a diferença entre as respostas. Um frame fixo marca 0, um rótulo a sua largura ideal, um intervalo infinito."}, {"code": "func hstack(_ children: [Child], width: Double, spacing: Double = 8) {\n    print(\"offered \\(Int(width)):\")\n    var remaining = width - spacing * Double(children.count - 1)\n    var widths = [Double](repeating: 0, count: children.count)\n    let leastFlexibleFirst = children.indices.sorted { flexibility(children[$0]) < flexibility(children[$1]) }\n    for (served, i) in leastFlexibleFirst.enumerated() {\n        let share = remaining / Double(children.count - served)\n        widths[i] = children[i].width(for: Proposal(width: share))\n        remaining -= widths[i]\n    }\n", "note": "A stack tira o espaçamento primeiro, depois serve os filhos do menos flexível ao mais. A cada um é oferecida uma parte igual do que sobra; ele escolhe, e o que não pegou volta para o montante dos que ainda esperam."}, {"code": "    var x = 0.0\n    for (child, w) in zip(children, widths) {\n        print(\"  \" + child.name.padding(toLength: 20, withPad: \" \", startingAt: 0)\n              + String(format: \"x %5.1f  width %5.1f\", x, w))\n        x += w + spacing\n    }\n}\n", "note": "O passo três: posicionar. Os filhos vão da esquerda para a direita na ordem em que foram escritos, que não é a ordem em que foram servidos."}, {"code": "let row: [Child] = [Label(name: \"SQL Databases\", ideal: 104), Gap(), Label(name: \"50 min\", ideal: 48)]\nhstack(row, width: 360)\nhstack([Fixed(name: \"icon\", fixed: 24), Label(name: \"Mobile Fundamentals\", ideal: 150),\n        Label(name: \"40 min\", ideal: 48)], width: 180)\n", "note": "Duas linhas da lista de cursos do planner: uma com espaço de sobra, e uma estreita demais para o título."}]}
```

```
ana@vm:~/l04$ swift layout.swift
offered 360:
  SQL Databases       x   0.0  width 104.0
  Spacer              x 112.0  width 192.0
  50 min              x 312.0  width  48.0
offered 180:
  icon                x   0.0  width  24.0
  Mobile Fundamentals x  32.0  width  92.0
  40 min              x 132.0  width  48.0
```

**Na primeira linha o spacer fica com o que os rótulos não quiseram**, 192 pontos, porque foi servido
por último. É assim que um `Spacer` empurra o `50 min` para a borda direita sem ninguém calcular onde
a borda fica.

**Na segunda linha é o título que cede.** O ícone foi servido primeiro e pegou os seus 24; o `40 min`
veio em seguida, recebeu a oferta de 70 e pegou os seus 48; o título veio por último e ficou com os 92
que sobraram, contra um ideal de 150. No SwiftUI um `Text` que recebe menos do que quer corta ou
quebra, e a aula 5 decide entre os dois. Repare que o rótulo escrito no meio foi servido por último:
**a ordem de serviço é a flexibilidade, não a posição.**

O que o modelo não consegue dizer é exatamente como o SwiftUI desenharia essas linhas num telefone. Os
números são do modelo, e um Mac rodando essas views num preview mediria o texto e poderia dar outra
coisa. A regra que os números ilustram, o menos flexível primeiro e o que sobra para o resto, é a que
você leva para a aula 5, onde modificadores embrulham views em novos participantes do layout.
