---
title: CSV, e a vírgula dentro de um campo
version: 1
---

O CSV parece o mais simples dos quatro formatos: uma linha por registro, os campos separados por
vírgulas, uma linha de cabeçalho com o nome das colunas. Uma planilha o abre, e toda linguagem
também. Ele é também o que **falha sem avisar**, e o motivo está no nome. A vírgula separa os
campos, e a vírgula é também um caractere comum que os campos contêm.

## Uma resposta que é lida e está errada

Aqui o café pediu o cardápio em CSV com três colunas, e este é o tipo de resposta que volta. Ela
foi gravada num arquivo na bancada e lida com o módulo `csv` do Python, que imprime quantos campos
encontrou em cada linha e quais eram:

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

Então um prompt que quer CSV diz as regras em voz alta, e o curso escreveu este como ilustração:

```localised
Devolva o cardápio em CSV com exatamente três colunas: item,price,notes.
Escreva primeiro a linha de cabeçalho. Ponha entre aspas duplas todo
campo que contenha vírgula ou aspas duplas, e escreva uma aspa dupla
dentro de um campo como duas aspas duplas. Escreva os preços com ponto
como separador decimal: 18.50, não 18,50. Nenhum outro texto.
```

A última regra remove a causa mais comum do problema em vez de contorná-la com aspas. Vale fazer
isso sempre que você controla o formato, e a vírgula decimal brasileira é um caso em que controla.

## Conferindo uma resposta em CSV

Como o leitor não reclama, **a conferência fica por sua conta**, e ela é curta: toda linha tem tantos
campos quanto o cabeçalho. A primeira captura teria falhado nela em duas linhas. Conte os campos de
cada linha antes de usar qualquer um, e trate uma diferença do jeito que a primeira seção de leitura
trata uma resposta JSON que não é lida.

Quando os dados têm aninhamento, campos opcionais ou texto livre longo, essa conferência é um sinal
de alerta sobre a escolha do formato. O JSON põe aspas em toda string por regra e recusa o que não
consegue ler, então é a coisa mais segura para pedir a um modelo, e um programa pode transformá-lo
em CSV depois com uma biblioteca que nunca esquece uma aspa.
