---
title: Instalando o laboratório
version: 1
---

Tudo abaixo roda num terminal do Ubuntu 24.04, com o seu próprio usuário, e só o primeiro bloco pede
`sudo`. **O resto vai para dois lugares: `~/gcp`, onde você trabalha no resto do curso, e `~/.local`,
para onde vão a Google Cloud CLI e o Terraform.** Apagar esses dois remove o laboratório por completo.

## Os pacotes do Ubuntu

Python, `curl`, `jq` e `unzip` vêm do próprio repositório do Ubuntu, e o Java também, a linguagem em
que o emulador do Pub/Sub é escrito:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip openjdk-21-jre-headless
```

**O `python3-venv` e o runtime do Java são os dois que as pessoas esquecem**, porque nenhum vem com o
Ubuntu. A seção sobre falhas diz como é a falta de cada um.

## A Google Cloud CLI

O Google publica a linha de comando como um arquivo compactado que se desempacota num único diretório
e roda de lá, com uma cópia própria do Python dentro. Estes comandos baixam uma versão fixa, aquela
com que toda transcrição deste curso foi gravada, para o seu diretório pessoal, então não precisam de
`sudo`:

```sh
mkdir -p ~/gcp ~/.local/bin
cd ~/gcp
curl -sS -o gcloud.tar.gz https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-589.0.0-linux-x86_64.tar.gz
tar -xzf gcloud.tar.gz -C ~/.local
rm gcloud.tar.gz
```

O arquivo tem cerca de 90 MB. Num computador com processador Arm, o que inclui uma máquina virtual
num Mac com Apple silicon, o nome do arquivo termina em `linux-arm.tar.gz`. Uma versão mais nova
funciona para tudo que este curso faz; as linhas de versão e a redação de algumas mensagens vão
diferir das lições, e nada mais.

As instruções do próprio Google oferecem também a CLI como pacote do Ubuntu, vindo de
`packages.cloud.google.com`. Esse caminho a instala para todos os usuários e pede `sudo` a cada
atualização. O arquivo compactado mantém o laboratório inteiro no seu diretório pessoal, e esse é o
motivo de o curso escolhê-lo.

## Mais duas partes da CLI

A CLI é feita de **componentes**, e o arquivo traz só os principais. O emulador do Pub/Sub é um
componente, e os comandos `beta` que o iniciam também:

```sh
~/.local/google-cloud-sdk/bin/gcloud components install pubsub-emulator beta --quiet
```

Os componentes são instalados **na versão da CLI que você tem**, então a 589.0.0 traz o emulador que
saiu com a 589.0.0, e quem instalar o mesmo arquivo no ano que vem recebe o mesmo emulador.

## Terraform

As lições 2 a 21 escrevem o ambiente como arquivos do Terraform e perguntam ao Terraform o que ele
faria com eles. A HashiCorp o publica como um zip com um programa dentro:

```sh
cd ~/gcp
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.16.4/terraform_1.16.4_linux_amd64.zip
unzip -qo terraform.zip terraform -d ~/.local/bin
rm terraform.zip
```

Em Arm o arquivo é `terraform_1.16.4_linux_arm64.zip`. Se você fez o curso `iac` e guardou o
laboratório dele, esta é a mesma versão, e o `terraform version` vai dizer isso.

## As bibliotecas do Python, num ambiente virtual

Duas bibliotecas do Python são usadas mais adiante: a biblioteca cliente do Google para o Pub/Sub, na
lição 24, e o DuckDB, um banco de dados pequeno que lê os dados de faturamento da lição 14. Um ambiente
virtual é um diretório com a sua própria cópia do instalador de pacotes do Python, então o que você
instala ali não toca em mais nada da máquina:

```sh
python3 -m venv ~/gcp/venv
~/gcp/venv/bin/pip install -q 'google-cloud-pubsub==2.42.0' 'duckdb==1.5.6'
```

## Um arquivo que prepara todo terminal

Algumas variáveis de ambiente dizem às ferramentas onde as coisas estão. Um arquivo curto define todas
elas, e toda lição começa lendo-o:

```sh
cat > ~/gcp/env.sh <<'EOF'
# The Google Cloud courses' lab. Read it into every terminal: source ~/gcp/env.sh
export PATH="$HOME/.local/bin:$HOME/.local/google-cloud-sdk/bin:$PATH"
. "$HOME/gcp/venv/bin/activate"
export CLOUDSDK_CONFIG="$HOME/gcp/gcloud"
export PUBSUB_EMULATOR_HOST=localhost:8085
export TF_PLUGIN_CACHE_DIR="$HOME/gcp/terraform-plugins"
export CHECKPOINT_DISABLE=1
mkdir -p "$TF_PLUGIN_CACHE_DIR"
cd "$HOME/gcp"
EOF
```

Linha a linha, depois do comentário:

| linha | o que faz |
|---|---|
| `PATH` | põe no caminho o `~/.local/bin`, onde está o `terraform`, e o `bin` da própria CLI, onde está o `gcloud` |
| `activate` | entra no ambiente virtual, para o `python3` enxergar as duas bibliotecas |
| `CLOUDSDK_CONFIG` | **dá ao `gcloud` um diretório de configurações que pertence ao laboratório e a mais nada** |
| `PUBSUB_EMULATOR_HOST` | diz às bibliotecas cliente do Google para mandar os pedidos do Pub/Sub ao emulador deste computador |
| `TF_PLUGIN_CACHE_DIR` | guarda uma só cópia do provider do Google para o Terraform, uns 130 MB, para todo diretório que o pedir |
| `CHECKPOINT_DISABLE` | impede o Terraform de perguntar à HashiCorp se existe versão mais nova |

O `CLOUDSDK_CONFIG` é a linha que mais importa. Sem ela, o `gcloud` guarda as configurações e as
credenciais em `~/.config/gcloud`. **Se você já entrou alguma vez numa conta Google real com o
`gcloud`, é lá que a conta está**, e um laboratório que dividisse esse diretório mandaria os seus
comandos para os seus projetos reais. Com a linha, o laboratório enxerga um diretório só dele, que
nunca guardou credencial nenhuma.

## As configurações do laboratório

O `gcloud` lê as configurações, que ele chama de **propriedades**, desse diretório. Cinco delas fazem
do laboratório o que ele é:

```sh
source ~/gcp/env.sh
echo placeholder > ~/gcp/placeholder-token
gcloud config set core/project planner-dev
gcloud config set core/disable_usage_reporting true
gcloud config set auth/access_token_file ~/gcp/placeholder-token
gcloud config set api_endpoint_overrides/pubsub http://localhost:8085/
gcloud config set compute/region southamerica-east1
```

| propriedade | o que faz |
|---|---|
| `core/project` | `planner-dev`, o projeto sobre o qual todo comando age, a não ser que nomeie outro |
| `core/disable_usage_reporting` | impede a CLI de mandar ao Google estatísticas do próprio uso |
| `auth/access_token_file` | **a credencial: a palavra `placeholder` num arquivo.** O `gcloud` a manda como está, o emulador a ignora, e o Google a recusa |
| `api_endpoint_overrides/pubsub` | **manda todo pedido do Pub/Sub ao emulador, na porta 8085 deste computador, em vez de ao Google** |
| `compute/region` | `southamerica-east1`, São Paulo, a região em que toda lição trabalha |

Dois desses comandos respondem com um aviso, e os dois são esperados. O override avisa que
`http://localhost:8085/` não pertence a nenhum *universe domain* que ele conheça: um universo é uma
cópia separada do Google Cloud, como uma operada para um governo, e `googleapis.com` é o público. Um
endereço no seu próprio computador não está em nenhum deles, que é exatamente o que o laboratório
quer.

A ordem importa uma vez. O `gcloud` confere uma região com o Google antes de guardá-la, e não pergunta
nada enquanto não tem uma credencial, então o `compute/region` vem depois do token. Com só um
placeholder para mandar, a conferência não pode ser feita, e o `gcloud` diz isso e guarda o valor
mesmo assim. Definir a região uma segunda vez mostra o aviso:

```
ana@laptop:~/gcp$ gcloud config set compute/region southamerica-east1
WARNING: Property validation for compute/region was skipped.
Updated property [compute/region].
```

**Nunca ponha uma credencial real nesse arquivo**, nem em lugar nenhum que este curso mandar você
escrever. `placeholder` não é segredo, e um pedido que escape para o Google por engano falha em vez de
fazer alguma coisa. Um token real é segredo, e um arquivo no seu diretório pessoal vai parar em
backups, pastas compartilhadas e capturas de tela sem que ninguém tenha decidido isso.

## Toda vez que você abre um terminal

Uma linha, em cada um dos dois terminais:

```sh
source ~/gcp/env.sh
```

O seu prompt ganha um `(venv)` na frente; as transcrições das lições o deixam de fora.

No **primeiro terminal**, inicie o emulador. Ele deixa esse terminal ocupado enquanto roda, e é essa a
ideia: o que ele diz aparece ali na hora.

```sh
gcloud beta emulators pubsub start --host-port=localhost:8085
```

No **segundo terminal**, confira que cada ferramenta responde, e mande ao emulador o primeiro pedido:

```
ana@laptop:~/gcp$ gcloud version
Google Cloud SDK 589.0.0
beta 2026.10.09
bq 2.1.40
bundled-python3-unix 3.14.8
core 2026.10.09
gcloud-crc32c 1.0.0
gsutil 5.37
pubsub-emulator 0.8.37
Updates are available for some Google Cloud CLI components.  To install them,
please run:
  $ gcloud components update
ana@laptop:~/gcp$ gcloud config list
[api_endpoint_overrides]
pubsub = http://localhost:8085/
[auth]
access_token_file = /home/ana/gcp/placeholder-token
[compute]
region = southamerica-east1
[core]
disable_usage_reporting = true
project = planner-dev

Your active configuration is: [default]
ana@laptop:~/gcp$ gcloud pubsub topics create orders
Created topic [projects/planner-dev/topics/orders].
ana@laptop:~/gcp$ gcloud pubsub topics list
---
name: projects/planner-dev/topics/orders
ana@laptop:~/gcp$ terraform version
Terraform v1.16.4
on linux_amd64
ana@laptop:~/gcp$ python3 -c 'from importlib.metadata import version as v; print(v("duckdb"), v("google-cloud-pubsub"))'
1.5.6 2.42.0
ana@laptop:~/gcp$ cd ~ && du -sh .local/google-cloud-sdk .local/bin/terraform gcp/venv
893M	.local/google-cloud-sdk
115M	.local/bin/terraform
135M	gcp/venv
ana@laptop:~/gcp$ ps -C java -o rss=,comm=
178328 java
```

O `gcloud version` lista os componentes, e o `pubsub-emulator` e o `beta` estão entre eles. **Deixe
de lado a atualização que ele oferece**: o `gcloud components update` levaria a CLI inteira para a
versão mais nova, e as transcrições destas lições para uma versão com que não foram gravadas. O
`gcloud config list` imprime as cinco propriedades, e diz a que **configuração** elas pertencem:
`default`, aquela com que toda CLI começa. A lição 22 cria outras. O `topics create` e o `topics list`
são os primeiros pedidos a chegar ao emulador, que aceitou `planner-dev` como projeto sem perguntar se
ele existe. Nada neste computador sabe; essa é a primeira diferença entre o laboratório e o Google, e
a próxima seção lista as outras.

No primeiro terminal, o emulador imprimiu algumas linhas ao iniciar:

```
ana@laptop:~/gcp$ gcloud beta emulators pubsub start --host-port=localhost:8085
Executing: /home/ana/.local/google-cloud-sdk/platform/pubsub-emulator/bin/cloud-pubsub-emulator --host=localhost --port=8085
[pubsub] This is the Google Pub/Sub fake.
[pubsub] Implementation may be incomplete or differ from the real system.
[pubsub] Oct 30, 2026 2:55:35 PM com.google.cloud.pubsub.testing.v1.Main main
[pubsub] INFO: IAM integration is disabled. IAM policy methods and ACL checks are not supported
[pubsub] SLF4J(W): No SLF4J providers were found.
[pubsub] SLF4J(W): Defaulting to no-operation (NOP) logger implementation
[pubsub] SLF4J(W): See https://www.slf4j.org/codes.html#noProviders for further details.
[pubsub] Oct 30, 2026 2:55:36 PM com.google.cloud.pubsub.testing.v1.Main main
[pubsub] INFO: Server started, listening on 8085
[pubsub] Oct 30, 2026 2:55:36 PM io.gapi.emulators.netty.HttpVersionRoutingHandler channelRead
[pubsub] INFO: Detected non-HTTP/2 connection.
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.netty.HttpVersionRoutingHandler channelRead
[pubsub] INFO: Detected non-HTTP/2 connection.
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: Host
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: user-agent
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: accept-encoding
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: accept
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Not forwarding key: Connection
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Not forwarding key: Content-Length
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: content-type
[pubsub] Oct 30, 2026 2:55:39 PM io.gapi.emulators.grpc.HttpAdapter$StubMethodHandler handle
[pubsub] INFO: Forwarding key: authorization
```

**`IAM integration is disabled` é o emulador dizendo o que ele não é.** Ele aceita todo pedido de
qualquer um, e as lições 5 a 9, que tratam de quem pode fazer o quê, são ensinadas pela documentação do
Google exatamente por isso. As linhas depois de `Server started` são o primeiro pedido chegando, o
`topics create`, um cabeçalho de cada vez. A última delas, `Forwarding key: authorization`, é o token
placeholder chegando ao emulador, que não faz nada com ele. Todo pedido acrescenta uma dúzia de linhas
assim, e a transcrição para depois do primeiro.

As últimas linhas do segundo terminal são o custo do laboratório: o disco que as instalações ocupam, e
a memória que o emulador segura enquanto roda, em kilobytes. Pare o emulador com **Ctrl+C** no terminal
dele ao terminar uma sessão; a próxima lição o inicia de novo, vazio.
