---
title: O que reduz o problema, e o que não reduz
version: 1
---

O primeiro impulso é acrescentar uma linha ao prompt: "Não invente coisas." Não custa nada e ajuda
muito pouco, porque um modelo não sabe quais das respostas prováveis dele são inventadas; se
soubesse, não as escreveria. **O que funciona é fechar, de fora, a distância entre o provável e o
verdadeiro**: pôr o texto verdadeiro onde o modelo consegue vê-lo, tornar provável uma recusa
honesta e conferir o que volta contra algo que o modelo não escreveu.

## Ancorar a resposta em fontes que você fornece

Um modelo perguntado de memória sobre as regras de reembolso do café não tem em que se apoiar além
do que regras de reembolso costumam dizer. Dê as regras a ele, e a continuação mais provável passa a
ser uma que as repete. O `retrieve --prompt` da bancada monta esse tipo de prompt: ele acha as
linhas do manual que combinam com a pergunta e as põe acima dela, numeradas, com uma instrução:

```
ana@lab:~/pe$ retrieve "Can I get a refund in cash if I paid by card?" --prompt
Answer the question using only the sources below. Cite each source you use
as [1], [2]. If the sources do not contain the answer, say that the handbook
does not say, and do not answer from general knowledge.

[1] (refunds.md) Refunds are made to the card or method used to pay, never in cash for a card payment.
[2] (refunds.md) A refund above R$ 100 needs the shift manager's approval.
[3] (loyalty.md) Stamps cannot be exchanged for cash or for food.

Question: Can I get a refund in cash if I paid by card?
```

Três coisas nesse prompt fazem o trabalho. **As fontes estão no texto**, então os fatos agora são a
continuação provável, e não um palpite sobre cafés em geral. Elas são **numeradas**, então a
resposta pode dizer qual usou. E a primeira linha limita a resposta a elas. Eis uma resposta que um
modelo poderia dar, escrita pelo curso como ilustração:

```localised
Não. O reembolso volta para o cartão ou meio com que você pagou, nunca
em dinheiro para um pagamento com cartão [1].
```

O `[1]` é o que torna a resposta conferível: um leitor, ou um programa, pode ir à fonte 1 e ver se
ela diz aquilo.

::: track ai
A lição 11 trata dessa técnica, a geração aumentada por recuperação, e o curso `rag` da sua trilha
constrói a recuperação direito.
:::

::: track *
A lição 11 trata dessa técnica, a geração aumentada por recuperação: achar os trechos certos e
pô-los no prompt.
:::

## Tornar "não sei" uma resposta provável

A ancoragem tem uma armadilha própria. A recuperação sempre devolve as melhores correspondências
que tem, e a melhor correspondência pode não ter nada a ver. Pergunte ao manual quem é o dono do
café:

```
ana@lab:~/pe$ retrieve "Who owns the café?" --prompt
Answer the question using only the sources below. Cite each source you use
as [1], [2]. If the sources do not contain the answer, say that the handbook
does not say, and do not answer from general knowledge.

[1] (hours.md) On public holidays the café follows the Sunday hours.
[2] (hours.md) Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.

Question: Who owns the café?
```

**Nenhuma das fontes diz nada sobre um dono.** Elas apareceram porque mencionam o café. Um prompt
que só dissesse "use estas fontes" deixaria o modelo com duas linhas sobre horários e uma pergunta
que não dá para responder com elas, e a continuação mais provável de uma pergunta é uma resposta. É
por isso que a instrução tem a segunda frase: se as fontes não contêm a resposta, diga que o manual
não diz. **Uma saída explícita transforma a resposta honesta numa resposta provável.** A resposta
que essa instrução quer produzir, escrita pelo curso como ilustração:

```localised
O manual não diz quem é o dono do café.
```

Uma resposta curta assim é um sucesso, e precisa ser tratada como tal onde quer que as respostas
sejam medidas. Um teste que só conta perguntas respondidas premia exatamente o comportamento que
esta seção tenta eliminar.

## Pedir citações literais, e conferi-las

Uma referência como `[1]` aponta para uma fonte. Uma **citação literal** vai além: é a frase exata
em que a afirmação se apoia, e uma frase exata pode ser conferida por um programa, sem ler nem
julgar nada. Eis essa conferência feita com `grep`, uma vez para uma citação que uma resposta
poderia dar para a regra de reembolso e outra para uma que uma resposta poderia inventar:

```
ana@lab:~/pe$ grep -rF "never in cash for a card payment" handbook/
handbook/refunds.md:Refunds are made to the card or method used to pay, never in cash for a card payment.
ana@lab:~/pe$ grep -rF "cash refunds are available on request" handbook/ || echo "not in the handbook"
not in the handbook
```

A primeira está no `refunds.md`, palavra por palavra. A segunda não aparece em lugar nenhum, então o
que a resposta construiu em cima dela não tem fonte, por mais razoável que soe. **Uma citação que
não está na fonte é uma alucinação que você pegou automaticamente.** Pedir citações custa alguns
tokens na resposta, e torna possível a conferência mais barata que existe.

## Conferir as afirmações que importam

Nem toda resposta pode ser conferida por um programa. As outras ainda precisam de conferência
sempre que uma resposta errada custaria alguma coisa:

- verifique as referências: uma citação, um link, uma lei, uma função de uma biblioteca existem ou
  não existem, e descobrir leva um minuto;
- faça uma segunda pergunta que deveria concordar com a primeira: a lição 27 faz a mesma pergunta
  várias vezes e compara as respostas, e a discordância é sinal de que o modelo está chutando;
- mantenha uma pessoa no circuito onde um erro chegaria a um cliente, a um paciente ou a um
  tribunal, de modo que o modelo faça o rascunho e alguém responsável assine.

## Baixar a temperatura não resolve

A temperatura (lição 13) controla o quanto o sorteio é ousado. Em 0, o modelo pega sempre a nota
mais alta, e isso soa como o ajuste seguro:

```
ana@lab:~/pe$ toylm generate "the soup of the day is" --temperature 0 --samples 3
[seed 1] tomato.
[seed 2] tomato.
[seed 3] tomato.
```

Três respostas idênticas, e **consistente não é o mesmo que correto**. `tomato` tem a nota mais alta
porque o arquivo a menciona mais vezes, e a sopa de hoje pode muito bem ser a de lentilha. Uma
temperatura baixa faz o modelo repetir a resposta mais provável toda vez, inclusive quando a mais
provável é a inventada. É o ajuste certo para algumas tarefas, e não controla se a resposta é verdadeira.

Todos os remédios que funcionam têm uma ideia em comum: **a saída do modelo é um indício, não um
fato**. Dê a ele o material para acertar, dê um jeito de ele dizer que não consegue, e confira o que
ele devolve contra algo que ele não escreveu.
