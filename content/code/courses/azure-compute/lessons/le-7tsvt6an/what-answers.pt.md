---
title: O que responde, e o que não responde
version: 1
---

Cada lição deste curso trata de algo que o Azure roda, e quase nada disso pode ser criado num
notebook. **Por isso cada seção é de um de dois tipos, e diz qual é.** Uma seção *praticada* tem
transcrições gravadas no laboratório da seção anterior, comando por comando, com a saída colada
como a máquina a imprimiu. Uma seção *lida* é ensinada a partir da documentação da Microsoft:
mostra o comando que você digitaria contra uma assinatura real, diz com todas as letras que ele não
foi executado e não mostra saída nenhuma, porque qualquer saída mostrada teria sido inventada.

Esse segundo tipo não é uma lição menor. A política de atualização de um scale set, uma janela de
manutenção do AKS ou uma troca de slot no App Service é uma decisão escrita em poucas linhas e
executada pelas máquinas da Microsoft; o que você precisa aprender é o que essas linhas dizem e o
que acontece depois delas, e a documentação é a autoridade nas duas coisas. O que uma seção lida não
pode dar a você é a sensação da coisa falhando, e as lições dizem onde isso importa.

## O que roda no notebook

| o quê | faz o papel de | desde a lição |
| --- | --- | --- |
| a CLI do Azure, sem conta | a ajuda dela, as listas offline e a recusa que você viu na seção anterior | 1 |
| o compilador Bicep | a verificação que o Azure faz da forma de uma declaração, antes de qualquer coisa ser criada | 1 |
| o Docker rodando a imagem da loja | o contêiner que Container Instances, Container Apps, AKS e App Service rodariam | 7 |
| o sidecar do Dapr num contêiner | o Dapr como o Container Apps o hospeda | 9 |
| um registry local | a metade de push, pull, tag e digest do Container Registry | 10 |
| o kind, Kubernetes em contêineres Docker | o Kubernetes que o AKS gerencia, mas não o AKS em si | 11 |
| o host do Functions, na imagem da Microsoft, com o Azurite como armazenamento | o runtime, os gatilhos e os bindings de uma function app | 15 |
| os emuladores do Service Bus e do Event Hubs | o plano de dados dos dois serviços: enviar, receber, partições | 20 |

**O que nenhum deles reproduz é o plano de controle**: a parte do Azure que cria um recurso, o põe
num datacenter, o cobra e aplica as suas permissões sobre ele. Uma máquina virtual, um scale set, um
disco, uma zona de disponibilidade, um despejo de Spot, uma atualização do AKS, uma revisão do
Container Apps, um plano do App Service, um Logic App, um tópico do Event Grid: cada um é ensinado
pela leitura, e cada vez a seção diz isso.

## O compilador, o mais perto do Azure que se chega

Uma ferramenta ganha lugar em quase toda lição, e vale ver o que ela faz antes de a primeira lição
se apoiar nela. Um arquivo Bicep declara recursos; as lições 4 e 5 do `azure-operations` ensinam a
linguagem direito, e este curso usa só a parte mais simples dela. O compilador transforma o arquivo
no template JSON que o Resource Manager aceita. **No caminho, ele confere cada propriedade contra os
tipos de recurso que a Microsoft publica para cada versão da API, sem assinatura.**

Eis um disco de dados para a loja, declarado com dois erros. Salve como `check.bicep`:

```bicep
// check.bicep
param location string = 'brazilsouth'

resource disk 'Microsoft.Compute/disks@2024-03-02' = {
  name: 'shop-data'
  location: location
  sku: {
    name: 'Premium_LRS'
  }
  properties: {
    creationData: {
      createOption: 'Empty'
    }
    diskSizeGB: '128'
    burstingEnabeld: true
  }
}
```

E compile:

```
ana@laptop:~/azure$ bicep build check.bicep
/home/ana/azure/check.bicep(14,17) : Warning BCP036: The property "diskSizeGB" expected a value of type "int | null" but the provided value is of type "'128'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
/home/ana/azure/check.bicep(15,5) : Warning BCP089: The property "burstingEnabeld" is not allowed on objects of type "DiskProperties". Did you mean "burstingEnabled"? [https://aka.ms/bicep/core-diagnostics#BCP089]
ana@laptop:~/azure$ ls
check.bicep
check.json
venv
```

Os dois erros foram achados: um tamanho escrito como texto onde a API de discos pede um número, e
um nome de propriedade com duas letras trocadas, com a grafia certa sugerida. **Mas são avisos, e o
template foi escrito mesmo assim**, como `check.json`. O compilador conhece os tipos, e sabe também
que os tipos publicados pela Microsoft às vezes estão atrás do serviço, que é para isso que existe
a frase sobre relatar uma imprecisão. Então ele avisa e segue. O que o Azure faria com o arquivo como
está é decidido pelo serviço de discos, não pelo compilador: ele pode recusar o texto onde cabe um
número, e pode descartar a propriedade mal escrita sem dizer nada e criar um disco sem o bursting
que você pediu. Um notebook não tem como descobrir qual das duas.

**Trate todo aviso como uma recusa.** Neste curso uma declaração está pronta quando compila sem
aviso nenhum, porque essa é a verificação mais forte que alguém pode fazer dela sem uma assinatura.
O que o compilador não tem como saber é se o pedido daria certo: se o tamanho é oferecido em
`brazilsouth`, se sua assinatura tem a cota, se um nome já está em uso. Isso só o Azure responde, e
as lições dizem onde importa.

O template em si é JSON comum, e o `jq` consegue lê-lo:

```
ana@laptop:~/azure$ jq ".resources[0] | {type, apiVersion, name}" check.json
{
  "type": "Microsoft.Compute/disks",
  "apiVersion": "2024-03-02",
  "name": "shop-data"
}
```

Esse par de tipo e versão da API, `Microsoft.Compute/disks@2024-03-02`, é como o Resource Manager
nomeia aquilo de que um pedido trata. Todo recurso deste curso tem um, e a lição 25 do
`azure-foundations` diz como funciona a API por trás dele.

## A linha de comando sem conta

A CLI ainda ensina sem assinatura. O texto de ajuda dela é gerado das mesmas definições que montam
os pedidos, então ele diz o que cada parâmetro aceita e o que é escolhido quando você não diz nada.
Perguntada sobre que tamanho o `az vm create` dá a uma máquina quando nenhum tamanho é informado:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "Default: Standard_[A-Za-z0-9_]*"
Default: Standard_D2s_v5
```

Esse é um padrão real, escolhido pela Microsoft e escrito nesta versão da CLI, e a próxima seção o
lê letra por letra. Onde uma lição escreve um comando `az` que precisa de assinatura, ela diz isso e
não mostra saída.

## Preços

**Este curso não cita nenhum preço da tabela de preços do Azure.** A máquina em que as transcrições
foram gravadas não conseguia alcançar as páginas de preço da Microsoft nem a Retail Prices API, e um
preço copiado de memória seria o único tipo de número que um leitor não consegue conferir. Onde uma
lição precisa de conta, ela usa valores redondos e diz a cada vez que são ilustrativos, não do
Azure: o raciocínio é o mesmo em qualquer preço, e a lição 21 mostra como pôr os reais.

Você mesmo pode ler os reais. A Retail Prices API não pede conta nem chave, e responde em JSON; este
pedido pergunta o preço por hora do tamanho acima em São Paulo. Ele não foi executado neste curso:

```sh
curl -s "https://prices.azure.com/api/retail/prices?\$filter=armRegionName%20eq%20'brazilsouth'%20and%20armSkuName%20eq%20'Standard_D2s_v5'" | jq '.Items[] | {productName, meterName, retailPrice, unitOfMeasure}'
```

Ela responde com um item por forma de pagar por esse tamanho: Linux e Windows, pagamento conforme o
uso, Spot e as reservas. A lição 5 trata de por que há tantas. Um número que ESTÁ na documentação
da Microsoft, como uma cota mensal gratuita ou um teto de desconto, é citado com a data em que a
documentação foi lida, que para este curso foi 30 de outubro de 2026.
