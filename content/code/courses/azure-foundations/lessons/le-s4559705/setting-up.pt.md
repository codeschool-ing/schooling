---
title: Instalando o laboratório
version: 1
---

Tudo abaixo roda num terminal no Ubuntu 24.04, como o seu próprio usuário, e só o primeiro bloco
pede `sudo`. **Todo o resto vai para dois lugares: `~/azure`, onde você trabalha pelo resto do curso,
e `~/.local/bin`, onde o Terraform fica.** Apagar esses dois, e o cache de providers do Terraform em
`~/.terraform.d`, remove o laboratório por completo.

## Os pacotes do Ubuntu

Python, `curl`, `jq` e `unzip` vêm do próprio arquivo do Ubuntu, e o `dig` também, que a lição 21 usa
para fazer perguntas ao DNS público:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl jq unzip bind9-dnsutils
```

**`python3-venv` é o que as pessoas esquecem**, porque o Ubuntu entrega o Python sem ele. Sem ele o
próximo bloco falha, e a seção sobre falhas diz como isso aparece.

## A CLI do Azure, num ambiente virtual

Um ambiente virtual é um diretório com a sua própria cópia do instalador de pacotes do Python, então
o que você instala ali não toca em mais nada da máquina. A CLI do Azure é um programa Python, e a
Microsoft a publica no Python Package Index como `azure-cli`. Ela vai para um ambiente virtual em
`~/azure/venv`, fixada na versão com que as lições foram gravadas, junto com a biblioteca Azure
Identity, que a lição 8 usa:

```sh
mkdir -p ~/azure ~/.local/bin
python3 -m venv ~/azure/venv
~/azure/venv/bin/pip install -q 'azure-cli==2.91.0' 'azure-identity==1.27.0'
```

Leva alguns minutos e cerca de 700 MB, porque a CLI carrega um cliente para cada serviço do Azure. A
Microsoft também a empacota para o `apt` do Ubuntu, que é o caminho que a documentação dela põe
primeiro; o índice de pacotes é o que deixa fixar a versão num diretório seu sem `sudo`, e os dois
instalam o mesmo programa. Uma versão mais nova serve para tudo o que este curso faz: a linha da
versão e o texto de algumas mensagens vão diferir das lições, e nada mais.

## Terraform

O Terraform é um programa só, publicado pela HashiCorp como arquivo zip. A lição 26 o compara com os
outros jeitos de descrever o Azure, e várias lições antes dela conferem uma configuração com ele. Isto
põe uma versão fixa em `~/.local/bin`:

```sh
cd ~/azure
curl -sS -o terraform.zip https://releases.hashicorp.com/terraform/1.17.1/terraform_1.17.1_linux_amd64.zip
unzip -q terraform.zip terraform -d ~/.local/bin
rm terraform.zip
```

Num computador com processador Arm, o que inclui uma máquina virtual num Mac com Apple silicon, o
arquivo é `terraform_1.17.1_linux_arm64.zip`.

## Um arquivo que aponta tudo para o laboratório

Os dois programas leem as suas configurações de variáveis de ambiente. Um arquivo curto define todas
elas, e toda lição começa lendo esse arquivo:

```sh
cat > ~/azure/env.sh <<'END'
# The Azure courses' lab. Read it into every terminal: source ~/azure/env.sh
export PATH="$HOME/.local/bin:$PATH"
. "$HOME/azure/venv/bin/activate"
export AZURE_CONFIG_DIR="$HOME/azure/.azure"
export AZURE_CORE_COLLECT_TELEMETRY=no
export AZURE_DEFAULTS_LOCATION=brazilsouth
export TF_PLUGIN_CACHE_DIR="$HOME/.terraform.d/plugin-cache"
mkdir -p "$TF_PLUGIN_CACHE_DIR"
cd "$HOME/azure"
END
```

Linha por linha, depois do comentário:

| linha | o que faz |
|---|---|
| `PATH` | põe no caminho o `~/.local/bin`, onde o `terraform` está |
| `activate` | entra no ambiente virtual, o que põe o `az` no caminho |
| `AZURE_CONFIG_DIR` | **guarda tudo o que a CLI do Azure armazena, logins incluídos, em `~/azure/.azure`** em vez de `~/.azure`. Um terminal que nunca lê este arquivo é outra CLI do Azure, com a memória vazia, e é isso que a seção sobre uma conta de verdade usa |
| `AZURE_CORE_COLLECT_TELEMETRY` | impede a CLI de mandar à Microsoft um registro de cada comando que você roda |
| `AZURE_DEFAULTS_LOCATION` | `brazilsouth`, São Paulo, a região em que todas as lições trabalham, usada por qualquer comando que peça uma localização e não receba uma |
| `TF_PLUGIN_CACHE_DIR` | guarda uma cópia de cada provider do Terraform para todas as lições, em vez de uma por diretório |

**Nunca ponha um segredo neste arquivo**, nem em nenhum arquivo que o curso pedir para você criar. Não
há nenhum para pôr: nada no curso faz login em coisa alguma. Um arquivo no seu diretório pessoal acaba
copiado em backups, pastas compartilhadas e capturas de tela sem ninguém ter decidido isso.

## Toda vez que você abrir um terminal

Uma linha:

```sh
source ~/azure/env.sh
```

O seu prompt ganha `(venv)` na frente; as transcrições das lições o omitem.

Na primeira vez, e só nela, peça à CLI do Azure que busque o compilador do Bicep, que as lições 2 a 26
usam para transformar uma descrição de recursos do Azure no JSON que o Resource Manager lê. Ele vai
para `~/azure/.azure/bin`, dentro do diretório que o `env.sh` reservou:

```sh
az bicep install --version v0.48.1
```

Depois confira se cada ferramenta responde:

```
ana@laptop:~/azure$ az version
{
  "azure-cli": "2.91.0",
  "azure-cli-core": "2.91.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
ana@laptop:~/azure$ az bicep version
Bicep CLI version 0.48.1 (cec7951cf6)

ana@laptop:~/azure$ terraform version
Terraform v1.17.1
on linux_amd64

ana@laptop:~/azure$ az account show
ERROR: Please run 'az login' to setup account.
ana@laptop:~/azure$ cd ~ && du -sh azure/venv azure/.azure .local/bin/terraform
709M	azure/venv
117M	azure/.azure
124M	.local/bin/terraform
```

A CLI do Azure informa a sua própria versão e as das suas partes, o Bicep a versão que se pediu, e o
Terraform a versão do arquivo zip. `az account show` faz a pergunta que toda sessão do Azure sabe
responder depois que alguém fez login: em que assinatura estou trabalhando? Aqui ninguém fez, e a CLI
diz isso sem mandar nada a lugar nenhum. Essa recusa é o estado normal deste laboratório, e as
próximas seções dizem por que ele fica assim.

As três últimas linhas são o custo do laboratório em disco, 950 MB somadas: a CLI do Azure no seu
ambiente virtual, o compilador do Bicep dentro de `~/azure/.azure`, e o Terraform. A primeira lição
que roda `terraform init`, a lição 2, acrescenta o provider da Microsoft ao cache, e a lição 6
acrescenta o do Entra ID.
