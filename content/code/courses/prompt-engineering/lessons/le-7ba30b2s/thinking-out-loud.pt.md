---
title: Pedindo os passos antes da resposta
version: 2
---

A imagem comum é a de que o modelo calcula a resposta em algum lugar lá dentro e depois a relata,
de modo que pedir a ele para "mostrar a conta" só acrescenta palavras para o seu proveito. Não é
assim que ele produz texto. **O modelo não tem rascunho além do texto que escreve.** Pedir os
passos antes da resposta dá a ele um, e a resposta que vem depois é prevista a partir desses
passos. Isso é o prompting de cadeia de pensamento (*chain of thought*).

## Um pedido, de dois jeitos

Uma mesa do Café Aurora pede três flat whites a R$ 12 cada e duas fatias de bolo a R$ 15 cada. Paga
com um cartão fidelidade que já tem 9 carimbos, e o manual diz que o décimo café sai de graça.
Pedindo só o valor e mais nada, o modelo tem de pôr o número primeiro:

```
ana@lab:~/pe$ cat order-direct.txt
A table at Café Aurora orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. They pay with a loyalty card that already has 9 stamps, and the tenth coffee is free. How much do they pay? Reply with the amount only.
ana@lab:~/pe$ ask - --temperature 0 --plain < order-direct.txt | tee direct.txt
R$ 39
```

Pedindo, em vez disso, que ele "work it out step by step, then write the result on a last line that
starts with Answer:", que é o mesmo prompt com essa frase no lugar da última, a resposta começa
pelos passos:

```
ana@lab:~/pe$ tail -c 80 order-chain.txt
out step by step, then write the result on a last line that starts with Answer:
ana@lab:~/pe$ ask - --temperature 0 --plain < order-chain.txt | tee chain.txt
To calculate the total cost, we need to first calculate the cost of the flat whites and the cake.

Cost of flat whites: 3 x R$ 12 = R$ 36
Cost of cake: 2 x R$ 15 = R$ 30

Total cost: R$ 36 + R$ 30 = R$ 66

Since the customer has 9 stamps on their loyalty card, they have already earned 9 free coffees. However, they are ordering 3 flat whites, which means they will only get 2 free coffees (since the 10th coffee is free). So, they will pay for 1 flat white.

Cost of 1 flat white: R$ 12

Total cost: R$ 66 - R$ 12 = R$ 54

Answer: R$ 54
```

A conta de nenhuma das respostas precisa ser aceita na confiança. O Python confere o preço cheio, o
preço com um café de graça e o exemplo resolvido usado mais adiante:

```
ana@lab:~/pe$ python3 -c "print(3 * 12 + 2 * 15, 2 * 12 + 2 * 15, 2 * 9 + 11)"
66 54 29
```

A resposta direta é **R$ 39, que não é leitura nenhuma do pedido**: nem a conta cheia, nem a conta
com um café de graça. A cadeia chegou a 54, a resposta certa, e vale ler como. As três primeiras
linhas estão certas: 36, 30, 66. O parágrafo depois delas está errado em cada oração, "already earned
9 free coffees", "only get 2 free coffees", "pay for 1 flat white", e aí a linha seguinte tira um
café de 66, que é exatamente a correção certa. **A resposta está certa e o motivo dado para ela, não.**
Vale guardar isso; a próxima seção de leitura volta a esse ponto.

## Por que escrever os passos ajuda quem prevê o próximo token

A lição 1 mostrou o laço: o modelo dá nota ao próximo token a partir do texto até ali, um é
escolhido, e ele entra no texto. Na resposta direta, o primeiro token da resposta é escolhido sem
nada na frente além da pergunta. Na cadeia, quando o modelo chega a `Answer:`, o texto já contém
"Total cost: R$ 66 - R$ 12 = R$ 54". **Cada passo que ele escreveu agora é texto do qual os próximos
tokens dependem**, e a continuação provável de um texto que acabou de dizer 54 é 54.

Esse é o mecanismo inteiro, e ele explica onde a cadeia de pensamento ajuda: problemas cuja
resposta precisa de resultados intermediários, como contas sobre vários itens, uma regra aplicada
antes de uma soma, ou dois fatos combinados. Uma pergunta de um passo só ("quanto custa um flat
white?") não tem resultado intermediário para escrever, e não ganha nada quando se pede que
raciocine.

## Cadeias few-shot e zero-shot

Há dois jeitos de obter os passos.

**A cadeia de pensamento few-shot mostra no prompt um exemplo resolvido**, com os passos escritos,
e depois faz a pergunta nova. O modelo continua o padrão que viu, como na lição 21:

```
ana@lab:~/pe$ cat order-few.txt
Q: A customer orders 2 espressos at R$ 9 each and 1 cinnamon bun at R$ 11. Their loyalty card has 3 stamps; the tenth coffee is free. How much do they pay?
A: The card has 3 stamps, so these espressos are the 4th and 5th coffees. Neither is the tenth, so both are paid: 2 x 9 = 18. The bun is 11. Total: 18 + 11 = 29.
Answer: 29

Q: A table orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. Their loyalty card has 9 stamps; the tenth coffee is free. How much do they pay?
A:
ana@lab:~/pe$ ask - --temperature 0 --plain < order-few.txt | tee few.txt
To solve this problem, we need to determine how many coffees the table has ordered and how many stamps are left on their loyalty card.

The table orders 3 flat whites at R$ 12 each, which is a total of 3 x 12 = 36. They also order 2 slices of cake, which is a total of 2 x 15 = 30. The total amount they pay is 36 + 30 = 66.

Since the loyalty card has 9 stamps, and the tenth coffee is free, we need to determine how many coffees they have ordered. The tenth coffee is free, so we can assume that the table has ordered at least 9 coffees. Since they have ordered 3 flat whites, they must have ordered at least 9 flat whites to reach the 9th stamp. However, they have also ordered 2 slices of cake, which means they have ordered a total of 3 flat whites + 2 slices of cake = 5 coffees.

Since the table has ordered 5 coffees, and the loyalty card has 9 stamps, they have 4 stamps left. This means that the 6th, 7th, 8th, and 9th coffees are free. The 10th coffee is also free, so the table only pays for the 5 coffees they ordered.

The total amount they pay is 66 - 4 (free coffees) = 62.
```

O exemplo deveria ensinar o formato dos passos, até onde quebrar o problema e a linha `Answer:` no
fim; o 29 dele é conferido pela mesma linha de Python acima. Este modelo não pegou nenhum dos três.
A resposta é mais longa que o exemplo, conta as duas fatias de bolo como cafés, decide que quatro
cafés saem de graça, e termina em 62, errado, sem linha `Answer:`. A lição 21 mediu exemplos
piorando este modelo ao rotular, e esta é a mesma lição numa soma: **um exemplo é um pedido, e só a
resposta mostra se ele foi seguido.**

**A cadeia de pensamento zero-shot acrescenta só uma instrução**, sem exemplo: "pense passo a
passo" ou, melhor, uma frase que também fixe a última linha, como no segundo pedido acima. Ela é
mais barata de escrever e de enviar, e deixa o modelo escolher como dispor os passos. A lição 20
tratou do prompting zero-shot em geral; isto é a mesma ideia com uma frase que pede a conta.

Uma cadeia few-shot compensa os tokens a mais quando você precisa de uma disposição específica dos
passos, ou quando a decomposição que o próprio modelo faz vive pulando o passo que importa, e quando
um conjunto de teste mostra que o exemplo ajuda. Aqui, a instrução sozinha se saiu melhor.
