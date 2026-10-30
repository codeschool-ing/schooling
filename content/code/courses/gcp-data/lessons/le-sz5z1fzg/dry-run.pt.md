---
title: O dry run e o máximo de bytes cobrados
version: 1
---

**Um dry run pergunta ao BigQuery o que uma consulta processaria, e não roda nada.** O BigQuery analisa a
consulta, resolve as tabelas e colunas dela, aplica o filtro de partição e responde com o número de
bytes que processaria. Não custa nada: a consulta não roda, e a documentação do Google sobre estimar o
custo de consultas diz que um dry run não é cobrado. É o programa da última seção feito pelo próprio
serviço, contra a tabela real e os metadados reais. Nada nesta seção rodou, pelo motivo que a aula 13
deu: o `bq` não tem para onde ir aqui.

## Na linha de comando

Este é o comando que você digitaria, e a saída dele não aparece porque não há nenhuma para mostrar:

```sh
bq query --use_legacy_sql=false --dry_run \
  'SELECT district, SUM(total_cents) AS sales
   FROM quitanda.orders
   WHERE dt BETWEEN "2026-09-01" AND "2026-09-29"
   GROUP BY district'
```

**`--dry_run` faz o `bq` imprimir uma frase com o número de bytes que a consulta processaria** e sair.
Na tabela real esse número seriam os 15.023.069 que o `bqbill.py` imprimiu, com a diferença entre a
visão que o DuckDB tem da tabela e a do BigQuery: as mesmas linhas, os mesmos tipos, a mesma regra. O
editor de consultas do console faz o mesmo enquanto você digita, mostrando a estimativa acima do editor
antes de você apertar Run, e é o número mais útil da tela.

## Num programa

**Um programa pede um dry run pela biblioteca cliente**, e um programa é onde o hábito compensa, porque um
programa roda a mesma consulta milhares de vezes. Em Python, com a biblioteca `google-cloud-bigquery`, é
uma configuração do job:

```python
from google.cloud import bigquery

client = bigquery.Client(project='planner-dev')
config = bigquery.QueryJobConfig(dry_run=True, use_query_cache=False)
job = client.query(SQL, job_config=config)
print(job.total_bytes_processed)
```

**`use_query_cache=False` é como o próprio exemplo de dry run em Python do Google é escrito**, para a
estimativa descrever a consulta como ela rodaria, e não um resultado guardado dela, que não cobraria
nada. A biblioteca não está instalada neste laboratório, já que não há BigQuery com que ela fale, e o
bloco acima não rodou.

## O máximo de bytes cobrados

**`maximum_bytes_billed` é o veredito do dry run aplicado pelo BigQuery.** É um limite posto numa
consulta: se a consulta for cobrar mais que o limite, o BigQuery a recusa com um erro antes de ler
qualquer coisa, e a recusa não custa nada. Na linha de comando é uma flag:

```sh
bq query --use_legacy_sql=false --maximum_bytes_billed=1073741824 \
  'SELECT * FROM quitanda.orders WHERE dt = "2026-09-29"'
```

e na biblioteca é `bigquery.QueryJobConfig(maximum_bytes_billed=1073741824)`, 1 GiB. Um programa que o
põe em toda consulta que manda não pode ser o programa que lê o histórico inteiro por engano. **É a
proteção por consulta; as cotas personalizadas da aula 14 são a por dia**, e as duas são feitas para
erros diferentes: o máximo para uma consulta ruim, a cota para uma consulta razoável rodada vezes demais.

**O limite tem de ser escolhido para a consulta, não para o projeto.** Um limite de 1 GiB num painel que
lê 10 MB deixa espaço para um erro de cem vezes antes de agir; um limite de 1 GiB na transformação
noturna de uma tabela grande a recusa toda noite. O dry run é como o número é escolhido: rode uma vez,
pegue o que ele imprime e ponha o máximo com uma folga confortável acima.

## O que nenhum dos dois consegue saber

**Os dois são calculados antes de a consulta rodar, então os dois perdem o que só a execução revela.**
Numa tabela clusterizada, o dry run informa um limite superior e a conta costuma ser menor, como a aula
15 explicou, e um máximo tirado do dry run pode recusar uma consulta que de fato seria cobrada por menos.
E em preço por capacidade, nenhum dos dois diz nada sobre slots: um dry run informa bytes, e uma
consulta numa reserva é cobrada por tempo de slot, que só o grafo de execução, duas seções adiante,
mostra.
