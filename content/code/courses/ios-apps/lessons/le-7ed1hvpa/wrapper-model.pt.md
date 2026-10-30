---
title: Os embrulhos, construídos em Swift puro
version: 1
---

**Toda afirmação desta aula sobre embrulho e ordem pode ser conferida sem SwiftUI, construindo os
embrulhos como tipos genéricos comuns.** É o que esta seção faz: um texto, um padding e um fundo, cada
um uma `Layer` com tamanho, e dois métodos que embrulham uma camada em outra exatamente como um
modificador faz. É um modelo, escrito para este curso; os tipos de verdade do SwiftUI são mais
numerosos e privados. A aritmética é a da seção 03.

Salve isto como `wrappers.swift` em `~/l05`:

```schooling-example
{"language": "swift", "file": "wrappers.swift", "parts": [{"code": "// wrappers.swift: modifiers as wrapper types, each one a layer with a size\nstruct Size: CustomStringConvertible {\n    var width: Double, height: Double\n    var description: String { \"\\(Int(width)) by \\(Int(height))\" }\n}\n\nprotocol Layer {\n    var label: String { get }\n    func size(offered: Size) -> Size\n    func inner() -> (any Layer)?\n}\n", "note": "Uma camada sabe dizer o que é, que tamanho escolhe para uma oferta, e o que está dentro dela, se houver algo."}, {"code": "/// Stands for Text: 8 points a character, 20 high.\nstruct Words: Layer {\n    let text: String\n    var label: String { \"Words(\\\"\\(text)\\\")\" }\n    func size(offered: Size) -> Size { Size(width: Double(text.count) * 8, height: 20) }\n    func inner() -> (any Layer)? { nil }\n}\n", "note": "A camada mais de dentro, no papel de um `Text`. Oito pontos por caractere é o número do modelo, não de uma fonte."}, {"code": "/// Stands for .padding(n): offers less inward, reports more outward.\nstruct Padded<Content: Layer>: Layer {\n    let content: Content, amount: Double\n    var label: String { \"padding \\(Int(amount))\" }\n    func size(offered: Size) -> Size {\n        let inside = content.size(offered: Size(width: offered.width - 2 * amount,\n                                                height: offered.height - 2 * amount))\n        return Size(width: inside.width + 2 * amount, height: inside.height + 2 * amount)\n    }\n    func inner() -> (any Layer)? { content }\n}\n", "note": "O padding, como a aula 4 seção 06 o descreveu: ele propõe ao que embrulha a oferta menos o padding, e informa esse tamanho mais o padding."}, {"code": "/// Stands for .background(colour): exactly the size of what it wraps.\nstruct Filled<Content: Layer>: Layer {\n    let content: Content, colour: String\n    var label: String { \"background \\(colour)\" }\n    func size(offered: Size) -> Size { content.size(offered: offered) }\n    func inner() -> (any Layer)? { content }\n}\n", "note": "Um fundo fica com o tamanho do que embrulha, nem mais nem menos. Essa linha é o motivo de a ordem importar."}, {"code": "extension Layer {\n    func padding(_ amount: Double = 16) -> Padded<Self> { Padded(content: self, amount: amount) }\n    func background(_ colour: String) -> Filled<Self> { Filled(content: self, colour: colour) }\n}\n", "note": "A sintaxe de modificador: um método que devolve um valor novo embrulhando o `self`, com um tipo montado a partir de `Self`."}, {"code": "/// Print each layer from the outside in, with the size it reports.\nfunc show(_ view: some Layer) {\n    print(type(of: view))\n    var layer: (any Layer)? = view\n    var depth = 1\n    while let l = layer {\n        let indent = String(repeating: \"  \", count: depth)\n        print(indent + l.label + \": \" + l.size(offered: Size(width: 390, height: 800)).description)\n        layer = l.inner()\n        depth += 1\n    }\n}\n\nshow(Words(text: \"50 min\").padding().background(\"yellow\"))\nshow(Words(text: \"50 min\").background(\"yellow\").padding())\n", "note": "As duas cadeias da seção 03, com uma oferta de 390 por 800, cada uma impressa como o seu tipo e depois camada por camada."}]}
```

```
ana@vm:~/l05$ swift wrappers.swift
Filled<Padded<Words>>
  background yellow: 80 by 52
    padding 16: 80 by 52
      Words("50 min"): 48 by 20
Padded<Filled<Words>>
  padding 16: 80 by 52
    background yellow: 48 by 20
      Words("50 min"): 48 by 20
```

**Os tipos são as cadeias, lidas de trás para a frente.** `Filled<Padded<Words>>` é "um fundo em volta
de um padding em volta de um texto", que é a primeira cadeia, `.padding().background(…)`. O primeiro
modificador escrito é o tipo mais de dentro.

**E os tamanhos são a imagem da seção 03 em números.** Na primeira cadeia a camada amarela informa 80
por 52: os 48 por 20 do texto mais 16 de cada lado. Na segunda a camada amarela informa 48 por 20, o
tamanho do próprio texto, e o padding de fora leva o total a 80 por 52 sem nada pintado no espaço
extra. Mesmo tamanho por fora, amarelo diferente.
