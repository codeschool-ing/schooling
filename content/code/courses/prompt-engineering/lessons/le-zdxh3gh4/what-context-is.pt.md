---
title: O que conta como contexto
version: 1
---

Uma crença comum sobre um bom modelo é que ele vai descobrir o que você quis dizer: que um pedido
curto basta, e o modelo completa o resto com bom senso. Ele completa o resto, sim. **Com o que ele
preenche a lacuna é o texto que costuma vir em seguida, não os fatos da sua situação**, porque o
prompt é a única coisa que ele tem para trabalhar (lição 1). Prompting contextual é o hábito de
pôr esses fatos no prompt em vez de deixar o modelo adivinhá-los.

## O mesmo pedido, duas vezes

O Café Aurora, o café a quem pertence o manual deste curso, recebe um e-mail. Alguém pagou
R$ 140 no cartão por um bolo de limão, recebeu um de chocolate e quer o dinheiro de volta, em
espécie se possível. O pedido seco é uma linha e a mensagem embaixo dela:

```
Reply to this customer:

I ordered a lemon cake for a party and was given a chocolate one. I paid R$ 140 by card. I'd like my money back, in cash if possible.
```

A resposta abaixo foi escrita por este curso como ilustração do que um modelo capaz
plausivelmente devolve para esse prompt. Não é uma captura:

```localised
Prezado cliente,

Sentimos muito pela confusão com o seu bolo! É claro que vamos
reembolsar o valor integral. É só passar no café com o recibo que
devolvemos os R$ 140 em dinheiro no balcão. Esperamos ver você de novo!

Abraços,
A equipe
```

O texto soa bem, e **duas das suas promessas quebram as regras do Café Aurora**: o manual diz que um
reembolso volta para o cartão que pagou, nunca em dinheiro, e que qualquer valor acima de
R$ 100 precisa da aprovação do gerente do turno. O modelo não conhecia nenhuma das duas regras.
Ele escreveu o que respostas de reembolso costumam dizer, que é a alucinação da lição 5 na sua
forma mais comum: nenhum fato inventado sobre o mundo, só uma política plausível que por acaso é
a de outra pessoa.

Com a página de reembolsos e quatro linhas sobre o trabalho no prompt (a próxima seção mostra o
prompt inteiro), a ilustração do curso para a resposta passa a ser:

```localised
Olá,

Lamentamos que você tenha recebido o bolo errado. Você tem direito ao
reembolso, e ele volta para o cartão com que você pagou: não podemos
devolver em dinheiro um pagamento feito no cartão. Como o valor passa de
R$ 100, o gerente do turno aprova antes; confirmamos por e-mail assim
que estiver feito.

Café Aurora
```

O modelo é o mesmo, e o pedido também. **A diferença são quatro tipos de fato que o primeiro
prompt não trazia.**

## Quatro tipos de contexto

| | o que responde | para o e-mail do reembolso |
|---|---|---|
| para quem é a resposta | o leitor, e o que ele já sabe | um cliente, por e-mail, que não leu o manual |
| para que ela serve | o que acontece com a saída depois | um rascunho que alguém da equipe confere e envia |
| restrições | os limites dentro dos quais a resposta tem de ficar | menos de 100 palavras; não prometer nada que o manual não cubra |
| os dados | o material com que a resposta tem de ser feita | a página de reembolsos e a mensagem do cliente |

Os dois primeiros decidem o tom e o formato. Uma resposta para um cliente é diferente de um
recado para o gerente do turno sobre o mesmo reembolso, e um rascunho que alguém vai conferir pode
dizer "alguém da equipe vai responder", o que uma mensagem enviada automaticamente não poderia.

As restrições são o que você corrigiria à mão depois. **Um limite que você não escreveu é um
limite que o modelo não tem como respeitar**, por mais óbvio que ele seja para você.

Os dados são a parte que mais se esquece, porque estão na sua cabeça ou na sua tela e não no
prompt. Um modelo a quem se pergunta "qual é o nosso horário?" não tem "nosso". Ele consegue
produzir o horário de um café típico com fluência total, e nada na resposta vai avisar que foi
inventado.

## O que contexto não é

Contexto são fatos sobre esta tarefa. Duas técnicas vizinhas põem texto no prompt por outros
motivos. Um prompt de sistema (lição 22) carrega as instruções que valem para uma conversa ou uma
aplicação inteira; um papel (lição 23) diz ao modelo com que voz responder. Os fatos podem ir
junto com qualquer um dos dois: o prompt de sistema do café na lição 22 diz de onde vêm os fatos
dele, e o texto do manual chega com cada pergunta. **O que torna isso prompting contextual é a pergunta que você faz enquanto
escreve: o que o modelo precisa saber sobre esta situação que ele não tem como saber de outro
jeito?**

Um teste útil é imaginar o prompt entregue a um desconhecido capaz, um temporário na primeira
manhã, sem chance de fazer perguntas. Tudo o que ele precisaria perguntar a você antes de escrever
uma boa resposta é contexto que falta no prompt.
