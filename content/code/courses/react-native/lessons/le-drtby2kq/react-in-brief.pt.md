---
title: "React em resumo: componentes, JSX e props"
version: 1
---

**React Native é React, e este curso não pressupõe React nenhum.** O curso `javascript`, que vem antes
dele na trilha `mobile`, não chega até lá, então esta seção dá as três ideias com que toda tela do curso
é construída. Se você já escreveu React para a web, leia-a pela única diferença: os elementos não são
HTML.

## Um componente é uma função

Um **componente** é uma função cujo nome começa com letra maiúscula e que devolve uma descrição do que
desenhar. O React a chama, pega o que ela devolve, e calcula o que a tela precisa virar. Você nunca
desenha nada; você diz o que deve estar ali, e o React faz acontecer. Salve isto como
`src/Greeting.tsx`:

```tsx
// src/Greeting.tsx: a component is a function that returns what to draw.
import { Text } from "react-native";

type Props = { name: string; minutes: number };

export function Greeting({ name, minutes }: Props) {
  const unit = minutes === 1 ? "minute" : "minutes";
  return (
    <Text>
      {name}, you have {minutes} {unit} planned today.
    </Text>
  );
}
```

## JSX é uma chamada de função escrita como marcação

A parte que parece HTML é **JSX**, e é JavaScript. A etapa do Babel no Metro transforma `<Text>Hello</Text>`
numa chamada que cria um elemento: um objeto dizendo *um `Text`, com este conteúdo*. Duas regras decorrem
disso:

- **As chaves põem JavaScript dentro dele.** `{name}` e `{minutes}` acima são expressões, avaliadas cada
  vez que o componente roda. Qualquer coisa que produza um valor vai ali: uma variável, uma soma, um
  ternário, uma chamada de função.
- **Um componente devolve um elemento.** Vários irmãos vão embrulhados, numa `View` ou num fragmento
  vazio, `<>…</>`, que os agrupa sem acrescentar nada à tela. O `App.tsx` usa um na última seção desta
  aula.

## Props são os argumentos de um componente

O `Greeting` recebe `{ name, minutes }`. Essas são as **props** dele, passadas por quem o usa, exatamente
como os atributos de uma tag HTML, e o tipo `Props` diz quais ele aceita. O TypeScript então recusa
`<Greeting name="Ana" />` sem o `minutes` antes de o app rodar. Usá-lo é como usar qualquer outro
elemento:

```tsx
<Greeting name="Ana" minutes={45} />
```

Uma prop de texto pode ir entre aspas; qualquer outra coisa, um número inclusive, vai entre chaves. **Um
componente nunca muda as próprias props.** Elas pertencem ao pai, e um componente que precisa de um
valor que possa mudar o guarda em estado, que a seção do Pressable desta aula apresenta e a aula 9
desenvolve.

## O que muda em relação ao React na web

Só os elementos. Na web as menores peças são `div`, `p`, `img`, `button`, e o React DOM as transforma em
HTML. **Aqui as menores peças são os componentes do React Native**, `View`, `Text`, `Image`, `ScrollView`,
`Pressable` e mais alguns, e o React Native os transforma em views nativas. Um `<div>` num componente
React Native é erro, porque nada sabe desenhar um. O resto desta aula são esses componentes, um de
cada vez.
