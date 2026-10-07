---
title: Onde falha
version: 2
---

Um prompt ancorado faz uma resposta valer exatamente o que valem os trechos dentro dele. A maior
parte das falhas de RAG não é do modelo: **a busca não devolveu nada, devolveu o trecho errado, ou metade do
certo, e o modelo escreveu fielmente a partir do que recebeu.** Cada uma das três dá para ver só com
o `retrieve`.

## Palavras diferentes não acham nada

O manual tem um arquivo inteiro sobre a rede de visitantes. Quando a pergunta usa outras palavras, a
busca não acha nada dele:

```
ana@lab:~/pe$ retrieve "is there wireless internet for customers"
query words: there wireless internet customers
no passage shares a word with the question
ana@lab:~/pe$ retrieve "what is the wifi password"
query words: wifi password
  2.80  wifi.md        The guest network is called aurora-guests and needs no password.
```

`wireless internet` e `Wi-Fi` querem dizer a mesma coisa para uma pessoa. Para uma busca por
palavra-chave, não têm nenhuma palavra em comum, então a primeira pergunta tira zero contra todas as
linhas. **A resposta existia, e a recuperação informou que não existia nada.** Com o prompt ancorado
da seção anterior, o modelo faz o que mandaram:

```
ana@lab:~/pe$ retrieve --prompt "is there wireless internet for customers" | ask - --temperature 0
I couldn't find any information on the availability of wireless internet for customers in the provided sources.

Handbook does not say.
-- llama3.2:3b, finish: stop, prompt 83 tokens, output 26 tokens
```

"Handbook does not say", o que é falso: um arquivo inteiro do manual é sobre a rede de visitantes.

## Um trecho cortado no lugar errado

Cada linha do manual é um trecho, e uma linha depende de outra:

```
ana@lab:~/pe$ retrieve "what time does the café open on public holidays"
query words: time caf open public holidays
  8.71  hours.md       On public holidays the café follows the Sunday hours.
  2.07  hours.md       Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
```

O primeiro trecho está exatamente certo e não diz horário nenhum: os horários estão em outra linha,
`On Sundays it opens at 08:00`, que não tem palavra em comum com a pergunta e não foi recuperada. Os
únicos horários nas fontes são os dos dias de semana. **Um modelo respondendo a partir desses dois
trechos tem uma fonte real apontando para o horário errado.** Este não caiu:

```
ana@lab:~/pe$ retrieve --prompt "what time does the café open on public holidays" | ask - --temperature 0
According to the provided sources, the café's hours on public holidays are the same as on Sundays, which is not explicitly stated in the sources. However, the source [1] states that the café follows the Sunday hours on public holidays.

Since the source [2] only provides the hours for Monday to Saturday, it does not provide information on public holidays.

Therefore, the answer is: The handbook does not say.
-- llama3.2:3b, finish: stop, prompt 130 tokens, output 85 tokens
```

Ele leu a fonte 1 direito, que feriado segue o horário de domingo, não achou horário de domingo na
frente dele, e disse que o manual não diz. É a resposta honesta ao que ele recebeu, e está errada
sobre o manual, que diz exatamente quando o café abre num feriado, numa linha que ninguém recuperou.
Outro modelo, ou este num outro dia, poderia muito bem ter escrito 07:00 e citado a fonte 2.

O lugar onde o texto é cortado em trechos, o que se chama *chunking*, decide o que pode ser achado
junto. Um corte que separa uma regra do detalhe a que ela se refere é a versão mais comum dessa
falha, e o conserto está no jeito de cortar os documentos, não no prompt.

## O trecho errado, recuperado com confiança

```
ana@lab:~/pe$ retrieve "can I get a refund for a cold coffee"
query words: get refund cold coffee
  2.67  refunds.md     A refund above R$ 100 needs the shift manager's approval.
  2.17  loyalty.md     The tenth coffee is free; stamps are counted per card, not per person.
  1.98  allergens.md   Oat, soya and lactose-free milk are available for every coffee at no extra cost.
ana@lab:~/pe$ retrieve "my drink was wrong, can I get my money back"
query words: drink wrong get money back
  5.35  refunds.md     A drink or a dish that is wrong or not as described is replaced or refunded on the spot.
  2.67  refunds.md     Money loaded onto a loyalty card is not refundable, but it never expires.
```

A primeira pergunta é respondida pela primeira regra de reembolso do manual: uma bebida que não é o
que foi descrito é trocada ou reembolsada na hora. Essa linha diz `refunded`, não `refund`, e
`drink`, não `coffee`, então não tinha palavra em comum com a pergunta e ficou de fora. No lugar dela
vieram três trechos que dividem uma palavra cada com a pergunta e respondem outra coisa. A segunda
pergunta, com as palavras do próprio manual, põe a regra certa em primeiro.

A busca não tem como saber a diferença. **Não existe uma nota que queira dizer "não relevante"**: os
três primeiros são devolvidos sejam eles quais forem. Com os três da primeira pergunta, o modelo os
julgou direito:

```
ana@lab:~/pe$ retrieve --prompt "can I get a refund for a cold coffee" | ask - --temperature 0
The handbook does not say.
-- llama3.2:3b, finish: stop, prompt 161 tokens, output 7 tokens
```

E isso também é falso, pelo mesmo motivo do Wi-Fi: o manual diz que uma bebida que não veio como
descrita é reembolsada na hora, e a busca não trouxe essa linha. O modelo acertou sobre as fontes e
errou sobre o café, e nada na resposta mostra a diferença.

## Busca por palavra e busca por significado

As três falhas vêm da mesma raiz: esta busca compara palavras, e as pessoas perguntam com palavras
diferentes das que o documento usa. O remédio usual é buscar por significado. Cada trecho e cada
pergunta viram uma lista de números, um **embedding**, produzida por um modelo treinado para que
textos de significado parecido recebam números parecidos, e a busca devolve os trechos cujos números
estão mais perto. `wireless internet` e `Wi-Fi` então caem perto um do outro.

A busca por significado tem falhas próprias, e sistemas reais muitas vezes combinam os dois tipos.
Esta lição dá o nome e para por aí.

::: track ai
Os cursos `embeddings-vectors` e `rag`, que vêm depois deste na trilha, constroem as duas metades direito:
como os embeddings são feitos e comparados, como os documentos são cortados em trechos e como medir
se a recuperação achou o trecho certo.
:::

::: track prompt security
Nesta trilha, esta lição é tudo o que há de RAG: a ideia, o prompt ancorado e as três maneiras como
ele falha. Isso basta para ler com senso crítico as respostas de um sistema de RAG e para fazer a
primeira pergunta certa quando uma delas está errada: o trecho certo foi recuperado?
:::

::: track *
Construir a recuperação direito, com embeddings, *chunking* e medição, é um assunto à parte, além
deste curso. O que esta lição dá a você é a ideia, o prompt ancorado e a primeira pergunta a fazer
quando uma resposta está errada: o trecho certo foi recuperado?
:::
