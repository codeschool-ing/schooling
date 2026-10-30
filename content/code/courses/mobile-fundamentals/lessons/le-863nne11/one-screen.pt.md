---
title: Uma tela pequena, três vezes
version: 1
---

**O mesmo pedaço do planner, escrito em cada um dos três caminhos da trilha, mostra como eles são
próximos na forma e distantes em todo o resto.** O pedaço é uma linha e um botão: o total da semana,
"120 of 180 minutes done", e um botão "Mark done" embaixo. Estes três fragmentos foram adaptados do
estilo da documentação de cada kit, e **não foram compilados nem rodados para este curso**: não há
SDK do Android, nem Xcode, nem celular na máquina em que as aulas foram gravadas. Leia-os para
reconhecer uma ideia em três grafias.

Jetpack Compose, em Kotlin:

```kotlin
@Composable
fun WeekLine(total: WeekTotal, onMarkDone: () -> Unit) {
    Column {
        Text("${total.done} of ${total.planned} minutes done")
        Button(onClick = onMarkDone) { Text("Mark done") }
    }
}
```

SwiftUI, em Swift:

```swift
struct WeekLine: View {
    let total: WeekTotal
    let onMarkDone: () -> Void

    var body: some View {
        VStack {
            Text("\(total.done) of \(total.planned) minutes done")
            Button("Mark done", action: onMarkDone)
        }
    }
}
```

React Native, em TypeScript:

```tsx
function WeekLine({ total, onMarkDone }: Props) {
  return (
    <View>
      <Text>{total.done} of {total.planned} minutes done</Text>
      <Button title="Mark done" onPress={onMarkDone} />
    </View>
  );
}
```

## O que é igual

**Os três são uma função dos dados.** Cada um recebe um `total` e algo para chamar quando o botão é
pressionado, e descreve como a tela deve ficar para aquele total. Nenhum deles muda o texto à mão
quando o número muda: o kit desenha a linha de novo a partir do total novo. Essa forma, a tela como
função do estado, é compartilhada por Compose, SwiftUI e React, e é por isso que quem aprende um
consegue ler os outros dois sem começar do zero.

**Os três empilham um texto sobre um botão**, com `Column`, `VStack` e `View`. A aula 8 trata de como
essas pilhas se esticam quando a tela muda de tamanho.

## O que não é

**A linguagem, e com ela tudo em que a tela se apoia.** `WeekTotal` no fragmento Kotlin é uma classe
Kotlin e no fragmento Swift uma struct Swift, e cada um precisa ser calculado por um `weekTotal`
escrito naquela linguagem. O fragmento React Native é o único que consegue importar o `weekTotal` de
`planner.ts` da aula 1 como ele está, porque é o único que roda JavaScript. Uma equipe de Kotlin
Multiplatform escreveria `weekTotal` uma vez em Kotlin e entregaria o resultado tanto ao fragmento
Compose quanto ao SwiftUI. Uma versão Flutter seria um widget Dart com a mesma forma, e a aula 22 de
`react-native` mostra como fica um.

**E o que o botão é quando chega à tela.** O botão do Compose é um botão Material, o do SwiftUI um
botão iOS, e o `Button` do React Native vira qualquer um dos dois, conforme o celular em que roda. A
aula 18 põe os dois guias de design lado a lado.
