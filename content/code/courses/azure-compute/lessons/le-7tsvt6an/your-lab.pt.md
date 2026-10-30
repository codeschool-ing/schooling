---
title: Seu laboratório, em resumo
version: 1
---

**Este curso é praticado com a linha de comando real do Azure, o compilador Bicep real e os
programas que a Microsoft distribui para rodar partes do Azure num notebook, e sem conta no
Azure.** Todo comando dele roda no seu próprio computador, não custa nada e não chega a nenhuma
assinatura. Os quatro cursos de Azure desta escola dividem um único ambiente, e o
`azure-foundations` o monta na lição 1, com cada caminho explicado. Se você fez aquele curso e
guardou o laboratório, pule para a verificação perto do fim desta seção. Se não, os passos estão
abaixo, em resumo, e montam a mesma coisa.

## Menos do que você talvez espere, e mais do que nada

Você pode esperar uma imitação do Azure que aceite `az vm create` e devolva o id de uma máquina,
como um servidor falso faz o papel de uma API numa suíte de testes. **Isso não existe para o
Azure.** Nada que roda num notebook responde ao Azure Resource Manager, a API pela qual toda
assinatura, máquina virtual, scale set, cluster AKS, Container App e plano do App Service é
criado. A próxima seção diz exatamente o que roda aqui e o que cada lição faz em vez disso. Por
ora, a versão curta é três ferramentas e o Docker:

- **a CLI do Azure**, `az`, que você vai usar pelo texto de ajuda, pelas listas offline e pela
  única resposta que ela dá sem assinatura, uma recusa;
- **o compilador Bicep**, que lê uma declaração de recursos do Azure e confere cada propriedade
  contra os tipos de recurso do próprio Azure, offline;
- **o Docker**, do curso `docker`, que roda as imagens que o Azure rodaria e os emuladores que a
  Microsoft publica como imagens: armazenamento, o host do Functions, Service Bus e Event Hubs.
  Cada lição que precisa de um deles o baixa na hora.

## Três jeitos de ter o laboratório

**Recomendado: instalar no Ubuntu 24.04**, no seu próprio computador ou na máquina virtual que você
usou no curso `docker`. A linha de comando e o compilador ocupam cerca de 800 MB de disco, e as
imagens que as lições seguintes baixam ocupam alguns gigabytes a mais até o fim. Uma **máquina
virtual** (VirtualBox, ou Multipass no Windows e no macOS) custa esses gigabytes mais 4 GB de
memória enquanto roda, porque a lição 11 sobe um pequeno cluster Kubernetes dentro dela; em troca,
dá a você um Ubuntu limpo para quebrar. Um **ambiente online** como o GitHub Codespaces não pede
instalação e já tem Docker, ao preço de uma cota mensal de horas e de armazenamento que você deve
conferir antes de depender dela. A lição 1 do `azure-foundations` percorre os três; os comandos
abaixo são os mesmos em cada um.

## Os comandos

Os pacotes vêm do repositório do próprio Ubuntu, e este é o único passo que pede `sudo`. O Docker
é o que o curso `docker` instalou, e não se repete aqui:

```sh
sudo apt-get update
sudo apt-get install -y python3 python3-venv curl unzip jq
```

A CLI do Azure, versão 2.91.0, num ambiente virtual só dela para não tocar em mais nada da máquina,
e o compilador Bicep, versão 0.48.1, que a CLI baixa para `~/.azure/bin`. A linha `config` desliga
os relatórios de uso que a CLI mandaria para a Microsoft:

```sh
mkdir -p ~/azure ~/.local/bin
cd ~/azure
python3 -m venv venv
venv/bin/pip install -q 'azure-cli==2.91.0'
venv/bin/az config set core.collect_telemetry=false
venv/bin/az bicep install --version v0.48.1
```

A instalação leva alguns minutos, a maior parte com o `pip` buscando as várias centenas de pacotes
da CLI. Num processador Arm, o que inclui uma máquina virtual num Mac com Apple silicon, os mesmos
comandos funcionam: o `pip` e o `az bicep install` escolhem sozinhos as versões para Arm.

**Toda vez que você abrir um terminal para trabalhar**, estas linhas vêm primeiro. Elas põem a CLI
e o compilador no seu path e escolhem São Paulo, `brazilsouth`, como a região que qualquer comando
que peça uma vai receber:

```sh
cd ~/azure
source venv/bin/activate
export PATH="$HOME/.local/bin:$HOME/.azure/bin:$PATH"
export AZURE_DEFAULTS_LOCATION=brazilsouth
```

Seu prompt ganha `(venv)` na frente; as transcrições o omitem.

## Conferindo que ele responde

No seu terminal de trabalho:

```
ana@laptop:~/azure$ az version
{
  "azure-cli": "2.91.0",
  "azure-cli-core": "2.91.0",
  "azure-cli-telemetry": "1.1.0",
  "extensions": {}
}
ana@laptop:~/azure$ bicep --version
Bicep CLI version 0.48.1 (cec7951cf6)
ana@laptop:~/azure$ docker --version
Docker version 29.9.2, build a82e528
```

Sua versão do Docker pode ser mais nova; qualquer uma a partir da 27 se comporta igual neste
curso. Agora pergunte algo ao Azure:

```
ana@laptop:~/azure$ az account show
ERROR: Please run 'az login' to setup account.
ana@laptop:~/azure$ az vm list-skus --size Standard_D2 --output table
ERROR: Please run 'az login' to setup account.
```

**Essa recusa é a resposta certa, e é a que você vai ver sempre que um comando precisar de uma
assinatura.** Nada foi mandado para lugar nenhum: a CLI não encontrou conta conectada e parou antes
de fazer o pedido. Não rode `az login` durante este curso. Ele abriria um login real da Microsoft,
e todo comando escrito aqui supõe que a CLI não tem ninguém em nome de quem agir.

## Quando ele não responde

Três falhas cobrem quase tudo. **As linhas do terminal não foram digitadas** neste terminal, então
nada chamado `az` está no path. Um terminal novo começa assim; este foi aberto com o ambiente vazio
para mostrar:

```
ana@laptop:~/azure$ env -i HOME=$HOME bash --norc -c "az version"
bash: line 1: az: command not found
```

Digite as quatro linhas de novo. **A instalação parou no meio**, quase sempre porque a rede caiu
enquanto o `pip` baixava: rode a linha do `pip install` de novo, e ele continua do que já tem. E
**o Docker não está rodando**, o que as lições seguintes vão mostrar como uma falha ao alcançar o
daemon:

```
ana@laptop:~/azure$ DOCKER_HOST=unix:///run/nothing.sock docker info 2>&1 | tail -n 1
failed to connect to the docker API at unix:///run/nothing.sock; check if the path is correct and if the daemon is running: dial unix /run/nothing.sock: connect: no such file or directory
```

O caminho aqui é um socket que não existe, escolhido para a mensagem aparecer; na sua máquina ela
cita `/var/run/docker.sock`. `sudo systemctl start docker` sobe o daemon, e a lição de instalação do
curso `docker` é o lugar para onde voltar se isso não resolver.

Vale fazer mais uma verificação antes de seguir, porque uma lição adiante depende dela. A linha da
região é lida por todo comando que aceita uma localização e não recebeu nenhuma:

```
ana@laptop:~/azure$ echo $AZURE_DEFAULTS_LOCATION
brazilsouth
```

Se ele imprimir uma linha vazia, a quarta linha do terminal ficou de fora.
