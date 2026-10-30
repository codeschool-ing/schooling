---
title: Escolhendo a classe quando o objeto é escrito
version: 1
---

**A classe é uma propriedade de cada objeto, definida quando o objeto é escrito**, e a requisição que o
escreve é o mesmo upload de sempre, com um campo a mais. Não existe serviço de arquivo para onde mandar
arquivos nem um tipo separado de bucket. O `gcloud storage cp` expõe o campo como `--storage-class`.
Quando a requisição não informa classe, o objeto recebe a classe padrão do bucket, e um bucket criado
sem padrão tem `STANDARD`.

A Quitanda fecha cada mês exportando seus pedidos, e o arquivo de setembro é a primeira coisa que vai
para o bucket de arquivo. Crie um, com 500 pedidos:

```sh
mkdir -p export
printf 'order_id,customer_id,total_cents\n' > export/orders-2026-09.csv
for i in $(seq 1 500); do
  printf 'ord-09-%d,c-%d,%d\n' "$i" $((i % 40)) $((990 + i * 7)) >> export/orders-2026-09.csv
done
```

Depois ponha quatro cópias dele em quatro classes, o que ninguém faria com um arquivo só e é o jeito
mais rápido de ver o que muda e o que não muda:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-archive-prod --location=southamerica-east1
Creating gs://quitanda-archive-prod/...
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/standard.csv
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/standard.csv
  

ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/nearline.csv --storage-class=NEARLINE
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/nearline.csv
  

ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/coldline.csv --storage-class=COLDLINE
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/coldline.csv
  

ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/archive.csv --storage-class=ARCHIVE
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/archive.csv
  

ana@laptop:~/gcp$ gcloud storage objects list 'gs://quitanda-archive-prod/orders/2026-09/*' --format='table(name,storage_class,size)'
NAME                         STORAGE_CLASS  SIZE
orders/2026-09/archive.csv   ARCHIVE        10295
orders/2026-09/coldline.csv  COLDLINE       10295
orders/2026-09/nearline.csv  NEARLINE       10295
orders/2026-09/standard.csv  STANDARD       10295
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/orders/2026-09/nearline.csv --format='yaml(storage_class,storage_class_update_time,size,generation)'
generation: '1793385009764338'
size: 10295
storage_class: NEARLINE
storage_class_update_time: 2026-10-30T15:30:09-0300
```

**Toda cópia tem o mesmo tamanho e foi escrita do mesmo jeito**; a única diferença é a palavra em
`STORAGE_CLASS`. O upload sem `--storage-class` saiu `STANDARD`, o padrão do bucket.
`storage_class_update_time` registra quando a classe foi definida pela última vez, o que, para um
objeto novo, é o momento em que foi escrito. O arquivo tem 10.295 bytes, e o Cloud Storage cobraria
cada cópia como 10.295 bytes: não há tamanho mínimo de objeto para arredondar para cima.

## Os nomes que a linha de comando conhece, e os que ela não confere

Os quatro nomes são `STANDARD`, `NEARLINE`, `COLDLINE` e `ARCHIVE`. A linha de comando transforma um
nome em minúsculas no nome em maiúsculas antes de mandar qualquer coisa. O que ela não faz é conferir
o nome contra a lista:

```
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/lower.csv --storage-class=nearline
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/lower.csv
  
.
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-archive-prod/orders/2026-09/glacier.csv --storage-class=GLACIER
Copying file://export/orders-2026-09.csv to gs://quitanda-archive-prod/orders/2026-09/glacier.csv
  

ana@laptop:~/gcp$ gcloud storage objects list gs://quitanda-archive-prod/orders/2026-09/lower.csv gs://quitanda-archive-prod/orders/2026-09/glacier.csv --format='table(name,storage_class)'
NAME                        STORAGE_CLASS
orders/2026-09/lower.csv    NEARLINE
orders/2026-09/glacier.csv  GLACIER
```

**`GLACIER` não é uma classe do Cloud Storage**, e o emulador a guardou mesmo assim. O Cloud Storage
recusa um upload que cite uma classe que ele não tem, com um erro e nenhum objeto; o fake-gcs-server
guarda qualquer texto que receber. Um script com a classe digitada errado, ou trazida do vocabulário
de outra nuvem, passa em todo teste contra este emulador e falha na primeira execução contra o Google.
Mantenha os quatro nomes numa constante do programa e teste essa constante, não a resposta do emulador.

## A classe padrão do bucket

A classe padrão de um bucket é definida quando o bucket é criado, com `--default-storage-class`, e
mudada depois com `gcloud storage buckets update`. Mudá-la afeta os objetos escritos depois da mudança
e nenhum dos que já estão lá. O bucket de desenvolvimento da Quitanda guarda dados que ninguém lê duas
vezes, então Nearline seria o padrão dele:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-raw-dev --location=southamerica-east1 --default-storage-class=NEARLINE
Creating gs://quitanda-raw-dev/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-raw-dev --format='value(default_storage_class)'
STANDARD
ana@laptop:~/gcp$ gcloud storage cp export/orders-2026-09.csv gs://quitanda-raw-dev/orders/2026-09/orders.csv
Copying file://export/orders-2026-09.csv to gs://quitanda-raw-dev/orders/2026-09/orders.csv
  

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-raw-dev/orders/2026-09/orders.csv --format='value(storage_class)'
STANDARD
ana@laptop:~/gcp$ gcloud storage buckets update gs://quitanda-raw-dev --default-storage-class=COLDLINE
  
Updating gs://quitanda-raw-dev/...

ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-raw-dev --format='value(default_storage_class)'
STANDARD
```

**O emulador ignora a classe padrão**, na criação e na atualização: o bucket mostra `STANDARD` as duas
vezes, e o objeto escrito nele sem classe própria também. No Cloud Storage o primeiro `describe`
imprimiria `NEARLINE`, o objeto seria `NEARLINE`, e depois da atualização o bucket mostraria `COLDLINE`
enquanto aquele objeto continuaria `NEARLINE`. Neste laboratório, defina a classe em todo upload que
precise de uma, que é o hábito que vale a pena ter de qualquer forma: um upload que diz a sua classe
não depende de uma configuração que alguém pode mudar.

**A classe padrão também define o preço das requisições do próprio bucket.** A página de preços diz
que uma operação sobre um bucket, como listar os objetos dele, é cobrada ao preço da classe padrão do
bucket, e uma operação sobre um objeto ao preço da classe do objeto. Um bucket cujo padrão é Archive
paga 0,05 USD a cada mil listagens, contra 0,005 de um bucket cujo padrão é Standard, quaisquer que
sejam os objetos dentro dele. Um job que lista um prefixo a cada minuto para ver se um arquivo chegou
faz 43.200 listagens num mês de 30 dias: 43.200 / 1.000 × 0,005 = 0,22 USD num bucket Standard, e
× 0,05 = 2,16 num Archive, dez vezes mais pela mesma pergunta. A Quitanda mantém o padrão do bucket de arquivo em Standard e informa a classe em todo
upload, o que sai mais barato para fazer perguntas e não manda um arquivo para o Archive por acidente.

## Mudando a classe de um objeto

A classe de um objeto só muda quando o objeto é escrito de novo, e `gcloud storage objects update
--storage-class` é o comando que faz isso. A ajuda dele diz isso numa linha: usar a opção "triggers a
rewrite of underlying object data", ou seja, dispara uma reescrita dos dados do objeto.

```
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/orders/2026-09/standard.csv --format='value(storage_class,generation,creation_time)'
STANDARD	1793385008602532	2026-10-30T15:30:08-0300
ana@laptop:~/gcp$ gcloud storage objects update gs://quitanda-archive-prod/orders/2026-09/standard.csv --storage-class=COLDLINE
  
Rewriting gs://quitanda-archive-prod/orders/2026-09/standard.csv...

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/orders/2026-09/standard.csv --format='value(storage_class,generation,creation_time)'
STANDARD	1793385028551218	2026-10-30T15:30:28-0300
ana@laptop:~/gcp$ gcloud storage objects update gs://quitanda-archive-prod/orders/2026-09/nearline.csv --storage-class=ARCHIVE
  
Rewriting gs://quitanda-archive-prod/orders/2026-09/nearline.csv...

ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-archive-prod/orders/2026-09/nearline.csv --format='value(storage_class,generation)'
STANDARD	1793385030548817
```

**A reescrita aconteceu, e a classe não mudou.** `Rewriting` é impresso, e o objeto voltou com um novo
número de geração e um novo horário de criação, os dois sinais de um objeto novo escrito sobre o
antigo. A classe voltou `STANDARD`, depois de uma reescrita para `COLDLINE` e de outra para `ARCHIVE`.
O fake-gcs-server 1.54.0 escreve todo objeto reescrito como Standard, peça a requisição o que pedir. No
Cloud Storage as duas linhas de `describe` diriam `COLDLINE` e `ARCHIVE`.

O que o emulador mostra corretamente é a parte que custa dinheiro. **Uma reescrita é um objeto novo**,
então no Cloud Storage ela é uma operação Class A, cobrada ao preço da classe de destino, e o objeto
antigo termina a vida naquele dia. A cópia em Nearline acima foi reescrita segundos depois de escrita:
no Cloud Storage essa cópia pagaria de uma vez os seus 30 dias de Nearline, como exclusão antecipada.
Fazer isso à mão para alguns arquivos não tem problema. Para um prefixo inteiro, todo mês, a ferramenta
é uma regra de ciclo de vida: ela muda a classe sem reescrita e sem a cobrança de exclusão antecipada,
e a aula 3 escreve uma.
