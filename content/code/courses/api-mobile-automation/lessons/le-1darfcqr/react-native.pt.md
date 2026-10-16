---
title: Um código em JavaScript, dois apps nativos
version: 1
---

**Um app React Native é escrito em JavaScript, ou TypeScript, e desenha views nativas de verdade.** O
código roda num motor de JavaScript dentro do app. O React Native transforma o que ele descreve nos
widgets da própria plataforma: um `<Text>` vira um `TextView` no Android e um `UILabel` no iOS, uma
`<FlatList>` uma lista rolável em cada um. Um código, dois apps, cada um com a cara da sua
plataforma.

O erro comum é pensar num app desses como uma página web numa moldura, como alguns frameworks mais
antigos funcionavam. Não é: não há navegador nem HTML. Para um teste ele parece qualquer outro app
nativo, e é por isso que o Appium consegue conduzi-lo. O page source da lição 15 de um app React
Native está cheio de classes `android.widget` como as do Tickets. O que um teste não vê de fora é o
lado JavaScript, onde mora a maior parte do comportamento do app.

## `testID`: um nome, duas plataformas

A lição 14 fez do resource id a primeira alça de um teste. A lição 15 disse que o problema de rodar
um teste nas duas plataformas é que os dois apps nomeiam os elementos separadamente. O React Native
tira esse problema dos seus próprios componentes com uma propriedade, **`testID`**:

| escrito uma vez | no Android vira | no iOS vira |
|---|---|---|
| `<Button testID="refresh" … />` | o resource id que a árvore de acessibilidade informa, `refresh`, sem pacote na frente | o accessibility identifier, `refresh` |

Então `by.id('refresh')` no Detox acha o mesmo botão nas duas plataformas, e assim faria um
localizador do Appium por plataforma. **A promessa entre desenvolvedores e testadores da lição 14 é
cumprida uma vez, no JavaScript**, e os dois apps a herdam.

## O app desta lição

Esta lição não refaz o Tickets em React Native tela por tela. Ela escreve só a lista, num arquivo.
Há os espetáculos do boxoffice e um botão de atualizar. Há uma linha de erro quando o boxoffice não
pode ser alcançado, e uma linha embaixo com o espetáculo tocado e os lugares dele. Isso basta para uma spec
carregar, tocar e conferir, e é pequeno o bastante para ser lido inteiro na seção 05.

**Nenhum app React Native foi compilado ou executado para este curso.** Compilar um baixa o Gradle e
bibliotecas do repositório do Google, que a máquina de gravação não alcança. Rodá-lo precisa de um
emulador, que essa máquina não consegue iniciar, como a lição 14 mostrou. Todo o resto desta lição rodou lá: criar
o projeto, conferir o código com TypeScript, instalar o Detox e pedir a ele que testasse.
