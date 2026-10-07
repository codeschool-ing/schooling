---
title: Revisar o código de um júnior
version: 1
---

**Quando o autor está aprendendo, a revisão tem dois trabalhos: acertar a mudança e deixar o autor
capaz de acertar a próxima sem você.** O segundo trabalho muda o que o revisor faz. Corrigir o código
você mesmo, ou escrever a linha exata a usar, cumpre o primeiro trabalho e pula o segundo.

## Menos comentários, escolhidos

Um revisor sênior quase sempre encontra vinte coisas a dizer sobre o pull request de um engenheiro
novo. Publicar as vinte enterra as duas que importam e ensina ao autor que toda revisão é uma lista de
falhas. **Escolha os comentários que ensinam algo transferível e deixe o resto para lá**, ou junte-os
numa nota só: "algumas coisinhas de nomes, aceite ou não".

A regra prática de Lívia ao revisar junto com Diego: no máximo um *issue* por revisão que seja sobre
aprendizado, e não sobre correção. Issues de correção sempre recebem comentário. Comentários de
aprendizado são racionados, para que cada um seja ouvido.

## Aponte, não resolva

| em vez de | escreva |
|---|---|
| "Troque a linha 12 por `slots = [first + timedelta(hours=i) for i in range(count)]`" | "nitpick: este loop poderia ser uma comprehension; vale tentar, se você ainda não usou uma para isso" |
| "Isto está errado, use a tabela de horários de funcionamento" | "issue: o horário de fechamento é uma constante aqui, mas a logística tem uma tabela de horários de funcionamento. Consegue encontrá-la e usá-la?" |
| "Por que você fez assim?" | "question: o que fez você escolher uma constante em vez da tabela? Quero entender antes de sugerir qualquer coisa" |

A coluna da esquerda corrige a mudança mais depressa. A da direita faz o autor encontrar a resposta,
que é a parte que ele precisa praticar.

## Revisem juntos, às vezes

Nos primeiros pull requests de um engenheiro novo, uma chamada de vinte minutos lendo o diff juntos
ensina mais do que qualquer quantidade de comentários escritos. O revisor pode pedir "me explica essa
parte" e ouvir o raciocínio do autor, que uma revisão escrita nunca mostra. A aula 12 diz o mesmo sobre
programação em par: **certos conhecimentos só se transferem quando duas pessoas olham para a mesma
coisa ao mesmo tempo.**

## O tom, que é lido mais alto do que se pretendia

Comentários escritos perdem o tom de voz, e um comentário curto de uma pessoa sênior para uma júnior é
lido como mais duro do que foi escrito. "Por quê?" é lido como "isto está errado". Três hábitos
ajudam: **escreva frases completas, diga do que gostou e use "nós" para o código** ("nós costumamos
colocar isso na configuração") em vez de "você" para a pessoa. E quando uma thread de revisão começa a
ir e voltar, leve-a para uma chamada, a mesma regra da aula 9 para qualquer desacordo.
