---
title: De ponta a ponta, e quem aplica os insets
version: 1
---

**No iOS o kit de interface mantém o conteúdo na área segura a menos que o app diga o contrário;
num Android recente o app desenha de ponta a ponta e é ele o responsável pelos insets.** Essa única
diferença explica a maioria dos defeitos de inset que aparecem numa plataforma e não na outra.

## Android: de ponta a ponta agora é a regra

A documentação do Android sobre insets diz a mudança com clareza. No Android 14, API level 34, e
anteriores, a interface de um app não é desenhada embaixo das barras do sistema e do recorte da
tela por padrão. **No Android 15, API level 35, e posteriores, um app que mira o SDK 35 é desenhado
embaixo delas**, e a documentação marca isso como obrigatório: um app que não era de ponta a ponta
antes pode ter partes da tela escondidas até tratar os insets. As mudanças de comportamento do
Android 16, lidas em 30 de outubro de 2026, fecham a saída: um app que mira o API level 36 não pode
mais recusar o modo de ponta a ponta quando roda no Android 16.

Então um app Android feito hoje trata os insets, e **o Compose dá as ferramentas**: modificadores
como `safeDrawingPadding()` e `imePadding()`, que acrescentam a um layout o espaço de um inset, e o
`Scaffold` do Material 3, que a documentação diz poder reduzir o trabalho. O segundo erro da seção
anterior mora aqui: acrescentar na mão o espaço que um componente já acrescentou.

## iOS: a área segura por padrão, e sair dela de propósito

O SwiftUI começa pela outra ponta. **A documentação da Apple para `ignoresSafeArea` diz que, por
padrão, o sistema de layout dimensiona e posiciona as views para evitar certas áreas seguras**, para
que conteúdo do sistema como o teclado virtual ou as bordas do aparelho não as cubra. O app não faz
nada para ficar seguro; ele escreve `ignoresSafeArea` quando uma view, normalmente um fundo, deve
se estender para essas regiões. O `safeAreaInset` vai no sentido contrário, e acrescenta uma view
do próprio app, como uma barra de botões, na borda da área segura, para que o resto do conteúdo se
afaste dela como se afasta das do sistema.

## React Native: uma biblioteca que informa os insets

A `SafeAreaView` do próprio React Native está marcada como obsoleta na documentação, que aponta a
**biblioteca `react-native-safe-area-context`** no lugar. A `SafeAreaView` dela é uma view com os
insets aplicados como padding, com uma lista `edges` para os lados em que deve aplicá-los, e o hook
`useSafeAreaInsets()` devolve os quatro números `{ top, right, bottom, left }` para código que
posiciona coisas na mão. A documentação dela traz um aviso que vale guardar: os valores não são
atualizados de forma síncrona, então uma rotação pode mostrá-los com um instante de atraso.

## A mesma tela em três grafias

Os trechos abaixo desenham a tela de curso do planner com o fundo até as bordas e a lista e o
botão de adicionar sessão dentro da área segura. Eles foram adaptados da documentação de cada
plataforma, e **não foram compilados nem rodados para este curso**.

```kotlin
// Compose: draw to the edges, pad the content by the safe drawing insets
Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.surface)) {
    Column(Modifier.fillMaxSize().safeDrawingPadding()) {
        SessionList(Modifier.weight(1f))
        AddSessionButton()
    }
}
```

```swift
// SwiftUI: content is kept in the safe area; only the background leaves it
ZStack {
    Color(.systemBackground).ignoresSafeArea()
    VStack {
        SessionList()
        AddSessionButton()
    }
}
```

```tsx
// React Native: the library pads the content by the insets it reports
<View style={{ flex: 1, backgroundColor: "#fff" }}>
  <SafeAreaView style={{ flex: 1 }} edges={["top", "bottom", "left", "right"]}>
    <SessionList />
    <AddSessionButton />
  </SafeAreaView>
</View>
```

**Lidos lado a lado, os padrões ficam visíveis.** O trecho em Kotlin precisa pedir o espaço; o em
Swift precisa pedir para sair dele; o em React Native precisa trazer uma biblioteca que conhece os
números. A intenção é idêntica nos três: o fundo vai para todo lado, e o que o aluno lê ou toca
fica onde nada o cobre.
