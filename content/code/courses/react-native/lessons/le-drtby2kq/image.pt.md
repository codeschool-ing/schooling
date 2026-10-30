---
title: Image, que precisa saber o próprio tamanho
version: 1
---

**Uma `Image` desenha uma figura e, ao contrário de um `<img>`, não se dimensiona pelo arquivo que
baixa.** Essa diferença sozinha explica quase tudo o que dá errado com imagens no React Native.

## Dois tipos de origem

| origem | escrita como | tamanho |
|---|---|---|
| um arquivo do projeto | `source={require("../assets/icon.png")}` | conhecido no build do app, pelo arquivo |
| uma figura na rede | `source={{ uri: "https://example.org/cover.png" }}` | desconhecido até chegar, então **você precisa dar um** |

O `require` é resolvido pelo Metro na hora do bundle, como um `import`, então um arquivo que falta é erro
quando o app é empacotado, e não um espaço em branco depois. O arquivo entra no bundle (ou, num celular,
nos assets do app) em cada resolução que o projeto oferece: `icon.png`, `icon@2x.png` e `icon@3x.png` lado
a lado são escolhidos pela densidade de pixels da tela.

**Uma imagem da rede sem `width` e `height` é desenhada com zero por zero**, ou seja, não é desenhada,
sem erro nenhum. É a resposta de costume quando alguém pergunta por que uma imagem não aparece no React Native. Dê a
ela um tamanho, ou um `flex` e um `aspectRatio` que produzam um.

## Pixels que você vê, pixels que você paga

O tamanho no estilo é em **pixels independentes de densidade**, a unidade da aula 5: um ícone de 40 por 40
tem 40 por 40 em qualquer celular, e cobre 120 por 120 pixels reais num celular de densidade três. O
arquivo da imagem deve ter mais ou menos esse tamanho, ou um dos irmãos `@2x` e `@3x`. Uma foto de 4000
pixels mostrada num quadrado de 40 pontos é decodificada inteira na memória antes; a aula 19 mede quanto
isso custa, e por que uma lista dessas fotos é como um app fica sem memória.

## O que um leitor de tela diz

Uma imagem que significa algo precisa de palavras: `alt="Statistics course cover"`, que o React Native
passa à plataforma como o rótulo da imagem. Uma imagem que só decora, como o ícone do planner ao lado do
título, deve ser pulada, e o `aria-hidden` diz isso. Sem nenhum dos dois, o que um leitor de tela faz com
ela fica a cargo da plataforma, e a escolha de nenhuma das duas é a que você queria.

## Como o planner usa uma

A primeira tela dele põe o ícone do próprio app, que já está em `assets/` desde o modelo, à esquerda do
título. Um arquivo do projeto, então `require`, e decorativo, então `aria-hidden`. A última seção desta
aula o mostra no lugar, e o estilo lhe dá 40 por 40 explícitos, de que uma imagem local não precisa a
rigor e que tornam o leiaute independente do tamanho do arquivo.
