---
title: Buckets, objetos e as pastas que não estão lá
version: 1
---

**Um bucket é um contêiner com nome, e um objeto é um nome e os bytes guardados sob ele.** Esse é o
modelo de dados inteiro do Cloud Storage. Não há diretórios dentro de um bucket, nem arquivos no
sentido do sistema operacional, nem jeito de mudar parte de um objeto: você o escreve inteiro, o lê
inteiro ou num intervalo, e o apaga. As barras que as pessoas põem nos nomes dos objetos parecem um
sistema de arquivos, e o console desenha pastas a partir delas, e as duas coisas são uma conveniência
posta sobre uma lista plana de nomes.

O exemplo que atravessa este curso é a Quitanda, uma empresa de entrega de mercado em São Paulo, e o
primeiro bucket dela guarda os arquivos que a loja exporta toda noite. Crie três pequenos, um por
dia:

```sh
mkdir -p export
for d in 01 02 03; do
  printf 'order_id,customer_id,total_cents\n%s-1,c-17,4590\n%s-2,c-03,12800\n' "$d" "$d" \
    > export/orders-2026-10-$d.csv
done
```

Depois crie um bucket e ponha os arquivos nele, cada um sob um nome que começa com `raw/orders/`:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-prod --location=southamerica-east1
Creating gs://quitanda-raw-prod/...
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-10-01.csv gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
Copying file://export/orders-2026-10-01.csv to gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
  

ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-10-0[23].csv gs://quitanda-raw-prod/raw/orders/
Copying file://export/orders-2026-10-02.csv to gs://quitanda-raw-prod/raw/orders/orders-2026-10-02.csv
Copying file://export/orders-2026-10-03.csv to gs://quitanda-raw-prod/raw/orders/orders-2026-10-03.csv
  


Average throughput: 88.1kiB/s
```

`gcloud storage buckets create` criou o bucket, e `--location` é onde os dados dele moram: São Paulo,
uma única região. Cada `cp` foi uma requisição de upload por arquivo, e o nome do objeto é a string
inteira depois do nome do bucket, barras incluídas. As linhas vazias são o que sobra de um medidor de
progresso que se redesenha no lugar; um terminal as mostra do mesmo jeito.

## Listar é pedir um prefixo

```
ana@laptop:~/gcp$ gcloud storage ls gs://quitanda-raw-prod
gs://quitanda-raw-prod/raw/
ana@laptop:~/gcp$ gcloud storage ls --recursive gs://quitanda-raw-prod
gs://quitanda-raw-prod/:

gs://quitanda-raw-prod/raw/:

gs://quitanda-raw-prod/raw/orders/:
gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
gs://quitanda-raw-prod/raw/orders/orders-2026-10-02.csv
gs://quitanda-raw-prod/raw/orders/orders-2026-10-03.csv
ana@laptop:~/gcp$ curl -s 'http://localhost:4443/storage/v1/b/quitanda-raw-prod/o?prefix=raw/&delimiter=/' | python3 -m json.tool
{
    "kind": "storage#objects",
    "prefixes": [
        "raw/orders/"
    ]
}
```

**A primeira listagem mostra um `raw/` que ninguém criou.** `gcloud storage ls` pediu os nomes do
bucket agrupados na primeira barra, e a resposta foi um grupo, porque todo nome começa com esses
quatro caracteres. `--recursive` pede os próprios objetos, e lá estão eles: três, cada um com o nome
completo, sob títulos que a linha de comando imprime para deixar a lista legível. O terceiro comando
pergunta direto à API JSON, com `curl`, do jeito que todo cliente faz por baixo: um `prefix` para
filtrar e um `delimiter` para agrupar, e a resposta é uma lista de `prefixes`. **Uma pasta é a
resposta a uma pergunta, e só existe enquanto o nome de algum objeto começar com ela.**

Isso tem uma consequência em que as pessoas tropeçam. Pedir a "pasta" como objeto falha, porque esse
objeto não existe:

```
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/
ERROR: (gcloud.storage.objects.describe) gs://quitanda-raw-prod/raw%2Forders%2F not found: 404.
```

O `%2F` no erro é a barra, escapada, porque para a API o nome inteiro é uma string só. O botão
"Criar pasta" do console contorna a pasta que falta escrevendo um objeto vazio cujo nome termina em
barra, `raw/orders/` com zero bytes. Esse objeto é real, aparece na listagem, e é o motivo de uma
"pasta vazia" aparecer no console e não num programa que lista só objetos com conteúdo.

**O Cloud Storage também tem buckets em que as pastas são reais**, com o *namespace hierárquico*
ligado na criação do bucket. Lá uma pasta é um recurso próprio, e renomeá-la é uma operação só em vez
de uma cópia de cada objeto debaixo dela. A tabela de preços cobra cerca de 30% a mais pelas operações
de Classe A desses buckets, e a aula 5 mostra quanto custa uma operação. Tudo neste curso usa o
namespace plano comum, que é o padrão e o único que o fake-gcs-server imita.

## Um objeto é substituído, nunca editado

```
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv --format='value(size,md5_hash,generation)'
64	R0DILdLg74YE8u85q+7WgQ==	1793383629365701
ana@laptop:~/gcp$ printf '01-3,c-22,990\n' >> export/orders-2026-10-01.csv && gcloud storage cp export/orders-2026-10-01.csv gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
Copying file://export/orders-2026-10-01.csv to gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv
  

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-raw-prod/raw/orders/orders-2026-10-01.csv --format='value(size,md5_hash,generation)'
78	Lz4TVx6/63wQznBxKPlXhg==	1793383635165064
ana@laptop:~/gcp$ gcloud storage hash export/orders-2026-10-01.csv --skip-crc32c
---
digest_format: base64
md5_hash: Lz4TVx6/63wQznBxKPlXhg==
url: export/orders-2026-10-01.csv
```

**O tamanho mudou, o MD5 mudou e a geração também, porque o segundo `cp` escreveu um objeto novo sob
o mesmo nome**; nada foi editado no lugar. A **geração** é o número que o Cloud Storage dá a cada
versão dos bytes de um objeto, e um upload novo sempre recebe uma nova, então ela é o jeito mais
barato de perguntar "este ainda é o arquivo que eu li?". O MD5 é dos bytes, escrito em base64 em vez
de hexadecimal, e é por isso que `gcloud storage hash` no arquivo local imprime os mesmos 24
caracteres. Os metadados vieram do `objects describe`, que lê tudo sobre um objeto menos o corpo, e
custa uma requisição em vez de um download.

**Sobrescrever é silencioso e definitivo**, a menos que o bucket guarde versões. No bucket acima, a
primeira versão de `orders-2026-10-01.csv` se foi, e não há como desfazer. A aula 3 liga o
versionamento, que faz uma sobrescrita guardar os bytes antigos como uma versão não atual, e mostra
quanto isso custa. Um programa que não pode sobrescrever a escrita de outro manda, junto com o upload,
a geração que leu, como pré-condição, e o upload falha se o objeto tiver mudado: a mesma ideia de uma
coluna de versão numa tabela de banco de dados.
