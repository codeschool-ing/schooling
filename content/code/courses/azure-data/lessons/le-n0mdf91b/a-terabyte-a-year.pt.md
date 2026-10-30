---
title: Um terabyte por um ano, em cada tier
version: 1
---

**O tier mais barato para guardar dados é o mais caro para lê-los**, e o único jeito de escolher é pôr
os dois números lado a lado para os dados em questão. Um terabyte é um bom tamanho para raciocinar;
digamos que sejam cinco anos de exportações de pedidos da Quitanda. O programa abaixo calcula quanto
ele custa por um ano em cada tier, soma o que custaria lê-lo inteiro de volta uma vez e põe preço no
erro da seção anterior: guardar dez dias e apagar.

**Os preços nele são ilustrativos.** A lição 1 explica por que este curso não cita nenhum preço do
Azure: a máquina em que as transcrições foram gravadas não alcançava a tabela de preços. Os números
abaixo são redondos, na ordem documentada, e feitos para serem trocados. Rode o `prices.py` da lição 1
para cada tier, ponha os preços de verdade, e o mesmo programa faz as mesmas contas com eles.

```schooling-example
{"language": "python", "file": "year.py", "parts": [{"code": "\"\"\"A terabyte for a year in each access tier, at ILLUSTRATIVE prices.\"\"\"\n\nTB = 1024        # GB in a terabyte, as the price sheet counts them\nMONTHS = 12\n", "note": "Um terabyte são 1.024 GB, porque o gigabyte da tabela de preços é 2 elevado a 30 bytes. Mude `TB` para calcular outro volume."}, {"code": "\n# tier: (USD per GB-month kept, USD per GB read back, minimum days billed)\n# The prices are ROUND NUMBERS FOR THE ARITHMETIC, not Azure's: replace them\n# with what `python prices.py Storage <tier> LRS` prints. The days are documented.\nTIERS = {\n    \"Hot\":     (0.020, 0.00, 0),\n    \"Cool\":    (0.010, 0.01, 30),\n    \"Cold\":    (0.004, 0.03, 90),\n    \"Archive\": (0.002, 0.02, 180),\n}\n", "note": "**Todo preço aqui é ilustrativo**, escolhido para as contas serem fáceis de seguir e os tiers manterem a ordem documentada. Os dias mínimos são os da Microsoft. O preço de leitura do archive é o da prioridade padrão de reidratação."}, {"code": "\nprint(f\"{'tier':<9}{'a year':>9}{'read once':>11}{'total':>9}{'kept 10 days':>14}\")\nfor tier, (keep, read, minimum) in TIERS.items():\n    year = TB * keep * MONTHS\n    once = TB * read\n    ten_days = TB * keep * max(10, minimum) / 30\n    print(f\"{tier:<9}{year:>9.2f}{once:>11.2f}{year + once:>9.2f}{ten_days:>14.2f}\")\n", "note": "Um ano é o volume vezes o preço mensal vezes doze, e ler tudo de volta uma vez é o volume vezes o preço de leitura. A última coluna guarda o terabyte por dez dias e apaga, cobrado pelo mínimo quando o mínimo é maior, com o mês contado como 30 dias."}], "output": "tier        a year  read once    total  kept 10 days\nHot         245.76       0.00   245.76          6.83\nCool        122.88      10.24   133.12         10.24\nCold         49.15      30.72    79.87         12.29\nArchive      24.58      20.48    45.06         12.29\n"}
```

Rode com `python year.py`; a saída está embaixo do programa.

## Lendo a tabela

**Hot custa 245,76 pelo ano e archive 24,58**, dez vezes menos, e essa diferença é o motivo de o
archive existir. Ler o terabyte de volta uma vez soma 20,48 ao archive e ele continua sendo de longe a
linha mais barata. Dados lidos uma vez por ano, ou menos, vão para o archive, desde que horas de espera
sejam aceitáveis quando forem lidos.

**Cold é o tier em que as leituras mais pesam.** O ano dele é 49,15 e uma leitura completa é 30,72,
mais da metade do ano de novo. Leia o terabyte inteiro quatro vezes e o cold custa 49,15 + 4 × 30,72 =
172,03; com sete leituras completas ele chega a 264,19, acima dos 245,76 do hot. Cold é para dados
quase nunca lidos, e necessários na hora quando são.

**Cool fica entre os dois**: 122,88 pelo ano e 10,24 por leitura completa. O ponto de equilíbrio com o
hot é (245,76 − 122,88) / 10,24 = 12 leituras completas por ano. Com esses preços, dados lidos toda
semana saem mais baratos em hot e dados lidos a cada trimestre saem mais baratos em cool. Com os
preços reais do Azure o ponto de equilíbrio muda, e o programa o encontra do mesmo jeito.

**A última coluna é a cobrança por exclusão antecipada em ação.** Dez dias em hot custam 6,83, um
terço de mês. Dez dias em cool custam 10,24, porque são cobrados como trinta; em cold, 12,29, cobrados
como noventa; e em archive também 12,29, cobrados como cento e oitenta. Para dados que ficam dez dias,
hot é o tier mais barato e archive não é, o contrário da primeira coluna.

## O que a tabela deixa de fora

Três coisas, e a primeira sozinha pode virar a ordem:

- **operações.** Toda leitura é uma requisição, e cada tier cobra requisições de um jeito, mais caro
  quanto mais frio. Um terabyte de arquivos de 1 GB são 1.024 leituras; um terabyte de arquivos de
  10 KB são cerca de cem milhões, e a lição 7 calcula o que isso faz;
- **a reidratação de prioridade alta**, que custa mais por gigabyte que o preço padrão usado aqui;
- **o tempo.** Os 20,48 do archive vêm com até quinze horas de espera em prioridade padrão, um preço
  pago em outra coisa que não dinheiro.
