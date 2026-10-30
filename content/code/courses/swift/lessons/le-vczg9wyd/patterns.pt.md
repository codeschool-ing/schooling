---
title: Padrões, where e if case
version: 1
---

As linhas `case` de um switch são **padrões**: descrições de um formato com que um valor pode casar,
que podem ligar partes dele a nomes no caminho. A seção 04 usou três tipos, um caso com ligações, um
intervalo e o `default`. Há mais, e eles se combinam. Este programa classifica sessões pelos minutos e
por terem sido feitas ou não:

```schooling-example
{"language": "swift", "file": "Patterns.swift", "parts": [{"code": "// Patterns.swift\nenum Activity {\n    case reading(pages: Int)\n    case video(minutes: Int)\n}\nlet goal = 45", "note": "Um `Activity` menor que o da seção 03, e uma meta para uma sessão."}, {"code": "func describe(minutes: Int, done: Bool) -> String {\n    switch (minutes, done) {\n    case (_, false):\n        return \"not done yet\"\n    case (0..<15, true):\n        return \"a short one\"\n    case (15..<60, true):\n        return \"a solid session\"\n    default:\n        return \"a long one\"\n    }\n}", "note": "Um switch sobre uma tupla de dois valores. O `_` casa com qualquer coisa, um intervalo casa com um número dentro dele, e o primeiro caso que casa vence."}, {"code": "func verdict(_ minutes: Int) -> String {\n    switch minutes {\n    case let m where m >= goal:\n        return \"goal met by \\(m - goal)\"\n    case let m:\n        return \"\\(goal - m) short\"\n    }\n}", "note": "`case let m` liga o valor inteiro, e o `where` acrescenta uma condição que o padrão sozinho não expressa. O segundo caso casa com o que sobrar, então não precisa de `default`."}, {"code": "print(describe(minutes: 50, done: false), describe(minutes: 10, done: true), describe(minutes: 50, done: true), describe(minutes: 90, done: true))\nprint(verdict(60), verdict(30))", "note": "Quatro sessões pelo primeiro switch, duas pelo segundo."}, {"code": "let plan: [Activity] = [.reading(pages: 12), .video(minutes: 20), .video(minutes: 15)]\nif case .reading(let pages) = plan[0] {\n    print(\"starts with \\(pages) pages\")\n}\nvar videoMinutes = 0\nfor case .video(let minutes) in plan {\n    videoMinutes += minutes\n}\nprint(\"videos:\", videoMinutes)", "note": "`if case` testa um padrão; `for case` percorre só os elementos que casam com ele, ligando os nomes no caminho."}], "output": "not done yet a short one a solid session a long one\ngoal met by 15 15 short\nstarts with 12 pages\nvideos: 35"}
```

O primeiro switch casou uma **tupla**, dois valores entre parênteses, contra padrões de tupla, e é
assim que um switch decide sobre duas coisas ao mesmo tempo. **Os casos são tentados de cima para
baixo e o primeiro que casa vence**, então a ordem faz parte da lógica: `(_, false)` está primeiro, e
pega toda sessão não feita antes de qualquer intervalo ser consultado.

O `where` acrescenta uma condição a um padrão depois das ligações dele, e o segundo switch o usou para
comparar os minutos ligados com a meta, o que um intervalo escrito no padrão não conseguiria, já que a
meta é uma variável.

## Quando só um caso interessa

Um switch precisa cobrir tudo, e às vezes a pergunta é só "é este caso?". **O `if case` casa um
padrão e roda o corpo só se ele servir**, ligando nomes como um switch faria. O `for case` faz o mesmo
dentro de um laço e pula os elementos que não servem, que é como as últimas linhas somam só os vídeos.

A sintaxe parece invertida no começo: o padrão fica à esquerda e o valor à direita do `=`, como em
`if case .video(let minutes) = activity`. Leia como "se o caso `.video(let minutes)` casa com
`activity`".
