---
title: Um data warehouse que você opera, e um a que você só pergunta
version: 1
---

**O Synapse Analytics é um workspace que guarda dois motores de SQL diferentes sob um nome só**, e a
diferença entre eles é a diferença entre ter um data warehouse e alugar respostas. Esta seção é
ensinada a partir da documentação da Microsoft e não foi executada: nenhum emulador responde ao Synapse,
e o resto da lição diz com clareza o que o substitui.

| | pool de SQL dedicado | pool de SQL serverless |
|---|---|---|
| o que é | um data warehouse, com as tabelas guardadas no formato dele | um motor que lê arquivos no lago |
| você provisiona | um tamanho em unidades de data warehouse, de `DW100c` a `DW30000c` | nada: todo workspace tem um, chamado `Built-in` |
| os dados | carregados nas tabelas do pool | ficam no lago como Parquet, CSV ou Delta |
| você paga por | cada hora em que o pool roda, pelo tamanho, mais o armazenamento | os dados que cada consulta processa, por terabyte |
| quando ninguém pergunta | ainda é cobrado, a menos que você o pause | não custa nada |

## O pool dedicado

**Um pool de SQL dedicado é um data warehouse massivamente paralelo: um nó de controle que planeja cada
consulta e nós de computação que a executam em pedaços.** O tamanho dele é um número de unidades de data
warehouse, que compra processador, memória e entrada e saída juntos; `DW100c` é o menor, e cada degrau
acima compra mais nós de computação para os mesmos dados. Seja qual for o tamanho, toda tabela é
dividida em 60 distribuições, e cada nó de computação trabalha na parte dele. A próxima seção é sobre
como as linhas são atribuídas às distribuições, porque isso decide se os nós trabalham juntos ou ficam
esperando uns aos outros.

**Um pool pausado cobra o armazenamento e não a computação**, e pausar é a opção que mais importa para
um data warehouse usado algumas horas por dia. O relatório noturno da Quitanda roda por uma hora; um pool
ligado o dia todo para ele paga vinte e três horas de nada. Pausar e retomar levam minutos, e um pool
pausado não responde consulta nenhuma, então o agendamento precisa saber quando os relatórios rodam.

## O pool serverless

**O pool serverless lê os arquivos onde eles estão**, pelo `OPENROWSET`, que nomeia os arquivos e o
formato deles, ou por tabelas externas definidas sobre uma pasta. Uma consulta sobre o lago fica assim,
no dialeto de T-SQL do Synapse; ela é mostrada e não executada:

```sql
SELECT payment, COUNT(*) AS orders, SUM(total_cents) / 100.0 AS reais
FROM OPENROWSET(
    BULK 'https://stquitandalakeprd.dfs.core.windows.net/lake/orders/dt=*/*.parquet',
    FORMAT = 'PARQUET'
) AS orders
GROUP BY payment;
```

**Ele é cobrado pelos dados que cada consulta processa**, que a documentação conta como os dados lidos,
mais os dados movidos entre os passos dele e qualquer coisa gravada, com mínimo de 10 MB por consulta e
toda consulta arredondada para cima até o próximo megabyte. Não há nada para provisionar nem para pausar,
e uma consulta descuidada sobre uma pasta grande é cobrada por cada byte dela. Então o layout dos
arquivos é a tabela de preços: o que uma pergunta consegue pular, ela não paga. As seções 04 e 05 desta
lição medem isso com um substituto, e a lição 18 volta ao assunto com o Delta Lake.

**Os dois não são rivais.** Um formato comum é o lago como o depósito de tudo, o serverless para
explorá-lo e para perguntas feitas de vez em quando, e um pool dedicado só para as tabelas consultadas o
dia todo por painéis que não podem esperar. A lição 17 é o Microsoft Fabric, para onde a Microsoft está
levando as mesmas ideias, sob uma capacidade só em vez de dois motores.
