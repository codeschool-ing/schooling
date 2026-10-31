---
title: Listas longas que rolam suave
version: 1
---

**Uma FlatList é rápida por padrão; alguns hábitos a deixam lenta.** Cada item desta seção é uma causa
conhecida de uma lista que engasga ou pisca espaço em branco ao rolar, e a correção de cada um é local.

## Não redesenhe toda linha a cada mudança

Quando a tela renderiza de novo, a FlatList renderiza de novo, e por padrão toda linha renderizada roda o
`renderItem` outra vez mesmo que o item dela não tenha mudado. Duas coisas impedem isso:

- **`React.memo` no componente da linha.** Um `CourseRow` memorizado só renderiza de novo quando as props dele
  mudam.
- **Props estáveis.** Uma função escrita em linha, `onOpen={(id) => setOpen(id)}`, é uma função nova a cada
  renderização, o que conta como prop alterada e derruba o memo. Passar o próprio `setOpen`, como o planner
  faz, é estável; o `useCallback` da aula 9 torna outras funções estáveis.

A aula 19 mede a diferença com o profiler do React, em vez de supô-la.

## Diga à lista a altura da linha, quando ela é fixa

Uma FlatList mede cada linha depois de renderizá-la, para saber onde vai a próxima e até onde vai a barra de
rolagem. Quando toda linha tem a mesma altura, o `getItemLayout` a informa de antemão, o que torna instantâneo
rolar até um item e tira uma medição por linha:

```tsx
getItemLayout={(_, index) => ({ length: 62, offset: 62 * index, index })}
```

O 62 é a altura que a aula 5 mediu para as linhas do planner. Se o tamanho de texto da pessoa crescer, as
linhas crescem também, e um `getItemLayout` fixo fica errado; use-o só em linhas cuja altura não pode mudar.

## Imagens nas linhas

Uma lista de figuras é a lista mais pesada que existe. Cada imagem é decodificada no tamanho inteiro na
memória, então miniaturas devem ser servidas em tamanho de miniatura, e uma lista deve usar um componente de
imagem que guarda em cache e reduz a resolução, o `expo-image` por exemplo. A aula 19 mede quanto custa uma
foto em tamanho cheio numa linha pequena.

## Quando a FlatList não basta

A **FlashList**, da Shopify, recicla os componentes das linhas em vez de criá-los e destruí-los, o que ajuda
listas de milhares de linhas complexas em celulares Android mais lentos. É uma biblioteca à parte, com as
próprias regras de dimensionamento. O planner não precisa dela, e uma lista que precisa deve ser medida antes
e depois da troca, como a aula 19 faz com as mudanças acima.
