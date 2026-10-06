---
title: O que os geradores erram, e o que recusam
version: 1
---

Dois tipos de limite se aplicam a todo gerador de imagens: **o que ele não consegue fazer bem**, que vem de como foi treinado, e **o que ele não vai fazer**, que vem da política do provedor. Os dois precisam ser contornados no desenho, e nenhum se resolve insistindo no prompt.

## O que sai errado

| pedido | o que volta | por quê |
|---|---|---|
| uma placa que diz "Used books" | letras que parecem letras e não formam palavra, ou uma palavra com erro | texto era uma parte pequena e variada das imagens de treino |
| cinco livros numa pilha | quatro, ou sete | o modelo aprendeu *uma pilha*, não uma contagem |
| uma mão segurando um livro | um dedo a mais, uma articulação no lugar errado | mãos variam muito e muitas vezes aparecem parcialmente escondidas nas fotografias |
| um livro vermelho sobre um azul | as cores trocadas, ou os dois vermelhos | o prompt é um vetor só; qual palavra se liga a qual objeto é frouxo |
| "um médico" ou "um CEO" | quem os dados de treino mais mostravam | o modelo reproduz o que mais viu |

Modelos mais novos, incluindo os da aula 9, desenham texto curto muito melhor do que os primeiros, e alguns contam números pequenos com segurança. Teste o que você precisa no modelo que você usa; não tome um limite de um artigo, este incluído, como fato sobre o modelo do ano que vem.

A última linha merece mais do que um ajuste no prompt. **O padrão de um gerador para uma pessoa é uma média estatística dos dados de treino**, e nas imagens que uma loja publica essa média vira escolha da loja. Se houver pessoas numa imagem, decida quem elas são e diga; deixar para o padrão também é uma decisão.

## O que é recusado

Os provedores filtram tanto o prompt quanto a imagem. As recusas tratam tipicamente de conteúdo sexual, violência, pessoas reais (sobretudo figuras públicas), marcas e logotipos, e conteúdo que imita um artista vivo. A API responde com um erro em vez de uma imagem, e a aula 9 mostra o formato desse erro.

Duas dessas importam a uma loja comum toda semana:

- **Pessoas reais.** Uma imagem que parece uma pessoa identificável, mesmo inventada a partir de uma descrição, pode prejudicar essa pessoa e expor a loja. O guia de estilo da Marginalia diz *sem rostos*.
- **Marcas e o trabalho dos outros.** Um banner com um logotipo reconhecível, uma capa de livro famosa ou um personagem de filme é propriedade de alguém, gerado ou não. Uma capa de *Dom Casmurro* pode ser desenhada porque o romance está em domínio público; a capa que uma editora criou para ele não está.

## Contornar os dois no desenho

Trate toda imagem gerada como um **rascunho que uma pessoa aprova** antes de publicar, e anote por que foi aprovada. A coluna de aprovação do registro da seção 04 é o lugar mais barato para esse registro, e é o que a loja mostraria a quem perguntasse de onde veio uma imagem.
