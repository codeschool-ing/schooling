---
title: Crawlers, e o que o crawler do moto não faz
version: 1
---

**Um crawler é um programa que a AWS roda para ler arquivos e escrever o catálogo por você.**
Apontado para um prefixo, ele lista o que há lá, abre uma amostra dos arquivos, descobre o formato e
as colunas deles, e cria ou atualiza tabelas e partições para combinar. É a resposta para "tenho um
bucket de arquivos e não faço ideia do que há neles", e uma resposta ruim para "meu job gravou mais
um dia", que é o caso que a maioria dos lagos tem toda noite.

O moto guarda a definição de um crawler e não roda nada dela, então esta seção tem duas metades: o
que foi registrado, e o que um crawler de verdade teria feito com a mesma definição.

## A definição

```
ana@laptop:~/aws$ aws glue create-crawler --name orders-crawler --role arn:aws:iam::123456789012:role/quitanda-glue-crawler --database-name quitanda --targets 'S3Targets=[{Path=s3://quitanda-curated-prod/orders/,SampleSize=5}]' --schema-change-policy UpdateBehavior=LOG,DeleteBehavior=LOG --recrawl-policy RecrawlBehavior=CRAWL_NEW_FOLDERS_ONLY --schedule 'cron(30 3 * * ? *)'
ana@laptop:~/aws$ aws glue get-crawler --name orders-crawler --query 'Crawler.[State,Schedule.State,SchemaChangePolicy.UpdateBehavior,RecrawlPolicy.RecrawlBehavior]' --output text
READY	SCHEDULED	LOG	CRAWL_NEW_FOLDERS_ONLY
```

Toda configuração voltou como foi enviada, e cada uma é uma decisão sobre a qual um crawler de
verdade age:

- **`SampleSize=5`** lê cinco arquivos por pasta em vez de todos. A amostra deixa o crawl rápido num
  prefixo grande, e quer dizer que um esquema é deduzido de cinco dias e suposto para os outros 26.
- **`UpdateBehavior=LOG`** manda relatar uma mudança de esquema no log em vez de escrevê-la na
  tabela. O padrão, `UPDATE_IN_DATABASE`, reescreve a tabela no momento em que um arquivo discorda
  dela, e é assim que uma única exportação malformada muda o tipo de uma coluna para toda consulta na
  manhã seguinte.
- **`DeleteBehavior=LOG`** deixa uma tabela no lugar quando os arquivos dela somem. As outras opções
  a marcam como obsoleta, que é o padrão, ou a apagam do catálogo.
- **`CRAWL_NEW_FOLDERS_ONLY`** visita só as pastas que ainda não viu, o que transforma um crawl
  noturno de três anos num crawl de um dia. A terceira opção, o modo de eventos, lê as notificações
  de objetos novos do S3 em vez de listar qualquer coisa.
- **`cron(30 3 * * ? *)`** é 03:30 em UTC, porque os agendamentos do Glue são escritos em UTC. Em São
  Paulo isso é meia-noite e meia, o que vale saber antes de marcar um crawl para "depois da
  exportação" e vê-lo rodar antes dela.

## A execução que nunca termina

```
ana@laptop:~/aws$ aws glue start-crawler --name orders-crawler
ana@laptop:~/aws$ aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text
RUNNING	RUNNING
ana@laptop:~/aws$ sleep 10; aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text
RUNNING	RUNNING
ana@laptop:~/aws$ aws glue get-tables --database-name quitanda --query 'TableList[].Name' --output text
orders
ana@laptop:~/aws$ aws glue stop-crawler --name orders-crawler
ana@laptop:~/aws$ sleep 10; aws glue get-crawler --name orders-crawler --query 'Crawler.[State,LastCrawl.Status]' --output text
STOPPING	STOPPING
```

**`RUNNING`, dez segundos depois ainda `RUNNING`, e o catálogo só tem a tabela que esta lição fez à
mão.** Parado, ele foi para `STOPPING` e ficou lá. O moto nunca leva um crawler além desses estados
e nunca abre um arquivo, então nada nesta seção passou por crawl. O que vem a seguir é o
comportamento documentado da AWS, não rodado aqui.

## O que um crawl de verdade faz

Um crawler de verdade começa pelos **classificadores**: pequenos reconhecedores, tentados em ordem,
cada um respondendo se um arquivo é do formato dele e com que certeza. O Glue tem os embutidos para
CSV, JSON, Parquet, ORC, Avro, XML e formatos comuns de log, e você pode pôr os seus antes, um padrão
grok para uma linha de log ou um CSV com um delimitador próprio. O classificador vencedor dá o
esquema da amostra.

Depois ele **agrupa**. Arquivos sob um prefixo cujos esquemas são parecidos o bastante viram uma
tabela, e as pastas abaixo viram partições: `dt=2026-10-01/` dá uma chave de partição `dt`, e uma
pasta sem `name=` dá uma chamada `partition_0`. Quando os esquemas são diferentes demais, um crawler
faz uma tabela para cada pasta, e um lago com uma exportação esquisita pode acordar com uma tabela
para cada uma de 31 pastas. A configuração que evita isso é a que pede um único esquema por caminho,
e o hábito que evita isso é não passar crawler num prefixo cujo arranjo você já conhece.

**Um crawl é cobrado por DPU-hora, por segundo, com um mínimo de dez minutos por execução**, pela
linha de crawler da tabela, 0,69 dólar, a mesma de um job. Uma DPU é uma unidade de computação que o
Glue dimensiona para o crawl, e é a AWS que escolhe quantas. Com uma DPU, a execução mínima custa 0,69 × 10 / 60 = 0,115 dólar. Um crawl noturno que nunca termina mais rápido que o mínimo dá 31 × 0,115 = 3,565 dólares em outubro, por um trabalho que uma chamada `batch-create-partition` de
quem grava faz dentro da faixa grátis.
