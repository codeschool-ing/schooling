---
title: CSV, e a vírgula dentro de um campo
version: 2
---

O CSV parece o mais simples dos quatro formatos: uma linha por registro, os campos separados por
vírgulas, uma linha de cabeçalho com o nome das colunas. Uma planilha o abre, e toda linguagem
também. Ele é também o que **falha sem avisar**, e o motivo está no nome. A vírgula separa os
campos, e a vírgula é também um caractere comum que os campos contêm.

## Uma resposta que é lida e está errada

Eis um cardápio em CSV com três colunas, com o erro que quem escreve CSV mais comete. O curso
escreveu este, e ele é lido com o módulo `csv` do Python, que imprime quantos campos encontrou em
cada linha e quais eram:

```
ana@lab:~/pe$ cat replies/menu.csv
item,price,notes
flat white,12.00,oat milk at no extra cost
soup of the day,18,50,tomato
cinnamon bun,9.00,contains nuts, eggs and milk
ana@lab:~/pe$ python3 -c "import csv, sys; [print(len(row), row) for row in csv.reader(open(sys.argv[1]))]" replies/menu.csv
3 ['item', 'price', 'notes']
3 ['flat white', '12.00', 'oat milk at no extra cost']
4 ['soup of the day', '18', '50', 'tomato']
4 ['cinnamon bun', '9.00', 'contains nuts', ' eggs and milk']
```

Leia as duas últimas linhas contra o cabeçalho. A sopa foi escrita com a vírgula decimal
brasileira, `18,50`, e por isso **o preço saiu como `18` e as observações como `50`**, com `tomato`
empurrado para uma quarta coluna que o cabeçalho nunca nomeou. A observação do pão de canela foi
cortada em duas na sua própria vírgula.

**Nada falhou.** Não há mensagem de erro nem código de saída para conferir: para o leitor, essas são
linhas de quatro campos, o que o CSV permite. Um programa que pega o segundo campo como preço cobra
18 pela sopa e segue em frente. Essa é a diferença em relação às respostas JSON da primeira seção de
leitura desta lição, que o parser recusou na hora.

## Aspas são a correção, e precisam ser pedidas

A regra do próprio CSV é que um campo que contém vírgula vai entre aspas duplas. O mesmo cardápio,
com aspas, pelo mesmo leitor:

```
ana@lab:~/pe$ cat replies/menu-quoted.csv
item,price,notes
flat white,12.00,oat milk at no extra cost
soup of the day,"18,50",tomato
cinnamon bun,9.00,"contains nuts, eggs and milk"
ana@lab:~/pe$ python3 -c "import csv, sys; [print(len(row), row) for row in csv.reader(open(sys.argv[1]))]" replies/menu-quoted.csv
3 ['item', 'price', 'notes']
3 ['flat white', '12.00', 'oat milk at no extra cost']
3 ['soup of the day', '18,50', 'tomato']
3 ['cinnamon bun', '9.00', 'contains nuts, eggs and milk']
```

Toda linha tem três campos, e o leitor removeu as aspas. Um campo que contém aspas duplas também tem
regra: a aspa é escrita duas vezes, `"the ""house"" blend"`. Um modelo que viu muito CSV conhece
essas regras, e as **aplica com menos confiabilidade do que uma biblioteca de CSV**, porque está
escrevendo texto provável e não executando a regra.

## O que o modelo escreveu

Peça ao modelo local o mesmo cardápio, escrito do jeito que o café escreve os preços:

```
ana@lab:~/pe$ cat prompts/menu.txt
Return Café Aurora's menu as CSV with three columns: item,price,notes.
The menu: flat white, R$ 12,00, oat milk at no extra cost; soup of the day,
R$ 18,50, tomato; cinnamon bun, R$ 9,00, contains nuts, eggs and milk.
ana@lab:~/pe$ ask - --temperature 0 --plain < prompts/menu.txt > replies/menu-model.csv
ana@lab:~/pe$ cat replies/menu-model.csv
Here is Café Aurora's menu in CSV format with three columns: item, price, and notes:

"item","price","notes"
"flat white","12,00","oat milk at no extra cost"
"soup of the day","18,50","tomato"
"cinnamon bun","9,00","contains nuts, eggs and milk"
ana@lab:~/pe$ python3 -c "import csv, sys; [print(len(row), row) for row in csv.reader(open(sys.argv[1]))]" replies/menu-model.csv
3 ["Here is Café Aurora's menu in CSV format with three columns: item", ' price', ' and notes:']
0 []
3 ['item', 'price', 'notes']
3 ['flat white', '12,00', 'oat milk at no extra cost']
3 ['soup of the day', '18,50', 'tomato']
3 ['cinnamon bun', '9,00', 'contains nuts, eggs and milk']
```

Ele pôs aspas em todos os campos, então as vírgulas decimais estão a salvo, e pôs uma frase na
frente. **A frase é uma linha válida de três campos**, `Here is ... item`, ` price` e ` and notes:`,
cortada nas próprias vírgulas, então uma conferência que conta campos a aprova. O cabeçalho de
verdade chega na terceira linha.

Então um prompt que quer CSV diz as regras em voz alta:

```
ana@lab:~/pe$ cat prompts/menu-rules.txt
Return the menu as CSV with exactly three columns: item,price,notes.
Write the header line first. Put every field that contains a comma
or a double quote inside double quotes, and write a double quote
inside a field as two double quotes. Write prices with a full stop
as the decimal separator: 18.50, not 18,50. No other text.

The menu: flat white, R$ 12,00, oat milk at no extra cost; soup of the day,
R$ 18,50, tomato; cinnamon bun, R$ 9,00, contains nuts, eggs and milk.
ana@lab:~/pe$ ask - --temperature 0 < prompts/menu-rules.txt
"item","price","notes"
"flat white","R$ 12,00","oat milk at no extra cost"
"soup of the day","R$ 18,50","tomato"
"cinnamon bun","R$ 9,00","contains nuts, eggs and milk"
-- llama3.2:3b, finish: stop, prompt 155 tokens, output 61 tokens
```

A frase sumiu e as aspas estão certas, e **os preços ficaram com a vírgula decimal e o `R$`**, a
única regra que o prompt deu com um exemplo. A última regra remove a causa mais comum do problema
em vez de pôr aspas em volta dela, o que vale pedir onde quer que você controle o formato, e
continua sendo um pedido: é a conferência que diz que ele foi ignorado.

## Conferindo uma resposta em CSV

Como o leitor não reclama, **a conferência fica por sua conta**, e ela é curta: a primeira linha é
exatamente o cabeçalho que você pediu, e toda linha depois dela tem tantos campos quanto o
cabeçalho. O primeiro cardápio falha na segunda metade em duas linhas, e a primeira resposta do
modelo falha na primeira metade logo na primeira linha. Confira as duas coisas antes de usar
qualquer campo, e trate uma falha do jeito que a primeira seção de leitura trata uma resposta JSON
que não é lida.

Quando os dados têm aninhamento, campos opcionais ou texto livre longo, essa conferência é um sinal
de alerta sobre a escolha do formato. O JSON põe aspas em toda string por regra e recusa o que não
consegue ler, então é a coisa mais segura para pedir a um modelo, e um programa pode transformá-lo
em CSV depois com uma biblioteca que nunca esquece uma aspa.
