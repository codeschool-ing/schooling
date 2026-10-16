---
title: Buckets, objetos e as pastas que não estão lá
version: 1
---

**Um bucket é um contêiner com um nome, e um objeto é uma chave e os bytes guardados nela.** Esse é o
modelo de dados inteiro do S3. Não há diretórios dentro de um bucket, nem arquivos no sentido do
sistema operacional, nem jeito de mudar parte de um objeto: você o escreve inteiro, lê inteiro ou um
trecho, e apaga. As barras que as pessoas põem nas chaves parecem um sistema de arquivos, e o console
desenha pastas a partir delas, e as duas coisas são uma conveniência posta sobre uma lista plana de
nomes.

O exemplo que atravessa este curso é a Quitanda, uma empresa de entrega de mercado em São Paulo, e o
primeiro bucket dela guarda os arquivos que a loja exporta toda noite. Crie três pequenos, um por dia:

```sh
mkdir -p export
for d in 01 02 03; do
  printf 'order_id,customer_id,total_cents\n%s-1,c-17,4590\n%s-2,c-03,12800\n' "$d" "$d" \
    > export/orders-2026-10-$d.csv
done
```

Depois crie um bucket e ponha os arquivos nele, cada um sob uma chave que começa com `raw/orders/`:

```
ana@laptop:~/aws$ aws s3 mb s3://quitanda-raw-prod
make_bucket: quitanda-raw-prod
ana@laptop:~/aws$ aws s3 cp export/orders-2026-10-01.csv s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
upload: export/orders-2026-10-01.csv to s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
ana@laptop:~/aws$ aws s3 cp export/ s3://quitanda-raw-prod/raw/orders/ --recursive --exclude "*" --include "*-0[23].csv"
upload: export/orders-2026-10-03.csv to s3://quitanda-raw-prod/raw/orders/orders-2026-10-03.csv
upload: export/orders-2026-10-02.csv to s3://quitanda-raw-prod/raw/orders/orders-2026-10-02.csv
```

`aws s3 mb` é "make bucket", e criou o bucket na região para a qual o terminal aponta, São Paulo. Cada
`cp` foi uma requisição `PutObject`, e a chave é a string inteira depois do nome do bucket, com
barras e tudo.

## Listar é pedir um prefixo

```
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod
                           PRE raw/
ana@laptop:~/aws$ aws s3 ls s3://quitanda-raw-prod --recursive
2026-10-16 12:31:13         64 raw/orders/orders-2026-10-01.csv
2026-10-16 12:31:14         64 raw/orders/orders-2026-10-02.csv
2026-10-16 12:31:14         64 raw/orders/orders-2026-10-03.csv
ana@laptop:~/aws$ aws s3api list-objects-v2 --bucket quitanda-raw-prod --prefix raw/ --delimiter / --query CommonPrefixes
[
    {
        "Prefix": "raw/orders/"
    }
]
```

**A primeira listagem mostra um `PRE raw/` que ninguém criou.** O `aws s3 ls` pediu ao S3 as chaves do
bucket agrupadas na primeira barra, e o S3 respondeu com um grupo, `raw/`, porque toda chave começa
com esses quatro caracteres. O `--recursive` pede as próprias chaves, e lá estão elas: três objetos,
cada um com o nome inteiro. A chamada `s3api` por baixo mostra o que é o agrupamento: um `Prefix` para
filtrar e um `Delimiter` onde agrupar, e a resposta é uma lista de `CommonPrefixes`. **Uma pasta é a
resposta a uma pergunta, e só existe enquanto alguma chave começar com ela.**

Isso tem uma consequência em que muita gente tropeça. Pedir a "pasta" como objeto falha, porque esse
objeto não existe:

```
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/

aws: [ERROR]: An error occurred (404) when calling the HeadObject operation: Not Found
```

O botão "Create folder" do console contorna isso gravando um objeto vazio cuja chave termina em barra,
`raw/orders/` com zero bytes. Esse objeto é real, aparece na listagem, e é o motivo de uma "pasta
vazia" ser visível no console e não num programa que lista só objetos com conteúdo.

## Um objeto é substituído, nunca editado

```
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/orders-2026-10-01.csv --query "[ContentLength,ETag]" --output text
64	"4740c82dd2e0ef8604f2ef39abeed681"
ana@laptop:~/aws$ printf "ord-01-3,c-22,990\n" >> export/orders-2026-10-01.csv && aws s3 cp export/orders-2026-10-01.csv s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
upload: export/orders-2026-10-01.csv to s3://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
ana@laptop:~/aws$ aws s3api head-object --bucket quitanda-raw-prod --key raw/orders/orders-2026-10-01.csv --query "[ContentLength,ETag]" --output text
82	"3c43e2ba2e34e273de8eb7f5abb2bd32"
ana@laptop:~/aws$ md5sum export/orders-2026-10-01.csv
3c43e2ba2e34e273de8eb7f5abb2bd32  export/orders-2026-10-01.csv
```

**O ETag mudou e o tamanho também, porque o segundo `cp` gravou um objeto novo sob a mesma chave**;
nada foi editado no lugar. O ETag de um objeto enviado numa só requisição é o MD5 dos seus bytes, e é
por isso que o terceiro comando, `md5sum`, imprime os mesmos 32 caracteres. Os metadados vieram do
`head-object`, que lê tudo de um objeto menos o corpo, e custa uma requisição em vez de um download.

**Sobrescrever é silencioso e definitivo**, a menos que o bucket guarde versões. No bucket acima, a
primeira versão de `orders-2026-10-01.csv` sumiu, e não há como desfazer. A lição 3 liga o
versionamento, que faz uma sobrescrita guardar os bytes antigos como versão anterior, e mostra quanto
isso custa.
