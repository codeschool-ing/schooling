---
title: O seu laboratório, em resumo
version: 1
---

**Este curso é praticado contra os emuladores da própria Microsoft, no seu computador, com a linha de
comando de verdade do Azure e sem conta no Azure.** É o ambiente que os quatro cursos de Azure
compartilham, e a lição 1 do `azure-foundations` monta a parte comum passo a passo: a linha de
comando, o Docker, o Azurite e o Terraform. Se você fez aquela lição e guardou o laboratório, leia só
"Mais três, para este curso" e "Toda vez que abrir um terminal", abaixo. Se não fez, os passos estão
aqui em resumo. A plataforma não roda nada por você: nem máquina, nem shell no navegador, nem conta.

**Todas as transcrições foram gravadas no Ubuntu 24.04**, e há três jeitos de tê-lo. Instalado é o
recomendado, como seu sistema ou no WSL do Windows (`wsl --install -d Ubuntu-24.04` num PowerShell de
administrador, e o Docker instalado dentro do Ubuntu como abaixo). Uma máquina virtual é o caminho
num Mac: Ubuntu Server 24.04 no UTM, no VirtualBox ou no Multipass, com 4 processadores, 8 GB de
memória e 40 GB de disco, porque só o SQL Server pede 2 GB de memória. Um shell online alugado por
hora também serve, desde que deixe rodar o Docker, mas nenhuma lição depende da cota gratuita de
empresa nenhuma. No seu disco o laboratório inteiro ocupa uns 7 GB, quase tudo imagens de contêiner,
e nada nele roda se você não mandar.

## Os pacotes do Ubuntu

```sh
sudo apt-get update
sudo apt-get install -y docker.io docker-compose-v2 python3 python3-venv curl unzip jq
sudo usermod -aG docker "$USER"
```

A última linha deixa você rodar `docker` sem `sudo`. Ela vale a partir do próximo login, então saia
da sessão e entre de novo uma vez antes de seguir.

## A linha de comando do Azure

Versão 2.91.0, do índice de pacotes do Python, num diretório só dela, para que nada mais que você
instale possa atrapalhá-la:

```sh
mkdir -p ~/azure ~/.local/bin
python3 -m venv ~/.local/azure-cli
~/.local/azure-cli/bin/pip install -q azure-cli==2.91.0
ln -sf ~/.local/azure-cli/bin/az ~/.local/bin/az
```

Leva alguns minutos e ocupa uns 700 MB. **A linha de comando é o mesmo programa que administra uma
assinatura de verdade**; aqui ela só vai falar com os emuladores, porque todo comando que este curso
lhe dá aponta o endereço do emulador.

## Terraform

Versão 1.17.1, num arquivo só. A segunda metade manda o Terraform guardar os providers que baixa num
cache compartilhado, para que o diretório de cada lição não baixe de novo os 250 MB do provider do
Azure:

```sh
cd ~/azure
curl -sSfO https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_amd64.zip
unzip -oq terraform_1.17.1_linux_amd64.zip terraform -d ~/.local/bin
rm terraform_1.17.1_linux_amd64.zip
mkdir -p ~/.terraform.d/plugin-cache
printf 'plugin_cache_dir = "%s/.terraform.d/plugin-cache"\n' "$HOME" > ~/.terraformrc
```

Num processador Arm, o que inclui uma máquina virtual num Mac com Apple silicon, o arquivo é
`terraform_1.17.1_linux_arm64.zip`. **O Terraform nunca cria nada neste curso.** Ele lê os arquivos
que declarariam uma conta de armazenamento ou um banco e diz se o provider do Azure os aceita, que é a
única pergunta sobre o plano de controle que se responde sem conta.

## Mais três, para este curso

**Esta é a parte que o `azure-foundations` não tem.** Primeiro, as bibliotecas Python que os
programas das lições usam: os kits de desenvolvimento da Microsoft para Blob Storage, Cosmos DB e
Event Hubs, e três para as lições de análise. O DuckDB é um motor de banco de dados que mora dentro
de um programa Python, o PyArrow lê e escreve Parquet, e o `deltalake` lê e escreve tabelas Delta:

```sh
python3 -m venv ~/azure/venv
~/azure/venv/bin/pip install -q azure-storage-blob==12.30.0 azure-cosmos==4.17.1 \
  azure-eventhub==5.15.1 azure-eventhub-checkpointstoreblob==1.2.0 \
  duckdb==2.0.0 pyarrow==26.0.0 deltalake==1.6.6
```

**A biblioteca do Blob Storage está uma versão atrás de propósito.** Cada versão dela fala a versão
mais nova do protocolo de armazenamento, e o Azurite 3.37.0 entende versões até `2026-06-06`, que é a
que a 12.30.0 fala. A versão seguinte pede uma mais nova, e o Azurite recusa toda requisição.

Segundo, um arquivo que nomeia cada emulador que o curso usa e como ligá-lo. Salve-o como
`compose.yaml`, em `~/azure`:

`compose.yaml`:

```yaml
name: azure
services:
  azurite:
    image: mcr.microsoft.com/azure-storage/azurite:3.37.0
    command: >-
      azurite --blobHost 0.0.0.0 --queueHost 0.0.0.0 --tableHost 0.0.0.0
      --inMemoryPersistence --disableTelemetry
    ports:
      - "127.0.0.1:10000-10002:10000-10002"

  cosmos:
    image: mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-EN20261019
    command: --protocol http
    ports:
      - "127.0.0.1:8081:8081"
    profiles: [cosmos]

  sql:
    image: mcr.microsoft.com/mssql/server:2025-CU9-ubuntu-24.04
    environment:
      ACCEPT_EULA: "Y"
      MSSQL_SA_PASSWORD: "Quitanda-Lab-2026"
      MSSQL_AGENT_ENABLED: "true"
    ports:
      - "127.0.0.1:1433:1433"
    profiles: [sql]

  eventhubs:
    image: mcr.microsoft.com/azure-messaging/eventhubs-emulator:2.2.1
    environment:
      ACCEPT_EULA: "Y"
      BLOB_SERVER: azurite
      METADATA_SERVER: azurite
    volumes:
      - ./eventhubs/config.json:/Eventhubs_Emulator/ConfigFiles/Config.json:ro
    ports:
      - "127.0.0.1:5672:5672"
    depends_on: [azurite]
    profiles: [eventhubs]

  postgres:
    image: postgres:17.6
    environment:
      POSTGRES_PASSWORD: "Quitanda-Lab-2026"
    ports:
      - "127.0.0.1:5432:5432"
    profiles: [postgres]

  redis:
    image: redis:8.2.2
    ports:
      - "127.0.0.1:6379:6379"
    profiles: [redis]
```

Toda porta é publicada só em `127.0.0.1`, então nada na sua rede alcança os emuladores, e a senha é
uma senha de laboratório que não protege nada. O `--inMemoryPersistence` faz o Azurite esquecer tudo
quando para, como os outros emuladores daqui. O `--disableTelemetry` importa mais do que parece: sem
ele, o Azurite informa o próprio uso à Microsoft pela internet. **Um profile é um grupo de serviços
que só sobe quando é pedido**, então um `docker compose up -d` simples sobe só o Azurite, e uma lição
que precisa do Cosmos DB diz `--profile cosmos`.

Terceiro, o emulador do Event Hubs lê de um arquivo os hubs que deve criar. Salve-o como
`eventhubs/config.json`, também em `~/azure`:

`eventhubs/config.json`:

```json
{
  "UserConfig": {
    "NamespaceConfig": [
      {
        "Type": "EventHub",
        "Name": "emulatorNs1",
        "Entities": [
          {
            "Name": "clicks",
            "PartitionCount": 4,
            "ConsumerGroups": [{ "Name": "fraud" }]
          }
        ]
      }
    ],
    "LoggingConfig": { "Type": "File" }
  }
}
```

Depois baixe cada imagem uma vez, para que nenhuma lição fique esperando por uma:

```sh
docker compose --profile '*' pull
```

As imagens somam uns 6 GB. O SQL Server só é publicado para processadores Intel; num Mac com Apple
silicon, o Docker Desktop o roda pela camada de emulação, devagar mas corretamente.

## Ligar o que uma lição precisa

Cada parte do curso diz os emuladores que usa, e você os liga com uma linha em `~/azure`. As lições
de armazenamento precisam só do Azurite:

```sh
docker compose up -d
```

**Parar é `docker compose --profile '*' down`, e isso esquece tudo**: cada contêiner, blob, documento
e evento que os emuladores guardavam. Cada lição começa de emuladores vazios e constrói o que precisa,
então você pode parar no fim de uma sessão de estudo sem perder nada que uma lição não reconstrua.

## Toda vez que abrir um terminal

No terminal em que você vai digitar pelo resto do curso:

```sh
cd ~/azure
export PATH="$HOME/.local/bin:$PATH" && source venv/bin/activate
export AZURE_STORAGE_CONNECTION_STRING="UseDevelopmentStorage=true"
export AZURE_CORE_COLLECT_TELEMETRY=false
```

A primeira linha é onde ficam os arquivos do curso. A segunda põe `az` e `terraform` no path e ativa
o ambiente virtual. **A terceira é o truque inteiro**: todo comando `az storage` lê essa variável, e
`UseDevelopmentStorage=true` é um nome curto que as bibliotecas do Azure expandem para o endereço do
Azurite em `127.0.0.1`, com o nome e a chave fixos e publicados da conta dele. A quarta impede a linha
de comando de informar o próprio uso à Microsoft, o mesmo que o `--disableTelemetry` faz pelo Azurite.

## Confira se responde

```
ana@laptop:~/azure$ az version --query '"azure-cli"' -o tsv
2.91.0
ana@laptop:~/azure$ terraform version | head -1
Terraform v1.17.1
ana@laptop:~/azure$ docker compose ps --format '{{.Service}} {{.State}}'
azurite running
ana@laptop:~/azure$ az storage container list -o table

ana@laptop:~/azure$ az storage container create -n smoke-test
{
  "created": true
}
ana@laptop:~/azure$ az storage container list --query '[].name' -o tsv
smoke-test
ana@laptop:~/azure$ az storage account show-connection-string -n devstoreaccount1 2>&1 | tail -1
ERROR: Please run 'az login' to setup account.
```

**A primeira lista vazia é um Azurite vazio, e o contêiner que aparece depois dela é a prova de que a
linha de comando chegou até ele.** O último comando é o que vale guardar. Ele pergunta sobre uma
*conta* de armazenamento, que é o plano de controle: o Azure Resource Manager, atrás de um login,
dentro de uma assinatura. Nenhum emulador responde a isso, então a linha de comando para antes de
mandar qualquer coisa e pede que você faça login, o que você não vai fazer neste curso. Tudo o que
fica dentro de uma conta, os contêineres e os blobs, é o plano de dados, e é a isso que o Azurite
responde.
