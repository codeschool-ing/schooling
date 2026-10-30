---
title: Dynamic Type, o texto que a pessoa dimensiona
version: 1
---

**É a pessoa que escolhe o tamanho do texto, nos Ajustes, e um app que ignora a escolha fica ilegível
para quem a fez.** O iOS chama o recurso de **Dynamic Type**: uma faixa de tamanhos de texto do extra
pequeno até os cinco tamanhos de acessibilidade no topo, que são muito maiores que o padrão. Nada
nesta seção foi executado; ela segue a documentação da Apple para o `Font`, o `ScaledMetric` e o
`DynamicTypeSize` do SwiftUI, lida em 30 de outubro de 2026.

**Estilos de texto escalam; tamanhos em pontos não.** `.font(.body)`, `.font(.headline)` e os outros
estilos seguem o ajuste da pessoa sem código nenhum. `.font(.system(size: 15))` tem quinze pontos
qualquer que seja o ajuste, então quem pediu texto grande recebe texto pequeno naquele lugar.

```swift
// SessionSummary.swift
import SwiftUI

struct SessionSummary: View {
    let minutes: Int
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20

    var body: some View {
        Label {
            Text("\(minutes) minutes")
                .font(.body)
        } icon: {
            Image(systemName: "clock")
                .resizable()
                .frame(width: iconSize, height: iconSize)
        }
    }
}
```

O `@ScaledMetric` é para os números que não são texto mas deveriam crescer com ele: o tamanho de um
ícone, o espaço ao lado de uma linha. **Vinte pontos no tamanho padrão viram mais num tamanho
maior**, no passo do `.body`, para que o ícone não acabe como um ponto ao lado de uma linha grande.

## Layouts que sobrevivem aos maiores tamanhos

Nos tamanhos de acessibilidade, uma linha montada lado a lado fica sem largura: o título do curso e
os minutos não cabem mais numa linha, e algo é cortado com reticências. Duas respostas, as duas no
SwiftUI:

- ler o tamanho e mudar o layout, com `@Environment(\.dynamicTypeSize)` e
  `dynamicTypeSize.isAccessibilitySize`, empilhando a linha na vertical quando for verdadeiro;
- ou deixar o SwiftUI escolher com o `ViewThatFits`, que tenta primeiro o layout horizontal e cai no
  vertical quando o primeiro não cabe.

**Nunca responda limitando o tamanho.** `.dynamicTypeSize(...DynamicTypeSize.large)` limita uma view
a um tamanho, e existe para o raro controle que não pode crescer, uma barra de abas de altura fixa.
Usado em texto comum, ele desfaz a escolha da pessoa.

No Xcode, o botão *Variants* do canvas mostra uma preview em cada tamanho de uma vez, e o
Accessibility Inspector muda o tamanho de um simulador em execução; a aula 20 usa as previews desse
jeito.
