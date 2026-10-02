---
title: Exemplos são uma especificação
version: 1
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

A tarefa de rotular da lição 20, em três versões. O curso escreveu as três como ilustração, e elas
estão encurtadas para a parte que muda.

Zero-shot, só a descrição:

```localised
Rotule a mensagem como positive, negative, mixed ou not_a_review.
Responda só com o rótulo.

<message>Great, another forty minutes for a coffee.</message>
```

One-shot, a descrição e um exemplo resolvido:

```localised
Rotule a mensagem como positive, negative, mixed ou not_a_review.
Responda só com o rótulo.

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Great, another forty minutes for a coffee.</message>
```

Few-shot, com um exemplo para cada rótulo, inclusive um irônico:

```localised
Rotule a mensagem como positive, negative, mixed ou not_a_review.
Responda só com o rótulo.

<message>Oh lovely, a cold croissant again.</message>
negative

<message>Can I book the terrace for six on Saturday?</message>
not_a_review

<message>Friendly staff, but the music was far too loud.</message>
mixed

<message>Best coffee on the street.</message>
positive

<message>Great, another forty minutes for a coffee.</message>
```

A versão one-shot fixa a **forma**: um rótulo puro, numa linha só, que a descrição também pedia.
Ela não resolve a ironia, porque o seu único exemplo não é irônico. A versão few-shot tem uma
mensagem irônica rotulada `negative`, que mostra a fronteira que a lição 20 só conseguia descrever.
Esse é o argumento a favor dos exemplos numa frase: **eles respondem à pergunta "de que lado da
linha isto cai?" pondo alguma coisa de cada lado.**

O one-shot tem um risco próprio. Com um único exemplo, tudo nele parece parte do padrão: o rótulo,
o tamanho, o assunto. Um modelo que viu só `not_a_review` pode pender para esse rótulo na próxima
mensagem, e é por isso que a próxima seção de leitura pede exemplos que cubram todas as classes.
