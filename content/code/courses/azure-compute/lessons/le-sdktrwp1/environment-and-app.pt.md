---
title: "O ambiente, e o app dentro dele"
version: 1
---

A lição 7 terminou com as lacunas que um grupo de contêineres deixa: uma cópia só, uma atualização
que o reinicia no lugar, nenhum endereço na frente de várias cópias. A imagem tentadora do Container
Apps é a de um grupo de contêineres com essas três coisas aparafusadas. **Ele está mais perto de um
cluster Kubernetes que a Microsoft roda e você nunca vê**: a documentação diz que o serviço cuida
para você dos detalhes do Kubernetes e da orquestração de contêineres, e que escala com o KEDA, o
autoescalador orientado a eventos do Kubernetes. O que você declara são dois recursos. Um
**ambiente**, `Microsoft.App/managedEnvironments`, é a fronteira: uma rede e um destino de logs
compartilhados por tudo o que está dentro. Um **container app**, `Microsoft.App/containerApps`,
nomeia o seu ambiente e descreve um serviço. Esta seção declara os dois para a loja e os compila.
Nada é criado: isso exige uma assinatura, e os comandos que os criariam aparecem marcados como não
executados.

## O ambiente

A documentação da Microsoft chama um ambiente de fronteira segura em volta de um ou mais container
apps e jobs, e o runtime cuida dele: atualizações do sistema operacional, escala, failover. Os apps
de um ambiente **compartilham uma rede virtual e um destino de logs**, e esse é o teste de quantos
você precisa. A API de pedidos da loja e o relatório noturno ficam num só. Uma cópia de teste da
loja, que nunca pode dividir computação com a produção, fica em outro.

Há dois tipos, e a ajuda da CLI mostra qual você recebe por padrão. As descrições dela quebram numa
coluna estreita, então o `awk` e o `tr` juntam cada parâmetro numa linha só:

```
ana@laptop:~/azure$ az containerapp env create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(enable-workload-profiles|infrastructure-subnet-resource-id|internal-only) '
 --enable-workload-profiles -w : Boolean indicating if the environment is enabled to have workload profiles. Allowed values: false, true. Default: True. 
 --infrastructure-subnet-resource-id -s : Resource ID of a subnet for infrastructure components and user app containers. 
 --internal-only : Boolean indicating the environment only has an internal load balancer. These environments do not have a public static IP resource, therefore must provide infrastructureSubnetResourceId if enabling this property. Allowed values: false, true. 
```

`--enable-workload-profiles` vale true por padrão, então um ambiente novo é um ambiente de
**workload profiles**, que a documentação chama de padrão e de tipo que todo ambiente novo deve
ser. O outro tipo, *Consumption only*, está marcado como legado. Um workload profile é o tipo de
computação em que um app roda. Todo ambiente de workload profiles vem com um que você não consegue
remover, o primeiro desta tabela:

| perfil | o que você recebe | como é cobrado |
| --- | --- | --- |
| Consumption | de 0,25 a 4 vCPUs e de 0,5 a 8 GiB por réplica, escala até zero | por segundo, pelo que cada réplica em execução recebeu, e por requisição |
| Dedicated, por exemplo `D4` a `D32`, `E4` a `E32` | nós inteiros do tamanho escolhido, com vários apps em cada um | por nó, mais uma taxa fixa de gerenciamento pelo ambiente |
| Flexible (preview) | single-tenant, até 16 GiB por réplica | como o Consumption, mais a taxa de gerenciamento; não escala até zero |

**Escalar até zero é coisa do perfil Consumption.** A loja roda nele, e tudo nesta lição também. Um
perfil Dedicated é para trabalho constante num hardware que você escolhe, e a lição 21 o põe ao
lado dos outros serviços, com aritmética.

Um ambiente sem nada rodando também tem regras. A Microsoft apaga um ambiente que ficou ocioso, ou
falhou por causa da rede ou de uma policy, por mais de 90 dias.

## A rede embaixo dele

Ao criar um ambiente você escolhe a rede dele uma vez, e a escolha é permanente. Sem rede nomeada, o
Azure lhe dá uma própria, alcançável pela internet e capaz de alcançar só o que está na internet.
Com a sua própria rede virtual, o ambiente ocupa **uma sub-rede só dele**, e para um ambiente de
workload profiles a documentação põe três condições: no mínimo um `/27`, delegado a
`Microsoft.App/environments`, e um tamanho que não se muda depois. Um `/27` tem 18 endereços
sobrando depois que a plataforma fica com os 14 dela, e a documentação planeja um endereço a cada
dez réplicas do Consumption, com espaço reservado para a duplicação que uma implantação exige
(seção 04): no máximo 90 réplicas. A lição 16 de `azure-foundations` construiu a rede virtual da
loja; a sub-rede do ambiente seria mais uma nela.

`--internal-only` é a outra decisão permanente. Um ambiente interno não tem endereço público
nenhum, como diz o texto de ajuda acima, e só atende num balanceador de carga dentro da rede
virtual. É o lugar da exportação financeira, que ninguém de fora da empresa deve alcançar.

## O app, em duas metades

Aqui está a loja como container app, declarada em Bicep. É o arquivo como ele fica no dia em que uma
segunda versão vai para um cliente em cada dez, então ele traz uma regra de escala, um sufixo de
revisão e uma divisão de tráfego que as seções 03 a 05 explicam. Salve-o como
`~/azure/shop-app.bicep`:

```bicep
// shop-app.bicep
param location string = 'brazilsouth'
param registry string = 'shopregistry.azurecr.io'
@secure()
param registryPassword string

resource env 'Microsoft.App/managedEnvironments@2026-01-01' = {
  name: 'shop-env'
  location: location
  properties: {
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

resource shop 'Microsoft.App/containerApps@2026-01-01' = {
  name: 'shop'
  location: location
  properties: {
    environmentId: env.id
    workloadProfileName: 'Consumption'
    configuration: {
      activeRevisionsMode: 'Multiple'
      secrets: [
        { name: 'registry-password', value: registryPassword }
      ]
      registries: [
        { server: registry, username: 'shopregistry', passwordSecretRef: 'registry-password' }
      ]
      ingress: {
        external: true
        targetPort: 8080
        traffic: [
          { revisionName: 'shop--v1-0', weight: 90 }
          { revisionName: 'shop--v1-1', weight: 10, label: 'canary' }
        ]
      }
    }
    template: {
      revisionSuffix: 'v1-1'
      containers: [
        {
          name: 'shop'
          image: '${registry}/shop:1.0'
          env: [
            { name: 'SHOP_VERSION', value: '1.1' }
          ]
          resources: {
            cpu: json('0.5')
            memory: '1Gi'
          }
        }
      ]
      scale: {
        minReplicas: 0
        maxReplicas: 10
        cooldownPeriod: 300
        pollingInterval: 30
        rules: [
          {
            name: 'http'
            http: {
              metadata: {
                concurrentRequests: '50'
              }
            }
          }
        ]
      }
    }
  }
}

output fqdn string = shop.properties.configuration.ingress.fqdn
```

**As propriedades do app se dividem em `configuration` e `template`, e essa divisão é a coisa mais
importante do arquivo.** `configuration` trata do app como um todo: quantas revisões podem estar
ativas, os segredos, os registros de onde ele puxa imagens e o ingress. `template` é o que uma
revisão roda: os contêineres, os recursos deles, a regra de escala, o sufixo. A seção 04 mostra o
que decorre disso, porque uma mudança em `template` cria uma revisão nova e uma mudança em
`configuration` não cria.

**Ingress** é o que o grupo de contêineres da lição 7 não tinha: um endereço na frente de todas as
cópias, sem balanceador de carga nem IP público seus para criar. `external: true` publica o app na
borda do ambiente, e `false`, *interno*, o deixa alcançável só por outros apps do mesmo ambiente.
`targetPort` é a porta em que o contêiner escuta, a 8080 da loja. Quem chama nunca a vê: o ingress
HTTP atende na 443, com um nome próprio, e por padrão redireciona a porta 80 para ela. A
documentação também fixa um timeout de requisição de 240 segundos.

**Segredos** pertencem ao app, não a uma revisão, e são citados pelo nome. A senha do registro chega
como parâmetro `@secure()`, então nunca é escrita no arquivo, e a entrada de `registries` aponta
para ela com `passwordSecretRef`. Um contêiner chegaria a um segredo do mesmo jeito, com `secretRef`
no lugar de `value` no `env` dele. Uma identidade gerenciada com o papel `AcrPull`, lição 8 de
`azure-foundations`, elimina a senha de vez, com `identity: 'system'` na entrada do registro.

**No Consumption, o tamanho do contêiner vem em pares.** A documentação lista as combinações que os
contêineres de um app podem somar, de 0,25 vCPU com 0,5 GiB a 4 vCPUs com 8 GiB, e meio núcleo vai
com 1 GiB. O `json('0.5')` é o da lição 7: o Bicep não tem frações. A ajuda da CLI é mais estreita
que a documentação aqui:

```
ana@laptop:~/azure$ az containerapp create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(ingress|target-port|cpu|memory) '
 --cpu : Required CPU in cores from 0.25 - 2.0, e.g. 0.5. 
 --memory : Required memory from 0.5 - 4.0 ending with "Gi", e.g. 1.0Gi. 
 --ingress : The ingress type. Allowed values: external, internal. 
 --target-port : The application port used for ingress traffic. 
```

De 0,25 a 2,0 núcleos e até 4,0 GiB é o limite que a documentação dá para o ambiente legado,
enquanto um ambiente de workload profiles permite 4 e 8. Onde as duas discordam, este curso segue
a documentação.

## Compilado

```
ana@laptop:~/azure$ bicep build shop-app.bicep
ana@laptop:~/azure$ ls shop-app.*
shop-app.bicep
shop-app.json
ana@laptop:~/azure$ jq -c '.resources[] | {type, apiVersion, name}' shop-app.json
{"type":"Microsoft.App/managedEnvironments","apiVersion":"2026-01-01","name":"shop-env"}
{"type":"Microsoft.App/containerApps","apiVersion":"2026-01-01","name":"shop"}
ana@laptop:~/azure$ jq '.resources[1].dependsOn' shop-app.json
[
  "[resourceId('Microsoft.App/managedEnvironments', 'shop-env')]"
]
```

Nenhum aviso, um template ao lado do arquivo, e os dois recursos nele com a versão de API,
`2026-01-01`, uma versão estável para a qual o compilador tem tipos. **O compilador também deduziu a
ordem**: o app se refere a `env.id`, então o template diz que o app depende do ambiente, e o
Resource Manager os cria nessa ordem. Uma porta escrita como texto é apanhada:

```
ana@laptop:~/azure$ sed "s/targetPort: 8080/targetPort: '8080'/" shop-app.bicep > port.bicep
ana@laptop:~/azure$ bicep build port.bicep
/home/ana/azure/port.bicep(36,21) : Warning BCP036: The property "targetPort" expected a value of type "int | null" but the provided value is of type "'8080'". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

Isso é um tipo, e tipos o compilador conhece. As seções 03 a 05 mostram quatro erros neste arquivo
que ele não conhece. Como seria criar o ambiente, com a resposta que você recebe sem conta:

```
ana@laptop:~/azure$ az containerapp env create --name shop-env --resource-group shop
ERROR: Please run 'az login' to setup account.
```

Numa assinatura, a linha seguinte seria `az containerapp create` com `--environment shop-env`, ou
uma implantação do arquivo acima; nenhum dos dois é executado neste curso.

**O `az containerapp` faz parte da própria CLI**, não é algo somado a ela:

```
ana@laptop:~/azure$ az extension list
[]
ana@laptop:~/azure$ az containerapp --help | grep -A1 '^Group'
Group
    az containerapp : Manage Azure Container Apps.
```

Nenhuma extensão instalada, e o grupo de comandos está lá. A Microsoft também publica uma extensão
`containerapp`, que traz recursos em preview, e as páginas dela a instalam com
`az extension add --name containerapp --upgrade --allow-preview true` quando um recurso precisa
dela. Na máquina em que este curso foi gravado, o índice de extensões não pôde ser alcançado, então
todo comando desta lição é da CLI básica.
