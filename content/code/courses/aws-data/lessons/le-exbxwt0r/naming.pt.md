---
title: Um esquema de nomes que dura
version: 1
---

**O nome de um bucket é global e o nome de uma chave é para sempre**, e esses dois fatos são para o
que serve um esquema de nomes. O nome de um bucket é compartilhado por todas as contas da partição
comercial da AWS, então `quitanda-raw-prod` pertence a quem o criou primeiro, em qualquer lugar do
mundo. E uma chave é a única alça que um programa tem para um objeto: renomeie uma e todo programa,
relatório e tabela que apontava para a chave antiga agora aponta para nada, porque o S3 não tem
renomear. Mover um objeto é copiar e apagar.

## As regras do nome de um bucket

As regras da AWS para um bucket de uso geral são curtas. De 3 a 63 caracteres. Letras minúsculas,
dígitos, hífens e pontos, começando e terminando com letra ou dígito. Sem cara de endereço IP, sem
começar com `xn--` ou `sthree-`, e sem terminar em `-s3alias` ou `--ol-s3`. E **sem pontos, na
prática**: o ponto é permitido, e quebra o certificado TLS do endereço
`bucket.s3.sa-east-1.amazonaws.com`, cujo curinga cobre um rótulo e não dois.

O moto confere menos disso do que a AWS, que é o ponto da seção anterior, agora feito com um nome:

```
ana@laptop:~/aws$ aws s3 mb s3://qr
make_bucket failed: s3://qr An error occurred (InvalidBucketName) when calling the CreateBucket operation: The specified bucket is not valid.
ana@laptop:~/aws$ aws s3 mb s3://Quitanda_Raw
make_bucket: Quitanda_Raw
ana@laptop:~/aws$ aws s3 mb s3://192.168.5.4
make_bucket: 192.168.5.4
ana@laptop:~/aws$ aws s3 mb s3://quitanda.raw.prod
make_bucket: quitanda.raw.prod
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket failed: s3://quitanda-raw-prod An error occurred (BucketAlreadyOwnedByYou) when calling the CreateBucket operation: Your previous request to create the named bucket succeeded and you already own it.
```

**O moto recusou o nome de duas letras e aceitou os três seguintes.** A AWS recusa `Quitanda_Raw`, com
a maiúscula e o sublinhado, e recusa `192.168.5.4`. O nome com pontos seria aceito lá também, e
falharia na primeira vez que um programa chegasse nele por HTTPS pelo endereço de sempre. Então as
regras são conferidas aqui por você, não pelo servidor. E o segundo `mb` com o mesmo nome encontrou
`BucketAlreadyOwnedByYou`, que é a versão gentil de uma colisão. No S3 de verdade, um nome que outra
pessoa já tem falha com `BucketAlreadyExists`, e essa resposta não foi produzida aqui: o moto imita
uma conta só, então não há mais ninguém para ser dono de um nome.

## Um esquema para nomes de bucket

Um esquema vale a pena antes que exista o segundo bucket. O que este curso usa põe a palavra mais
estável primeiro e a mais variável por último:

```
quitanda-raw-prod
quitanda-curated-prod
quitanda-logs-prod
quitanda-raw-dev
```

**Empresa, camada, ambiente.** A empresa torna o nome difícil de já estar tomado. A camada diz que
tipo de dado mora ali, que é também o que decide a classe de armazenamento, o ciclo de vida e quem
pode ler, os assuntos das lições 2 a 4. O ambiente mantém dados de desenvolvimento fora dos buckets de
produção, onde um teste que apaga tudo é um teste que apaga tudo.

Duas coisas não entram no nome de um bucket. **O nome de uma pessoa ou de uma equipe**, porque pessoas
mudam de lugar e o bucket fica. **Qualquer coisa secreta ou pessoal**, porque o nome de um bucket
viaja em consultas de DNS, em logs e em mensagens de erro que estranhos podem ver. Algumas equipes
acrescentam o número da conta e a região, `quitanda-raw-prod-123456789012-sa-east-1`, e isso resolve
o problema de colisão de vez, ao preço de 40 dos 63 caracteres.

## Um esquema para chaves

Dentro de um bucket, as chaves são onde um data lake dá certo ou fracassa, e a regra é **organizar as
chaves pela pergunta que mais será feita**. Para dados que chegam todo dia e são lidos por data, isso
quer dizer que a data entra no caminho, escrita de modo que a ordem alfabética seja a ordem do tempo:

```
raw/orders/dt=2026-10-01/orders.csv
raw/orders/dt=2026-10-02/orders.csv
raw/payments/dt=2026-10-01/payments.csv
```

**`dt=2026-10-01` e não `01-10-2026`.** O S3 devolve as chaves na ordem dos bytes em UTF-8, então uma
data ano-mês-dia lista na ordem do tempo e uma dia-mês-ano lista todos os dias 1º juntos. A forma
`nome=valor` é a convenção que o Athena, o Glue e o Spark leem como partição, e a lição 15 a usa para
ler um dia em vez de todos. Um nome de origem antes da data, `orders` e `payments`, mantém os arquivos
de um feed fora da listagem do outro.

**Escreva as chaves como se nunca pudessem ser renomeadas**, porque na prática não podem. Minúsculas,
sem espaços, sem acentos, sem caracteres que uma URL precise escapar. Uma chave pode legalmente ter
quase qualquer coisa, e `relatório final (2).csv` é válida; é também uma chave que cada ferramenta
escapa de um jeito.
