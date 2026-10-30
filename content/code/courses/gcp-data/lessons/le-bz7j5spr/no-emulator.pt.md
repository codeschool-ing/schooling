---
title: Sem emulador, e o que fica no lugar
version: 1
---

**O BigQuery não tem emulador.** O Google publica emuladores para Pub/Sub, Firestore, Bigtable e
Spanner, e este curso roda os quatro; para o BigQuery ele não publica nenhum, e não existe
configuração da linha de comando que mande um comando `bq` para qualquer lugar que não seja o
Google. Projetos da comunidade que imitam a API existem, e nenhum deles implementa as três coisas de
que esta aula e as cinco seguintes tratam: **como o BigQuery cobra uma consulta, como ele distribui
os slots e como ele guarda uma tabela**. Um laboratório que respondesse a `bq query` com as linhas
certas e a conta errada ensinaria a metade errada, então este curso não usa nenhum.

A linha de comando diz a mesma coisa com as palavras dela. O seu terminal manda o `gcloud` para os
emuladores e nenhuma credencial para ninguém, e o `bq` é a única ferramenta sem ter para onde ir:

```
ana@laptop:~/gcp$ bq query --dry_run --use_legacy_sql=false 'SELECT 1' 2>&1 | head -2
ERROR: (bq) You do not currently have an active account selected.
Please run:
```

**O `bq` recusou antes de mandar qualquer coisa**, porque quer uma conta e a aula 1 garantiu que não
há nenhuma. Até o dry run, que não custa nada no Google Cloud e é a principal ferramenta da aula 16,
precisa do serviço de verdade para responder. Todo comando `bq` destas seis aulas aparece num bloco
`sh` simples, como o comando que você digitaria, e nenhum deles rodou.

## O que fica no lugar: o DuckDB, sobre os mesmos arquivos

**O DuckDB é um motor de banco de dados que roda dentro de um programa Python**, sem servidor, e lê
arquivos Parquet diretamente. A aula 1 o instalou no ambiente virtual, com o PyArrow para escrever
os arquivos:

```
ana@laptop:~/gcp$ python3 -c "import duckdb, pyarrow; print('duckdb', duckdb.__version__, '/ pyarrow', pyarrow.__version__)"
duckdb 1.5.6 / pyarrow 25.0.1
```

**O que o DuckDB dá a estas aulas é o SQL, rodado de verdade, sobre os mesmos arquivos que o
BigQuery carregaria.** Na próxima seção você escreve os pedidos da Quitanda em Parquet, uma pasta por
dia, e sobe os mesmos arquivos para o emulador do Cloud Storage. Daí em diante toda consulta do curso
roda duas vezes na sua cabeça: uma no DuckDB, onde devolve linhas reais de dados reais em uma fração
de segundo, e uma no BigQuery, onde devolveria as mesmas linhas e mandaria uma conta.

**Boa parte do que o BigQuery faz com uma consulta o DuckDB também faz**, e é por isso que ele é um
substituto justo e não um brinquedo. Ele é colunar, então lê só as colunas que a consulta cita. Ele
lê a data de uma pasta chamada `dt=2026-08-01` e pula as pastas que um filtro em `dt` descarta, que é
exatamente o que é a poda de partições no BigQuery. Ele guarda o mínimo e o máximo de cada coluna em
cada grupo de linhas de um arquivo Parquet e pula os grupos que um filtro não pode atingir, que é a
ideia por trás do clustering. E ele imprime o plano, com o tempo de cada passo, que a aula 16 põe ao
lado do plano do BigQuery.

## O que ele não consegue substituir

| | DuckDB, aqui | BigQuery |
|---|---|---|
| o SQL | roda, no seu laptop | roda, nos slots do Google |
| quais colunas e pastas uma consulta lê | medido | a mesma ideia, calculada |
| a conta de uma consulta | **nada**: é gratuito | bytes por tipo, arredondados, com mínimo |
| slots, estágios e shuffle | um processo, os seus núcleos | milhares de slots, o escalonador do Google |
| o tamanho guardado de uma tabela | arquivos Parquet que você mede | arquivos Capacitor que você não vê |
| time travel, fail-safe, cache, cotas | nenhum deles | todos eles |

**A conta é a primeira coisa que ele não dá, e a mais importante.** Rodar o DuckDB não custa nada,
então todo valor em dólares destas aulas é calculado, não medido. O cálculo não é um palpite: o
BigQuery documenta exatamente quantos bytes cada tipo de valor conta, e a página de preços documenta
o preço por TiB, o arredondamento e o mínimo. Duas seções adiante, esta aula começa essa conta, e a
aula 16 a transforma num programa.

**Os slots são a segunda.** O DuckDB roda uma consulta nos núcleos do seu laptop, e o BigQuery a
espalha por quantos slots decidir dar a ela. Quanto tempo uma consulta leva no DuckDB não diz nada
sobre quantas slot-horas ela usaria no BigQuery, então nenhuma aula aqui cita um número de slots como
se tivesse sido medido. A aula 14 põe preço nos slots a partir da página de preços, e a aula 16 lê o
grafo de execução do BigQuery na documentação.

**O armazenamento é a terceira.** Parquet e Capacitor são ambos colunares e comprimidos, e não são o
mesmo formato. Quando a última seção desta aula compara o tamanho dos arquivos Parquet com o tamanho
que o BigQuery cobraria, o tamanho do Parquet é uma pista de quanto essas colunas comprimem, e nunca
o número que o BigQuery imprimiria.

**E o dialeto difere nas bordas.** O SQL do BigQuery se chama GoogleSQL, e o do DuckDB segue o
PostgreSQL. Quase todo `SELECT` com `WHERE`, `GROUP BY` e `JOIN` é igual nos dois. Algumas funções
não são: o GoogleSQL escreve `DATE_TRUNC(dt, MONTH)` e o DuckDB escreve `date_trunc('month', dt)`,
com os argumentos ao contrário. Onde uma aula mostra GoogleSQL que não rodaria no DuckDB, ela avisa,
e mostra num bloco que ninguém rodou.

**Então todo número destas aulas carrega a sua origem.** Uma contagem de linhas, um tamanho de
arquivo, um plano ou um tempo são do DuckDB e foram medidos. Um número de bytes cobrados, um preço ou
um slot é calculado a partir da documentação do Google, e a conta aparece para você conferir. Nada é
apresentado como saída do BigQuery, porque nada aqui é o BigQuery.
