---
title: O que deixar passar, e quando aprovar
version: 1
---

A habilidade mais difícil da revisão não é achar coisas. É **não escrever** a maior parte do que você acha.

## Deixe passar as preferências

A Ana teria oferecido uma lista de horários em vez de um campo livre. Isso é preferência: os dois
funcionam, e o que o Bruno escolheu não é pior, só diferente. Escrever isso pede para ele refazer algo que
está bom, e ensina que toda escolha dele vai ser reaberta. A quarta linha da figura nunca é escrita por
esse motivo.

Um teste útil antes de publicar: **o código ficaria pior de um jeito que alguém notaria se o meu comentário
fosse ignorado?** Se não, é preferência, e fica na sua cabeça ou, no máximo, entra como um `nit:` que quem
escreveu pode ignorar.

## Mova o que está fora do escopo

A mudança de cor do título é outro problema. Pode até ser uma boa ideia, mas não faz parte do ticket #30,
e muda todas as páginas do site dentro de um pull request sobre pedidos. O comentário certo pede para ela
sair daqui, não para ela ser desfeita para sempre:

> A mudança de cor do título afeta todas as páginas. Ela pode ir num pull request próprio, para ter a
> própria revisão?

Isso mantém o #31 sobre o #30, e se a cor nova for revertida depois, o formulário de pedidos não vai junto.

## Aprove com comentários

Quando só sobraram nits, **aprove e deixe os comentários**. Todo serviço de hospedagem deixa aprovar e
comentar ao mesmo tempo. Segurar um pull request por um texto de botão melhor custa um dia a quem escreveu
e um merge à equipe, e compra quase nada. A revisão da Ana no #31 é um comentário que bloqueia, uma
pergunta, um nit e um pedido para mover a mudança de cor. Quando o `required` entrar e a pergunta tiver
resposta, ela aprova.

## Seja rápido

Uma revisão pedida e sem resposta por três dias é o jeito mais comum de um pull request morrer: o branch se
afasta, quem escreveu passa para outro trabalho, e voltar custa mais a cada dia. Muitas equipes combinam uma
primeira resposta em até um dia útil. Meia hora de revisão hoje vale mais que uma revisão perfeita na
sexta.
