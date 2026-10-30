---
title: O seu Google Cloud, no seu próprio computador
version: 1
---

Este curso é praticado no seu próprio computador, contra **os emuladores que o Google publica** para
alguns dos seus serviços e uma imitação de código aberto do Cloud Storage, com a linha de comando
`gcloud` de verdade apontada para eles. Não há conta do Google Cloud em lugar nenhum, nada é cobrado,
e a plataforma não roda nada por você: cada comando destas lições é um que você digita no seu próprio
terminal. **A lição 1 de `gcp-foundations` monta este ambiente por inteiro**, com as três formas de ter
um terminal com Ubuntu 24.04 (instalado, que ela recomenda; uma máquina virtual; um shell alugado on-line),
quanto cada uma custa ao seu computador e o que fazer quando a instalação falha. Se você fez aquele
curso, já tem tudo o que vem abaixo. Se não fez, ou apagou desde então, esta seção é a mesma montagem
em resumo.

## Montando

O Docker roda os emuladores, e mais três pacotes vêm do repositório do Ubuntu. `python3-venv` é o
que as pessoas esquecem, porque o Ubuntu traz o Python sem ele:

```sh
sudo apt-get update
sudo apt-get install -y docker.io python3-venv curl unzip jq
sudo usermod -aG docker "$USER"
```

A última linha deixa você rodar `docker` sem `sudo`. Ela vale a partir do próximo login, então saia
e entre de novo antes de continuar.

Depois, a linha de comando `gcloud`, versão 591.0.0, em `~/.local`, um ambiente virtual Python só
dela em `~/gcp/venv`, e as duas imagens que fazem o papel da nuvem. Nada aqui precisa de `sudo`:

```sh
mkdir -p ~/gcp ~/.local/bin && cd ~/gcp
curl -sS -o gcloud.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-591.0.0-linux-x86_64.tar.gz
tar -xzf gcloud.tar.gz -C ~/.local && rm gcloud.tar.gz
ln -sf ~/.local/google-cloud-sdk/bin/gcloud ~/.local/bin/gcloud
python3 -m venv ~/gcp/venv
docker pull -q fsouza/fake-gcs-server:1.52.2
docker pull -q gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators
```

Num computador com processador Arm o arquivo é `google-cloud-cli-591.0.0-linux-arm.tar.gz`.

## Iniciando, toda vez

**Os dois emuladores guardam tudo em memória e esquecem quando param**, então nada de ontem está lá
hoje, e nenhuma lição supõe que esteja. Inicie-os com dois comandos; cada um imprime o id do contêiner
que iniciou:

```sh
docker run -d --rm --name gcs -p 4443:4443 fsouza/fake-gcs-server:1.52.2 -scheme http -backend memory -public-host localhost:4443
docker run -d --rm --name pubsub -p 8085:8085 gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators gcloud beta emulators pubsub start --project=planner-dev --host-port=0.0.0.0:8085
```

`gcs` responde à API do Cloud Storage na porta 4443, e `pubsub` é o próprio emulador de Pub/Sub do
Google, na porta 8085. Depois, no terminal em que você trabalha, oito linhas apontam tudo para eles:

```sh
cd ~/gcp && source venv/bin/activate
export PATH="$HOME/.local/bin:$PATH"
export CLOUDSDK_CORE_PROJECT=planner-dev
export CLOUDSDK_AUTH_DISABLE_CREDENTIALS=true
export CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE=http://localhost:4443/storage/v1/
export CLOUDSDK_API_ENDPOINT_OVERRIDES_PUBSUB=http://localhost:8085/
export STORAGE_EMULATOR_HOST=http://localhost:4443
export PUBSUB_EMULATOR_HOST=localhost:8085
```

O projeto é `planner-dev`, o nome que os quatro cursos de Google Cloud compartilham; a loja que este
curso opera mora nele. `CLOUDSDK_AUTH_DISABLE_CREDENTIALS` diz ao `gcloud` para não procurar um
login, porque não há nenhum para achar. As duas linhas `OVERRIDES` mandam as requisições de Cloud
Storage e de Pub/Sub para o seu computador em vez do Google, e as duas linhas `EMULATOR_HOST` fazem o
mesmo para as bibliotecas cliente do Google em Python. As variáveis vivem só naquele terminal, então
um terminal novo precisa das oito linhas de novo.

Depois confira que responde:

```
ana@laptop:~/gcp$ gcloud version
Google Cloud SDK 591.0.0
bq 2.1.41
bundled-python3-unix 3.14.9
core 2026.10.26
gcloud-crc32c 1.0.0
gsutil 5.38
ana@laptop:~/gcp$ gcloud storage buckets create gs://planner-dev-check --location=southamerica-east1
Creating gs://planner-dev-check/...
ana@laptop:~/gcp$ gcloud storage buckets list --format="value(name)"
planner-dev-check
ana@laptop:~/gcp$ gcloud pubsub topics create check
Created topic [projects/planner-dev/topics/check].
ana@laptop:~/gcp$ du -sh ~/.local/google-cloud-sdk ~/gcp/venv
535M	/home/ana/.local/google-cloud-sdk
16M	/home/ana/gcp/venv
ana@laptop:~/gcp$ docker image ls --format '{{.Repository}}:{{.Tag}} {{.Size}}' | grep -E 'fake-gcs|emulators'
gcr.io/google.com/cloudsdktool/google-cloud-cli:591.0.0-emulators 1.73GB
fsouza/fake-gcs-server:1.52.2 78MB
```

O bucket foi criado no `gcs` e o tópico no `pubsub`, e nenhum dos dois saiu do seu computador. Os
dois últimos comandos são o disco que o ambiente ocupa: cerca de meio gigabyte para o `gcloud`, e
1,8 GB para as duas imagens, quase tudo da imagem dos emuladores, que carrega um `gcloud` inteiro e
um runtime Java próprios. `docker image rm` com os dois nomes, e apagar `~/gcp` e
`~/.local/google-cloud-sdk`, remove tudo.

## Quando não responde

Três falhas cobrem quase todos os casos.

**Faltam as variáveis.** Um terminal novo em que as oito linhas não foram digitadas tem um `gcloud`
que quer um login, e diz isso antes de mandar qualquer coisa para qualquer lugar:

```
ana@laptop:~/gcp$ gcloud storage buckets list
ERROR: (gcloud.storage.buckets.list) You do not currently have an active account selected.
Please run:

  $ gcloud auth login

to obtain new credentials.

If you have already logged in with a different account, run:

  $ gcloud config set account ACCOUNT

to select an already authenticated account to use.
```

**Não rode `gcloud auth login`.** É o conselho certo para quem tem conta e o errado aqui: digite as
oito linhas e pergunte de novo.

**Um emulador não está rodando**, porque o computador reiniciou ou o contêiner foi parado. O `gcloud`
não consegue conectar e relata isso como uma queda, com a porta no meio da mensagem:

```
ana@laptop:~/gcp$ gcloud storage buckets list
ERROR: gcloud crashed (ConnectionError): HTTPConnectionPool(host='localhost', port=4443): Max retries exceeded with url: /storage/v1/b?alt=json&maxResults=1000&project=planner-dev&projection=full (Caused by NewConnectionError("HTTPConnection(host='localhost', port=4443): Failed to establish a new connection: [Errno 111] Connection refused"))

If you would like to report this issue, please run the following command:
  gcloud feedback

To check gcloud for common problems, please run the following command:
  gcloud info --run-diagnostics
```

`Connection refused` na 4443 é o `gcs`, na 8085 é o `pubsub`. `docker ps` lista o que está rodando;
inicie o que falta com a linha `docker run` dele.

**A porta está ocupada**, por um contêiner que você iniciou antes ou por outro programa. O Docker cria
o contêiner e depois não consegue lhe dar a porta:

```
ana@laptop:~/gcp$ docker run -d --rm --name gcs2 -p 4443:4443 fsouza/fake-gcs-server:1.52.2 -scheme http -backend memory -public-host localhost:4443
627bfbe920cd756429b675f61451b8fdf52b78525213609b05ea9146e7bbf474
docker: Error response from daemon: failed to set up container networking: driver failed programming external connectivity on endpoint gcs2 (74cf65e283314206890feca19bc21fcd6473e1d264a1bcd5f5243b446cfd94fb): Bind for 0.0.0.0:4443 failed: port is already allocated

Run 'docker run --help' for more information
```

O emulador que já está naquela porta costuma ser o que você quer. `docker ps` dá o nome dele, e
`ss -ltnp | grep 4443` acha um programa que não é contêiner.
