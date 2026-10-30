---
title: "Tamanhos, e o que acontece quando o processo termina"
version: 1
---

Um grupo de contêineres é dimensionado pelo que os contêineres dele pedem, e não por um cardápio de
tamanhos de máquina como o da lição 1, e é cobrado por segundo pelo que recebeu. **Dois números por
contêiner decidem o tamanho, e uma configuração por grupo decide o que acontece quando um processo
termina.** Os dois ficam fixos durante a vida do grupo: mudar qualquer um significa apagar o grupo e
criá-lo de novo. Esta seção declara o grupo da loja em Bicep, compila, e roda no laptop os
equivalentes Docker das políticas de reinício, porque uma política de reinício só se mostra quando
alguma coisa termina.

## Pedidos e limites

Todo contêiner declara um **pedido**: quantos núcleos de CPU e quantos gigabytes de memória ele
precisa. O pedido é obrigatório, e é o que o grupo recebe. Um contêiner também pode declarar um
**limite**, que precisa ser pelo menos o pedido, e o deixa usar mais quando o grupo tem folga. A
documentação da Microsoft descreve a conta com dois contêineres pedindo uma CPU cada. O grupo recebe
duas, e qualquer um deles pode ganhar um limite de até duas, tudo o que o grupo recebeu, para poder
pegar emprestado o que o outro não está usando. Sem limite, o teto de um contêiner é o pedido dele.

O grupo como um todo tem um piso e um teto. A documentação da Microsoft, lida em 30 de outubro de
2026, põe o piso em **1 CPU e 1 GB por grupo**, enquanto um contêiner dentro dele pode pedir menos, e
o teto de um grupo padrão em 31 CPUs e 240 GB. Ela também avisa que grupos acima de 4 CPUs e 16 GB
podem falhar na implantação quando falta capacidade numa região. Uma pequena parte do que um grupo
recebe vai para os processos do próprio serviço, então um contêiner que pede exatamente o que o
programa precisa vai ter um pouco menos do que isso.

A linha de comando diz o que aceita. Perguntada sobre as quatro configurações desta seção:

```
ana@laptop:~/azure$ az container create --help | awk '/^    --/{p=0} /^    --(cpu|memory|ports|restart-policy) /{p=1} p'
    --cpu                                          : The required number of CPU cores of the
                                                     containers, accurate to one decimal place.
    --memory                                       : The required memory of the containers in GB,
                                                     accurate to one decimal place.
    --ports                                        : A list of ports to open. Space-separated list
                                                     of ports.  Default: [80].
    --restart-policy                               : Restart policy for all containers within the
                                                     container group.  Allowed values: Always,
                                                     Never, OnFailure.
```

CPU e memória vão até uma casa decimal, e a política de reinício aceita três valores, assunto da
próxima parte desta seção. Olhe o `--ports`. **Deixe-o de fora e a CLI abre a porta 80**, em que
nada da loja escuta: um grupo criado com flags e sem `--ports 8080` inicia, roda, e não responde a
ninguém.

## O grupo em Bicep

O arquivo YAML da seção anterior, como uma declaração Bicep. Salve como `~/azure/shop.bicep`:

```bicep
// shop.bicep
param location string = 'brazilsouth'
param image string = 'shopregistry.azurecr.io/shop:1.0'

resource shop 'Microsoft.ContainerInstance/containerGroups@2025-09-01' = {
  name: 'shop'
  location: location
  properties: {
    osType: 'Linux'
    restartPolicy: 'Always'
    containers: [
      {
        name: 'shop'
        properties: {
          image: image
          environmentVariables: [
            { name: 'SHOP_VERSION', value: '1.0' }
          ]
          ports: [
            { port: 8080, protocol: 'TCP' }
          ]
          resources: {
            requests: {
              cpu: 1
              memoryInGB: json('1.5')
            }
          }
        }
      }
    ]
    ipAddress: {
      type: 'Public'
      dnsNameLabel: 'shop-sp'
      ports: [
        { port: 8080, protocol: 'TCP' }
      ]
    }
  }
}

output fqdn string = shop.properties.ipAddress.fqdn
```

A versão da API é mais nova que a do arquivo YAML, `2025-09-01`, a mais nova para a qual este
compilador tem tipos; as propriedades usadas aqui são as mesmas nas duas. Compilado:

```
ana@laptop:~/azure$ bicep build shop.bicep
ana@laptop:~/azure$ ls shop.*
shop.bicep
shop.json
ana@laptop:~/azure$ jq ".resources[0].properties.containers[0].properties.resources" shop.json
{
  "requests": {
    "cpu": 1,
    "memoryInGB": "[json('1.5')]"
  }
}
```

Nenhum aviso, e um template ao lado do arquivo. **A linha estranha é `json('1.5')`.** O Bicep tem
números inteiros e nenhum outro, então uma memória de um gigabyte e meio não pode ser escrita como
número. A função `json` lê o texto `'1.5'` como JSON, e o template o leva como uma expressão que o
Resource Manager transforma em 1,5 quando implanta. Escrever o número direto não dá um aviso, dá um
arquivo que o compilador não consegue ler:

```
ana@laptop:~/azure$ sed "s/json('1.5')/1.5/" shop.bicep > float.bicep
ana@laptop:~/azure$ bicep build float.bicep
/home/ana/azure/float.bicep(25,29) : Error BCP020: Expected a function or property name at this location. [https://aka.ms/bicep/core-diagnostics#BCP020]
/home/ana/azure/float.bicep(25,29) : Error BCP236: Expected a new line or comma character at this location. [https://aka.ms/bicep/core-diagnostics#BCP236]
/home/ana/azure/float.bicep(25,29) : Error BCP022: Expected a property name at this location. [https://aka.ms/bicep/core-diagnostics#BCP022]
/home/ana/azure/float.bicep(25,29) : Error BCP055: Cannot access properties of type "1". An "object" type is required. [https://aka.ms/bicep/core-diagnostics#BCP055]
/home/ana/azure/float.bicep(25,30) : Error BCP018: Expected the ":" character at this location. [https://aka.ms/bicep/core-diagnostics#BCP018]
ana@laptop:~/azure$ ls float.*
float.bicep
```

Cinco erros na linha 25, todos do compilador sem conseguir entender o ponto depois do 1, e nenhum
`float.json`: ao contrário de um aviso, um erro não escreve template.

### O que o compilador deixa passar

Os tipos do Bicep para a política de reinício aceitam as três palavras e, ao lado delas, qualquer
outro texto. Uma política escrita errado compila, portanto, sem uma palavra, enquanto a CLI, que tem
a própria lista de valores permitidos, recusa o mesmo erro na hora:

```
ana@laptop:~/azure$ sed "s/'Always'/'OnFaliure'/" shop.bicep > typo.bicep
ana@laptop:~/azure$ bicep build typo.bicep
ana@laptop:~/azure$ jq -r ".resources[0].properties.restartPolicy" typo.json
OnFaliure
ana@laptop:~/azure$ az container create --resource-group shop --name shop --image shopregistry.azurecr.io/shop:1.0 --restart-policy OnFaliure 2>&1 | head -n 1
ERROR: az container create: 'OnFaliure' is not a valid value for '--restart-policy'. Allowed values: Always, OnFailure, Never.
```

O template agora pede ao Azure uma política de reinício chamada `OnFaliure`, e só o Azure pode dizer
o que faz com isso. **O compilador verifica os nomes e os tipos, e não todos os valores.** Leia você
mesmo uma política de reinício, um tipo de endereço IP e um SKU antes que uma implantação faça isso
por você.

## As três políticas de reinício

A política é do grupo e vale para todos os contêineres dele. A documentação da Microsoft define as
três:

| política | um contêiner que termina é reiniciado | serve para |
|---|---|---|
| `Always`, o padrão | qualquer que seja o código de saída | um servidor, que nunca deveria parar |
| `OnFailure` | só se o código de saída não for 0 | um job que deve terminar uma vez, e tentar de novo se falhar |
| `Never` | não depois do código 0; depois de uma falha a plataforma ainda pode reiniciá-lo | um job que não pode rodar duas vezes depois de dar certo |

**Para a API de pedidos da loja a política é `Always`**, que também é o padrão: um servidor que
termina falhou, qualquer que seja o código, e deve voltar. **Para o relatório de vendas noturno é
`OnFailure`**: o relatório roda, escreve o arquivo, sai com 0, e o grupo para, com o estado mostrado
como *Terminated* e a cobrança parada junto. Um relatório que cai no meio sai com erro e é iniciado
de novo. Preste atenção na nota sobre `Never`. A documentação diz que um contêiner que sai com
código diferente de zero pode ser reiniciado pela plataforma mesmo assim, então um job que deve
rodar no máximo uma vez precisa tratar as próprias falhas e sair com 0.

O Docker tem as mesmas três ideias com nomes próprios, `always`, `on-failure` e `no`, e as roda no
seu laptop, o que o Container Instances não faz. Um relatório que falha toda vez, iniciado com
`on-failure` e o limite opcional do Docker de três novas tentativas:

```
ana@laptop:~/azure$ docker run -d --name report --restart on-failure:3 shop:1.0 python -c "import sys; print('report failed'); sys.exit(1)" > /dev/null
ana@laptop:~/azure$ docker inspect --format "{{.RestartCount}} {{.State.Status}} {{.State.ExitCode}}" report
3 exited 1
ana@laptop:~/azure$ docker logs report
report failed
report failed
report failed
report failed
```

Quatro execuções, a primeira e três reinícios, e então o Docker parou de tentar, deixando o
contêiner `exited` com código 1. A mesma política com um relatório que dá certo:

```
ana@laptop:~/azure$ docker run -d --name report-ok --restart on-failure:3 shop:1.0 python -c "print('report written')" > /dev/null
ana@laptop:~/azure$ docker inspect --format "{{.RestartCount}} {{.State.Status}} {{.State.ExitCode}}" report-ok
0 exited 0
ana@laptop:~/azure$ docker logs report-ok
report written
```

Nenhum reinício, porque um código 0 quer dizer pronto. O Container Instances não documenta limite
de novas tentativas para `OnFailure`, e o `:3` é coisa do Docker; os dois significados da política
são os mesmos.

**Um reinício começa do zero.** Rode a loja, faça um pedido e reinicie:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 shop:1.0 > /dev/null
ana@laptop:~/azure$ curl -s -w '\n' -X POST localhost:8080/orders -d '{"item": "coffee", "qty": 2}'
{"item": "coffee", "qty": 2, "id": 1}
ana@laptop:~/azure$ docker restart shop
shop
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/orders
[]
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/version
{"version": "1.0", "host": "ed31bcd5ec6c", "up_s": 0.7}
```

O pedido sumiu e o `up_s` recomeçou, porque `ORDERS` vivia no processo. No Container Instances um
reinício também pode mudar o endereço IP do grupo, como disse a seção 02. O que precisa sobreviver
vai para um banco de dados, ou para um compartilhamento do Azure Files montado como volume.

## Grupos Spot e confidenciais

Duas variantes do grupo são escolhidas com uma propriedade cada.

**Spot**, `priority: 'Spot'`, roda o grupo em capacidade ociosa com um desconto que a documentação
da Microsoft, lida em 30 de outubro de 2026, põe em até 70%. A lição 5 trata das máquinas virtuais
Spot, e a versão para contêineres difere em pontos que importam. Não há política de remoção para
escolher: um grupo removido é reiniciado pelo próprio Azure. Um grupo Spot não tem endereço público,
nem lugar numa rede virtual, nem SKU confidencial, e fica limitado a 4 CPUs e 16 GB. **Está em
preview, e é oferecido em três regiões, East US 2, West Europe e West US**, portanto não em
`brazilsouth`. O compilador aceita um lá mesmo assim, porque verifica tipos e não regiões. Aqui está
o arquivo da loja com uma linha acrescentada depois da política de reinício:

```
ana@laptop:~/azure$ sed "s/restartPolicy: 'Always'/&\n    priority: 'Spot'/" shop.bicep > spot.bicep
ana@laptop:~/azure$ grep -n -A1 restartPolicy spot.bicep
10:    restartPolicy: 'Always'
11-    priority: 'Spot'
ana@laptop:~/azure$ bicep build spot.bicep
ana@laptop:~/azure$ jq -r ".resources[0].properties.priority" spot.json
Spot
```

Um template pedindo um grupo Spot em São Paulo, escrito sem uma palavra de aviso. Só a implantação
descobriria que a região não o oferece.

**Confidencial**, `sku: 'Confidential'`, roda o grupo dentro de um ambiente de execução confiável em
processadores AMD SEV-SNP, com a memória cifrada por uma chave que o processador guarda. Ele também
deixa o grupo provar a uma parte remota o que está rodando antes que ela libere um segredo para ele. O que
pode rodar lá dentro é fixado por uma política, que a Microsoft diz ter de ser gerada pela extensão
`confcom` da CLI e não poder ser escrita à mão. Serve para dados que quem opera o hardware não pode
ver; os pedidos da loja não são isso.

## Mudar um grupo depois

Um grupo é atualizado rodando o create de novo com o mesmo nome e pelo menos uma propriedade
mudada, e todos os contêineres dele reiniciam no lugar. Algumas propriedades não mudam assim. **A
política de reinício, a CPU e a memória, o sistema operacional, o perfil de rede e a zona de
disponibilidade** só mudam apagando o grupo e criando-o de novo, o que baixa a imagem outra vez do
zero e pode dar a ele um endereço novo. Escolha-os como se fossem permanentes, porque durante a vida
do grupo eles são.
