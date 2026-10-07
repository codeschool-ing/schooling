---
title: Trabalhar dentro do limite
version: 2
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
para sair, que viaja na parte que nunca é cortada. Um `sed` acrescenta uma frase ao fim do prompt de
sistema, e o resto da conversa fica como estava:

```
ana@lab:~/pe$ sed "s/The kitchen uses nuts.\"}/The kitchen uses nuts. Noted earlier in this conversation: the customer is Bruno and he is allergic to nuts.\"}/" chat.json > chat-noted.json
ana@lab:~/pe$ tok fit chat-noted.json -b 120 -w sent-noted.json
budget 120, system prompt 71
  dropped  1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  dropped  2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  dropped  3 user        11  Are you open on Sunday morning?
  dropped  4 assistant   23  Yes, on Sundays we open at 08:00 and c
  kept     5 user        10  And on a public holiday?
  kept     6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 116 tokens, 3 of 7 turns
ana@lab:~/pe$ ask --chat sent-noted.json --temperature 0
I'd be happy to recommend our Lemon Lavender Pound Cake, it's a popular choice and nut-free.
-- llama3.2:3b, finish: stop, prompt 135 tokens, output 23 tokens
```

As mesmas quatro vezes foram descartadas, o prompt de sistema cresceu de 53 tokens para 71, e **a
alergia sobreviveu**, porque não está mais numa vez. A nota custou 18 tokens em cada pedido; as
quatro vezes que ela substituiu custavam 75.

O que o modelo fez com ela é outra questão. Ele usou a alergia, e fez a mesma promessa que a resposta
com todas as vezes: um bolo sem nozes, de uma cozinha que o mesmo prompt de sistema diz usar nozes.
**Uma nota mantém a informação na janela; o que o modelo faz com ela quem decide são as
instruções**, e estas não dizem nada sobre alergias.

Numa aplicação de verdade, a nota é escrita por um segundo pedido, mais barato, a um modelo, que
recebe as vezes que vão sair e um prompt que diz o que tem de sobreviver. Um resumo pode deixar de
fora o único detalhe que importava tão facilmente quanto o corte, então o prompt precisa dizê-lo:

```
ana@lab:~/pe$ cat summarise.txt old-turns.txt
These turns are about to be removed from the conversation. In at most
two sentences, write down anything the customer said about themselves
(name, allergies, preferences) and any promise the assistant made.
Write nothing else.
user: Hi, I'm Bruno. I'm allergic to nuts, so please keep that in mind.
assistant: Thanks, Bruno. I'll keep your nut allergy in mind in everything I suggest.
user: Are you open on Sunday morning?
assistant: Yes, on Sundays we open at 08:00 and close at 12:00.
ana@lab:~/pe$ ask - --system "$(cat summarise.txt)" --temperature 0 < old-turns.txt
Bruno is allergic to nuts. I promised to keep his nut allergy in mind in everything I suggest.
-- llama3.2:3b, finish: stop, prompt 139 tokens, output 22 tokens
```

Duas frases, a alergia e a promessa, e nada sobre o horário de domingo, que o prompt de sistema já
carrega.

## Enviar o que a pergunta precisa, não tudo o que você tem

O manual da equipe do café são seis arquivos curtos. As lições seguintes fazem buscas nele, citam
trechos e os passam ao modelo, então crie-o agora, colando este bloco no terminal:

```sh
mkdir -p ~/pe/handbook
cat > ~/pe/handbook/allergens.md <<'EOF'
# Allergens

Every cake label lists the 14 major allergens it contains.
The kitchen uses nuts, so no item can be guaranteed nut-free.
Oat, soya and lactose-free milk are available for every coffee at no extra cost.
If a customer asks about an ingredient that is not on the label, ask the kitchen; never guess.
EOF
cat > ~/pe/handbook/deliveries.md <<'EOF'
# Deliveries

Bread arrives at 06:15 and milk at 06:30, at the side door.
The person opening checks the delivery note against what arrived and signs it.
A missing item is reported to the supplier the same morning, by e-mail, with the note's number.
EOF
cat > ~/pe/handbook/hours.md <<'EOF'
# Opening hours

Café Aurora opens at 07:00 and closes at 18:00 from Monday to Saturday.
On Sundays it opens at 08:00 and closes at 12:00.
The kitchen stops taking hot food orders 30 minutes before closing.
On public holidays the café follows the Sunday hours.
EOF
cat > ~/pe/handbook/loyalty.md <<'EOF'
# Loyalty card

The tenth coffee is free; stamps are counted per card, not per person.
A lost card can be replaced at the counter, and its balance is moved to the new card if the customer knows the card number.
Stamps cannot be exchanged for cash or for food.
EOF
cat > ~/pe/handbook/refunds.md <<'EOF'
# Refunds

A drink or a dish that is wrong or not as described is replaced or refunded on the spot.
Refunds are made to the card or method used to pay, never in cash for a card payment.
Money loaded onto a loyalty card is not refundable, but it never expires.
A refund above R$ 100 needs the shift manager's approval.
EOF
cat > ~/pe/handbook/wifi.md <<'EOF'
# Wi-Fi

The guest network is called aurora-guests and needs no password.
Sessions end after 2 hours and can be started again at once.
Staff devices use the network aurora-staff, which guests are never given.
EOF
```

Depois conte-os:

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
instrução a cada pedaço e junte as respostas** num último pedido. Duas coisas dão errado. Um fato
pode ser cortado ao meio na fronteira entre dois pedaços, e é por isso que os pedaços costumam se sobrepor em algumas frases. E uma pergunta que
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

Os cinco hábitos remetem ao `toylm` e à pergunta sobre o domingo. O modelo só responde com o que está
na frente dele, e decidir o que está na frente dele é trabalho seu, não do modelo.
