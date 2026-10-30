---
title: Traits, o que um elemento é e faz
version: 1
---

**Um trait diz ao VoiceOver que tipo de coisa é um elemento, e o VoiceOver diz o trait depois do
rótulo.** Um `Button` é lido como *Add session, botão*; um título como *This week, título*. A pessoa
aprende o que pode fazer com um elemento por essa palavra, e se move por ela: o rotor do VoiceOver
salta de título em título, que é como uma tela longa é percorrida de ouvido. Nada nesta seção foi
executado; ela foi escrita a partir da documentação da Apple para `AccessibilityTraits` e os
modificadores que os acrescentam e tiram, lida em 30 de outubro de 2026.

**Use o controle que já tem o trait antes de acrescentar um à mão.** O defeito mais comum é um `Text`
ou uma `Image` com `onTapGesture`: faz algo quando tocado e o VoiceOver não faz ideia, então é lido
como texto e ninguém sabe que dá para ativá-lo. Um `Button` traz o `.isButton`, aceita o toque duplo
do VoiceOver, funciona com teclado e com controle por botão, e se destaca quando pressionado.

```swift
// WeekHeader.swift
import SwiftUI

struct WeekHeader: View {
    let title: String
    var showAll: () -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Spacer()
            Button("Show all", action: showAll)
        }
    }
}
```

O `.font(.headline)` faz o texto parecer um título e não diz nada ao VoiceOver. **É o trait que o
torna um** para quem não vê o peso da fonte.

## Os traits que o planner usa

| trait | onde no planner | o que o VoiceOver acrescenta |
|---|---|---|
| `.isHeader` | o título da semana, o nome de cada curso na sua tela | *título*, e uma parada para o rotor |
| `.isButton` | todo `Button`, sem pedir | *botão* |
| `.isSelected` | o curso aberto numa lista que mostra a escolha | *selecionado* |
| `.updatesFrequently` | um cronômetro de uma sessão em andamento | lê o valor novo à medida que muda |

`.isSelected` é um estado, então liga e desliga com a seleção: `accessibilityAddTraits` quando o item
é escolhido e `accessibilityRemoveTraits` quando não é. Um trait que o elemento não tem é uma
promessa que ele não cumpre: uma linha marcada `.isButton` que não faz nada no toque duplo é pior que
nenhum trait, porque a pessoa tenta e nada acontece.

## Ações sem gesto

Arrastar uma linha para apagá-la é um gesto que quem usa o VoiceOver pode nunca descobrir. Os
`swipeActions` do SwiftUI numa linha de lista são oferecidos ao VoiceOver como **ações
personalizadas** automaticamente: a pessoa desliza um dedo para cima ou para baixo para ouvi-las. Uma
ação que só existe como um arrasto próprio ou um toque longo precisa ser dada do mesmo jeito, com
`.accessibilityAction(named:)`, para que toda pessoa chegue a toda ação por um caminho ou outro.
