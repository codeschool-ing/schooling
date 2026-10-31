---
title: O CSS que aqui não existe
version: 1
---

**Quase tudo o que torna o CSS poderoso falta de propósito**, e cada peça que falta tem um substituto que é
código comum. Conhecer a lista poupa uma longa busca por uma propriedade que nunca esteve ali.

| na web | aqui | o que escrever no lugar |
|---|---|---|
| seletores, classes, a cascata | nada | um objeto de estilo por elemento; reuso importando-o |
| herança de fontes e cores | só de um `Text` para o `Text` dentro dele | passe a cor, ou leia-a de um tema, como faz a seção do modo escuro |
| `:hover`, `:active`, `:focus` | nada | o `pressed` do `Pressable`, e estado que você guarda |
| media queries | nada | `useWindowDimensions` e `useColorScheme`, lidos no componente |
| `display: grid`, floats | nada | linhas e colunas de flex, ou `flexWrap: "wrap"` |
| `px`, `em`, `rem`, `vh` | nada | números simples, porcentagens, `flex` |
| `box-shadow` nas duas plataformas | o `boxShadow` existe, e cada plataforma o desenha | confira nas duas, aula 6 |
| transições e keyframes de CSS | nada | as bibliotecas de animação da aula 12 |

## O que é igual

O modelo de caixa: `margin`, `padding`, `borderWidth`, `borderRadius`, com os atalhos `Horizontal` e
`Vertical` acrescentados, `paddingHorizontal: 16` para esquerda e direita de uma vez. `position: "absolute"`
com `top`, `left`, `right` e `bottom` funciona como na web, em relação ao pai. O `zIndex` ordena irmãos.
`opacity`, `transform` e `overflow` se comportam como você espera, e `gap` espaça filhos flex.

## Duas armadilhas vindas da web

**O `display: "none"` existe e raramente é o certo.** Ele tira o elemento do leiaute e o mantém na árvore,
montado, com o estado. Para mostrar algo condicionalmente, renderize condicionalmente, `{open && <Panel />}`,
como faz a linha de status do planner.

**Porcentagens precisam de um pai com tamanho.** `width: "50%"` dentro de um pai cuja largura vem do conteúdo
é uma porcentagem de algo que depende do filho, e o Yoga resolve o círculo desistindo. Numa coluna cujos
filhos se esticam, que é o padrão, funciona; dentro de uma linha cujos filhos se medem pelo conteúdo, não.
