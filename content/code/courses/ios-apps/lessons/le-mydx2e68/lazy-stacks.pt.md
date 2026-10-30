---
title: VStack, LazyVStack e List
version: 1
---

**Um `VStack` constrói todas as filhas assim que aparece; um `LazyVStack` e um `List` constroem uma
linha só quando ela está para entrar na tela.** Para oito linhas a diferença é nenhuma. Para oito mil,
um `VStack` dentro de um `ScrollView` constrói oito mil linhas antes de a tela mostrar a primeira, e
guarda todas. Nada nesta seção foi executado; o comportamento é o que o artigo da Apple *Creating
performant scrollable stacks* descreve.

```swift
ScrollView {
    LazyVStack(alignment: .leading, spacing: 8) {
        ForEach(model.plan.sessions) { session in
            SessionCard(session: session)
        }
    }
    .padding()
}
```

**Os três não são intercambiáveis, e a escolha vai além da velocidade:**

| | constrói linhas | dá a você | use para |
|---|---|---|---|
| `VStack` | todas, de uma vez | layout exato, mais nada | um punhado de linhas que sempre cabem |
| `LazyVStack` num `ScrollView` | conforme se aproximam da tela | o seu próprio desenho de linha, sem separadores nem modo de edição | um feed longo de cartões próprios |
| `List` | conforme se aproximam da tela | ações de deslizar, seções, seleção, modo de edição, a cara da plataforma | a maioria das listas de um app, a do planner inclusive |

**O preguiçoso tem um custo que o `VStack` não tem**: a stack não sabe a altura das linhas que ainda
não construiu, então a barra de rolagem é uma estimativa, e pular para o fim significa construir as
linhas do caminho.

**O próprio conselho da Apple é começar pela stack simples.** O mesmo artigo diz que stacks
preguiçosas *trocam algum grau de correção do layout por desempenho*, e que só se deve trocar quando o
perfilamento mostrar uma melhora que valha a pena: o menu *Product* do Xcode, *Profile*, e o template
SwiftUI do Instruments, cujo instrumento View Body conta as views carregadas. Ele diz também para
nunca perfilar no simulador, só num aparelho de verdade. Nada disso foi executado para este curso.
