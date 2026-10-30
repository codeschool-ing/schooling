---
title: Os componentes, comparados ao HTML que você conhece
version: 1
---

**O React Native tem uma lista curta de componentes embutidos, e quase toda tela é feita de seis
deles.** Não há `<div>`, nem `<p>`, nem `<button>`: cada um é substituído por um componente que
corresponde a uma view nativa em cada plataforma, e que o `react-native-web` transforma de volta em HTML
num navegador.

| React Native | o HTML mais próximo | o que saber |
|---|---|---|
| `View` | `<div>` | uma caixa; ela posiciona os filhos com flexbox e não desenha texto |
| `Text` | `<span>`, `<p>` | **todo texto mora num `Text`**; texto direto dentro de uma `View` é erro num celular |
| `Pressable` | `<button>` | qualquer coisa que recebe um toque; não diz nada a um leitor de tela até ter um `role` |
| `TextInput` | `<input>` | o campo e o teclado da própria plataforma; o valor dele é estado que você guarda |
| `FlatList` | um `<ul>` comprido | desenha só as linhas visíveis, e as reaproveita enquanto a lista rola |
| `ScrollView` | `<div>` com `overflow: auto` | rola tudo o que está dentro, tudo desenhado de uma vez; serve para uma tela curta |
| `Image` | `<img>` | precisa de um tamanho, ou não desenha nada |

**A segunda linha pega todo mundo que vem da web uma vez.** Num navegador, texto pode ficar em qualquer
lugar. No React Native, um texto fora de um `<Text>` para o app num celular com um erro que nomeia o
componente, enquanto o build web pode mostrá-lo mesmo assim. O build web ser tolerante onde o celular é
rígido é um padrão que vale esperar.

## `FlatList` e `ScrollView`

A aula 6 mediu o planner com cinco mil sessões e achou o custo em desenhar tudo. **A `FlatList` é a
resposta do React Native exatamente a isso**: dê a ela o array inteiro, `data`, um jeito de nomear cada
item, `keyExtractor`, e uma função que desenha uma linha, `renderItem`, e ela desenha só o que cabe na
tela, mais uma margem. Uma `ScrollView` com as mesmas cinco mil linhas dentro desenharia todas, como a
versão web fez. Use `ScrollView` para uma tela que é comprida por causa do conteúdo, e `FlatList` para
uma tela que é comprida por causa dos dados.

## Sem eventos em tudo

Uma `View` não pode ser apertada: só um `Pressable` recebe `onPress`. Um `TextInput` não guarda o
próprio valor como um `<input>` guarda numa página web simples: você dá a ele um `value` e o muda no
`onChangeText`, que é o padrão de campo controlado do React, e num celular é o único.
