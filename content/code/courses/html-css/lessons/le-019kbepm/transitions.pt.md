---
title: Transições: de um estado para outro
version: 1
---

Quando uma propriedade muda, por causa de `:hover`, `:focus` ou de uma classe, o valor novo vale na hora. Uma **transição** (*transition*) espalha a mudança no tempo:

```css
.button {
  background-color: #2f6f4e;
  transition: background-color 200ms ease-out;
}
.button:hover { background-color: #1e4a33; }
```

O atalho recebe a **propriedade** a animar, a **duração**, a **função de tempo** da seção 06 e, opcionalmente, um **atraso**. A transição vai no elemento no estado normal, não no `:hover`, para que rode nos dois sentidos: rumo à cor do hover quando o ponteiro chega, e de volta quando ele sai.

O passo **`at MS`** pausa toda animação e transição da página naquele número de milissegundos desde o início dela, para que o meio de uma possa ser lido:

```
ana@laptop:~/site$ probe transition.html style .button background-color hover .button at 100 style .button background-color at 200 style .button background-color
button.button  background-color: rgb(47, 111, 78)
button.button  background-color: rgb(35, 86, 60)
button.button  background-color: rgb(30, 74, 51)
```

Antes do hover, o fundo é `rgb(47, 111, 78)`. Com **100 ms** de transição ele é `rgb(35, 86, 60)`, entre os dois. Em **200 ms**, o fim, é `rgb(30, 74, 51)`, que é `#1e4a33`. Metade do tempo não é metade da cor: cada canal já está a uns dois terços do caminho, o vermelho descendo de 47 para 35 a caminho de 30, porque o `ease-out` gasta o tempo assim.

## Algumas regras práticas

**Liste as propriedades.** `transition: all 200ms` anima tudo o que muda, inclusive propriedades que você não quis, como um `padding` alterado por uma media query no momento em que a janela é redimensionada. Dê nome às que você quer, separadas por vírgulas: `transition: background-color 200ms, scale 200ms`.

**Seja breve.** Retorno de interface, um hover, um clique, um anel de foco, pede **100 a 300 ms**. Mais que isso parece lento, porque a pessoa tem de esperar a interface alcançá-la.

**Faça a transição em `:focus-visible` também.** O que um hover revela ou muda, quem usa teclado precisa igual, seção 05 da aula 5, e a mesma transição serve aos dois seletores.

**Nem tudo pode ter transição.** Uma propriedade é animada interpolando entre dois valores, então precisa de valores intermediários: cores, comprimentos, números, transforms. De `display: none` para `block` não há nada no meio, e a seção 10 trata do que fazer no lugar.
