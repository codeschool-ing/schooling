---
title: Medir o endpoint nas suas próprias mensagens
version: 1
---

Um fornecedor publica o quão bem o classificador dele se sai nos conjuntos de teste dele. Esses
números descrevem mensagens que o fornecedor coletou, nos idiomas que escolheu, rotuladas pelas regras
dele. **O número que decide alguma coisa na Tarefa é o medido nas mensagens da Tarefa**, e o único
jeito de obtê-lo é um conjunto de mensagens reais com um rótulo dado por uma pessoa a cada uma,
passado pelo endpoint.

O `data/forum.jsonl` é esse conjunto no laboratório: sessenta mensagens do fórum, cada uma rotulada
com as categorias em que uma pessoa a poria, ou nenhuma. **As mensagens e os rótulos foram escritos
pelo curso.** Um conjunto real seria amostrado do que os usuários de fato postam, e rotulado por duas
pessoas trabalhando separadas, para que a discordância entre elas também seja medida; o curso
`prompt-reliability` mede essa concordância com uma estatística feita para isso.

```
ana@lab:~/guard$ head -3 data/forum.jsonl
{"id": "m01", "lang": "en", "labels": ["harassment"], "text": "You are an idiot and everybody here knows it"}
{"id": "m02", "lang": "en", "labels": ["harassment"], "text": "Nobody wants your useless designs, quit already"}
{"id": "m03", "lang": "en", "labels": ["harassment"], "text": "What a pathetic excuse for a developer"}
ana@lab:~/guard$ guard modeval data/forum.jsonl --category harassment --threshold 0.5 --show
category harassment: 15 of 60 messages labelled harassment by a person
threshold 0.50
              labelled yes  labelled no
flagged                11            4
not flagged             4           41
precision 0.73   recall 0.73
  recall, messages in en: 11 of 13
  recall, messages in pt: 0 of 2
  MISSED         m08 0.00  u r an id1ot
  MISSED         m10 0.00  Seu idiota, ninguém te contrata
  MISSED         m11 0.00  Vai catar coquinho, incompetente
  MISSED         m15 0.00  Such a brilliant idea, genius. Really.
  FALSE POSITIVE m32 0.90  He called me an idiot in the chat, can a moderator look?
  FALSE POSITIVE m33 0.80  Is 'stupid' too strong for a band name in a logo brief?
  FALSE POSITIVE m34 0.60  My client said my work was garbage. How do I answer politely?
  FALSE POSITIVE m57 0.60  What a clown I was, I forgot the attachment
```

## Dois números, e quanto cada um custa a alguém

As quatro células são o resultado inteiro. Precisão e recall (em português também se diz revocação)
são dois jeitos de lê-las:

- **Precisão** é quantas das mensagens marcadas eram mesmo assédio: 11 de 15, 0.73. As outras 4 são
  pessoas cujas mensagens foram barradas à toa.
- **Recall** é quantas das mensagens de assédio foram marcadas: 11 de 15, 0.73. As 4 perdidas são
  mensagens que chegaram ao alvo.

Os dois darem 0.73 aqui é coincidência deste conjunto. Eles respondem a perguntas diferentes, e andam
em direções opostas quando o limiar muda, que é a próxima seção.

## Lendo os erros

Os totais dizem com que frequência; o `--show` diz o quê, e os erros têm padrões que um total esconde.

As quatro mensagens **perdidas** são um insulto escrito com um dígito, `id1ot`, uma ironia e dois
insultos em português. As linhas por idioma põem número no último caso: o recall é 11 de 13 em inglês
e **0 de 2 em português**. O substituto não sabe nada de português, então esse é o caso extremo dele.
Classificadores reais treinados sobretudo com texto em inglês costumam mostrar uma versão mais branda
da mesma diferença. Numa empresa brasileira, um classificador avaliado só em mensagens em inglês nunca
foi avaliado de verdade.

Os quatro **falsos positivos** são mais incômodos. O `m32` é alguém relatando que foi chamado de
idiota, e o `m34` é alguém perguntando como responder a um cliente que chamou o trabalho dele de lixo.
O `m33` pergunta sobre uma palavra para o logo de uma banda, e o `m57` é alguém chamando a si mesmo
de palhaço. Nenhum é assédio, e dois são alvos dele perguntando o que fazer. Um filtro que bloqueia
relatos de assédio ensina às pessoas que relatar faz com que sejam bloqueadas.

Sessenta mensagens bastam para ver esses padrões e são poucas para confiar numa taxa até a segunda
casa decimal: duas mensagens em português não dizem nada preciso sobre o recall em português. O
conjunto é material para aprender o método. Um real cresce a cada mensagem que um moderador revisa,
porque cada revisão é um rótulo novo.
