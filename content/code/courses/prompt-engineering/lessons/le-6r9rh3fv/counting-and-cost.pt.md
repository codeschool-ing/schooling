---
title: Contar tokens, e quanto eles custam
version: 1
---

Quando alguém estima o tamanho de um prompt, conta palavras, ou caracteres, porque é isso que um
editor de texto mostra. **Todo limite e todo preço de um modelo de linguagem são contados em
tokens**, e os três números não andam juntos. Dois arquivos com o horário do café, um em cada
língua, dizem a mesma coisa:

```
ana@lab:~/pe$ cat hours.en.txt hours.pt.txt
Café Aurora opens at seven and closes at six from Monday to Saturday.
On Sundays and public holidays it opens at eight and closes at noon.
The kitchen stops taking hot food orders thirty minutes before closing.
O Café Aurora abre às sete e fecha às seis, de segunda a sábado.
Aos domingos e feriados, abre às oito e fecha ao meio-dia.
A cozinha para de aceitar pedidos de comida quente trinta minutos antes de fechar.
```

O `tok count` dá tokens, palavras e caracteres de cada arquivo:

```
ana@lab:~/pe$ tok count hours.en.txt hours.pt.txt
tokens  words  chars  file
    41     37    211  hours.en.txt
    48     39    207  hours.pt.txt
```

O português tem duas palavras a mais e quatro caracteres a menos, e tem **sete tokens a mais**: 48
contra 41. Nem a contagem de palavras nem a de caracteres diriam qual arquivo era maior para um
modelo. Contada com o vocabulário mais antigo da seção anterior, a diferença aumenta:

```
ana@lab:~/pe$ tok count hours.en.txt hours.pt.txt -e cl100k_base
tokens  words  chars  file
    42     37    211  hours.en.txt
    59     39    207  hours.pt.txt
```

59 contra 42. O mesmo texto, enviado em português a um modelo que usa a `cl100k_base`, custa cerca
de dois quintos a mais do que em inglês, e enche a janela dele mais depressa. **Se os seus usuários
escrevem numa língua que não é o inglês, meça com o texto deles**, nunca com uma amostra em inglês e
uma regra de bolso.

## Por que o taxímetro corre em tokens

A lição 1 mostrou a geração como um laço: dar nota ao próximo pedaço, escolher um, juntar, dar nota
de novo. O `toylm` informava a própria contabilidade no fim de cada execução,
`prompt 4 tokens, output 2 tokens`, e uma API de modelo devolve os mesmos dois números a cada
resposta. Eles são a medida honesta do trabalho feito:

- cada token de **entrada** tem de ser lido pelo modelo antes de ele escrever qualquer coisa;
- cada token de **saída** é uma volta do laço, escrita uma depois da outra.

Por isso o provedor cobra os dois, por token, e **com preços separados**. Os tokens de entrada podem
ser processados juntos, numa passada só; os de saída não, porque cada um depende do anterior. Nas
tabelas de preço dos grandes provedores no momento em que este curso foi escrito (2026), um token de
saída custa mais que um de entrada, muitas vezes várias vezes mais. Os preços mudam, e variam entre
modelos do mesmo provedor, então o único número que vale usar é o da página de preços do provedor no
dia em que você faz a conta, com a data anotada ao lado.

## Fazendo a conta

O `tok cost` recebe um arquivo como entrada, o número de tokens de saída que você espera e dois
preços por milhão de tokens. **Os preços abaixo são ilustrativos, digitados na linha de comando**:
2 por milhão para a entrada e 8 para a saída, sem moeda definida. Não são os preços de nenhum
provedor.

```
ana@lab:~/pe$ tok cost hours.pt.txt -o 300 -i 2 -p 8
input  48 tokens x 2 per million = 0.000096
output 300 tokens x 8 per million = 0.002400
one request: 0.002496
10,000 requests: 24.96
```

A entrada são os 48 tokens que o `tok count` mediu; a saída é um palpite de 300, uma resposta longa.
Um pedido custa 0,002496, pouco demais para alguém notar, e dez mil deles custam 24,96. Encurte a
resposta esperada para 30 tokens, sem mudar mais nada:

```
ana@lab:~/pe$ tok cost hours.pt.txt -o 30 -i 2 -p 8
input  48 tokens x 2 per million = 0.000096
output 30 tokens x 8 per million = 0.000240
one request: 0.000336
10,000 requests: 3.36
```

De 24,96 para 3,36. **Aqui a saída era a maior parte da conta**, porque havia seis vezes mais tokens
de saída que de entrada e cada um custava quatro vezes mais. Com um prompt curto e uma resposta
longa, esse é o formato comum; com um documento longo colado no prompt e uma resposta de uma linha,
quem domina é a entrada. A conta é a mesma nos dois casos, e vale fazê-la antes de construir, não
depois da primeira fatura.

Três coisas deixam a conta real maior do que um prompt sugere:

- a conversa inteira é enviada de novo a cada vez (lição 2), então a décima mensagem de um chat
  **paga as nove anteriores** como entrada;
- o prompt de sistema vai junto em todo pedido, quantos forem, então um prompt longo é **pago
  milhares de vezes por dia**;
- o tamanho da saída não é você quem decide, a não ser que defina um limite, que é a lição 15.

A lição 4 trata da outra coisa contra a qual os tokens são contados: o tamanho da janela que um
modelo consegue ver de uma vez.
