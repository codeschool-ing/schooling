---
title: Um esquema de nomes que sobrevive
version: 1
---

**O nome de um bucket é global e o nome de um objeto é para sempre**, e esses dois fatos são a razão
de ser de um esquema de nomes. Um nome de bucket é compartilhado por todos os projetos do Cloud
Storage, então `quitanda-raw-prod` pertence a quem o criou primeiro, em qualquer lugar do mundo. E o
nome é a única alça que um programa tem para um objeto: renomeie um e todo programa, relatório e
tabela que apontava para o nome antigo agora aponta para nada, porque num bucket de namespace plano
renomear é copiar e apagar.

## As regras para o nome de um bucket

As regras do Google para o nome de um bucket são curtas. De 3 a 63 caracteres, ou até 222 quando o
nome tem pontos. Letras minúsculas, dígitos, hífens, sublinhados e pontos, começando e terminando
com uma letra ou um dígito. Sem forma de endereço IP, sem começar com `goog` e sem conter `google`
ou um erro de grafia parecido. E **sem pontos, na prática**: um nome com pontos fica reservado para
quem prova ser dono do domínio que ele soletra, pelo Search Console, e quebra o certificado TLS do
endereço `bucket.storage.googleapis.com`, cujo curinga cobre um rótulo e não dois.

O fake-gcs-server confere menos disso do que o Cloud Storage, e é o argumento da seção anterior feito
com um nome:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://qr
Creating gs://qr/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://Quitanda_Raw
Creating gs://Quitanda_Raw/...
ERROR: (gcloud.storage.buckets.create) HTTPError 400: invalid bucket name
ana@laptop:~/gcp$ gcloud storage buckets create gs://192.168.5.4
Creating gs://192.168.5.4/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda.raw.prod
Creating gs://quitanda.raw.prod/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://goog-quitanda
Creating gs://goog-quitanda/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod
Creating gs://quitanda-raw-prod/...
ERROR: (gcloud.storage.buckets.create) HTTPError 409: A Cloud Storage bucket named 'quitanda-raw-prod' already exists. Try another name. Bucket names must be globally unique across all Google Cloud projects, including those outside of your organization.
```

**O emulador recusou um dos cinco nomes que o Cloud Storage recusaria ou seguraria**, e o recusou pela
letra maiúscula. O Cloud Storage recusa `qr`, com dois caracteres, e `192.168.5.4`, e `goog-quitanda`
pelas quatro primeiras letras. Ele só aceitaria `quitanda.raw.prod` de alguém verificado como dono de
`raw.prod`, que aqui não é ninguém. Então as regras são conferidas por você, não por este servidor. A
segunda criação de `quitanda-raw-prod` deu o 409, e a frase dele é a do próprio serviço real: os nomes
são únicos entre todos os projetos, inclusive os de outras pessoas. Contra o Cloud Storage essa
resposta também vem quando o nome foi tomado por alguém de quem você nunca ouviu falar, e o
fake-gcs-server só consegue produzi-la para um nome seu, porque não imita mais ninguém.

## Um esquema para nomes de bucket

Vale ter um esquema antes que o segundo bucket exista. O que este curso usa põe a palavra mais
estável primeiro e a mais variável por último:

```
quitanda-raw-prod
quitanda-curated-prod
quitanda-logs-prod
quitanda-raw-dev
```

**Empresa, camada, ambiente.** A empresa torna o nome improvável de já estar tomado. A camada diz que
tipo de dado mora ali, e é também o que decide a classe de armazenamento, o ciclo de vida e quem pode
ler, os assuntos das aulas 2 a 4. O ambiente mantém os dados de desenvolvimento fora dos buckets de
produção, onde um teste que apaga tudo é um teste que apaga tudo.

Duas coisas não vão no nome de um bucket. **O nome de uma pessoa ou de um time**, porque as pessoas
mudam e o bucket fica. **Qualquer coisa secreta ou pessoal**, porque o nome de um bucket viaja em
consultas de DNS, em logs e em mensagens de erro que estranhos podem ver. Alguns times acrescentam o
id do projeto, `quitanda-raw-prod-planner-dev`, o que resolve o problema da colisão de vez ao preço de
um nome mais longo em todo caminho.

## Um esquema para nomes de objeto

Dentro de um bucket, os nomes dos objetos são onde os data lakes dão certo ou dão errado, e a regra é
**organizar os nomes pela pergunta que será feita com mais frequência**. Para dados que chegam todo
dia e são lidos por data, isso quer dizer que a data entra no caminho, escrita de modo que a ordem
alfabética seja a ordem do tempo:

```
raw/orders/dt=2026-10-01/orders.csv
raw/orders/dt=2026-10-02/orders.csv
raw/payments/dt=2026-10-01/payments.csv
```

**`dt=2026-10-01` e não `01-10-2026`.** O Cloud Storage lista os nomes em ordem lexicográfica dos
bytes, então uma data ano-mês-dia sai em ordem de tempo e uma dia-mês-ano junta todos os primeiros
dias do mês. A forma `nome=valor` é a convenção de *particionamento hive* que as tabelas externas do
BigQuery, o Spark e o DuckDB leem como partição, e que as aulas 15 e 17 usam para ler um dia em vez de
todos. Um nome de origem antes da data, `orders` e `payments`, mantém os arquivos de um fluxo fora da
listagem de outro.

**Escreva os nomes como se nunca pudessem ser renomeados**, porque na prática não podem. Minúsculas,
sem espaços, sem acentos, sem caracteres que uma URL precise escapar. Um nome de objeto pode conter
legalmente quase qualquer UTF-8 até 1.024 bytes, e `relatório final (2).csv` é um nome válido; é
também um nome que cada ferramenta põe entre aspas de um jeito, como o `%2F` no erro da seção anterior
já mostrou para uma simples barra.
