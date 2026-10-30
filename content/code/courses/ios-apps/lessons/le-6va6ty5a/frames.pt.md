---
title: Frames: uma view nova em volta da antiga
version: 1
---

**`.frame(width: 200)` não define a largura de uma view. Ele a põe dentro de uma view nova e
invisível com 200 de largura, e propõe 200 à view de dentro.** A view de dentro então escolhe, como a
seção 02 disse que toda view faz. A documentação da Apple para `frame(width:height:alignment:)` o
descreve nesses termos: posiciona esta view dentro de um frame invisível com o tamanho indicado.

A diferença aparece no momento em que a view de dentro quer menos que o frame:

```swift
Text("50 min")
    .frame(width: 200)
    .border(.red)
```

A borda vermelha é desenhada em volta do frame, com 200 pontos de largura, e o texto fica no meio
dele com a largura das suas palavras. **Duas views, dois tamanhos**: o frame tem 200, o texto não. O
argumento `alignment` decide onde, dentro do frame, fica a view menor, e a documentação observa que
ele não tem efeito visível quando os dois tamanhos coincidem.

## Frames flexíveis

A segunda forma de `frame` aceita mínimos, ideais e máximos em vez de um tamanho fixo, e o uso mais
comum dela é um argumento só:

```swift
Text("Week of 19 October")
    .frame(maxWidth: .infinity, alignment: .leading)
```

**`maxWidth: .infinity` faz um frame que aceita qualquer largura oferecida**, então numa stack ele se
comporta como um spacer, ficando com o que sobra. A documentação da Apple para a forma flexível
detalha a regra: sem mínimo nem máximo numa dimensão o frame adota o dimensionamento do filho, e com
restrições ele limita a proposta a elas. O `alignment: .leading` põe então o texto à esquerda desse
frame largo, que é o jeito comum de alinhar um título à esquerda atravessando a tela.

## Quando o texto não cabe

Um `Text` a quem se oferece menos que a largura ideal quebra em mais linhas se puder, e corta com
reticências se não puder. O `.fixedSize()` diz a uma view para ignorar a proposta e ficar com o
tamanho ideal, o que a documentação da Apple para `fixedSize()` demonstra com uma string longa dentro
de um frame de 200 pontos: com ele, o texto passa do frame em vez de quebrar. É a ferramenta certa
quando um rótulo curto não pode ser cortado nunca, e a errada para uma frase, que sairia da tela.

Nada nesta seção foi executado para o curso. As listagens foram escritas a partir da documentação da
Apple para os dois modificadores `frame` e para o `fixedSize()`, lida em 30 de outubro de 2026, e o
curso não mostra captura de tela do que eles desenham.
