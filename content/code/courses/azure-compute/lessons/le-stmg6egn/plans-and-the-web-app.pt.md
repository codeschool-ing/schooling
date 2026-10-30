---
title: O plano, e o web app que roda nele
version: 1
---

A imagem fácil do App Service é um servidor pequeno por web app: você cria um app, o Azure dá a
ele um lugar para rodar, e cada app é cobrado por si. **As máquinas são do plano, não do app.** Um
plano do App Service, `Microsoft.Web/serverfarms` num template, é um conjunto de máquinas virtuais
numa região: um sistema operacional, um tamanho, um número de instâncias e um tier de preço. Um web
app, `Microsoft.Web/sites`, é o que roda nelas, e a documentação da Microsoft diz isso com todas as
letras: um app sempre roda num plano, e quando roda, roda em toda instância que o plano tem. Fora
dos tiers Free e Shared, você paga por instância do plano, rode o que rodar nela e esteja ela
ocupada ou não. Esta seção declara um plano e a loja como web app em Bicep e os compila. Nada é
criado, porque isso precisa de uma assinatura.

## Os tiers, e o que cada um acrescenta

O tier decide duas coisas de uma vez: de quem são as máquinas onde seus apps rodam, e que recursos
o plano tem. A tabela é a página de limites da Microsoft, lida em 2026-10-30, reduzida às linhas que
esta lição usa.

| tier | as máquinas | instâncias no máximo | acrescenta |
| --- | --- | --- | --- |
| Free (F1) | uma VM dividida com apps de outros clientes, com cota de CPU de 60 minutos por dia | 1 | nada para escalar; Linux e Windows |
| Shared (D1) | o mesmo, 240 minutos por dia | 1 | só Windows |
| Basic (B1 a B3) | VMs dedicadas, divididas só pelos apps do mesmo plano | 3 | Always On, domínios personalizados com TLS, escala manual |
| Standard (S1 a S3) | dedicadas | 10 | autoscale, 5 slots de implantação por app |
| Premium v3 e v4 (P0v3, P1v3…) | dedicadas, hardware mais novo | 30 | 20 slots, e escalonamento automático, que soma instâncias pela carga HTTP sem regras |
| Isolated v2 (I1v2…) | VMs dedicadas num App Service Environment, numa rede virtual sua | 100 | 20 slots, isolamento de rede em relação a outros clientes |

**Os slots começam no Standard e o autoscale começa no Standard**, e é por isso que o plano da loja
não é Basic. O tier Basic serve bem a um site que é reiniciado no lugar quando muda; a loja quer o
que as duas próximas seções constroem, e isso precisa do Standard ou acima.

Redundância entre zonas não é uma linha dessa tabela. É uma propriedade do plano, `zoneRedundant`,
e a documentação põe duas condições: pelo menos duas instâncias, e um plano cujo
`maximumNumberOfZones` seja maior que um. Esse número depende da região e da unidade de escala onde
o plano foi posto, e não só do nome do tier. Um plano que responde um precisa ser feito de novo, num
grupo de recursos novo. Brazil South tem zonas de disponibilidade, lição 6, e o exemplo da própria
Microsoft de um plano redundante entre zonas é um `P1V3` com dois workers, que é o da loja.

## Vários apps, um plano

Como o plano é as máquinas, todo app posto nele as divide. Três apps num plano de duas instâncias
são seis cópias rodando, três em cada máquina, e a conta continua sendo de duas instâncias. A
documentação lista o que divide as máquinas: todo app do plano, **todo slot de implantação de todo
app**, e os logs de diagnóstico, os backups e os WebJobs que eles rodam. Ela conta um slot ativo
como um app ativo exatamente por isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma caixa para o plano do App Service shop-plan, P1v3, Linux, duas instâncias, redundante entre zonas. Dentro dela, duas instâncias lado a lado, na zona 1 e na zona 2. Cada instância roda as mesmas três coisas: shop-sp, o slot de produção, com a imagem shop:1.0; shop-sp/staging, o slot de staging, com shop:1.1; e outro app, shop-admin. Embaixo, duas notas: a conta é de duas instâncias, rode o que rodar nelas, e o autoscale muda o número de instâncias, de modo que os três sobem e descem juntos.\"><rect x=\"20\" y=\"15\" width=\"680\" height=\"245\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"38\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\" font-weight=\"600\">plano do App Service</text><text x=\"178.0\" y=\"35\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--phosphor)\">shop-plan</text><text x=\"682\" y=\"35\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">P1v3 · Linux · 2 instâncias, redundante entre zonas</text><rect x=\"40\" y=\"55\" width=\"305\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"55\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">instância 1</text><text x=\"330\" y=\"73\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zona 1</text><rect x=\"55\" y=\"88\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"68\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp</text><text x=\"68\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">slot de produção</text><text x=\"318\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop:1.0</text><rect x=\"55\" y=\"138\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp/staging</text><text x=\"68\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">slot de staging</text><text x=\"318\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop:1.1</text><rect x=\"55\" y=\"188\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"68\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-admin</text><text x=\"68\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outro app</text><rect x=\"375\" y=\"55\" width=\"305\" height=\"190\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"390\" y=\"73\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\" font-weight=\"600\">instância 2</text><text x=\"665\" y=\"73\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">zona 2</text><rect x=\"390\" y=\"88\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"403\" y=\"101\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp</text><text x=\"403\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">slot de produção</text><text x=\"653\" y=\"108\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop:1.0</text><rect x=\"390\" y=\"138\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"403\" y=\"151\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp/staging</text><text x=\"403\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">slot de staging</text><text x=\"653\" y=\"158\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop:1.1</text><rect x=\"390\" y=\"188\" width=\"275\" height=\"40\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"403\" y=\"201\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-admin</text><text x=\"403\" y=\"216\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outro app</text><text x=\"20\" y=\"282\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cobrado: 2 instâncias, rode o que rodar nelas</text><text x=\"20\" y=\"304\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">o autoscale muda o número de instâncias, e os três sobem e descem juntos</text></svg>", "caption": "O plano é as máquinas, e um app é o que roda nelas. Um slot também é um app, nas mesmas instâncias, e é por isso que pôr uma versão nova em staging usa a capacidade de que a produção está servindo."}
```

Isso é uma economia e um risco na mesma frase. O back office da loja, um site administrativo
pequeno que os três desenvolvedores usam, não custa nada a mais no plano da loja. Ele também escala
junto: o autoscale muda o número de instâncias do plano, então todo app dele sobe e desce junto. E
se o site administrativo começa uma exportação pesada ao meio-dia, a API de pedidos está nos mesmos
processadores. A orientação da Microsoft é dar a um app um plano próprio quando ele consome muitos
recursos, quando precisa escalar sozinho, ou quando pertence a outra região, e ela dá densidades
aproximadas, 16 apps para um `P1v3`. Existe também o *escalonamento por app*, que limita um app a
menos instâncias do plano, mas o que você paga continua sendo o plano.

## A loja, como contêiner

O App Service roda código num runtime que ele mantém, Python ou .NET ou Node, ou uma imagem de
contêiner que você construiu. A loja já é uma imagem, a `shop:1.0` da lição 7, então o web app roda
essa. No Linux a imagem é nomeada numa string só, `linuxFxVersion`, com a palavra `DOCKER` e uma
barra vertical na frente.

Três coisas sobre um contêiner no App Service vêm da documentação dele e decidem como o arquivo
abaixo é escrito:

- A porta. O App Service manda requisições para uma porta do contêiner. A referência de
  configurações diz que ele tenta 80 e 8080 sozinho, e a página sobre contêineres personalizados diz
  que ele presume 80. A loja escuta na 8080, então o arquivo diz isso com `WEBSITES_PORT`, e não
  depende de qual página está atualizada. Essa configuração é lida pela plataforma e não é passada
  ao contêiner.
- Configurações de app são variáveis de ambiente. Todo outro nome e valor em `appSettings`
  chega ao processo do contêiner como variável de ambiente, que é como a loja já lê `PORT` e
  `SHOP_VERSION`. `SHOP_ENV` é uma que a loja ainda não lê; a próxima seção precisa dela.
- As credenciais do registry vão em três configurações cujos nomes começam com
  `DOCKER_REGISTRY_SERVER_`, e a documentação diz que essas três não são expostas à aplicação. A
  senha chega como parâmetro `@secure()`, como na lição 8. Uma identidade gerenciada com `AcrPull`,
  lição 8 de `azure-foundations`, elimina a senha, com `acrUseManagedIdentityCreds: true` em
  `siteConfig`.

Aqui está o arquivo inteiro. Ele traz o slot `staging` e as configurações de aquecimento que as
seções 03 e 04 explicam, porque é o arquivo como ele está no dia em que `shop:1.1` vai para o
staging. Salve como `~/azure/shop-web.bicep`:

```bicep
// shop-web.bicep
param location string = 'brazilsouth'
param registry string = 'shopregistry.azurecr.io'
@secure()
param registryPassword string

resource plan 'Microsoft.Web/serverfarms@2024-11-01' = {
  name: 'shop-plan'
  location: location
  kind: 'linux'
  sku: {
    name: 'P1v3'
    capacity: 2
  }
  properties: {
    reserved: true
    zoneRedundant: true
  }
}

resource site 'Microsoft.Web/sites@2024-11-01' = {
  name: 'shop-sp'
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${registry}/shop:1.0'
      alwaysOn: true
      healthCheckPath: '/healthz'
      appSettings: [
        { name: 'WEBSITES_PORT', value: '8080' }
        { name: 'DOCKER_REGISTRY_SERVER_URL', value: 'https://${registry}' }
        { name: 'DOCKER_REGISTRY_SERVER_USERNAME', value: 'shopregistry' }
        { name: 'DOCKER_REGISTRY_SERVER_PASSWORD', value: registryPassword }
        { name: 'WEBSITE_WARMUP_PATH', value: '/healthz' }
        { name: 'WEBSITE_WARMUP_STATUSES', value: '200' }
        { name: 'WEBSITE_SWAP_WARMUP_PING_PATH', value: '/healthz' }
        { name: 'WEBSITE_SWAP_WARMUP_PING_STATUSES', value: '200' }
        { name: 'SHOP_ENV', value: 'production' }
      ]
    }
  }
}

resource staging 'Microsoft.Web/sites/slots@2024-11-01' = {
  parent: site
  name: 'staging'
  location: location
  kind: 'app,linux,container'
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${registry}/shop:1.1'
      alwaysOn: true
      healthCheckPath: '/healthz'
      appSettings: [
        { name: 'WEBSITES_PORT', value: '8080' }
        { name: 'DOCKER_REGISTRY_SERVER_URL', value: 'https://${registry}' }
        { name: 'DOCKER_REGISTRY_SERVER_USERNAME', value: 'shopregistry' }
        { name: 'DOCKER_REGISTRY_SERVER_PASSWORD', value: registryPassword }
        { name: 'WEBSITE_WARMUP_PATH', value: '/healthz' }
        { name: 'WEBSITE_WARMUP_STATUSES', value: '200' }
        { name: 'WEBSITE_SWAP_WARMUP_PING_PATH', value: '/healthz' }
        { name: 'WEBSITE_SWAP_WARMUP_PING_STATUSES', value: '200' }
        { name: 'SHOP_ENV', value: 'staging' }
      ]
    }
  }
}

resource sticky 'Microsoft.Web/sites/config@2024-11-01' = {
  parent: site
  name: 'slotConfigNames'
  properties: {
    appSettingNames: [
      'SHOP_ENV'
    ]
  }
}

output production string = site.properties.defaultHostName
output staging string = staging.properties.defaultHostName
```

`kind: 'linux'` com `reserved: true` faz do plano um plano Linux. `sku` nomeia o tamanho, `P1v3`, e
`capacity` é o número de instâncias. O site aponta para o plano com `serverFarmId`, e essa
referência é tudo o que põe um app nas máquinas dele. `alwaysOn` mantém o app carregado quando
ninguém o chama há algum tempo, e precisa do Basic ou acima. `healthCheckPath` é da seção 04.

## Compilado

A CLI é o outro jeito de criar o mesmo plano, e a ajuda dela mostra três das decisões do plano:

```
ana@laptop:~/azure$ az appservice plan create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(is-linux|number-of-workers|zone-redundant) ' | sed 's/ Global Policy Arguments//'
 --is-linux : Host web app on Linux worker. Defaults to true unless --hyper-v is specified. Use "--is-linux false" to create a Windows plan. Allowed values: false, true. 
 --number-of-workers : Number of workers to be allocated. Default: 1. 
 --zone-redundant -z : Enable zone redundancy for high availability. Minimum instance count is 2. 
```

Depois o arquivo:

```
ana@laptop:~/azure$ bicep build shop-web.bicep
ana@laptop:~/azure$ jq -c '.resources[] | {type, name}' shop-web.json
{"type":"Microsoft.Web/serverfarms","name":"shop-plan"}
{"type":"Microsoft.Web/sites","name":"shop-sp"}
{"type":"Microsoft.Web/sites/slots","name":"[format('{0}/{1}', 'shop-sp', 'staging')]"}
{"type":"Microsoft.Web/sites/config","name":"[format('{0}/{1}', 'shop-sp', 'slotConfigNames')]"}
ana@laptop:~/azure$ jq -r '.resources[1].properties.siteConfig.linuxFxVersion' shop-web.json
[format('DOCKER|{0}/shop:1.0', parameters('registry'))]
```

Nenhum aviso, quatro recursos, e a imagem chega ao template como uma string que o compilador monta
com `format`. **Para o compilador, `linuxFxVersion` é texto.** Ele confere que a propriedade
existe e que o valor é uma string, e nada sobre o que a string diz. Uma porta escrita como número é
um tipo, e isso ele conhece:

```
ana@laptop:~/azure$ sed "s/value: '8080'/value: 8080/" shop-web.bicep > port.bicep
ana@laptop:~/azure$ bicep build port.bicep
/home/ana/azure/port.bicep(33,41) : Warning BCP036: The property "value" expected a value of type "null | string" but the provided value is of type "8080". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
/home/ana/azure/port.bicep(60,41) : Warning BCP036: The property "value" expected a value of type "null | string" but the provided value is of type "8080". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP036]
```

Dois avisos, um por slot, e um template escrito mesmo assim: a regra da lição 1, trate todo aviso
como uma recusa. Agora dois erros que ele não conhece:

```
ana@laptop:~/azure$ sed 's/DOCKER|/DOCKER:/' shop-web.bicep > colon.bicep
ana@laptop:~/azure$ bicep build colon.bicep
ana@laptop:~/azure$ sed '/reserved: true/d' shop-web.bicep > windows.bicep
ana@laptop:~/azure$ bicep build windows.bicep
ana@laptop:~/azure$ jq -c '.resources[0].properties' windows.json
{"zoneRedundant":true}
```

Os dois compilam sem uma palavra. O primeiro nomeia a imagem como
`DOCKER:shopregistry.azurecr.io/shop:1.0`, que não é runtime nenhum que o App Service conheça. O
segundo é pior, porque o template que sai é válido e quer dizer outra coisa: a descrição da própria
API REST para `reserved` é *true se for plano Linux, false caso contrário*, e o padrão é false.
**Sem `reserved: true` o plano é um plano Windows**, e `kind: 'linux'` sozinho não muda isso. A CLI
vai pelo outro lado, `--is-linux` tem true como padrão, então um plano feito à mão e um plano feito
de um arquivo sem uma linha são máquinas diferentes.

O comando da CLI para o app recebe a imagem direto:

```
ana@laptop:~/azure$ az webapp create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --(container-image-name|runtime) '
 --container-image-name -c : The container custom image name and optionally the tag name (e.g., `<registry- name>/<image-name>:<tag>`). Note: if --container-registry-url is also provided, use `<image-name>:<tag>` without the registry name. 
 --runtime -r : Canonicalized web runtime in the format of Framework:Version, e.g. "PYTHON:3.14".Use `az webapp list-runtimes` for available list. 
```

Nada disso foi rodado contra o Azure. Criar o plano a partir do arquivo seria
`az deployment group create --resource-group shop --template-file shop-web.bicep`, que precisa de
uma assinatura, e este curso não tem nenhuma.
