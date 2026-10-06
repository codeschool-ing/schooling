---
title: As partes de um prompt de imagem
version: 1
---

Um prompt de texto para um modelo de linguagem é uma instrução. Um prompt de imagem está mais perto de uma **descrição de uma imagem que já existe**, porque foi disso que o modelo aprendeu: imagens e as legendas que as pessoas escreveram para elas. "Faça um banner que venda livros" é uma instrução, e não há imagem no treino com essa legenda. "Uma pilha de livros usados numa mesa de café, ilustração em aquarela" descreve algo que uma legenda poderia dizer.

Ajuda escrever a descrição em partes com nome, porque cada parte controla uma coisa diferente e pode ser mudada sozinha:

| parte | o que controla | o banner da Marginalia |
|---|---|---|
| **assunto** | o que há na imagem | a stack of second-hand books on a café table |
| **meio** | do que ela parece feita | watercolour illustration |
| **estilo** | o modo de tratar o meio | loose brushwork, soft edges |
| **composição** | enquadramento, onde ficam as coisas, espaço vazio | wide banner, books on the left third, empty space on the right |
| **luz** | hora do dia, direção, clima | late afternoon sun from the left |
| **paleta** | as cores | warm ochre and deep green |

A linha de composição carrega a exigência real do banner: **espaço vazio à direita**, porque a newsletter põe a manchete ali. É a parte que mais se esquece, e a que decide se a imagem serve.

Alguns hábitos fazem esses prompts funcionarem melhor, e nenhum deles é frase secreta.

**Concreto vence avaliativo.** "Lindo", "deslumbrante" e "alta qualidade" descrevem um julgamento, não uma imagem. "Sol do fim da tarde vindo da esquerda" descreve uma luz que o modelo viu milhares de vezes.

**Diga o que há, não o que não há.** "Sem pessoas" põe a palavra *pessoas* no prompt. Alguns modelos locais aceitam um **prompt negativo** separado para o que evitar; onde a API não tem, descreva a cena de modo que pessoas fiquem deslocadas ("um café vazio antes de abrir").

**O tamanho tem teto.** Muitos modelos abertos leem o prompt pelo codificador de texto CLIP, que aceita 77 tokens e ignora o resto, então o fim de um prompt longo nem é lido. Modelos mais novos usam codificadores maiores e leem muito mais. De um jeito ou de outro, as partes que importam vêm primeiro.

**Texto dentro da imagem é um pedido à parte.** Se o banner precisa de palavras, ponha-as entre aspas e curtas ("a chalkboard sign that says \"Used books\""), ou, melhor, deixe o espaço vazio e acrescente as palavras na newsletter, onde são texto de verdade que um leitor de tela consegue ler em voz alta (aula 14).

Os prompts ficam em inglês porque os modelos citados aprenderam sobretudo com legendas em inglês; a maioria aceita português, e o mesmo método de variar uma parte por vez serve para descobrir se, no modelo que você usa, a língua muda o resultado.
