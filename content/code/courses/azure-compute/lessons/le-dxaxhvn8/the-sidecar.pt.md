---
title: O sidecar, um segundo processo no localhost da loja
version: 1
---

O Dapr, Distributed Application Runtime, é um programa que roda ao lado do seu e responde a uma
API HTTP em `localhost:3500`. O seu código pede a ele que guarde um valor, publique uma mensagem ou
chame outro serviço, e o Dapr faz o trabalho contra o armazenamento ou o broker com que foi
configurado. **No Container Apps, ligar o Dapr é uma configuração do app, e o Azure então inicia o
sidecar em cada réplica.** Esta seção inicia um ao lado da loja no seu laptop, com Docker, e depois
lê o que o Container Apps pede. A primeira metade é praticada; a segunda é lida da documentação da
Microsoft.

A imagem com que quase todo mundo chega é a de uma biblioteca: algo que se instala com `pip
install`, como o SDK do Azure, e que transforma uma chamada de função num pedido ao Redis ou ao
Service Bus. Ou então a de um serviço, em algum lugar do Azure, que o app chama pela internet. Não
é nenhum dos dois. **O Dapr é um processo separado dentro da sua réplica, e o seu programa o alcança
em `localhost`.** O Dapr publica SDKs para várias linguagens, mas eles são clientes finos dessa
mesma API local; um programa que só tem um cliente HTTP consegue usar tudo, e os programas da loja
nesta lição fazem exatamente isso.

## Iniciado ao lado da loja

O sidecar é um programa chamado `daprd`, e o Dapr o publica como imagem, `daprio/daprd`. Este curso
fixa a versão 1.17.16. A linha de comando do próprio Dapr, `dapr`, inicia o mesmo programa por você;
aqui ele é iniciado com Docker, para que cada configuração fique à vista e o arranjo seja o mesmo
que o Container Apps monta.

A imagem da loja é a que a lição 7 construiu, `shop:1.0`. Crie uma rede para esta lição, inicie a
loja nela e inicie o sidecar dentro do namespace de rede da loja com `--network container:shop`, a
opção que a lição 7 usou para um segundo contêiner no mesmo `localhost`. O sidecar recebe três
configurações: o nome pelo qual conhece o app, a porta em que o app escuta e um diretório de
componentes, vazio por enquanto:

```
ana@laptop:~/azure$ docker network create shop-net
060c017201602ce5c37b560bd66b8f3156780a835e1b15d307272e55718e69f4
ana@laptop:~/azure$ docker run -d --name shop --network shop-net -p 8080:8080 -p 3500:3500 shop:1.0 > /dev/null
ana@laptop:~/azure$ mkdir components
ana@laptop:~/azure$ docker run -d --name shop-dapr --network container:shop -v ~/azure/components:/components daprio/daprd:1.17.16 ./daprd --app-id shop --app-port 8080 --resources-path /components > /dev/null
ana@laptop:~/azure$ docker port shop
3500/tcp -> 0.0.0.0:3500
8080/tcp -> 0.0.0.0:8080
ana@laptop:~/azure$ docker port shop-dapr
```

`docker network create` imprime o id da nova rede, que muda de máquina para máquina, e `> /dev/null`
descarta os ids de contêiner que `docker run` imprimiria. As duas chamadas a `docker port` são o
ponto. As portas 8080 e 3500 estão as duas publicadas no contêiner da loja, e o sidecar não tem
nenhuma. **Um sidecar não tem rede própria, então as portas dele são publicadas no contêiner cujo
namespace ele usa**: o `-p 3500:3500` teve de ser dado quando a loja iniciou, antes de o sidecar
existir.

O que o sidecar disse ao iniciar, tirado de um log de várias dezenas de linhas:

```
ana@laptop:~/azure$ docker logs shop-dapr 2>&1 | grep -o 'msg="[^"]*"' | grep -E 'app id|waiting on port|application discovered|Status: Running'
msg="app id: shop"
msg="application protocol: http. waiting on port 8080.  This will block until the app is listening on that port."
msg="application discovered on port 8080"
msg="dapr initialized. Status: Running. Init Elapsed 15ms"
```

Ele recebeu o app id `shop` e esperou até haver algo escutando na porta 8080 antes de se declarar
em execução. O sidecar nasce como parceiro de um programa, e não se diz pronto enquanto esse
programa não está lá.

## Perguntando coisas a ele

A verificação de saúde do Dapr responde na própria API dele, e a chamada de metadados diz o que é
este sidecar:

```
ana@laptop:~/azure$ curl -s -o /dev/null -w '%{http_code}\n' localhost:3500/v1.0/healthz
204
ana@laptop:~/azure$ curl -s localhost:3500/v1.0/metadata | jq '{id, runtimeVersion, components, appConnectionProperties}'
{
  "id": "shop",
  "runtimeVersion": "1.17.16",
  "components": null,
  "appConnectionProperties": {
    "port": 8080,
    "protocol": "http",
    "channelAddress": "127.0.0.1"
  }
}
```

`204` é saudável e sem nada a dizer. Os metadados trazem o app id, a versão do Dapr em execução e
`"components": null`: nenhum armazenamento e nenhum broker ainda. `appConnectionProperties` diz que
o sidecar alcança o app em `127.0.0.1:8080`, o que só funciona porque os dois dividem um
`localhost`.

O log da própria loja mostra o outro sentido:

```
ana@laptop:~/azure$ docker logs shop
{"msg": "listening", "port": 8080, "version": "1.0"}
{"path": "/dapr/config", "status": "404", "version": "1.0"}
```

A loja nunca chamou o Dapr; o Dapr chamou a loja. Ao iniciar, o sidecar pediu ao app a configuração
do Dapr em `/dapr/config`, e a loja, que não tem essa página, respondeu 404, o que o sidecar entende
como "nada a configurar". **O tráfego corre nos dois sentidos**: o app chama o sidecar para guardar
estado e publicar, e o sidecar chama o app para saber o que ele assina e para entregar o que chega.
A próxima seção mostra a segunda metade.

Pedir estado agora dá uma recusa que diz o que falta:

```
ana@laptop:~/azure$ curl -s localhost:3500/v1.0/state/statestore/order-1 | jq -c '{errorCode, message}'
{"errorCode":"ERR_STATE_STORE_NOT_CONFIGURED","message":"state store statestore is not configured"}
```

`statestore` é o nome de um componente, e o diretório de componentes está vazio. A URL nomeia um
armazenamento e não diz nada sobre o tipo dele; isso fica num arquivo que o sidecar lê, que é o
assunto da próxima seção.

```schooling-figure
{"svg": "<svg id=\"fig-sidecar\" viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"A loja e o seu sidecar num só namespace de rede. O curl no laptop alcança a loja na porta 8080 e o sidecar na porta 3500, as duas publicadas no contêiner da loja. Dentro do namespace a loja pede estado e publicação ao sidecar em localhost porta 3500, e o sidecar chama a loja em localhost porta 8080 para ler as assinaturas e entregar eventos. O sidecar fala com o redis na porta 6379, que guarda estado e streams. billing tem um namespace próprio com o seu sidecar, que lê do redis e entrega ao subscriber.py na porta 8080. No Container Apps cada caixa dessas é uma réplica, e o Azure põe o sidecar em todas.\"><defs><marker id=\"sidecar-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"128\" width=\"112\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"72\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" font-weight=\"600\">curl</text><text x=\"72\" y=\"168\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">no laptop</text><rect x=\"160\" y=\"28\" width=\"292\" height=\"252\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></rect><text x=\"306\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um namespace de rede, um localhost</text><rect x=\"186\" y=\"62\" width=\"240\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" font-weight=\"600\">shop</text><text x=\"306\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app.py  :8080</text><rect x=\"186\" y=\"194\" width=\"240\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"306\" y=\"214\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--amber)\" font-weight=\"600\">shop-dapr</text><text x=\"306\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">daprd  :3500  :50001</text><polyline points=\"290,124 290,192\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><polyline points=\"322,194 322,126\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><text x=\"282\" y=\"146\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estado,</text><text x=\"282\" y=\"161\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">publicação</text><text x=\"282\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:3500</text><text x=\"330\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">assinaturas,</text><text x=\"330\" y=\"161\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">eventos</text><text x=\"330\" y=\"176\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:8080</text><polyline points=\"128,144 184,96\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><polyline points=\"128,168 184,222\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><text x=\"140\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:8080</text><text x=\"140\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper-dim)\">:3500</text><rect x=\"520\" y=\"36\" width=\"184\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--phosphor)\" font-weight=\"600\">redis  :6379</text><text x=\"612\" y=\"78\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">estado e streams</text><polyline points=\"426,225 482,225 482,67 518,67\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><rect x=\"512\" y=\"128\" width=\"200\" height=\"152\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"6 4\"></rect><text x=\"612\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o namespace de billing</text><rect x=\"528\" y=\"158\" width=\"168\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"174\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--amber)\" font-weight=\"600\">billing-dapr</text><text x=\"612\" y=\"192\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">daprd</text><rect x=\"528\" y=\"222\" width=\"168\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"612\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" fill=\"var(--phosphor)\" font-weight=\"600\">billing</text><text x=\"612\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">subscriber.py  :8080</text><polyline points=\"612,98 612,156\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><polyline points=\"612,204 612,220\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#sidecar-ah)\"></polyline><text x=\"360\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">No Container Apps cada caixa tracejada é uma réplica, e o Azure põe o sidecar em todas.</text></svg>", "caption": "Dois processos, um endereço. A loja e o daprd dividem um localhost, então um alcança o outro sem passar pela rede, e as portas que alguém de fora alcança são publicadas no contêiner da loja, porque o sidecar não tem rede própria."}
```

## O que o Container Apps pede

No Container Apps você nunca inicia o `daprd`. A documentação da Microsoft lista as configurações
do Dapr em `properties.configuration.dapr` do container app, e as quatro que importam aqui são as
que você acabou de passar como opções: `enabled`, `appId`, `appPort` e `appProtocol`, que é `http` a
menos que o app fale gRPC. O sidecar responde HTTP na porta 3500 e gRPC na 50001, as mesmas duas
portas do seu laptop. A ajuda da CLI do Azure para ligar o Dapr, que dá para ler sem conta, lista as
mesmas configurações como opções:

```
ana@laptop:~/azure$ az containerapp dapr enable --help | sed -n '/^Dapr Arguments/,/^Global Policy/p' | head -n -2
Dapr Arguments
    --dal --dapr-enable-api-logging      : Enable API logging for the Dapr sidecar.
    --dapr-app-id                        : The Dapr application identifier.
    --dapr-app-port                      : The port Dapr uses to talk to the application.
    --dapr-app-protocol                  : The protocol Dapr uses to talk to the application.
                                           Allowed values: grpc, http.
    --dapr-http-max-request-size --dhmrs : Increase max size of request body http and grpc servers
                                           parameter in MB to handle uploading of big files.
    --dapr-http-read-buffer-size --dhrbs : Dapr max size of http header read buffer in KB to handle
                                           when sending multi-KB headers..
    --dapr-log-level                     : Set the log level for the Dapr sidecar.  Allowed values:
                                           debug, error, info, warn.
```

A seção 05 declara essas configurações em Bicep e as compila. Três fatos da documentação mudam a
forma de usar o Dapr lá.

**As configurações do Dapr pertencem ao app, não a uma revisão.** A lição 8 mostrou que uma mudança
no template cria uma revisão nova. Mudar uma configuração do Dapr não cria: no modo de várias
revisões, todas as revisões existentes são reiniciadas com os valores novos. Uma mudança no Dapr,
portanto, nunca é algo que se possa testar numa revisão com 10% do tráfego.

**Você não escolhe a versão.** O Container Apps roda uma build do Dapr feita pela Microsoft,
numerada como `1.13.6-msft.1`: a versão de código aberto a que corresponde e depois um sufixo para
as mudanças do Azure. Ele atualiza o ambiente sozinho, e a manutenção planejada do ambiente decide
quando, não se. O `runtimeVersion` de `/v1.0/metadata` é como um programa descobre qual recebeu, e
ela não precisa ser a 1.17.16 fixada aqui.

**Parte do Dapr não está lá.** O Container Apps suporta as APIs do Dapr em disponibilidade geral:
estado, pub/sub, bindings, invocação de serviço, atores, segredos e configuração, além das chamadas
de saúde e de metadados usadas acima. As APIs alfa não têm garantia. O arquivo de configuração do
próprio Dapr, e anotações do sidecar que a documentação não lista, não podem ser usados, e um job
do Container Apps não pode ter Dapr. O que vem sem pedir é uma verificação de saúde do próprio
sidecar, que o Container Apps configura sempre que o Dapr está ligado.
