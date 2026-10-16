---
title: Um job do Glue, e o cluster que não é seu
version: 1
---

**Um job do Glue é um script e um tamanho, e a AWS fornece o Spark para rodá-lo.** Você escreve um
programa Python contra o Spark, põe no S3 e diz ao Glue quantos workers de qual tipo usar. A cada
execução o Glue liga essa quantidade de máquinas, roda o script e as tira de novo. Não há cluster
entre uma execução e outra, então nada para atualizar, nada parado e nada para esquecer ligado, e a
conta é a execução: os workers, multiplicados pelos segundos em que ficaram ligados.

A imagem errada é que "serverless" quer dizer nenhuma capacidade para escolher. A capacidade é a
primeira coisa que uma definição de job pede, e é paga quer o script a mantenha ocupada ou não. Dez
workers rodando um script que precisava de dois custam dez.

## As palavras que uma definição de job usa

O Glue mede capacidade em **DPUs**, unidades de processamento de dados, e a AWS define uma como 4
vCPUs e 16 GB de memória. Um tipo de worker é um número de DPUs por worker:

| tipo de worker | DPUs | para que serve |
|---|---:|---|
| `G.1X` | 1 | a escolha comum para um job em lote |
| `G.2X` | 2 | jobs com pouca memória: joins largos, shuffles grandes |
| `G.4X`, `G.8X` | 4, 8 | os jobs em lote mais pesados |
| `G.025X` | 0,25 | jobs de streaming, que rodam o tempo todo com pouco |

**As DPUs de uma execução são os workers vezes as DPUs de cada um**, o driver incluído: dez workers
`G.1X` são dez DPUs, e um deles coordena em vez de calcular. O tipo do script também é uma escolha:
`glueetl` é Spark, `gluestreaming` é Spark lendo um stream, e `pythonshell` é Python puro em um
dezesseis avos de DPU ou em uma inteira, sem Spark nenhum. E `--glue-version` escolhe o Spark que a
execução recebe: o Glue 5.0 é Spark 3.5.

**Uma execução do Glue 2.0 em diante é cobrada por segundo, com um minuto como o mínimo que uma
execução custa.** As versões anteriores cobravam no mínimo dez minutos, o que vale saber pela linha
que o moto imprime abaixo.

## O que o moto faz com um job

O terminal é o da lição 1: o moto rodando no terminal dele e as quatro linhas de "O seu
laboratório, em resumo" da lição 1 digitadas neste. O script da próxima seção vai para o S3, e um
job o nomeia:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-glue-prod
make_bucket: quitanda-glue-prod
ana@laptop:~/aws$ aws s3 cp orders_etl.py s3://quitanda-glue-prod/scripts/orders_etl.py --only-show-errors
ana@laptop:~/aws$ aws glue create-job --name orders-etl --role arn:aws:iam::123456789012:role/quitanda-glue-etl --command Name=glueetl,ScriptLocation=s3://quitanda-glue-prod/scripts/orders_etl.py,PythonVersion=3 --glue-version 5.0 --worker-type G.1X --number-of-workers 10 --timeout 60 --default-arguments '{"--job-bookmark-option": "job-bookmark-enable"}'
{
    "Name": "orders-etl"
}
ana@laptop:~/aws$ aws glue start-job-run --job-name orders-etl
{
    "JobRunId": "jr_abcdd673ba3667e392d422417578d9435f2fe7b6912898e12172173557f5f595"
}
ana@laptop:~/aws$ aws glue get-job-run --job-name orders-etl --run-id jr_abcdd673ba3667e392d422417578d9435f2fe7b6912898e12172173557f5f595 --query 'JobRun.[JobRunState,ExecutionTime,GlueVersion,WorkerType,NumberOfWorkers,DPUSeconds]' --output text
SUCCEEDED	123	0.9	G.1X	10	None
ana@laptop:~/aws$ aws glue get-job --job-name orders-etl --query 'Job.GlueVersion' --output text
5.0
```

**`SUCCEEDED` em `123` segundos, e nada rodou.** O script nem foi aberto: o moto não tem Spark, e
toda execução de todo job volta `SUCCEEDED` com os mesmos 123, uma constante e não uma medida. A
execução também diz Glue `0.9` enquanto o job diz `5.0`, porque o moto preenche um padrão próprio, e
`DPUSeconds`, o campo que a AWS preenche para a conta de algumas execuções, está vazio. **Nada nessa
linha é evidência sobre o script**, e é por isso que a lição 1 chamou um sucesso do moto de afirmação
sobre a requisição. A definição do job é guardada fielmente, e esta lição usa o moto exatamente para
isso: registrar o que um job é. O que ele faz roda de verdade duas seções adiante, sem o Glue.

## Os dois preços

```
ana@laptop:~/aws$ python3 prices.py glue
AWS public price list, sa-east-1, USD, excluding tax

Glue, USD
  ETL job, per DPU-hour                                 0.69000  DPU-hour
  ETL job, Flex, per DPU-hour                           0.45000  DPU-hour
  crawler, per DPU-hour                                 0.69000  DPU-hour
  Data Catalog, per 100,000 objects beyond free         1.00000  month
  Data Catalog, per million requests beyond free        1.00000  million
```

**0,69 dólar por DPU-hora, ou 0,45 no Flex**, a classe de execução para jobs que podem esperar. Uma
execução Flex usa capacidade que a AWS tem sobrando, então pode começar mais tarde e demorar mais, e
custa cerca de um terço a menos pelas mesmas DPU-horas. A última seção desta lição faz a conta do job
noturno da Quitanda dos dois jeitos.
