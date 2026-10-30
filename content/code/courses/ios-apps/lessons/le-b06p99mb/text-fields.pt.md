---
title: Um campo de texto guarda texto
version: 1
---

**Um `TextField` ligado a uma `String` guarda exatamente o que está na tela, e é por isso que o planner
usa um para os minutos.** O SwiftUI oferece um segundo tipo, um campo ligado a um número por meio de um
estilo de formato, e ele parece a escolha óbvia para um número de minutos. Esta seção trata de por que
ele não é o certo aqui. Nada nela foi executado: o comportamento citado é o da documentação da Apple para
o `TextField`, lida em 30 de outubro de 2026.

## Duas formas de ligar um campo

```swift
// Minutes, two ways
@State private var minutesText = ""   // what the person typed
@State private var minutes = 30       // a number

TextField("Minutes", text: $minutesText)
TextField("Minutes", value: $minutes, format: .number)
```

O primeiro é um campo sobre uma string: cada tecla muda `minutesText`, e a string é o que o campo
mostra. O segundo converte entre o texto e um `Int` com um estilo de formato. A documentação da Apple
para `init(_:value:format:prompt:)` diz o que acontece quando a conversão falha:

> Se o `format` não consegue fazer a conversão, o campo de texto deixa `binding.value` sem mudança. Se o
> usuário para de editar o texto num estado inválido, o campo de texto troca o texto do campo pelo
> último valor válido conhecido.

**Então um campo ligado a um número pode mostrar uma coisa enquanto o modelo guarda outra.** Alguém troca
`30` por `forty` e toca em Add: o campo ainda diz `forty`, o binding ainda diz `30`, e entra uma sessão
de trinta minutos que ninguém digitou. Quando a pessoa sai do campo, ele volta em silêncio para `30`.
Nada foi recusado e nada disse por quê.

Isso é aceitável para um valor com um padrão razoável, como o tamanho de fonte numa tela de ajustes.
Para uma sessão que alguém está adicionando, o planner quer o contrário: **guardar o que foi digitado, e
dizer com clareza por que ainda não é uma sessão.** Esse é o rascunho da seção 04, cujo `minutesText` é
o primeiro binding acima.

## O que ainda dá para dizer ao campo

Ligar a texto não quer dizer aceitar qualquer teclado. Estes modificadores mudam como se digita num
campo sem mudar o que ele guarda, e cada um é um modificador da documentação da Apple para `View`:

| modificador | o que ele faz pelo campo de minutos |
|---|---|
| `.keyboardType(.numberPad)` | mostra um teclado de dígitos em vez do teclado completo; a seção 07 lida com a tecla de retorno que falta |
| `.autocorrectionDisabled()` | impede a correção automática de propor uma palavra num campo que quer dígitos |
| `.textInputAutocapitalization(.never)` | nada de maiúscula no começo, o que importa num campo de códigos ou nomes, não neste |
| `.submitLabel(.done)` | qual palavra a tecla de retorno mostra, nos teclados que têm uma |

**Um teclado numérico é uma conveniência, não uma conferência.** Um teclado físico ligado a um iPad
digita letras num campo `.numberPad`, e colar também. O `minutesNotWhole` do rascunho é o que as recusa,
e é por isso que ele existe mesmo com o teclado sem nenhuma letra.

## O placeholder e o rótulo

`TextField("Minutes", text:)` usa a string duas vezes: como o placeholder mostrado enquanto o campo está
vazio, e como o rótulo que o VoiceOver lê. Num `Form` no iOS esse placeholder é o único rótulo visível
do campo, e ele some assim que alguém digita. Para um campo cujo sentido deve continuar à vista, o
`LabeledContent` põe ao lado um rótulo que não vai embora:

```swift
// A label that stays
LabeledContent("Minutes") {
    TextField("30", text: $draft.minutesText)
        .keyboardType(.numberPad)
        .multilineTextAlignment(.trailing)
}
```

Agora `Minutes` fica à esquerda e `30` é só um exemplo, que some quando um número de verdade é digitado.
