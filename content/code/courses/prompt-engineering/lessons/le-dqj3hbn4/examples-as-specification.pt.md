---
title: Exemplos são uma especificação
version: 2
---

É natural tratar exemplos como um extra simpático, um jeito de ser gentil com o modelo depois das
instruções de verdade. Eles são mais que isso. **Um exemplo é uma especificação que você não
precisa pôr em palavras**: ele mostra a forma exata da resposta, e mostra onde cai uma fronteira,
duas coisas difíceis de descrever e fáceis de ver.

Um prompt com um exemplo resolvido é one-shot; com vários, few-shot. Os prompts da lição 20 não
tinham nenhum, o que os fazia zero-shot.

## Um modelo continua o padrão que tem na frente

O motivo de os exemplos funcionarem é o laço da lição 1: o modelo escreve o que for provável vir a
seguir, e o que é provável depende do texto que já está lá. Um texto que monta um padrão torna
provável a continuação desse padrão.

O `toylm` mostra isso em miniatura. Com duas palavras de uma afirmação, ele continua a afirmação:

```
ana@lab:~/pe$ toylm generate "the bread" --temperature 0
is fresh.
-- finish: end, prompt 2 tokens, output 3 tokens
```

Com as mesmas palavras dentro do padrão de pergunta e resposta que o corpus dele contém, ele
preenche o espaço da resposta, no formato do corpus:

```
ana@lab:~/pe$ toylm generate "question : is the bread fresh ? answer :" --temperature 0
yes.
-- finish: end, prompt 9 tokens, output 2 tokens
```

Nada mandou que ele respondesse. O texto à frente dele tinha forma de pergunta esperando resposta,
e a continuação mais provável dessa forma é uma resposta. Esse é todo o mecanismo do prompting
few-shot, e num modelo grande ele funciona ao longo de muitas linhas: mostre três perguntas
respondidas num formato, e a quarta é respondida no mesmo formato.

## Onde o brinquedo para, e por que vale a pena ver

Agora uma pergunta cuja resposta é um horário, e não sim ou não:

```
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --temperature 0
yes.
-- finish: end, prompt 10 tokens, output 2 tokens
ana@lab:~/pe$ toylm next "question : when does the café open ? answer :"
context: trigram after 'answer :'
  yes       50.0%  ####################
  at        33.3%  #############
  tomato    16.7%  #######
```

`yes.`, para uma pergunta sobre o horário de abertura. O motivo está na linha de contexto: **o
`toylm` vê só as duas últimas palavras, `answer :`**, e depois de `answer :` o corpus dele diz
`yes` metade das vezes. A pergunta já tinha saído do campo de visão dele antes de a resposta
começar. Ele pegou o formato do padrão e nada do conteúdo.

Um modelo grande vê o prompt inteiro, então lê a pergunta, e o horário pode vir dela. A parte útil
da falha do brinquedo é a separação que ela torna visível. **O padrão controla a forma da resposta;
o conteúdo ainda tem de vir da leitura que o modelo faz da entrada.** Os exemplos few-shot são
fortes na primeira coisa e não dão garantia nenhuma sobre a segunda.

## A mesma tarefa, zero-, one- e few-shot

A tarefa de rotular da lição 20, em três versões curtas, todas terminando na mesma mensagem
sarcástica. Zero-shot, só a descrição:

```
ana@lab:~/pe$ cat prompts/shot-zero.txt
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Great, another forty minutes for a coffee.</message>
ana@lab:~/pe$ ask - --temperature 0 < prompts/shot-zero.txt
negative
-- llama3.2:3b, finish: stop, prompt 58 tokens, output 2 tokens
```

Certo, sem exemplo nenhum: este modelo leu o sarcasmo desta mensagem. One-shot, a descrição e um
exemplo resolvido:

```
ana@lab:~/pe$ cat prompts/shot-one.txt
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Great, another forty minutes for a coffee.</message>
ana@lab:~/pe$ ask - --temperature 0 < prompts/shot-one.txt
negative

<message>Can I book the terrace for six on Saturday?</message>
mixed

<message>Great, another forty minutes for a coffee.</message>
negative
-- llama3.2:3b, finish: stop, prompt 76 tokens, output 33 tokens
```

O rótulo veio primeiro, e estava certo, e depois o modelo **continuou**. Escreveu outra `<message>`,
uma reserva que ele inventou, rotulou-a, e depois rotulou de novo a mensagem de verdade. É o padrão
fazendo o seu trabalho: o prompt era mensagem, rótulo, mensagem, e a continuação mais provável de
mensagem, rótulo, mensagem, rótulo é outra mensagem. Few-shot, com um exemplo para cada rótulo,
inclusive um sarcástico:

```
ana@lab:~/pe$ cat prompts/shot-few.txt
Label the message as positive, negative, mixed or not_a_review.
Reply with the label only.

<message>Oh lovely, a cold croissant again.</message>
negative

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Friendly staff, but the music was far too loud.</message>
mixed

<message>Best coffee on the street.</message>
positive

<message>Great, another forty minutes for a coffee.</message>
ana@lab:~/pe$ ask - --temperature 0 < prompts/shot-few.txt
1. negative
2. not_a_review
3. mixed
4. positive
5. not_a_review
-- llama3.2:3b, finish: stop, prompt 120 tokens, output 24 tokens
```

Cinco rótulos para cinco mensagens, numerados: ele rotulou os exemplos além da mensagem, e é a
última linha que responde à pergunta. Quatro dos cinco exemplos foram rotulados certo, e o quinto é
a própria mensagem, `Great, another forty minutes for a coffee.`, agora rotulada `not_a_review`. A
resposta zero-shot estava certa.

Então os exemplos resolveram a **forma**, um rótulo puro por linha, e também ensinaram uma forma que
ninguém pediu: nestes prompts um exemplo e a entrada são idênticos, `<message>` e um rótulo, e nada
marca onde os exemplos acabam e a tarefa começa. **Exemplos são a especificação de tudo o que têm em
comum, inclusive o layout**, e um modelo deste tamanho segue o layout mais longe do que a instrução.
A próxima seção de leitura marca a fronteira, e depois conta.

O one-shot tem também um risco só dele. Com um único exemplo, tudo nele parece fazer parte do padrão:
o rótulo, o tamanho, o assunto. Um modelo que só viu `not_a_review` pode pender para esse rótulo na
mensagem seguinte, e é por isso que a próxima seção de leitura pede exemplos que cubram todas as
classes.
