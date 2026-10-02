---
title: O prompt ancorado
version: 1
---

Colar trechos acima de uma pergunta não basta. Um modelo que recebe algumas fontes e uma pergunta
mistura as fontes, sem cerimônia, com o que achar provável, e quem lê não sabe de onde veio cada
frase. **Um prompt ancorado manda o modelo responder só a partir das fontes, citá-las e dizer quando
elas não contêm a resposta.** O `retrieve --prompt` monta um:

```
ana@lab:~/pe$ retrieve --prompt "when does the café open on sundays"
Answer the question using only the sources below. Cite each source you use
as [1], [2]. If the sources do not contain the answer, say that the handbook
does not say, and do not answer from general knowledge.

[1] (hours.md) On Sundays it opens at 08:00 and closes at 12:00.
[2] (hours.md) On public holidays the café follows the Sunday hours.
[3] (hours.md) Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.

Question: when does the café open on sundays
```

Três partes, numa ordem fixa: a instrução, as fontes numeradas com o arquivo de onde cada uma veio,
e a pergunta por último. Esse texto inteiro é o que seria enviado ao modelo, e é a única coisa que o
modelo saberia sobre o café.

O que um modelo poderia responder foi escrito por este curso como ilustração; nenhum modelo foi
rodado:

```localised
Aos domingos o café abre às 08:00 e fecha às 12:00 [1].
```

## Por que a citação importa

O `[1]` é a parte que torna a resposta conferível. **Uma resposta citada pode ser rastreada até uma
linha do manual**, por uma pessoa ou por um programa que confere se cada número citado existe e se o
horário mencionado aparece naquela fonte. Uma resposta sem citação precisa ser aceita na confiança, e
a lição 5 explicou por que texto fluente não merece isso.

As citações também são como você percebe que o modelo foi além das fontes. Uma frase sem citação
numa resposta ancorada é uma frase para olhar de perto.

## "O manual não diz" é uma resposta certa

A instrução permite mais um resultado, e é ele que protege você. O manual não diz nada sobre
cachorros, então a busca não acha nada, e o prompt sai sem fonte nenhuma:

```
ana@lab:~/pe$ retrieve --prompt "can I bring my dog"
Answer the question using only the sources below. Cite each source you use
as [1], [2]. If the sources do not contain the answer, say that the handbook
does not say, and do not answer from general knowledge.


Question: can I bring my dog
```

A resposta que a instrução pede, de novo escrita pelo curso como ilustração:

```localised
O manual não diz se cachorros podem entrar no café.
```

**Sem essa permissão, um modelo que recebe uma pergunta tende a produzir uma resposta**, porque uma
resposta é a continuação provável de uma pergunta (lição 1), e a resposta provável sobre cachorros em
cafés não é a política deste café. Dizer "o manual não diz" é o sistema funcionando, e um assistente
de atendimento que sabe dizer isso merece confiança nas perguntas que responde. A lição 5 trata do
problema mais amplo das respostas sem nada por trás.
