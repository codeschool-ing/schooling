---
title: Valores fora da escala
version: 1
---

Às vezes um valor não está na escala: uma largura vinda de um design, uma cor de marca usada uma vez. Colchetes aceitam qualquer valor, um **valor arbitrário**: `w-[37rem]`, `text-[#2f6f4e]`, `grid-cols-[12rem_1fr]`, com um sublinhado onde o CSS tem um espaço. Funcionam, e são o `margin: 13px` da seção 08 da aula 10: cada um é um valor que contorna os tokens do design.

A CLI tem um comando que reescreve listas de classes na forma **canônica**, que é o que um linter no editor faz enquanto você digita:

```
ana@laptop:~/site$ npx @tailwindcss/cli canonicalize "p-[16px] mt-[4px] w-[37rem] text-[#2f6f4e]"
mt-[4px] w-148 p-[16px] text-[#2f6f4e]
```

Ele pôs as classes na ordem do Tailwind, margens antes de larguras antes de padding. E **`w-[37rem]` virou `w-148`**: 37rem são 148 passos de 0,25rem, então o valor estava na escala, e a forma arbitrária só o escondia. `p-[16px]` e `mt-[4px]` ficaram como estavam, porque a escala é em rem e um valor em pixels é outro valor, mesmo que hoje fique igual na tela: se o tamanho de fonte padrão de quem lê é maior, `p-4` cresce junto e `p-[16px]` não. `text-[#2f6f4e]` ficou, porque essa cor não está na paleta. **A correção para uma cor usada duas vezes é um token em `@theme`**, seção 07, que dá a ela um nome e um utilitário.

## Onde o Tailwind para

Tudo deste curso continua disponível: uma folha de entrada pode ter qualquer CSS, e algumas linhas de CSS comum muitas vezes são mais claras que uma longa lista de valores arbitrários. O teste da seção 02 vale. Se você não consegue dizer que CSS uma lista de classes gera, a lista de classes é a ferramenta errada para aquele pedaço, e a aula que explica a propriedade é o lugar para procurar.
