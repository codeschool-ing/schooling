---
title: Rodando no laptop, com o Azurite como storage
version: 1
---

O app roda como dois contêineres numa rede Docker: **o Azurite, no papel da conta de storage, e o
function app construído a partir dos quatro arquivos**. O app acha o Azurite pelo nome do contêiner,
como acharia uma conta de storage pelo endereço, e o seu terminal alcança os dois por portas
publicadas no laptop. Tudo nesta seção é praticado, e a montagem é a mesma de onde as aulas 16 e 17
partem, então vale guardar os arquivos.

## As duas imagens

As duas vêm do registro da Microsoft. A imagem do Functions é grande, cerca de 770 MB para baixar e
2,8 GB depois de descompactada, porque leva o host, o worker Python e um bundle de extensões:

```sh
docker pull mcr.microsoft.com/azure-storage/azurite:3.37.0
docker pull mcr.microsoft.com/azure-functions/python:4-python3.12
```

As duas já estavam na máquina em que estas transcrições foram gravadas.

## Duas strings de conexão para um emulador

O Azurite aceita de saída uma conta, `devstoreaccount1`, com uma chave. **Essa chave está impressa
na documentação da Microsoft e é a mesma em toda cópia do Azurite. Não é segredo, e as strings
abaixo a mandam para o emulador e para nenhum outro lugar.** Pode ser escrita num arquivo sem risco,
e é para isso que este serve. Salve como `~/azure/storage.sh`:

```sh
# storage.sh
# Azurite's development account: a published key, not a secret
KEY='Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw=='
ACCOUNT="DefaultEndpointsProtocol=http;AccountName=devstoreaccount1;AccountKey=$KEY"
# for the function app, inside the Docker network
export FN_STORAGE="$ACCOUNT;BlobEndpoint=http://azurite:10000/devstoreaccount1;QueueEndpoint=http://azurite:10001/devstoreaccount1;TableEndpoint=http://azurite:10002/devstoreaccount1;"
# for az storage, on the laptop
export AZURE_STORAGE_CONNECTION_STRING="$ACCOUNT;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;QueueEndpoint=http://127.0.0.1:10001/devstoreaccount1;TableEndpoint=http://127.0.0.1:10002/devstoreaccount1;"
```

As duas strings só diferem em onde os serviços estão. A porta 10000 é de blobs, a 10001 de filas e a
10002 de tabelas, e o app precisa das três: o host usa blobs para o próprio estado, as funções desta
aula usam uma fila e blobs, e a aula 17 usa tabelas. Dentro da rede o endereço é o nome do
contêiner, `azurite`; do seu terminal é `127.0.0.1`. `AZURE_STORAGE_CONNECTION_STRING` é a variável
que o `az storage` lê quando nenhuma conta é dada na linha de comando, **então o Azure CLI, sem
login, consegue ler e gravar as filas e os blobs do emulador**. É o plano de dados do CLI,
conversando com o Azurite, e nada disso chega ao Azure.

Rode `source storage.sh` em todo terminal que trabalhe com o function app, depois das quatro linhas
que a aula 1 pôs no começo de todo terminal.

## Subindo

```
ana@laptop:~/azure$ source storage.sh
ana@laptop:~/azure$ docker network create functions
3d376dcbec7ec84e8052ab6d4235865a5fd71331faed7208b9a7077c76351384
ana@laptop:~/azure$ docker run -d --name azurite --network functions -p 10000-10002:10000-10002 mcr.microsoft.com/azure-storage/azurite:3.37.0
f331f706299a2cbc98fd47925e64341ee64b4507c1e90b3fe0d580ada928fae0
ana@laptop:~/azure$ docker build -q -t shopfn:1 shopfn
sha256:309dd51b2c36fe562acda7c37b056a48611cb6acade93dff524cfcbbd6bcd27d
ana@laptop:~/azure$ docker run -d --name shopfn --network functions -p 8080:80 -e AzureWebJobsStorage="$FN_STORAGE" shopfn:1
b07ba9e36af6b449b8b4288c778910d271a1ce8d5d3d9b86bd6c7c43c8586fcf
```

A rede se chama `functions` e os dois contêineres entram nela. O Azurite publica as três portas no
laptop. O build imprime o id da imagem nova. O contêiner do app publica a porta 80, que é a porta em
que a imagem do Functions escuta, como porta 8080 no laptop, e recebe uma configuração,
`AzureWebJobsStorage`, apontando para o Azurite. O host leva alguns segundos para começar; quando
está pronto, o log diz o que ele encontrou:

```
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -A1 "Found the following functions"
      Found the following functions:
      Host.Functions.take_order
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep "Mapped function route"
      Mapped function route 'api/orders' [POST] to 'take_order'
```

**Uma função, e uma rota, `api/orders`, aceita só para `POST`.** O `api/` na frente é o prefixo de
rotas do host, o mesmo para toda função HTTP de um app, a menos que o `host.json` o mude. Um pedido
agora chega à função:

```
ana@laptop:~/azure$ curl -s -XPOST localhost:8080/api/orders -d '{"order": "A-1001", "sku": "mug", "qty": 2}'
{"received": "A-1001"}
ana@laptop:~/azure$ docker logs shopfn 2>&1 | grep -A1 -E '^info: Function\.'
info: Function.take_order[1]
      Executing 'Functions.take_order' (Reason='This function was programmatically called via the host APIs.', Id=f55efa35-8e2c-47b9-828b-e5d6a4d816f5)
info: Function.take_order.User[0]
      order A-1001 for 2 x mug
info: Function.take_order[2]
      Executed 'Functions.take_order' (Succeeded, Id=f55efa35-8e2c-47b9-828b-e5d6a4d816f5, Duration=117ms)
```

Cada execução de uma função são duas linhas no log do host, `Executing` e `Executed`, com a linha de
`logging` da própria função entre elas, na categoria `Function.take_order.User`. O motivo,
"programmatically called via the host APIs", é como o host descreve toda chamada HTTP, e o id e a
duração mudam a cada execução.

## Dois processos num contêiner

```
ana@laptop:~/azure$ docker exec shopfn ps -eo pid,args | cut -c1-125
    PID COMMAND
      1 bash /opt/startup/start_nonappservice.sh
     10 /azure-functions-host/Microsoft.Azure.WebJobs.Script.WebHost
     74 python -X no_debug_ranges /azure-functions-host/workers/python/3.12/LINUX/X64/worker.py --host 127.0.0.1 --port 43513
    100 ps -eo pid,args
```

Abaixo do script de partida estão o host, `Microsoft.Azure.WebJobs.Script.WebHost`, e o worker
Python que ele iniciou, avisado na linha de comando de onde encontrar o host: uma porta em
`127.0.0.1`, dentro do contêiner. É a divisão desenhada na seção anterior, e o que o worker lê é só
o que o host manda. Os ids dos processos e a porta mudam a cada partida.

## O que o host gravou antes de qualquer função rodar

Nada em `take_order` toca o storage, e a conta de storage já tem algo dentro:

```
ana@laptop:~/azure$ az storage container list --query "[].name" -o tsv
azure-webjobs-hosts
ana@laptop:~/azure$ az storage blob list -c azure-webjobs-hosts --only-show-errors --query "[].name" -o tsv
locks/b07ba9e36af6-2137340777/host
```

`azure-webjobs-hosts` é o contêiner do host, e `locks/…/host` é o blob sobre o qual ele mantém um
lease. O caminho leva o id do host, que no laptop começa com o id do contêiner, então todo contêiner
novo toma um lease próprio. No Azure o id é feito do nome do function app, toda instância do app o
divide, e o lease é como elas combinam qual roda o que precisa rodar uma vez só, como um trigger de
timer. **A conta de storage faz parte do app mesmo quando nenhuma função a usa**, e a documentação é
direta sobre a configuração: "O seu function app não começa sem essa configuração de conexão."

O `--only-show-errors` no segundo comando cala um aviso que o CLI imprime para grupos de comandos
que ele chama de preview; as transcrições seguintes o levam pelo mesmo motivo.

## A mesma imagem no Azure, não executado aqui

A implantação do app não é executada neste curso: ela precisa de uma assinatura. A documentação da
Microsoft a descreve em três passos. Enviar a imagem para um registro, o que a aula 10 fez com a
imagem da loja. Criar uma conta de storage para a `AzureWebJobsStorage`. Depois criar o function app
com `--image` nomeando a imagem:

```sh
az functionapp create --name shop-fn --resource-group shop-rg --storage-account shopfnstore --plan shop-premium --image shopregistry.azurecr.io/shopfn:1 --functions-version 4
```

`--plan` nomeia um plano que já existe, e o plano é onde se escolhe a hospedagem. A ajuda do CLI
lista as outras maneiras de dizer onde um app roda, e essa ajuda é real no laptop:

```
ana@laptop:~/azure$ az functionapp create --help | grep -E '^    --(image|plan|flexconsumption-location|consumption-plan-location|environment) '
    --consumption-plan-location -c                 : Geographic location where function app will be
    --environment                        [Preview] : Name of the container app environment.
    --flexconsumption-location -f                  : Geographic location where function app will be
    --image -i                                     : Container image, e.g. publisher/image-name:tag.
    --plan -p                                      : Name or resource id of the functionapp app
```

**Qual delas aceita um contêiner não é detalhe.** A tabela de opções de hospedagem da documentação
diz que um contêiner roda no plano Premium, num plano Dedicado (App Service) e no Container Apps,
por `--environment`; o plano Flex Consumption e o plano Consumption só aceitam código: os mesmos
arquivos sem o `Dockerfile`, implantados como pacote. A aula 16 trata do que cada plano faz com a
partida de uma função. Seja qual for, as configurações que esta seção passou com `-e` viram
configurações de aplicativo do app, e o Azure manda os pedidos para a porta 80 do contêiner, a menos
que a configuração `WEBSITES_PORT` diga outra coisa.

Deixe os dois contêineres rodando. A próxima seção começa mandando a esta versão algo que ela não
consegue ler.
