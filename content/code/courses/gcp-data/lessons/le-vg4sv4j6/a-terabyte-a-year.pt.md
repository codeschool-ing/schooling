---
title: Um tebibyte por um ano, em cada classe
version: 1
---

**A classe mais barata para guardar dados é a mais cara para lê-los**, e o único jeito de escolher é
pôr os dois números lado a lado para os dados em questão. Um tebibyte é um bom tamanho para raciocinar;
digamos que sejam as exportações de pedidos da Quitanda de cinco anos. O programa abaixo calcula o
preço dele por um ano em cada classe, soma o que ler tudo de volta uma vez custaria, e calcula quantas
leituras completas por ano levam cada classe a custar o mesmo que o Standard. Salve-o como
`~/gcp/year.py` com o botão de copiar.

```schooling-example
{"language": "python", "file": "year.py", "parts": [{"code": "\"\"\"A tebibyte for a year in each Cloud Storage class, and reading it back.\"\"\"\n\nTIB = 1024        # GiB in a TiB: the price list counts gibibytes\nMONTHS = 12\n\n", "note": "Um tebibyte são 1.024 GiB, porque a lista de preços do Google é por gibibyte, 2 elevado a 30 bytes. Mude `TIB` para calcular outro volume."}, {"code": "# class: (USD per GiB-month, USD per GiB read back), southamerica-east1,\n# from cloud.google.com/storage/pricing, read 2026-10-30.\nPRICES = {\n    'Standard': (0.035, 0.00),\n    'Nearline': (0.020, 0.01),\n    'Coldline': (0.007, 0.02),\n    'Archive':  (0.003, 0.05),\n}\nSTANDARD_YEAR = TIB * PRICES['Standard'][0] * MONTHS\n\n\n", "note": "**Todo número aqui é uma linha da página de preços**: os preços de armazenamento de São Paulo e as taxas de recuperação, que são as mesmas em toda região. O Standard não cobra nada para ler de volta. `STANDARD_YEAR` é a linha com que todas as outras classes são comparadas."}, {"code": "print(f'{\"class\":<10}{\"a year\":>9}{\"read once\":>11}{\"total\":>9}{\"reads to pass Standard\":>24}')\nfor name, (store, read) in PRICES.items():\n    year = TIB * store * MONTHS\n    once = TIB * read\n    passes = '-' if read == 0 else f'{(STANDARD_YEAR - year) / once:.1f}'\n    print(f'{name:<10}{year:>9.2f}{once:>11.2f}{year + once:>9.2f}{passes:>24}')\n", "note": "Um ano é o volume vezes o preço mensal vezes doze, e uma leitura completa é o volume vezes a taxa de recuperação. A última coluna é quantas leituras completas por ano levam a classe mais barata a custar o mesmo que o Standard: o que se economiza no ano, dividido pelo que custa uma leitura."}]}
```

```
ana@laptop:~/gcp$ python3 year.py
class        a year  read once    total  reads to pass Standard
Standard     430.08       0.00   430.08                       -
Nearline     245.76      10.24   256.00                    18.0
Coldline      86.02      20.48   106.50                    16.8
Archive       36.86      51.20    88.06                     7.7
ana@laptop:~/gcp$ python3 -c 'print(round((86.016 - 36.864) / (51.2 - 20.48), 1), round((245.76 - 86.016) / (20.48 - 10.24), 1))'
1.6 15.6
```

## Lendo a tabela

**O Standard custa 430,08 pelo ano e o Archive 36,86**, e essa diferença é a razão de existirem as
classes mais frias. Ler o tebibyte de volta uma vez não muda a ordem: 51,20 em taxas de recuperação,
num total de 88,06, ainda é a linha mais barata. Um tebibyte lido uma vez por ano pertence ao Archive.

**A última coluna é onde cada classe para de compensar.** O Archive passa o Standard em 7,7 leituras
completas por ano, porque a taxa dele, de 0,05 por GiB, é a mais alta. O Coldline aguenta até 16,8, e o
Nearline, cuja taxa é a mais baixa, até 18,0. São os pontos em que cada classe custa o mesmo que o
Standard; não são os pontos em que uma classe fria ultrapassa outra, e o segundo comando acima calcula
esses.

Os dois números dele são onde a classe mais barata de cada par deixa de ser mais barata. Coldline e
Archive custam o mesmo em 1,6 leitura completa por ano, (86,02 − 36,86) / (51,20 − 20,48). Nearline e
Coldline custam o mesmo em 15,6, (245,76 − 86,02) / (20,48 − 10,24). **Então, para um tebibyte guardado
um ano inteiro em São Paulo, o Archive ganha até uma leitura e pouco, o Coldline daí até umas quinze, o
Nearline na faixa estreita até dezoito, e o Standard acima disso**, que é uma leitura a cada três
semanas. O Coldline é barato aqui, a um quinto do preço do Standard, e é por isso que cobre tanto da
faixa.

## Uma estadia mais curta

A tabela supõe um ano, e uma estadia mais curta que o mínimo de uma classe muda a resposta por
completo. Digamos que o tebibyte seja uma cópia temporária guardada por 60 dias e nunca lida. Cada
classe cobra o maior entre os 60 dias e o seu mínimo, contando um mês como 30 dias:

```
ana@laptop:~/gcp$ python3 -c 'for name, price, least in [("Standard", 0.035, 0), ("Nearline", 0.020, 30), ("Coldline", 0.007, 90), ("Archive", 0.003, 365)]: print(f"{name:<10}{1024 * price * max(60, least) / 30:>7.2f}")'
Standard    71.68
Nearline    40.96
Coldline    21.50
Archive     37.38
```

**O Coldline é o mais barato, com 21,50, e o Archive, o mais barato da tabela de um ano, custa
37,38**, porque cobra 365 dias por dados que ficaram 60. O Nearline cobra exatamente o que guardou,
40,96, e o Standard 71,68. Uma cópia temporária guardada por 20 dias poria o mínimo de 30 dias do
Nearline contra os 90 do Coldline e o nada do Standard, e a resposta mudaria de novo. Antes do preço
por GiB-mês, pergunte quanto tempo os dados ficam.

## O que a tabela deixa de fora

Duas coisas, e cada uma delas pode virar a ordem:

- **requisições.** Cada objeto escrito é uma operação Class A e cada um lido uma Class B, ao preço da
  sua classe. Um tebibyte de arquivos de 1 GiB são 1.024 deles, o que não custa nada que valha imprimir.
  Um tebibyte de arquivos de 10 KB são uns cem milhões, e em Archive isso dá 5.000 USD para escrevê-los,
  antes de guardar um byte. A aula 5 calcula o que isso faz;
- **a rede.** Uma leitura que sai da região paga pelos dados que atravessam, em toda classe, e isso
  também é a aula 5.

O que a tabela não precisa é de uma coluna para esperar. Toda classe entregou o primeiro byte em
milissegundos, então a escolha é feita só pelo dinheiro, e é isso que a torna uma conta.
