---
title: Quanto custa uma tabela externa
version: 1
---

**Uma tabela externa mexe em três linhas da conta e deixa a quarta onde estava.** As consultas custam o
que custam numa tabela nativa: sob demanda, 11,25 USD por TiB em `southamerica-east1`, pelos bytes das
colunas lidas nas partições mantidas. O que muda é onde o dado é guardado e a que tarifa, se o
armazenamento um dia vira longo prazo, e os pedidos que ler arquivos faz ao Cloud Storage. Esta seção
põe preço em cada um, pela página do Cloud Storage e pela do BigQuery, ambas lidas em 2026-10-30.

## O armazenamento

**Uma tabela nativa é cobrada pelos bytes lógicos ou físicos dela; uma externa, pelo tamanho dos
arquivos.** A aula 13 precificou 1 TiB de bytes lógicos, comprimindo três para um, como tabela nativa:
23,55 USD por mês tudo ativo e lógico, 17,10 com nove décimos em longo prazo, e 13,14 na cobrança física
com nove décimos em longo prazo. O mesmo dado como arquivos Parquet comprimindo três para um é um terço de
TiB num bucket Standard, a 0,035 USD por GiB-mês:

```
ana@laptop:~/gcp$ python3 -c 'print(round(1024 / 3 * 0.035, 2), round(1024 / 3 * 0.035 * 12, 2))'
11.95 143.36
```

**11,95 USD por mês, e 143,36 por ano**, mais barato que qualquer das linhas nativas enquanto a tabela é
jovem. Mas ele nunca fica mais barato sozinho. A página de preços do BigQuery é explícita de que o longo
prazo "applies only to BigQuery storage, not to data stored in external data sources", então um bucket
Standard cobra 0,035 por um arquivo em que ninguém escreve há três anos. Uma regra de ciclo de vida da
aula 3 pode mover arquivos antigos para Nearline, a 0,02 USD por GiB-mês em São Paulo, e a aula 2
explicou o que essa classe cobra cada vez que algo a lê, que é o que uma tabela externa consultada por
analistas faz.

**E os arquivos só são guardados uma vez.** O caso de que a aula 13 avisou, a exportação carregada numa
tabela e deixada no bucket, cobrada duas vezes, não acontece: os arquivos são a tabela. Para dado que tem
de ficar no bucket de qualquer jeito, porque outros motores o leem ou porque ele é o registro do que a
exportação entregou, uma tabela externa é a versão do warehouse que não acrescenta armazenamento nenhum.

## Os pedidos

**Todo arquivo que uma consulta abre são pedidos ao Cloud Storage**, e o leitor desta aula os contou: uma
listagem do prefixo e 87 leituras com faixa para as duas colunas de setembro. O Cloud Storage os cobra por
classe, por mil, para um bucket numa região só, na página de preços dele: 0,005 USD pela Classe A, que
inclui listar, e 0,0004 USD pela Classe B, que inclui ler um objeto. Para os pedidos que o leitor desta
aula fez, por mil consultas e por um mês de execuções de hora em hora:

```
ana@laptop:~/gcp$ python3 -c 'q = 87 / 1000 * 0.0004 + 1 / 1000 * 0.005; print(round(1000 * q, 4), round(720 * q, 4))'
0.0398 0.0287
```

**Quatro centavos por mil dessas consultas, e menos de três centavos por um mês delas de hora em hora.**
Neste tamanho os pedidos são um erro de arredondamento na conta das consultas. Eles crescem com o número
de arquivos que uma consulta abre, não com os bytes que há neles, que é o problema dos arquivos pequenos
da aula 15 aparecendo como linha da fatura: os mesmos pedidos cortados em uma hora por arquivo dariam
dezesseis vezes os pedidos pela mesma resposta. Se as leituras do próprio BigQuery numa tabela externa
aparecem na conta do bucket, e quantos pedidos ele faz, é entre o leitor dele e o Cloud Storage; esta
conta precifica o leitor que rodou aqui, e é a forma do custo e não o número do BigQuery.

**A rede não custa nada, desde que os dois estejam num lugar só.** O BigQuery exige que o dataset de uma
tabela externa esteja numa localização compatível com a do bucket, e uma consulta em `southamerica-east1`
lendo um bucket em `southamerica-east1` não move dado entre regiões. O egresso da aula 5 é o que um bucket
em outra região acrescentaria, e a regra de localização existe em parte para evitar isso.

## Escolher

**Carregue numa tabela nativa** quando o warehouse é o leitor principal, a tabela é consultada com
frequência e o histórico dela vai ficar anos: armazenamento de longo prazo, clustering, resultados em
cache e as estatísticas do próprio BigQuery estão todos do lado nativo. **Deixe os arquivos no lugar,
como tabela externa ou BigLake,** quando outros motores leem os mesmos arquivos, quando o dado tem de
ficar no bucket de qualquer jeito, ou quando ele é consultado tão raramente que carregá-lo daria mais
trabalho que consultá-lo no lugar. Para a Quitanda, os pedidos noturnos vão para uma tabela nativa,
particionada e clusterizada, porque os painéis os leem toda hora; as exportações brutas ficam em
`quitanda-raw-prod` e são alcançáveis como tabela externa no dia em que alguém precisar conferir o que
uma exportação de fato entregou.
