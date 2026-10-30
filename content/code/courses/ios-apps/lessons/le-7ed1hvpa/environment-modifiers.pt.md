---
title: Modificadores que descem pela árvore: o ambiente
version: 1
---

**Alguns modificadores não embrulham o layout de view nenhuma. Eles definem um valor que toda view
dentro deles lê.** Um `.font(.caption)` num `VStack` faz de todo texto dessa stack uma legenda, a não
ser que um texto defina a sua. A documentação da Apple para `font(_:)` o descreve com estas palavras: a
informação de fonte desce pela hierarquia de views como parte do ambiente, e continua valendo a não ser
que seja sobrescrita no nível de uma view ou de um contêiner.

```swift
VStack(alignment: .leading) {
    Text("Week of 19 October")
        .font(.headline)       // overrides the stack's font for this text only
    Text("120 of 180 minutes done")
    Text("3 sessions left")
}
.font(.subheadline)
.foregroundStyle(.secondary)
```

O título é um headline; os outros dois herdam da stack a fonte subheadline e a cor secundária. **O
ambiente é como o SwiftUI evita cem parâmetros**: a fonte, o esquema de cores, o locale, o tamanho de
texto que a pessoa escolheu, o `scenePhase` que a aula 2 leu, tudo desce pela árvore sem ser passado à
mão.

## O ambiente é um conjunto de valores, cada um com uma chave

A documentação da Apple para `EnvironmentValues` descreve o mecanismo: uma coleção de valores
propagada pela hierarquia, cada um lido com `@Environment` e um key path, uns definidos pelo sistema a
partir do aparelho e dos ajustes da pessoa, outros com um padrão que o SwiftUI fornece. Um modificador
como `.font(_:)` é um atalho para definir um deles, e `.environment(\.lineLimit, 2)` é a forma geral.

| definido por | exemplos |
|---|---|
| o sistema | `colorScheme`, `locale`, `dynamicTypeSize`, `scenePhase` |
| os seus modificadores | `font`, `lineLimit`, `isEnabled` via `.disabled(_:)` |
| chaves suas, aula 7 | o modelo do planner, posto no ambiente uma vez |

**Isso muda como a ordem se comporta.** Para um modificador que embrulha, a seção 03 disse que a ordem
é tudo. Para um modificador de ambiente, o que importa é quais views estão dentro dele: um `.font` na
stack alcança todo texto da stack, onde quer que esteja escrito na cadeia, e um `.font` mais perto de
um texto vence um mais distante.

A aula 7 usa o mesmo canal para dados: o modelo do planner entra no ambiente no topo da árvore e
qualquer tela o lê. A aula 19 lê dele o tamanho que a pessoa escolheu para o texto.

Nada nesta seção foi executado para o curso; ela foi escrita a partir da documentação da Apple para
`font(_:)`, `EnvironmentValues` e `environment(_:_:)`, lida em 30 de outubro de 2026.
