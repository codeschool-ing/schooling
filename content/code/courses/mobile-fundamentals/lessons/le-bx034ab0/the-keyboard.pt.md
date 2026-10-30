---
title: O teclado, o maior inset de todos
version: 1
---

**Quando um campo de texto ganha foco, o teclado virtual sobe por cima da parte de baixo da janela,
e o que estava ali fica coberto a menos que o layout o mova.** Nenhum outro inset é tão grande nem
muda tão de repente: a barra de status é uma faixa, a alça de gestos é um filete, e no exemplo desta
aula o teclado ocupa 300 das 844 unidades de uma tela em retrato. O Android o chama de IME, o editor
de método de entrada, e o informa como o inset `ime`; o SwiftUI o trata como uma região de área
segura própria, `.keyboard`, que a documentação da Apple descreve como a área que corresponde à
extensão atual de qualquer teclado virtual sobre a view.

A crença comum é que o sistema traz o campo à vista sozinho. Às vezes ele traz, em parte. **O
campo em que o usuário está digitando é a metade fácil; o botão abaixo dele é a metade que se
perde.** O formulário de nova sessão do planner tem um campo de título e, embaixo dele, o botão de
adicionar sessão. Com o teclado aberto, o campo pode ser rolado até a vista e o botão, de que o
aluno precisa em seguida, fica atrás das teclas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l09-keyboard\" aria-label=\"Dois diagramas do formulário de nova sessão do planner com o teclado aberto. À esquerda o formulário fica no lugar: o campo de título aparece, mas o botão Adicionar sessão fica embaixo do teclado. À direita a área de conteúdo termina no topo do teclado, então o formulário fica acima dele e o botão aparece.\"><text x=\"170\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">o layout ignora o teclado</text><text x=\"550\" y=\"16\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">o teclado é tratado como inset</text><rect x=\"80\" y=\"30\" width=\"180\" height=\"290\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><rect x=\"86\" y=\"210\" width=\"168\" height=\"104\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">teclado</text><rect x=\"96\" y=\"172\" width=\"148\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"106\" y=\"187.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Título</text><rect x=\"120\" y=\"228\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"170\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">coberto</text><rect x=\"460\" y=\"30\" width=\"180\" height=\"290\" rx=\"22\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.6\"></rect><rect x=\"466\" y=\"210\" width=\"168\" height=\"104\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"550\" y=\"298\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">teclado</text><rect x=\"476\" y=\"120\" width=\"148\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"486\" y=\"135.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">Título</text><rect x=\"500\" y=\"166\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"550.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">Adicionar sessão</text></svg>", "caption": "O campo muitas vezes é trazido à vista; o botão embaixo dele é o que se perde. Tratar o teclado como mais um inset inferior leva a borda de baixo do formulário ao topo das teclas."}
```

## Duas correções, e elas são a mesma ideia

| correção | o que acontece | quando serve |
|---|---|---|
| encolher a área de conteúdo da janela | o layout é refeito no espaço acima do teclado, então um botão na parte de baixo sobe junto | um formulário curto cujo último controle deve ficar logo acima das teclas |
| rolar | o conteúdo mantém a altura e passa a rolar, e o campo com foco, ou o próximo controle, é rolado até a vista | um formulário longo que não cabe acima do teclado de jeito nenhum |

**As duas tratam o teclado como mais um inset embaixo**, maior que a barra de gestos enquanto está
aberto e sumido quando fecha. A borda de baixo do formulário passa a ser o topo do teclado, ou a
borda de baixo da área segura quando não há teclado, a que estiver mais alta. A última seção desta
aula calcula exatamente isso.

## Em três grafias

Os trechos abaixo mantêm o formulário do planner e o botão acima do teclado. Eles foram adaptados
da documentação de cada plataforma, e **não foram compilados nem rodados para este curso**.

```kotlin
// Compose: pad the form by the keyboard's inset, and let it scroll
Column(
    Modifier.fillMaxSize()
        .imePadding()
        .verticalScroll(rememberScrollState())
) {
    OutlinedTextField(value = title, onValueChange = { title = it })
    Button(onClick = save) { Text("Add session") }
}
```

```swift
// SwiftUI: the keyboard is a safe area region, avoided by default
ScrollView {
    VStack {
        TextField("Title", text: $title)
        Button("Add session", action: save)
    }
}
// .ignoresSafeArea(.keyboard) would let the keyboard cover it again
```

```tsx
// React Native: a container that resizes or pads itself for the keyboard
<KeyboardAvoidingView behavior={Platform.OS === "ios" ? "padding" : "height"} style={{ flex: 1 }}>
  <ScrollView keyboardShouldPersistTaps="handled">
    <TextInput value={title} onChangeText={setTitle} />
    <Pressable onPress={save}><Text>Add session</Text></Pressable>
  </ScrollView>
</KeyboardAvoidingView>
```

**Os padrões diferem de novo, na mesma direção da área segura.** O SwiftUI evita o teclado a menos
que mandem não evitar. O Compose acrescenta o espaço dele quando pedido, com `imePadding()`. A
documentação do React Native para o `KeyboardAvoidingView` diz que ele ajusta a altura, a posição
ou o padding de baixo à altura do teclado. Diz também que as duas plataformas reagem de jeitos diferentes à opção
`behavior` e que defini-la é recomendado nas duas, e é por isso que o próprio exemplo dela
escolhe `padding` no iOS e `height` no Android.

## O que testar

A aula 8 pediu que cada layout fosse olhado em várias janelas. **O teclado acrescenta mais um estado
a cada uma delas**, e é o que mais fica sem teste, porque quem desenvolve numa mesa e digita num
teclado de verdade pode nunca ver o da tela. Num celular, em retrato e em paisagem, com o teclado
aberto: o campo aparece, o próximo controle é alcançável, e a tela volta a ser como era quando o
teclado fecha?
