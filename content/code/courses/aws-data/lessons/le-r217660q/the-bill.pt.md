---
title: Quanto custa uma execução, e o job grande demais
version: 1
---

**Uma conta do Glue é uma área: DPUs na vertical, segundos na horizontal.** Toda execução é cobrada
como as DPUs que recebeu multiplicadas pelo tempo em que ficaram ligadas, pela linha que a tabela
imprimiu, e nada mais na definição do job muda o preço. Então as duas perguntas que o decidem são
quantos workers e por quanto tempo, e a segunda tem um piso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"Três execuções desenhadas na mesma escala, DPUs para cima e minutos na horizontal. Dez workers G.1X por seis minutos formam um bloco de dez DPUs de altura e seis minutos de largura: uma DPU-hora, 0,69 dólar, ou 0,45 no Flex. Dois workers por vinte segundos formam um bloco pequeno de duas DPUs de altura, dentro de uma caixa tracejada de um minuto de largura, que é o que se cobra: 0,023 dólar. Um job Python shell de um dezesseis avos de DPU por dois minutos é uma linha fina de dois minutos de largura: 0,0014 dólar.\" data-fig=\"l17-area\"><rect x=\"40\" y=\"30\" width=\"360\" height=\"100\" rx=\"0\" fill=\"var(--phosphor-dim)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"48\" y=\"44\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dez workers G.1X, 6 minutos</text><text x=\"412\" y=\"80\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">1 DPU-hora: 0,69 USD, Flex 0,45</text><rect x=\"40\" y=\"180\" width=\"60\" height=\"20\" rx=\"0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><rect x=\"40\" y=\"180\" width=\"20.0\" height=\"20\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"112\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dois workers, 20 segundos</text><text x=\"412\" y=\"190\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cobrado 1 minuto: 0,023 USD</text><rect x=\"40\" y=\"242.8\" width=\"120\" height=\"1.2\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"1\"></rect><text x=\"172\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Python shell, 1/16 de DPU, 2 minutos</text><text x=\"412\" y=\"243\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">0,0014 USD</text><line x1=\"40\" y1=\"270\" x2=\"400\" y2=\"270\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><line x1=\"40\" y1=\"270\" x2=\"40\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"40\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><line x1=\"100\" y1=\"270\" x2=\"100\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"100\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">1</text><line x1=\"160\" y1=\"270\" x2=\"160\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"160\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">2</text><line x1=\"220\" y1=\"270\" x2=\"220\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"220\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">3</text><line x1=\"280\" y1=\"270\" x2=\"280\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"280\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">4</text><line x1=\"340\" y1=\"270\" x2=\"340\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"340\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">5</text><line x1=\"400\" y1=\"270\" x2=\"400\" y2=\"274\" stroke=\"var(--wire)\" stroke-width=\"1\"></line><text x=\"400\" y=\"284\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">6</text><text x=\"412\" y=\"284\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">minutos</text><text x=\"32\" y=\"30\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><text x=\"32\" y=\"130\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">0</text><text x=\"32\" y=\"80\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">DPUs</text></svg>", "caption": "O mesmo preço por DPU-hora, três áreas. A altura é DPUs e a largura é minutos; a caixa tracejada é o mínimo de um minuto que a execução curta paga.", "same": ["DPUs"]}
```

## A noite da Quitanda, com preço

Digamos que o job noturno rode em dez workers `G.1X` e leve seis minutos. São dez DPUs por um décimo
de hora, **uma DPU-hora, 0,69 dólar por noite** no preço padrão, e 31 × 0,69 = 21,39 dólares em
outubro. O mesmo job no Flex sai a 0,45 por noite e 13,95 no mês, por aceitar que pode começar
atrasado. Um job que grava os pedidos de ontem para um relatório lido às nove da manhã quase sempre
pode esperar, e é para esse caso que o Flex existe.

**O mínimo é onde os jobs pequenos perdem.** Uma execução de dois workers que termina o trabalho em
vinte segundos é cobrada por um minuto: 2 × 1/60 × 0,69 = 0,023 dólar, três vezes os vinte segundos
que usou. Ainda é pouco, e diz algo sobre o tamanho deste job: a camada raw inteira de outubro tem
40 MB, e **um job Spark de dez workers é muito mais máquina do que 40 MB precisam**.

## Três definições do mesmo job

As definições que o moto guarda deixam a escolha concreta, mesmo que nenhuma delas rode:

```
ana@laptop:~/aws$ aws glue create-job --name orders-etl-flex --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=glueetl,ScriptLocation=s3://quitanda-glue-prod/scripts/orders_etl.py,PythonVersion=3 --glue-version 5.0 --worker-type G.1X --number-of-workers 10 --execution-class FLEX
{
    "Name": "orders-etl-flex"
}
ana@laptop:~/aws$ aws glue create-job --name orders-etl-small --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=pythonshell,ScriptLocation=s3://quitanda-glue-prod/scripts/etl.py,PythonVersion=3.9 --max-capacity 0.0625
{
    "Name": "orders-etl-small"
}
ana@laptop:~/aws$ aws glue get-jobs --query 'Jobs[].[Name,Command.Name,ExecutionClass,WorkerType,NumberOfWorkers,MaxCapacity]' --output text
orders-etl	glueetl	STANDARD	G.1X	10	None
orders-etl-flex	glueetl	FLEX	G.1X	10	None
orders-etl-small	pythonshell	STANDARD	None	None	0.0625
```

**`STANDARD` e `FLEX` diferem em uma palavra e no preço; a terceira nem é Spark.** Um job
`pythonshell` roda um programa Python puro em um dezesseis avos de DPU, `0.0625`, que é mais ou menos
o que o `etl.py` precisa. Nesse tamanho, dois minutos custam 0,0625 × 2/60 × 0,69 = 0,0014 dólar,
pouco mais de quatro centavos pelas 31 noites de outubro, contra 21,39 do job Spark. O que esse
terceiro job precisaria, e este curso não monta, é que o `etl.py`, o `lake.py` e as bibliotecas que
eles importam fossem junto com ele para o Glue.

A escolha se inverte conforme os dados crescem. Uma camada raw de alguns gigabytes por noite não
cabe mais num processo Python pequeno, e é aí que os workers do Spark merecem as DPUs deles, o
assunto para o qual o Glue foi feito. Passado um certo tamanho e uma certa regularidade, rodar o seu
próprio Spark no EMR pode custar menos que a tarifa por segundo do Glue, e a lição 24 é onde essa
linha é traçada.
