---
title: O problema dos objetos pequenos
version: 1
---

**Muitos objetos pequenos tornam cara toda operação cobrada por requisição e barata toda operação
cobrada por byte**, e um projeto que escreve um objeto por evento escolhe o lado caro sem perceber. O
armazenamento de um milhão de objetos de 4 KB é o armazenamento de 4 GB. As requisições deles são as
requisições de um milhão de objetos, toda vez que alguém os lê, lista, copia ou passa para outra
classe.

O aplicativo da Quitanda manda um pequeno evento JSON a cada toque: 2 milhões deles por mês, cerca de
4 KB cada. O primeiro projeto escreve cada evento como um objeto próprio, e um painel lê todos eles toda
manhã para desenhar o último mês. O programa abaixo dá o preço disso, e de outros três projetos, a
partir da tabela. Salve-o como `~/aws/reads.py`:

```schooling-example
{"language": "python", "file": "reads.py", "parts": [{"code": "\"\"\"What reading costs against what storing costs, for S3 in sa-east-1.\"\"\"\nimport math\n\n# USD, from `python3 prices.py s3 transfer`\nSTORE = 0.04050          # Standard, per GB-month\nPUT = 0.00700 / 1000     # PUT, COPY, POST, LIST, per request\nGET = 0.00056 / 1000     # GET and the rest, per request\nOUT = [(10_240, 0.15000), (40_960, 0.13800), (102_400, 0.12600), (None, 0.11400)]\nDAYS = 30\n\n\n", "note": "**Os quatro preços são linhas da tabela**, e os preços de requisição são divididos por 1.000 porque a tabela os imprime por mil. `OUT` são as quatro faixas de transferência para a internet, cada uma um número de GB e o preço dela: 10 TB, depois 40, depois 100, depois o resto."}, {"code": "def egress(gb):\n    \"\"\"USD for gb sent to the internet in one month, tier by tier.\"\"\"\n    usd, left = 0.0, gb\n    for size, price in OUT:\n        step = left if size is None else min(left, size)\n        usd += step * price\n        left -= step\n        if left <= 0:\n            break\n    return usd\n\n\n", "note": "Um preço em faixas é uma escada, não uma tarifa única: os primeiros 10.240 GB do mês a 0,15, os 40.960 seguintes a 0,138, e assim por diante. Cada degrau leva tanto do que sobra quanto a faixa dele comporta."}, {"code": "def gb(objects, kb):\n    return objects * kb / 1024 / 1024\n\n\ndef money(x):\n    return '-' if x is None else f'{x:,.2f}'\n\n\n", "note": "Uma contagem de objetos de um tamanho em KB, em GB. E uma coluna de dinheiro que imprime um traço para um preço que a tabela não tem."}, {"code": "def show(name, stored_gb, puts, gets, out):\n    store = stored_gb * STORE\n    requests = puts * PUT + gets * GET\n    total = None if out is None else store + requests + out\n    print(f'{name:<32}{money(store):>9}{money(requests):>10}{money(out):>11}{money(total):>11}')\n\n\n", "note": "Uma linha da tabela: um mês de armazenamento, um mês de requisições, um mês de transferência para fora, e a soma."}, {"code": "events = gb(2_000_000, 4)\nfiles = math.ceil(events * 1024 / 64)\nprint(f'{\"a month\":<32}{\"storage\":>9}{\"requests\":>10}{\"transfer\":>11}{\"total\":>11}')\nshow('2M events of 4 KB, read daily', events, 2_000_000, 2_000_000 * DAYS, 0)\nshow(f'the same, in {files} files of 64 MB', events, files, files * DAYS, 0)\nshow('500 GB of images, 20 TB out', 500, 0, 52_000_000, egress(20_480))\nshow('the same behind CloudFront', 500, 0, 2_600_000, None)\n", "note": "**Quatro projetos, uma linha cada.** Os eventos são escritos uma vez no mês e cada um é lido uma vez por dia. Os mesmos bytes empacotados em arquivos de 64 MB são escritos e lidos como arquivos. As imagens são uma biblioteca de 500 GB da qual saem 20 TB por mês, cerca de 52 milhões de downloads de 400 KB. Atrás do CloudFront, 95 de cada 100 downloads saem do cache dele, e o preço dele para entregá-los não está na tabela."}]}
```

```
ana@laptop:~/aws$ python3 reads.py
a month                           storage  requests   transfer      total
2M events of 4 KB, read daily        0.31     47.60       0.00      47.91
the same, in 123 files of 64 MB      0.31      0.00       0.00       0.31
500 GB of images, 20 TB out         20.25     29.12   2,949.12   2,998.49
the same behind CloudFront          20.25      1.46          -          -
```

**O mês do painel dá 47,91, dos quais 0,31 são armazenamento.** O resto são requisições: 2.000.000 de
`PUT`s a 0,00700 o milhar dá 14,00, e 2.000.000 de `GET`s por dia durante 30 dias são 60 milhões a
0,00056 o milhar, 33,60. Ler custa mais de cem vezes o que guardar custa, e nada nos dados mudou além
de como foram cortados.

**Empacotar os eventos em arquivos de 64 MB leva as requisições a 0,00**: 123 arquivos, escritos uma
vez e lidos 123 vezes por dia, custam frações de centavo. Os bytes guardados são os mesmos 7,63 GB.
Esse é um dos motivos de lagos de dados manterem arquivos grandes, e a lição 19 volta a isso: um motor
de consulta que lê um lago paga por cada arquivo que abre, além dos bytes, e a conta de requisições é a
parte disso que uma tabela de preços mostra.

## De onde vêm os objetos pequenos

Ninguém projeta um milhão de arquivos minúsculos de propósito. Eles chegam:

- **de streams**, onde algo escreve o que chegou nos últimos segundos, o que a lição 21 encontra com o
  Firehose e o buffer dele;
- **de partições finas demais para os dados**, um prefixo por hora por cliente, cada um com um arquivo
  de poucas linhas;
- **de projetos de um objeto por registro**, o evento acima, cômodo de escrever e ruinoso de ler.

A cura é a mesma toda vez: escrever menos objetos, e maiores, ou compactar os pequenos em grandes numa
rotina. E as classes de arquivo da lição 2 castigam objetos pequenos duas vezes, já que um evento de
4 KB no Glacier Instant Retrieval é cobrado como 128 KB e cada leitura dele é uma requisição a 0,01000 o
milhar, quase dezoito vezes o `GET` do Standard.

As duas últimas linhas da tabela são da próxima seção.
