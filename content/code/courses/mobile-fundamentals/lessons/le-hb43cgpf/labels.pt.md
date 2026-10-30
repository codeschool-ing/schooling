---
title: Rótulos, papéis e agrupamento, em três grafias
version: 1
---

**A maior parte de uma tela acessível vem de graça dos componentes da própria plataforma, e o resto
é um punhado de declarações nos controles que você mesmo constrói.** Um `Text` é lido pelas próprias
palavras; um botão, uma caixa de seleção ou um interruptor padrão já declaram o papel e o estado. A
documentação do Android diz que "não é preciso fornecer um contentDescription para composables Text",
e o mesmo vale no iOS e no React Native. O que precisa ser escrito é o rótulo de tudo o que mostra
uma imagem em vez de palavras, o papel e o estado de tudo o que você desenhou, e o agrupamento das
coisas que andam juntas.

## Uma linha de sessão, três vezes

A semana do planner mostra cada sessão como uma linha: o curso, a data e a duração, e um tique que a
marca como feita. Ouvida ingenuamente, são três ou quatro elementos por linha, e um usuário de leitor
de tela desliza por todos eles para chegar à sessão seguinte. A linha melhor é **um elemento só**, que
lê a sessão como uma frase, diz que é uma caixa de seleção, diz se está marcada, e alterna com um
toque duplo.

Os três fragmentos abaixo fazem essa linha em cada plataforma. Eles foram adaptados da documentação
de acessibilidade de cada plataforma, a do Android sobre semântica no Compose, a da Apple sobre o
SwiftUI e a do React Native sobre as propriedades de acessibilidade, e **não foram compilados nem
executados para este curso**. Leia-os pela forma, não pela sintaxe: cada um faz as mesmas quatro
coisas.

```kotlin
// Compose: toggleable makes the row one element, with the checkbox role and its state
Row(
    Modifier.toggleable(
        value = session.done,
        role = Role.Checkbox,
        onValueChange = { onMarkDone(session.id) },
    )
) {
    Text(course.title)
    Text("${session.date}, ${session.minutes} minutes")
    Checkbox(checked = session.done, onCheckedChange = null)
}
```

```swift
// SwiftUI: combine the children into one element, then say what it is and how it is
HStack {
    Text(course.title)
    Text("\(session.date), \(session.minutes) minutes")
    Image(systemName: session.done ? "checkmark.circle.fill" : "circle")
}
.accessibilityElement(children: .combine)
.accessibilityAddTraits(.isButton)
.accessibilityValue(session.done ? "done" : "not done")
.onTapGesture { markDone(session.id) }
```

```tsx
// React Native: one Pressable, with its label, role and state declared on it
<Pressable
  onPress={() => markDone(session.id)}
  accessibilityLabel={`${course.title}, ${session.date}, ${session.minutes} minutes`}
  accessibilityRole="checkbox"
  accessibilityState={{ checked: session.done }}
>
  <Text>{course.title}</Text>
  <Text>{session.minutes} min</Text>
</Pressable>
```

**O agrupamento se escreve de três jeitos e significa uma coisa.** No Compose, um modificador
clickable ou toggleable funde o que está dentro dele, e `Modifier.semantics(mergeDescendants = true)`
faz o mesmo numa linha que não é clicável; a documentação do Android diz que os serviços de
acessibilidade então "focam o contêiner inteiro de uma vez". No SwiftUI,
`.accessibilityElement(children: .combine)` funde as propriedades dos filhos num elemento novo. No
React Native, uma view marcada `accessible={true}` é um elemento só para o VoiceOver e o TalkBack, e
os componentes tocáveis já são acessíveis por padrão.

**Papel e estado são onde os três mais diferem no nome.** O Compose define `role = Role.Checkbox` e
tira o estado de `value`; a documentação do Android acrescenta um `stateDescription` para quando
"marcada" e "não marcada" não são as palavras certas. O SwiftUI acrescenta um trait, `.isButton`, e
põe o estado no value. O React Native escreve `accessibilityRole="checkbox"` e
`accessibilityState={{ checked }}`.

## Rótulos que ajudam, e rótulos que não ajudam

**Um rótulo diz o propósito, com as palavras da tela, e nunca a aparência.** "Marcar SQL de sexta
como feita" ajuda. "Ícone de tique verde" descreve pixels que o usuário não vê e não diz nada sobre o
que acontece. "Botão marcar como feita" repete o papel, e o usuário ouve "botão" duas vezes. E sete
linhas rotuladas todas "marcar como feita" são sete sons idênticos: a documentação do Android pede
que cada descrição seja única, e é por isso que o rótulo do planner leva o curso e a data.

**Decoração não diz nada.** Um desenho ao lado do total da semana que não acrescenta informação deve
ficar escondido do leitor de tela, para o usuário não gastar um deslize com ele: `contentDescription
= null` num `Image` do Compose, `.accessibilityHidden(true)` no SwiftUI. As HIG pedem o mesmo:
excluir "imagens puramente decorativas", por "respeito ao tempo das pessoas".

**Uma dica serve para o que o rótulo e o papel deixam pouco claro**, e a maioria dos controles não
precisa de nenhuma. Uma caixa de seleção que alterna fica clara pelo papel. Uma linha que abre os
detalhes da sessão num toque duplo poderia levar "abre a sessão". A documentação do React Native
observa que o VoiceOver só lê uma dica quando o usuário está com as dicas ativadas, então nada
essencial pode morar só numa dica.

As declarações acima são tudo o que um leitor de tela precisa. As próximas seções tratam dos usuários
que veem a tela, mas não bem, e que tocam nela, mas sem precisão.
