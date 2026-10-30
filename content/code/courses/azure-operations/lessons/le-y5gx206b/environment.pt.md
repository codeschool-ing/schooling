---
title: O seu Azure, no seu computador
version: 1
---

Este curso é praticado no seu próprio computador, com a linha de comando real do Azure, `az`, e alguns
programas que a Microsoft publica para trabalhar sem a nuvem. Não há assinatura do Azure em parte
nenhuma, nada é cobrado, e a plataforma não roda nada por você: cada comando destas lições é um comando
que você digita no seu terminal. **A lição 1 de `azure-foundations` monta este ambiente por inteiro**,
com os três jeitos de ter um terminal com Ubuntu 24.04 (instalado, que ela recomenda; uma máquina
virtual; um shell alugado on-line), o que cada um custa ao seu computador e o que fazer quando a
instalação falha. Se você fez aquele curso, já tem o que vem a seguir. Se não fez, ou apagou depois,
esta seção é a mesma instalação em resumo. Lições posteriores acrescentam três ferramentas, cada uma na
lição que precisa dela primeiro: o Bicep na lição 4, o Terraform na lição 6 e um emulador do Kusto na
lição 9.

## Montando

Quatro pacotes vêm do repositório do Ubuntu. O `docker.io` roda os emuladores, e a última linha deixa
você usá-lo sem `sudo`; ela vale a partir do próximo login, então saia e entre de novo uma vez:

```sh
sudo apt-get update
sudo apt-get install -y python3-venv curl unzip jq docker.io
sudo usermod -aG docker "$USER"
```

Depois, a linha de comando do Azure, versão 2.91.0, num ambiente virtual próprio em `~/azure/venv`. Ela
é um programa em Python, e por isso vem do `pip`; nada aqui precisa de `sudo`:

```sh
mkdir -p ~/azure && cd ~/azure
python3 -m venv venv
venv/bin/pip install -q 'azure-cli==2.91.0'
```

O último passo é o **Azurite**, o emulador da Microsoft para o Azure Storage: blobs, filas e tabelas, em
três portas do seu computador. Ele roda num contêiner, e `--restart unless-stopped` o traz de volta
depois de reiniciar a máquina:

```sh
docker run -d --name azurite --restart unless-stopped \
  -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0
```

## Cada terminal novo

Três linhas apontam um terminal para o laboratório. A connection string `UseDevelopmentStorage=true` é
um atalho que toda ferramenta de armazenamento do Azure entende: significa o Azurite nesta máquina, com
a conta de desenvolvimento conhecida `devstoreaccount1`. A segunda variável impede a linha de comando de
enviar dados de uso para a Microsoft:

```sh
cd ~/azure && source venv/bin/activate
export AZURE_STORAGE_CONNECTION_STRING=UseDevelopmentStorage=true
export AZURE_CORE_COLLECT_TELEMETRY=false
```

Depois, confira se ele responde:

```
ana@laptop:~/azure$ az version
{
  "azure-cli": "2.91.0",
  "azure-cli-core": "2.91.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
ana@laptop:~/azure$ docker ps --format "{{.Names}}  {{.Image}}  {{.Status}}"
azurite  mcr.microsoft.com/azure-storage/azurite:3.37.0  Up 2 seconds
ana@laptop:~/azure$ az storage container create --name smoke -o tsv
True
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv
smoke
ana@laptop:~/azure$ du -sh ~/azure/venv
707M	/home/ana/azure/venv
```

A primeira resposta é a versão. O contêiner é o Azurite, e os dois comandos de armazenamento criaram nele
um contêiner chamado `smoke` e o listaram de volta. A última linha é o disco que a linha de comando ocupa,
que apagar `~/azure` devolve; a imagem do Azurite soma uns 600 MB, que `docker rmi` remove.

## Quando não responde

Três falhas cobrem quase todos os casos. **Falta a connection string**, num terminal novo onde as três
linhas não foram digitadas:

```
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv
ERROR: Please provide storage account name or connection string.
```

**O Azurite não está rodando**. A linha de comando tenta por um tempo e depois desiste do endereço:

```
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv 2>&1 | tail -1
ERROR: HTTPConnection(host='127.0.0.1', port=10000): Failed to establish a new connection: [Errno 111] Connection refused
```

**Um Azurite mais antigo continua na sua máquina.** Cada versão da linha de comando fala uma versão mais
nova da API de armazenamento, e o Azurite recusa uma que não conhece em vez de adivinhar. Este é o
3.35.0, duas versões atrás do que o curso fixa:

```
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv 2>&1 | grep -m1 "API version"
ERROR: The API version 2026-04-06 is not supported by Azurite. Please upgrade Azurite to latest version and retry. If you are using Azurite in Visual Studio, please check you have installed latest Visual Studio patch. Azurite command line parameter "--skipApiVersionCheck" or Visual Studio Code configuration "Skip Api Version Check" can skip this error. 
```

Remova-o com `docker rm -f azurite` e suba a imagem fixada de novo. A mensagem também sugere pular a
verificação de versão; não pule, porque aí os dois programas discordam em silêncio.
