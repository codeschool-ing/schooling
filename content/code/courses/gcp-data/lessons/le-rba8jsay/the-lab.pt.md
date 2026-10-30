---
title: O seu laboratório, passo a passo
version: 1
---

**Este curso é praticado contra emuladores, no seu próprio computador, com a linha de comando real
do Google Cloud e sem conta no Google Cloud.** Um emulador é um programa que responde numa porta do
seu notebook do jeito que um serviço do Google responde na internet, guarda na memória o que lhe
dizem e esquece tudo quando para. Os quatro cursos de Google Cloud deste catálogo usam o mesmo
ambiente, e o `gcp-foundations` também o monta na primeira aula. Se você o montou lá e o manteve,
confira com o último bloco desta seção e siga em frente. A plataforma não roda nada por você: nem
máquina, nem shell no navegador, nem conta.

## Três jeitos de ter a máquina

**O Ubuntu 24.04 é onde todas as transcrições foram gravadas**, e três jeitos de tê-lo funcionam:

- **Instalado, que é o recomendado.** O Ubuntu como seu sistema, ou no WSL do Windows:
  `wsl --install -d Ubuntu-24.04` num PowerShell de administrador, e depois abra "Ubuntu 24.04" pelo
  menu Iniciar. Tudo abaixo roda nesse terminal.
- **Uma máquina virtual**, que é o caminho num Mac: Ubuntu Server 24.04 no UTM, no VirtualBox ou no
  Multipass, com 2 processadores, 6 GB de memória e 20 GB de disco. Os emuladores das aulas 9 a 11
  são programas em Java, C++ e Go, e dois deles ao mesmo tempo querem mais memória do que um servidor
  sozinho.
- **Um shell online alugado por hora.** Nada aqui precisa de mais do que um terminal com rede para a
  instalação e nenhuma rede depois dela, mas nenhuma aula depende da cota gratuita de empresa alguma.

**No seu disco o laboratório inteiro ocupa cerca de 1,6 GB**, medidos no fim desta seção, e nada dele
roda a menos que você o inicie. A maior parte disso é a linha de comando do Google Cloud com os
emuladores.

## Os pacotes do Ubuntu

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl openjdk-21-jre-headless
```

**O Java é para os emuladores, não para você.** Os emuladores de Pub/Sub e de Firestore são programas
Java, e começam com o `java` que estiver no caminho.

## A linha de comando do Google Cloud

A versão 591.0.0, dentro de `~/gcp`, para não precisar de `sudo`, com os cinco emuladores que este
curso usa:

```sh
mkdir -p ~/gcp/bin
cd ~/gcp
curl -sS -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-591.0.0-linux-x86_64.tar.gz
tar -xzf google-cloud-cli-591.0.0-linux-x86_64.tar.gz
rm google-cloud-cli-591.0.0-linux-x86_64.tar.gz
export PATH="$HOME/gcp/google-cloud-sdk/bin:$PATH"
gcloud config set component_manager/fixed_sdk_version 591.0.0
gcloud components install beta pubsub-emulator cloud-firestore-emulator bigtable cbt cloud-spanner-emulator --quiet
```

O download tem 90 MB, e com os componentes o diretório chega a cerca de 1,2 GB. **A linha do
`fixed_sdk_version` é o que a mantém na 591.0.0**: sem ela, instalar um componente oferece atualizar
a linha de comando inteira primeiro, e a versão no seu terminal deixaria de ser a destas transcrições.

Num processador Arm, o que inclui uma máquina virtual num Mac com Apple silicon, o arquivo é
`google-cloud-cli-591.0.0-linux-arm.tar.gz`. **O emulador do Spanner é publicado só para Linux
x86-64**, então no Arm a aula 9 é lida em vez de praticada, ou rodada numa máquina x86-64.

## fake-gcs-server, para o Cloud Storage

O Google não publica emulador para o Cloud Storage. **O fake-gcs-server é um de código aberto**,
escrito por Francisco Souza, e é um arquivo só:

```sh
cd ~/gcp
curl -sSL -O https://github.com/fsouza/fake-gcs-server/releases/download/v1.54.0/fake-gcs-server_1.54.0_Linux_amd64.tar.gz
tar -xzf fake-gcs-server_1.54.0_Linux_amd64.tar.gz -C bin fake-gcs-server
rm fake-gcs-server_1.54.0_Linux_amd64.tar.gz
```

No Arm o arquivo termina em `_Linux_arm64.tar.gz`. Se você já tem Go 1.25 ou mais novo, `GOBIN=~/gcp/bin
go install github.com/fsouza/fake-gcs-server@v1.54.0` compila a mesma versão a partir do código-fonte,
e foi assim que se fez a cópia com que estas transcrições foram gravadas.

## As bibliotecas Python, num ambiente virtual

```sh
python3 -m venv ~/gcp/venv
~/gcp/venv/bin/pip install -q google-cloud-storage==3.16.0 google-cloud-pubsub==2.42.0 \
  google-cloud-firestore==2.33.0 google-cloud-bigtable==2.50.0 google-cloud-spanner==3.70.0
~/gcp/venv/bin/pip install -q duckdb==1.5.6 pyarrow==25.0.1
```

**A primeira linha são as bibliotecas cliente do Google**, aquelas que um programa usa para falar com
cada serviço, e cada uma delas procura um emulador numa variável de ambiente antes de procurar o
Google. **A segunda linha é deste curso**: o BigQuery não tem emulador nenhum, então as aulas da 13
em diante leem os mesmos arquivos Parquet com o **DuckDB**, um motor de banco de dados que vive
dentro de um programa Python, e os escrevem com o **PyArrow**. A aula 13 diz exatamente o que isso
substitui e o que não consegue substituir.

## Dois terminais

**Um emulador roda num terminal só dele**, e fica em primeiro plano ali, imprimindo uma linha por
requisição. Abra um terminal e inicie o do Cloud Storage:

```sh
cd ~/gcp && export PATH="$HOME/gcp/bin:$PATH"
fake-gcs-server -scheme http -port 4443 -backend memory -location southamerica-east1
```

Deixe rodando. `Ctrl+C` o interrompe, e **interrompê-lo esquece tudo**, porque `-backend memory`
guarda os buckets na memória e em nenhum outro lugar. `-scheme http` poupa você de um certificado em
que a linha de comando não confiaria, e `-location` é a região que ele informa para todo bucket, por
um motivo que a seção depois da próxima mostra. As aulas que precisam de outro emulador o iniciam do
mesmo jeito, cada um num terminal próprio, e dizem qual.

## Toda vez que você abrir um terminal

Num segundo terminal, aquele em que você digita pelo resto do curso:

```sh
cd ~/gcp
export PATH="$HOME/gcp/google-cloud-sdk/bin:$HOME/gcp/bin:$PATH" && source venv/bin/activate
export CLOUDSDK_CORE_PROJECT=planner-dev CLOUDSDK_AUTH_DISABLE_CREDENTIALS=true
export CLOUDSDK_API_ENDPOINT_OVERRIDES_STORAGE=http://localhost:4443/storage/v1/ STORAGE_EMULATOR_HOST=http://localhost:4443
export CLOUDSDK_API_ENDPOINT_OVERRIDES_PUBSUB=http://localhost:8085/ PUBSUB_EMULATOR_HOST=localhost:8085
export CLOUDSDK_API_ENDPOINT_OVERRIDES_SPANNER=http://localhost:9020/ SPANNER_EMULATOR_HOST=localhost:9010
export FIRESTORE_EMULATOR_HOST=localhost:8080 BIGTABLE_EMULATOR_HOST=localhost:8086
```

A primeira linha é onde ficam os arquivos do curso. A segunda põe o `gcloud` no caminho e ativa o
ambiente virtual. **A terceira é metade do truque**: `CLOUDSDK_CORE_PROJECT` dá nome ao projeto em
que todo comando age, `planner-dev`, que os emuladores aceitam como está escrito, e
`CLOUDSDK_AUTH_DISABLE_CREDENTIALS` diz ao `gcloud` para não mandar credencial nenhuma, de modo que
não há nada seu que possa chegar ao Google. **As outras três linhas são a outra metade**: cada
`CLOUDSDK_API_ENDPOINT_OVERRIDES_…` manda as requisições de um serviço feitas pelo `gcloud` para uma
porta deste notebook, e cada `…_EMULATOR_HOST` faz o mesmo para a biblioteca Python desse serviço.
Toda variável `CLOUDSDK_` é uma configuração do `gcloud` que vive só neste terminal, e esse é o
ponto: feche o terminal e não sobra nada configurado.

## Confira que ele responde

```
ana@laptop:~/gcp$ gcloud version
Google Cloud SDK 591.0.0
beta 2026.10.26
bigtable 
bq 2.1.41
bundled-python3-unix 3.14.9
cbt 1.25.7
cloud-firestore-emulator 1.22.0
cloud-spanner-emulator 1.5.59
core 2026.10.26
gcloud-crc32c 1.0.0
gsutil 5.38
pubsub-emulator 0.8.37
ana@laptop:~/gcp$ gcloud auth list

No credentialed accounts.

To login, run:
  $ gcloud auth login `ACCOUNT`

ana@laptop:~/gcp$ gcloud storage buckets list
Listed 0 items.
ana@laptop:~/gcp$ du -sh ~/gcp
1.6G	/home/ana/gcp
```

**`No credentialed accounts` é a primeira prova de que você não está falando com o Google**, e `Listed
0 items.` é a segunda: um Cloud Storage vazio. Contra o serviço real o mesmo comando sem credenciais
seria recusado, não respondido. Se você vir uma conta que reconhece, ou um erro, a próxima seção é a
que deve ler.
