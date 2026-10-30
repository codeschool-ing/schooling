---
title: O que uma lista redesenha, contado
version: 1
---

**Quando a coleção de uma lista muda, o SwiftUI descobre o que mudou comparando ids, e o trabalho que
vem depois depende de quantas linhas ele decide que mudaram.** Uma identidade que segue os dados
transforma uma inserção numa inserção. Uma identidade que segue a posição a transforma numa mudança
de toda linha abaixo dela. Essa conta dá para mostrar sem o SwiftUI. Salve isto como `diff.swift` em
`~/rows`:

```schooling-example
{"language": "swift", "file": "diff.swift", "parts": [{"code": "// diff.swift: what changed, asked by id and by position\nlet before = [\"SQL, joins\", \"Mobile, lifecycle\", \"SQL, indexes\", \"SQL, views\"]\nlet after = [\"Mobile, offline\"] + before          // one session added at the top\n", "note": "Quatro linhas, depois as mesmas quatro com uma acrescentada acima delas, a mudança mais comum que uma lista vê: um item novo no topo."}, {"code": "let byID = after.difference(from: before)\nprint(\"by id: \\(byID.count) change(s)\")\nfor change in byID {\n    if case let .insert(offset, element, _) = change {\n        print(\"  insert \\\"\\(element)\\\" at \\(offset)\")\n    }\n}\n", "note": "O `difference(from:)` é da biblioteca padrão, e compara elementos por igualdade, que aqui é o mesmo que pelo id: as strings são as identidades. É a pergunta que o SwiftUI faz a um `ForEach`."}, {"code": "var byPosition: [String] = []\nfor position in 0..<max(before.count, after.count) {\n    let old = position < before.count ? before[position] : nil\n    let new = position < after.count ? after[position] : nil\n    if old != new {\n        byPosition.append(\"  row \\(position): \\(old ?? \"nothing\") -> \\(new ?? \"nothing\")\")\n    }\n}\nprint(\"by position: \\(byPosition.count) change(s)\")\nbyPosition.forEach { print($0) }\n", "note": "A mesma pergunta feita por posição: a linha 0 era isto e agora é aquilo. É isso que uma lista indexada pela posição tem de concluir."}]}
```

```
ana@vm:~/rows$ swift diff.swift
by id: 1 change(s)
  insert "Mobile, offline" at 0
by position: 5 change(s)
  row 0: SQL, joins -> Mobile, offline
  row 1: Mobile, lifecycle -> SQL, joins
  row 2: SQL, indexes -> Mobile, lifecycle
  row 3: SQL, views -> SQL, indexes
  row 4: nothing -> SQL, views
```

**Uma mudança pelo id, cinco pela posição, para a mesma edição.** Pelo id, uma linha foi inserida no 0
e as outras quatro são as linhas que eram, então o SwiftUI pode deslizá-las para baixo sem redesenhar
nada nelas. Pela posição, o conteúdo de toda linha mudou, e a última linha é nova: cada uma das cinco
é reconstruída, e nenhuma anima, porque para a identidade nada se mexeu.

O resto da velocidade de uma lista está nas próprias linhas, e quatro hábitos cobrem quase tudo. A
sessão da WWDC da Apple *Demystify SwiftUI performance*, de 2023, é onde eles são discutidos a fundo;
nenhum foi medido para este curso.

- **Mantenha o `body` barato.** Nada de ordenar, filtrar ou formatar datas do plano inteiro dentro do
  `body` de uma linha; faça isso uma vez, acima da lista, ou no modelo.
- **Passe a uma linha o que ela desenha.** Uma linha que recebe um `StudySession` redesenha quando essa
  sessão muda. Uma linha que recebe o modelo inteiro e lê `model.plan` redesenha quando qualquer coisa
  no plano muda, como a aula 7 seção 03 mediu.
- **Mantenha os ids estáveis entre carregamentos.** Um id feito de novo a cada chegada de dados, um
  `UUID()` num decodificador, faz toda linha ser nova a cada atualização. Os ids da aula 12 vêm do
  servidor por esse motivo.
- **Meça antes de mudar qualquer coisa,** num aparelho. O template SwiftUI do Instruments, da seção 07,
  conta quantas vezes o `body` de cada view roda; uma lista lenta é achada ali, e não no palpite.
