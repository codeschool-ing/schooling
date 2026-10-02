---
title: Trabalhar dentro do limite
version: 1
---

A resposta óbvia para uma janela cheia é uma janela maior, e as janelas cresceram muito. Isso ajuda
menos do que parece. Uma janela maior custa mais em cada pedido (lição 3), ainda tem uma borda, e
um modelo não lê um contexto muito longo por igual. **A pergunta útil não é quanto cabe, e sim o
que o modelo precisa ver neste pedido**, e dela saem cinco hábitos.

## Manter a instrução

A seção anterior mostrou o `tok fit` mantendo o prompt de sistema, descartasse o que descartasse.
Faça o mesmo em tudo o que construir: as regras e o formato vão em todo pedido, e são a última coisa
a cortar. Quando o contexto é longo, também ajuda repetir a instrução que mais importa logo antes da
pergunta, onde o modelo a lê por último. A lição 22 trata de escrever o prompt de sistema em si.

## Levar uma nota adiante

Descartar vezes antigas perde o que foi dito nelas. A solução é **guardar o que importava num
formato que custe menos do que as vezes custavam**: uma nota curta, escrita quando as vezes estão
para sair, que viaja na parte que nunca é cortada. Eis a mesma conversa com uma frase a mais no
prompt de sistema, "Noted earlier in this conversation: the customer is Bruno and he is allergic to
nuts.", cortada para o mesmo orçamento de 120:

```
ana@lab:~/pe$ tok fit chat-noted.json -b 120
budget 120, system prompt 71
  dropped  1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  dropped  2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  dropped  3 user        11  Are you open on Sunday morning?
  dropped  4 assistant   23  Yes, on Sundays we open at 08:00 and c
  kept     5 user        10  And on a public holiday?
  kept     6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 116 tokens, 3 of 7 turns
```

As mesmas quatro vezes foram descartadas, o prompt de sistema cresceu de 53 tokens para 71, e **a
alergia sobreviveu**, porque não está mais numa vez. A nota custou 18 tokens em cada pedido; as
quatro vezes que ela substituiu custavam 75.

Numa aplicação de verdade, a nota é escrita por um segundo pedido, mais barato, a um modelo: resumir
as vezes que vão sair, guardando tudo o que o usuário disse sobre si mesmo. Um resumo pode deixar de
fora o único detalhe que importava tão facilmente quanto o corte, então o prompt de resumo precisa
dizer o que tem de sobreviver. Este foi escrito pelo curso como ilustração:

```localised
Estas vezes vão ser removidas da conversa. Em no máximo duas frases,
anote tudo o que o cliente disse sobre si mesmo (nome, alergias,
preferências) e qualquer promessa que o assistente fez. Não escreva
mais nada.
```

## Enviar o que a pergunta precisa, não tudo o que você tem

O manual da equipe do café são seis arquivos curtos:

```
ana@lab:~/pe$ tok count handbook/*.md
tokens  words  chars  file
    70     55    310  handbook/allergens.md
    60     44    249  handbook/deliveries.md
    65     46    261  handbook/hours.md
    58     50    260  handbook/loyalty.md
    74     62    318  handbook/refunds.md
    48     35    209  handbook/wifi.md
```

Entre 48 e 74 tokens cada. Colar tudo em cada pedido é barato aqui e um desperdício em qualquer
lugar de verdade, onde um manual tem centenas de páginas. Uma pergunta sobre o Wi-Fi dos clientes
precisa de uma linha do `wifi.md`, e os outros arquivos custam tokens e ainda são **texto que o
modelo precisa atravessar** para achar a linha que responde. A recuperação encontra os trechos que
combinam com a pergunta e envia só esses.

::: track ai
A lição 11 apresenta a recuperação, e o curso `rag` da sua trilha a constrói direito, com busca pelo
sentido e não só pelas palavras.
:::

::: track *
A lição 11 apresenta a recuperação: procurar no material os trechos que combinam com a pergunta e
pôr só esses no prompt.
:::

## Cortar um documento longo em pedaços

Algumas tarefas precisam do documento inteiro: o resumo de um contrato, todas as datas de um ano de
atas. Quando ele não cabe, **divida-o em pedaços que caibam com espaço para a resposta, dê a mesma
instrução a cada pedaço e junte as respostas** num último pedido. Duas coisas dão errado. Um fato pode ser cortado ao meio na fronteira entre dois
pedaços, e é por isso que os pedaços costumam se sobrepor em algumas frases. E uma pergunta que
precisa de duas partes distantes do documento ao mesmo tempo, como "a cláusula 9 contradiz a
cláusula 2?", não pode ser respondida por nenhum pedaço sozinho.

## Não confiar no meio de um contexto longo

Um modelo com uma janela enorme consegue receber um livro inteiro, e daí não segue que ele lê cada
página igualmente bem. Um estudo de 2023, "Lost in the Middle: How Language Models Use Long
Contexts", deu aos modelos um conjunto longo de documentos com a resposta em pontos diferentes. Eles
usavam a informação do **começo e do fim** do contexto muito melhor que a do meio. Os
modelos melhoraram desde então, e o conselho que saiu daí continua barato de seguir:

- ponha a instrução e o material mais importante no começo ou no fim, não enterrados entre outros
  documentos;
- envie menos trechos, mais bem escolhidos, em vez de muitos com pouca relação;
- se você precisa de um fato de um contexto longo, teste com esse fato em posições diferentes antes
  de confiar no resultado.

Os cinco hábitos voltam ao `toylm` perguntado sobre o domingo. O modelo só responde com o que está
na frente dele, e decidir o que está na frente dele é trabalho seu, não do modelo.
