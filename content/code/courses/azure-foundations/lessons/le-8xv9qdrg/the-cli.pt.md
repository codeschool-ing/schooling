---
title: Como a CLI do Azure é montada
version: 1
---

**A CLI do Azure não é um invólucro fino que manda ao Azure o que você digitar. É um programa grande,
que conhece todo comando, todo parâmetro e todo padrão antes de qualquer coisa sair do seu
computador**, e a maior parte dos erros que as pessoas cometem com ela é pega ali, no seu terminal. É
por isso que este laboratório, sem conta nenhuma, consegue mostrar quase tudo de como ela se comporta.

Todo comando tem o mesmo formato: `az`, um **grupo**, às vezes um subgrupo, um **comando**, depois os
parâmetros. `az group create`, `az network vnet subnet list`, `az account show`. Os grupos seguem os
serviços do Azure, e os comandos são verbos que querem dizer a mesma coisa em todo lugar: `create`,
`show`, `list`, `update`, `delete`.

## A ajuda está no programa

Crie primeiro o diretório da lição:

```sh
mkdir -p ~/azure/cli && cd ~/azure/cli
```

Depois pergunte a um comando o que ele recebe. A ajuda faz parte da instalação, então responde aqui
exatamente como responderia com uma conta:

```
ana@laptop:~/azure/cli$ az group create --help | sed -n '1,12p'

Command
    az group create : Create a new resource group.

Arguments
    --name --resource-group -g -n [Required] : Name of the new resource group.
    --location -l                            : Location. Values from: `az account list-locations`.
                                               You can configure the default location using `az
                                               configure --defaults location=<location>`.  Config:
                                               brazilsouth.
    --managed-by                             : The ID of the resource that manages this resource
                                               group.
```

Dois detalhes merecem atenção. Um parâmetro costuma ter várias grafias, `--name`, `--resource-group`,
`-g` e `-n`, e as curtas são as que você vai ver nos scripts dos outros. E a ajuda de `--location`
termina com **`Config: brazilsouth.`**: a CLI já achou o padrão que o `env.sh` definiu, e vai usá-lo
em qualquer comando em que você deixar a localização de fora.

**Um parâmetro faltando é recusado antes de o Azure ser consultado**:

```
ana@laptop:~/azure/cli$ az group create
ERROR: the following arguments are required: --name/--resource-group/-n/-g

Examples from command's help:
az group create -l westus -n MyResourceGroup
Create a new resource group in the West US region.

https://aka.ms/cli_ref
Read more about the command in reference docs
```

A CLI analisou a linha, não achou nome nenhum, e parou com o primeiro exemplo da ajuda. Nada foi
mandado, e ninguém precisou fazer login para essa resposta. Compare com o `az group list` da lição 1,
que era um comando válido recusado por falta de identidade: duas paradas diferentes, em dois lugares
diferentes.

## Padrões, e de onde veio cada configuração

Um padrão poupa digitar o mesmo parâmetro em todo comando, e **um padrão de que você esqueceu é o
jeito mais comum de rodar um comando contra a coisa errada**. A CLI os guarda na sua configuração, que
o `az config` lê e escreve:

```
ana@laptop:~/azure/cli$ az config set defaults.group=rg-shop-prod
WARNING: Command group 'config' is experimental and under development. Reference and support levels: https://aka.ms/CLI_refstatus
ana@laptop:~/azure/cli$ az config get defaults
WARNING: Command group 'config' is experimental and under development. Reference and support levels: https://aka.ms/CLI_refstatus
[
  {
    "name": "location",
    "source": "AZURE_DEFAULTS_LOCATION",
    "value": "brazilsouth"
  },
  {
    "name": "group",
    "source": "/home/ana/azure/.azure/config",
    "value": "rg-shop-prod"
  }
]
ana@laptop:~/azure/cli$ az config unset defaults.group
WARNING: Command group 'config' is experimental and under development. Reference and support levels: https://aka.ms/CLI_refstatus
```

O `az config get` diz a **origem** de cada valor, e essa é a sua utilidade maior. A localização veio
da variável de ambiente que o `env.sh` exporta, o grupo do arquivo `~/azure/.azure/config` que o
`az config set` escreveu, e o `az config unset` o tirou de novo. Quando um comando cai num lugar
inesperado, é a primeira coisa a ler. O aviso em cada linha diz que o `az config` ainda está marcado
como experimental; o irmão mais velho, `az configure --defaults group=rg-shop-prod`, escreve o mesmo
arquivo.

As configurações chegam à CLI de três lugares, e o último vence:

| lugar | exemplo | dura |
|---|---|---|
| o arquivo de configuração em `AZURE_CONFIG_DIR` | `az config set defaults.group=rg-shop-prod` | até ser removido |
| uma variável de ambiente, `AZURE_<SEÇÃO>_<NOME>` | `AZURE_DEFAULTS_LOCATION=brazilsouth` | por aquele terminal |
| um parâmetro na linha de comando | `--location southcentralus` | por aquele comando |

**Um parâmetro na linha sempre vence**, então um script que precisa agir sobre um grupo em particular
o cita toda vez, e não se apoia num padrão que alguém pode ter mudado.

## Extensões

Alguns comandos não estão na própria CLI e sim em **extensões**, pacotes separados que ela instala sob
demanda: `az extension add --name <nome>`, ou automaticamente na primeira vez em que você digita um
comando que precisa de uma. Elas vão para dentro do `AZURE_CONFIG_DIR`, então as do laboratório ficam
separadas de qualquer outra CLI da máquina:

```
ana@laptop:~/azure/cli$ az extension list
[]
```

Nenhuma ainda. **Adicionar uma não foi executado para este curso**: a CLI baixa o índice de extensões
de um endereço de armazenamento da Microsoft que a máquina onde as lições foram gravadas não alcança. Na
sua máquina funciona, e o `az extension list` então a cita com a versão. Nada neste curso precisa de
extensão.

## Quando um comando se comporta mal

O `--debug` faz a CLI imprimir cada passo que dá: quais módulos carregou, quais parâmetros analisou,
qual cliente montou, cada pedido que mandou e cada resposta que recebeu, cabeçalhos incluídos. A lição
25 o usa para ver um comando ir até onde consegue sem conta. Duas opções menores são para scripts: o
`--only-show-errors` cala avisos como o do `az config`, e o `--output none` não imprime nada quando o
código de saída é tudo de que um script precisa.
