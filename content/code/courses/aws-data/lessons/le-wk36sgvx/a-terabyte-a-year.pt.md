---
title: Um terabyte por um ano, em cada classe
version: 1
---

**A classe mais barata para guardar dados é a mais cara para lê-los de volta**, e o único jeito de
escolher é pôr os dois números lado a lado para os dados em questão. Um terabyte é um bom tamanho para
raciocinar; digamos que sejam as exportações de pedidos da Quitanda de cinco anos. O programa abaixo
dá o preço dele, por um ano, em cada classe, e soma quanto custaria ler o terabyte inteiro de volta uma
vez. Salve-o como `~/aws/year.py` com o botão de copiar, como a lição 1 fez com a tabela de preços.

```schooling-example
{"language": "python", "file": "year.py", "parts": [{"code": "\"\"\"A terabyte for a year in each S3 class, and reading it back once.\"\"\"\n\nTB = 1024        # GB in a terabyte, as the price list counts them\nMONTHS = 12\n\n", "note": "Um terabyte são 1.024 GB, porque o gigabyte da lista de preços é 2 elevado a 30 bytes. Mude `TB` para dar preço a outro volume."}, {"code": "# class: (USD per GB-month, USD per GB read back), from `python3 prices.py s3`.\n# None is a price the sheet does not print.\nPRICES = {\n    'Standard':                    (0.04050, 0.0),\n    'Standard-IA':                 (0.02210, 0.01000),\n    'One Zone-IA':                 (0.01770, None),\n    'Glacier Instant Retrieval':   (0.00830, 0.03000),\n    'Glacier Flexible, standard':  (0.00765, 0.01400),\n    'Deep Archive, standard':      (0.00320, 0.02800),\n    'Deep Archive, bulk':          (0.00320, 0.00800),\n}\n\n\n", "note": "**Todo número aqui é uma linha do bloco do S3**, copiada à mão. O Standard não cobra nada para ler de volta. A taxa de recuperação do One Zone-IA não está na tabela, então ela é `None` em vez de um chute, e o programa imprime um traço no lugar. O Deep Archive aparece duas vezes, uma por tier de restauração."}, {"code": "def money(x):\n    return '-' if x is None else f'{x:,.2f}'\n\n\n", "note": "Um preço desconhecido sai como um traço, nunca como zero."}, {"code": "print(f'{\"class\":<30}{\"a year\":>10}{\"read once\":>11}{\"total\":>10}')\nfor name, (store, read) in PRICES.items():\n    year = TB * store * MONTHS\n    once = None if read is None else TB * read\n    total = None if once is None else year + once\n    print(f'{name:<30}{money(year):>10}{money(once):>11}{money(total):>10}')\n", "note": "Um ano é o volume vezes o preço mensal vezes doze. Ler tudo de volta uma vez é o volume vezes o preço de recuperação, e só o armazenamento do ano é certo; quantas vezes os dados são lidos é a parte que um projeto chuta."}]}
```

```
ana@laptop:~/aws$ python3 year.py
class                             a year  read once     total
Standard                          497.66       0.00    497.66
Standard-IA                       271.56      10.24    281.80
One Zone-IA                       217.50          -         -
Glacier Instant Retrieval         101.99      30.72    132.71
Glacier Flexible, standard         94.00      14.34    108.34
Deep Archive, standard             39.32      28.67     67.99
Deep Archive, bulk                 39.32       8.19     47.51
```

## Lendo a tabela

**O Standard custa 497,66 pelo ano e o Deep Archive 39,32**, e essa diferença é a razão de existirem
classes de arquivo. Ler o terabyte de volta uma vez não muda a ordem: 8,19 na velocidade bulk do
Deep Archive, 28,67 na velocidade padrão, e ele continua sendo a linha mais barata. Um terabyte lido uma vez por ano é caso de
arquivo.

**O Glacier Instant Retrieval é a classe em que as leituras mais pesam.** O ano dele dá 101,99 e uma
leitura completa dá 30,72, quase um terço do ano de novo. Leia o terabyte inteiro quatro vezes e as
leituras, 122,88, custam mais que o armazenamento. Com cerca de onze leituras completas por ano,
101,99 + 11 × 30,72 = 439,91, ele está chegando perto dos 497,66 do Standard, e com treze já passou:
101,99 + 13 × 30,72 = 501,35. O Instant Retrieval é para dados lidos raramente e necessários na hora
quando são, como as imagens de um pedido que um cliente contesta meses depois.

**O Standard-IA fica entre os dois**: 271,56 pelo ano, 10,24 por leitura completa. A mesma conta põe o
ponto de equilíbrio dele com o Standard em cerca de 22 leituras completas por ano,
(497,66 − 271,56) / 10,24 = 22,08. Dados lidos toda semana saem mais baratos no Standard; dados lidos
a cada trimestre saem mais baratos no Standard-IA.

## O que a tabela deixa de fora

Três coisas, e as duas primeiras podem, cada uma, virar a ordem do avesso:

- **as requisições.** Cada objeto lido é um `GET`, e nas classes de arquivo também uma requisição de
  restauração. Um terabyte de arquivos de 1 GB são 1.024 deles, o que não custa nada que valha
  imprimir. Um terabyte de arquivos de 10 KB são cerca de cem milhões, e a lição 5 dá o preço do que
  isso faz;
- **as durações e os tamanhos mínimos** da seção sobre o que uma classe troca. A tabela supõe que todo
  objeto fica um ano inteiro e tem mais de 128 KB;
- **o tempo.** Os 8,19 do Deep Archive vêm com até 48 horas de espera, que é um preço pago em outra
  coisa que não dinheiro.
