---
title: O que conta como contexto
version: 2
---

Uma crença comum sobre um bom modelo é que ele vai descobrir o que você quis dizer: que um pedido
curto basta, e o modelo completa o resto com bom senso. Ele completa o resto, sim. **Com o que ele
preenche a lacuna é o texto que costuma vir em seguida, não os fatos da sua situação**, porque o
prompt é a única coisa que ele tem para trabalhar (lição 1). Prompting contextual é o hábito de
pôr esses fatos no prompt em vez de deixar o modelo adivinhá-los.

## O mesmo pedido, duas vezes

O Café Aurora, o café a quem pertence o manual deste curso, recebe um e-mail. Alguém pagou R$ 140 no
cartão por um bolo de limão, recebeu um de chocolate, e quer o dinheiro de volta, em espécie se
possível. O pedido puro é uma linha e a mensagem embaixo dela. Salve-o como `~/pe/bare.txt` e mande:

```
ana@lab:~/pe$ cat bare.txt
Reply to this customer:

I ordered a lemon cake for a party and was given a chocolate one. I paid R$ 140 by card. I'd like my money back, in cash if possible.
ana@lab:~/pe$ ask - --temperature 0 < bare.txt
Dear valued customer,

I apologize for the inconvenience and disappointment caused by the incorrect cake order. I can imagine how frustrating it must be to receive a different cake than what you had ordered.

I'm happy to help resolve this issue for you. I'd like to offer you a full refund of R$ 140, which will be processed back to your original payment method as soon as possible. Unfortunately, I won't be able to provide a cash refund, as our refund policy only allows for credit to the original payment method.

Please allow me a few minutes to process the refund. You should receive the credit back to your account within the next 24-48 hours, depending on your bank's processing time.

If you have any further questions or concerns, please don't hesitate to contact me directly. I apologize again for the mistake and appreciate your patience and understanding.

Thank you for your business, and I hope you have a wonderful party with your guests.

Best regards,
[Your Name]
-- llama3.2:3b, finish: stop, prompt 66 tokens, output 199 tokens
```

Ela se lê bem, e vale conferir linha por linha contra o manual. Recusa o dinheiro em espécie, que é a
regra do café, e dá um motivo, "our refund policy only allows for credit to the original payment
method", que não leu em lugar nenhum: **ela chutou a política, e o chute calhou de estar certo**.
Promete o dinheiro em 24 a 48 horas, o que ninguém decidiu. Não diz nada sobre o gerente de turno,
cuja aprovação o manual exige acima de R$ 100. E vem assinada `[Your Name]`. É a alucinação da lição 5
na forma mais comum: nenhum fato inventado sobre o mundo, só uma política plausível, certa por sorte
num ponto e calada em outro.

Com a página de reembolsos e quatro linhas sobre o trabalho no prompt, o `with-context.txt`, que a
próxima seção mostra inteiro:

```
ana@lab:~/pe$ ask - --temperature 0 < with-context.txt
Subject: Refund for Incorrect Order

Dear [Customer],

We apologize for the mistake with your order. We will process a refund for the incorrect lemon cake. The refund amount is R$ 140, which will be returned to your original payment method. Please note that we cannot provide cash refunds for card payments.

Thank you for bringing this to our attention, and we hope you can enjoy the rest of your party.

Best regards,
Café Aurora
-- llama3.2:3b, finish: stop, prompt 244 tokens, output 92 tokens
```

O modelo é o mesmo, e o pedido também. A regra do cartão agora vem do manual, o prazo sumiu, e quem
assina é o café. **E a aprovação do gerente continua faltando**, mesmo sendo uma das quatro linhas da
página de reembolsos que está no prompt: o contexto tornou possível a resposta certa, e não fez o
modelo usar tudo dele. A resposta também diz que o reembolso é pelo "incorrect lemon cake", o bolo
que o cliente nunca recebeu. Um funcionário lê todo rascunho antes do envio, e o prompt diz isso, e
é exatamente por isso.

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
