---
title: Pedindo os passos antes da resposta
version: 1
---

A imagem comum é a de que o modelo calcula a resposta em algum lugar lá dentro e depois a relata,
de modo que pedir a ele para "mostrar a conta" só acrescenta palavras para o seu proveito. Não é
assim que ele produz texto. **O modelo não tem rascunho além do texto que escreve.** Pedir os
passos antes da resposta dá a ele um, e a resposta que vem depois é prevista a partir desses
passos. Isso é o prompting de cadeia de pensamento (*chain of thought*).

## Um pedido, de dois jeitos

Uma mesa no Café Aurora pede três flat whites a R$ 12 cada e duas fatias de bolo a R$ 15 cada. Ela
paga com um cartão fidelidade que já tem 9 carimbos, e o manual diz que o décimo café sai de graça.
Quando se pede só o valor e nada mais, o modelo tem de pôr o número primeiro. O curso escreveu esta
resposta como ilustração do que pode voltar:

```localised
R$ 66
```

Quando se pede, em vez disso, "resolva passo a passo e escreva o resultado numa última linha que
comece com Answer:", a resposta começa pelos passos. Esta também é ilustração do curso, não
captura:

```localised
Três flat whites a R$ 12 cada.
O cartão já tem 9 carimbos, então o primeiro café deste pedido é o
décimo, e sai de graça.
Sobram 2 cafés para pagar: 2 x 12 = R$ 24.
Duas fatias de bolo a R$ 15 cada: 2 x 15 = R$ 30.
Total: 24 + 30 = R$ 54.
Answer: 54
```

A aritmética de nenhuma das duas precisa ser aceita de olhos fechados. O Python confere o preço
cheio, o preço com um café de graça e o exemplo resolvido usado mais abaixo:

```
ana@lab:~/pe$ python3 -c "print(3 * 12 + 2 * 15, 2 * 12 + 2 * 15, 2 * 9 + 11)"
66 54 29
```

**66 não é um erro ao acaso: é a conta com todos os cafés pagos**, a leitura óbvia do pedido. A
regra da fidelidade precisa de um passo no meio, e a resposta direta não tinha onde pô-lo.

## Por que escrever os passos ajuda quem prevê o próximo token

A lição 1 mostrou o laço: o modelo dá nota ao próximo token a partir do texto até ali, um é
escolhido, e ele entra no texto. Na resposta direta, o primeiro token da resposta é escolhido sem
nada na frente além da pergunta. Na cadeia, quando o modelo chega a `Answer:`, o texto já contém
"o primeiro café deste pedido é o décimo, e sai de graça" e "Total: 24 + 30 = R$ 54". **Cada passo
que ele escreveu agora é texto do qual os próximos tokens dependem**, e a continuação provável de
`Total: 24 + 30 = R$` é `54`.

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
Q: A customer orders 2 espressos at R$ 9 each and 1 cinnamon bun at R$ 11. Their loyalty card has 3 stamps; the tenth coffee is free. How much do they pay?
A: The card has 3 stamps, so these espressos are the 4th and 5th coffees. Neither is the tenth, so both are paid: 2 x 9 = 18. The bun is 11. Total: 18 + 11 = 29.
Answer: 29

Q: A table orders 3 flat whites at R$ 12 each and 2 slices of cake at R$ 15 each. Their loyalty card has 9 stamps; the tenth coffee is free. How much do they pay?
A:
```

O exemplo ensina o formato dos passos, até onde quebrar o problema e a linha `Answer:` no fim. O 29
dele é conferido pela mesma linha de Python do pedido acima.

**A cadeia de pensamento zero-shot acrescenta só uma instrução**, sem exemplo: "pense passo a
passo" ou, melhor, uma frase que também fixe a última linha, como no segundo pedido acima. Ela é
mais barata de escrever e de enviar, e deixa o modelo escolher como dispor os passos. A lição 20
tratou do prompting zero-shot em geral; isto é a mesma ideia com uma frase que pede a conta.

Uma cadeia few-shot compensa os tokens a mais quando você precisa de uma disposição específica dos
passos, ou quando a decomposição que o próprio modelo faz vive pulando o passo que importa. Fora
disso, a instrução costuma bastar para começar.
