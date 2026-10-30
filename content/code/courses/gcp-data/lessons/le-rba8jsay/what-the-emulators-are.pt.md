---
title: O que são os emuladores, e onde eles param
version: 1
---

**Um emulador responde ao plano de dados de um serviço, e a nada mais.** A API do Google Cloud tem
duas metades. O *plano de controle* é onde se criam projetos, IAM, redes, faturamento e os próprios
recursos: uma instância do Cloud SQL, um job do Dataflow, uma reserva do BigQuery. O *plano de
dados* é o que esses recursos fazem depois de existir: guardar um objeto, entregar uma mensagem,
responder a uma leitura. O Google publica emuladores para o plano de dados de quatro serviços, e
alguém de fora do Google escreveu um para o Cloud Storage. **Para o plano de controle não há
emulador nenhum**, de serviço nenhum, de ninguém.

É uma lista curta, e este curso é construído em torno do que falta nela em vez de escondê-lo:

| o quê | neste laboratório | o que é |
|---|---|---|
| Cloud Storage | fake-gcs-server 1.54.0 | uma imitação de código aberto da API JSON, feita por uma pessoa de fora do Google |
| Pub/Sub | o emulador de Pub/Sub, um componente do `gcloud` | do próprio Google, um programa Java |
| Firestore | o emulador de Firestore | do próprio Google, o mesmo que o Firebase usa |
| Bigtable | `cbtemulator` | do próprio Google, em Go, só na memória |
| Spanner | o emulador de Spanner | do próprio Google, em C++ |
| BigQuery | **nada**; o DuckDB roda o SQL | nenhum emulador do Google; a aula 13 diz o que o DuckDB substitui |
| Cloud SQL, AlloyDB, Memorystore | **nada**; PostgreSQL 16 e Redis 7 rodam o motor | o motor é real, o serviço gerenciado em volta dele não está |
| Dataflow, Dataproc, Composer, Datastream, Dataplex | **nada**; Apache Beam e Spark rodam localmente onde dá | ensinados pela documentação do Google |
| projetos, IAM, faturamento, redes | **nada** | ensinados pela documentação do Google |

**Então cada aula é de um de três tipos**, e diz qual ao lado de cada transcrição. Algumas são
praticadas contra um emulador. Algumas rodam o motor de código aberto sobre o qual o serviço
gerenciado é construído, e dizem com todas as letras que quem respondeu foi o PostgreSQL ou o Spark,
e não o Cloud SQL ou o Dataproc. As demais são lidas: mostram o comando que você digitaria contra um
projeto real, dizem que ele não foi rodado e não mostram saída, porque uma resposta inventada seria
pior do que nenhuma.

## O que um emulador não confere

Inicie um vazio, no outro terminal como antes, e teste as bordas:

```
ana@laptop:~/gcp$ gcloud storage buckets create gs://quitanda-emu-demo --location=us-east1
Creating gs://quitanda-emu-demo/...
ana@laptop:~/gcp$ gcloud storage buckets describe gs://quitanda-emu-demo --format='value(location,location_type)'
southamerica-east1	region
ana@laptop:~/gcp$ echo hello > note.txt && gcloud storage cp note.txt gs://quitanda-emu-demo/note.txt
Copying file://note.txt to gs://quitanda-emu-demo/note.txt
  

ana@laptop:~/gcp$ curl -s http://localhost:4443/storage/v1/b/quitanda-emu-demo/o/note.txt?alt=media
hello
ana@laptop:~/gcp$ gcloud storage objects describe gs://quitanda-emu-demo/note.txt --format='value(acl[0].entity)'
projectOwner-test-project
```

Aconteceram três coisas que o Cloud Storage não faria.

**O bucket foi pedido em `us-east1` e informa `southamerica-east1`.** O fake-gcs-server não guarda
uma localização própria por bucket: responde com aquela com que foi iniciado, o `-location` do
quinto bloco de the-lab. É por isso que o laboratório o inicia com São Paulo, para que o que ele
informa seja o que este curso pede. Uma localização é uma promessa sobre onde os seus dados moram
fisicamente, e aqui ela é uma string.

**O `curl` leu o objeto sem credencial nenhuma.** O emulador não confere assinatura, token nem
política do IAM, então toda requisição é permitida. A aula 4 é sobre quem pode ler um bucket, e
toda recusa nela é ensinada pela documentação, porque nada aqui consegue produzir uma.

**O dono do objeto é `projectOwner-test-project`**, e essa string é a assinatura do emulador: um
projeto chamado `test-project`, que não é `planner-dev`, inventado pelo fake-gcs-server para todo
objeto que ele guarda. Se um describe algum dia mostrar uma ACL com um projeto seu, você não está
falando com o emulador.

## Os serviços sem ter para onde ir

```
ana@laptop:~/gcp$ bq ls
ERROR: (bq) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
ana@laptop:~/gcp$ env -u CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE gcloud storage buckets list
ERROR: gcloud crashed (ConnectionError): HTTPSConnectionPool(host='storage.googleapis.com', port=443): Max retries exceeded with url: /storage/v1/b?alt=json&maxResults=1000&project=planner-dev&projection=full (Caused by NameResolutionError("HTTPSConnection(host='storage.googleapis.com', port=443): Failed to resolve 'storage.googleapis.com' ([Errno -3] Temporary failure in name resolution)"))

If you would like to report this issue, please run the following command:
  gcloud feedback

To check gcloud for common problems, please run the following command:
  gcloud info --run-diagnostics
```

**O `bq` não tem emulador para onde mandar**, então faz o que o `gcloud` fez na seção anterior sem
`CLOUDSDK_AUTH_DISABLE_CREDENTIALS`: procura uma conta e para. O segundo comando tirou a linha do
endpoint, e o `gcloud` foi atrás de `storage.googleapis.com`, o endereço real. Na máquina em que estas
transcrições foram gravadas ele não conseguiu resolver o nome, porque a gravação não tinha rede. **Na
sua ele chegaria ao Google**, sem credenciais, e seria recusado, já que listar os buckets de um projeto
exige uma conta que tenha permissão para isso. Essa recusa é a única segurança em que este desenho se
apoia, e é por isso que a terceira linha do bloco importa mais que as outras: com as credenciais
desligadas, um terminal que perdeu o endpoint pergunta ao Google como ninguém.

## Uma conta real, se você quiser uma

**Nada neste curso precisa de uma**, e nenhuma aula supõe que você tenha. Se mais tarde você praticar
num projeto real, a aula 1 do `gcp-foundations` tem uma seção sobre fazer isso com segurança e a aula
12 daquele curso é sobre orçamentos. A ordem dos passos delas é a coisa mais valiosa que uma conta
real pode ensinar: um orçamento com alerta antes de qualquer outra coisa, um segundo fator na conta e
nada deixado rodando. A camada gratuita do Google é um jeito de começar, e nem este curso nem aquele
dependem dela.
