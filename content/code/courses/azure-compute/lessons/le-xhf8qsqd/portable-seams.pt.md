---
title: Costuras portáveis, e quanto custa a portabilidade
version: 1
---

A resposta ao lock-in de API costuma ser posta como uma escolha de serviço: escolha o portável.
**A resposta melhor é uma escolha de onde o provedor tem permissão de aparecer.** Uma costura é a
linha entre a parte de um sistema que sabe o que a loja faz e a parte que sabe onde ela roda. Trace
a linha uma vez, mantenha o Azure de um lado dela, e mudar passa a ser reescrever o lado fino.

A loja já tem uma, e este curso se apoia nela desde a aula 7.

## Uma imagem, três maneiras, um digest

A imagem é a costura da computação. A aula 7 construiu `shop:1.0` a partir de dois arquivos, e as
aulas 8, 11 e 18 descreveram essa imagem para mais três serviços do Azure. Aqui ela roda de três
maneiras no notebook, e a pergunta é sempre a mesma: ainda é a mesma imagem?

Construa-a a partir do `app.py` e do `Dockerfile` da aula 7, em `~/azure/shop`, e pergunte ao Docker
o que ele construiu:

```
ana@laptop:~/azure$ docker build --quiet --tag shop:1.0 shop
sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ docker image inspect shop:1.0 --format '{{.Id}}'
sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ docker build --quiet --tag shop:again shop
sha256:0f51deba6e7940a87457019be876e963767de91583025a226f0b9fa16ce1a9eb
ana@laptop:~/azure$ docker image rm shop:again
Untagged: shop:again
Deleted: sha256:0f51deba6e7940a87457019be876e963767de91583025a226f0b9fa16ce1a9eb
```

O mesmo `sha256:` duas vezes: esse é o **digest** da imagem. É um hash do documento que descreve
a imagem, que por sua vez nomeia cada camada pelo próprio hash. A mudança de um byte em qualquer lugar dá um digest novo, e a aula 10 viu o mesmo tipo de nome num registro. Ele nomeia um
build, não um conjunto de arquivos. Os mesmos dois arquivos, construídos de novo um instante depois
como `shop:again`, saíram com outro digest. O seu vai ser diferente dos dois, e o que importa é que
um build mantém um digest nas três execuções abaixo. O segundo build foi removido porque nada
precisa dele.

Primeiro, Docker puro, como a aula 7 a executou. `docker inspect` diz de qual imagem o contêiner em
execução foi criado:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 shop:1.0 > /dev/null
ana@laptop:~/azure$ curl -s -w '\n' localhost:8080/version
{"version": "1.0", "host": "48c72c33cffa", "up_s": 0.6}
ana@laptop:~/azure$ docker inspect shop --format '{{.Image}}'
sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ docker rm -f shop > /dev/null
```

Segundo, ao lado de um sidecar do Dapr, como a aula 9 a executou. A loja sobe com a porta 3500 do
sidecar também publicada, o sidecar entra na rede dela, e a requisição vai para o Dapr, que chama o
`/version` da loja em nome de quem pediu. Desta vez não há arquivos de componente, porque a
invocação de serviço não precisa de nenhum:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 -p 3500:3500 shop:1.0 > /dev/null
ana@laptop:~/azure$ docker run -d --name shop-dapr --network container:shop daprio/daprd:1.17.16 ./daprd --app-id shop --app-port 8080 > /dev/null
ana@laptop:~/azure$ curl -s -w '\n' localhost:3500/v1.0/invoke/shop/method/version
{"version": "1.0", "host": "6c1d643d6eb9", "up_s": 2.9}
ana@laptop:~/azure$ docker inspect shop --format '{{.Image}}'
sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ docker rm -f shop shop-dapr > /dev/null
```

Terceiro, como um pod, como a aula 11 a executou. Um cluster com um control plane e um worker
basta. Salve isto como `~/azure/cluster.yaml`; os dois patches perto do topo são necessários numa
máquina com cgroup v1, e no cgroup v2, que é o de toda distribuição atual e do Docker Desktop, eles
são inofensivos:

```yaml
# cluster.yaml: one control plane and one worker, enough for one pod.
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
```

E o pod, como `~/azure/shop-pod.yaml`. `imagePullPolicy: IfNotPresent` faz o nó usar a cópia que o
`kind load` entrega a ele em vez de pedir a um registro, como na aula 11:

```yaml
# shop-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: shop
spec:
  containers:
  - name: shop
    image: shop:1.0
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 2
```

Crie o cluster, entregue a imagem a ele e suba o pod. Nada publica a porta do pod no notebook,
então o `kubectl exec` pergunta à loja de dentro do próprio contêiner dela. Depois pergunte onde o
pod rodou e o que ele rodou, ao Kubernetes e ao próprio nó. Um nó do kind é um contêiner chamado
`shop-worker`, e o `ctr` é o cliente de linha de comando do containerd dentro dele, cujo aviso
sobre o cgroup v1 desta máquina vai para `/dev/null`:

```
ana@laptop:~/azure$ kind create cluster --name shop --config cluster.yaml --quiet
ana@laptop:~/azure$ kind load docker-image shop:1.0 --name shop
Image: "shop:1.0" with ID "sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382" not yet present on node "shop-worker", loading...
Image: "shop:1.0" with ID "sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382" not yet present on node "shop-control-plane", loading...
ana@laptop:~/azure$ kubectl apply -f shop-pod.yaml
pod/shop created
ana@laptop:~/azure$ kubectl wait --for=condition=Ready pod/shop --timeout=120s
pod/shop condition met
ana@laptop:~/azure$ kubectl exec shop -- python -c "import urllib.request; print(urllib.request.urlopen('http://localhost:8080/version').read().decode())"
{"version": "1.0", "host": "shop", "up_s": 0.7}
ana@laptop:~/azure$ kubectl get pod shop -o jsonpath='{.spec.nodeName} {.status.containerStatuses[0].image}{"\n"}'
shop-worker docker.io/library/shop:1.0
ana@laptop:~/azure$ kubectl get pod shop -o jsonpath='{.status.containerStatuses[0].imageID}{"\n"}'
docker.io/library/import-2026-10-30@sha256:d17c4f32994b3474c254b9a18234b8f4301749c9f817f937f48049e982b947ff
ana@laptop:~/azure$ docker exec shop-worker ctr -n k8s.io images ls name==docker.io/library/shop:1.0 2> /dev/null | awk '{print $1, $3}'
REF DIGEST
docker.io/library/shop:1.0 sha256:25d8715c3057e69a6df3afaa336cd1ebbf4ae8ab7ff392bfad00fbfeb55d4382
ana@laptop:~/azure$ kind delete cluster --name shop
Deleting cluster "shop" ...
Deleted nodes: ["shop-worker" "shop-control-plane"]
```

Três runtimes, e a versão `1.0` em `/version` em cada um. O nome do host e os segundos no ar
mudaram, porque pertencem ao contêiner ou ao pod. **E o mesmo digest em cada um.** O `docker inspect` o deu nas duas
execuções do Docker. No pod, o `kind load` o imprimiu ao copiar a imagem para os dois nós, e o
containerd do worker, perguntado por `shop:1.0`, guarda a imagem sob esse digest. O campo `imageID`
do próprio Kubernetes mostra outra coisa aqui: uma referência que começa com `import-` e a data do
dia, um nome inventado durante a importação para o arquivo que o `kind load` enviou, não para a
imagem dentro dele. Quando os dois parecerem discordar, pergunte ao runtime o que ele guarda, como
o último comando fez.

Um cuidado para a sua execução. O Docker desta máquina guarda as imagens no containerd:

```
ana@laptop:~/azure$ docker info --format '{{.DriverStatus}}'
[[driver-type io.containerd.snapshotter.v1]]
```

Um Docker com o armazenamento de imagens antigo imprime como id o hash da configuração da imagem, e
a lista do nó não vai bater com ele caractere por caractere. A imagem continua sendo uma só; os dois
são hashes de dois documentos diferentes sobre ela.

Nenhuma das três execuções precisou de mudança no `app.py` ou no `Dockerfile`, e nenhum dos quatro
serviços do Azure que as aulas 7, 8, 11 e 18 descreveram precisou. **O que mudou a cada vez foi o
arquivo em volta da imagem**: uma linha de `docker run`, um sidecar ao lado, um manifesto de pod e,
no Azure, um grupo de contêineres, um Container App, um Deployment e um web app. Esses arquivos são a
parte do lock-in de computação que resta, e cada um tem algumas dezenas de linhas. O último comando
apagou o cluster, e cada execução do Docker terminou com `docker rm -f`.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" aria-label=\"A imagem shop:1.0, com um digest, no meio. À esquerda, três maneiras como ela rodou no notebook nesta seção: Docker puro, ao lado de um sidecar do Dapr e como um pod no kind. À direita, quatro serviços do Azure que a executam, não executados aqui: Container Instances a partir de shop-aci.yaml na aula 7, Container Apps como Microsoft.App/containerApps na aula 8, AKS a partir de shop.yaml na aula 11 e App Service como Microsoft.Web/sites na aula 18. Uma nota diz que a imagem viaja sem mudar e que o arquivo em volta dela é o que fica para trás.\"><defs><marker id=\"l22-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"120\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">no notebook, executado aqui</text><text x=\"600\" y=\"14\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper-dim)\">no Azure, não executado aqui</text><rect x=\"285\" y=\"115\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360\" y=\"136\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">shop:1.0</text><text x=\"360\" y=\"156\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">um digest</text><rect x=\"20\" y=\"40\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Docker puro</text><text x=\"120\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">docker run</text><path d=\"M283 145 L222 65\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"20\" y=\"115\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ao lado de um sidecar do Dapr</text><text x=\"120\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">daprd</text><path d=\"M283 145 L222 140\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"20\" y=\"190\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um pod no kind</text><text x=\"120\" y=\"224\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-pod.yaml</text><path d=\"M283 145 L222 215\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"500\" y=\"25\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"42\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Container Instances, aula 7</text><text x=\"600\" y=\"59\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop-aci.yaml</text><path d=\"M437 145 L498 50\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"500\" y=\"90\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Container Apps, aula 8</text><text x=\"600\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Microsoft.App/containerApps</text><path d=\"M437 145 L498 115\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"500\" y=\"155\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">AKS, aula 11</text><text x=\"600\" y=\"189\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shop.yaml</text><path d=\"M437 145 L498 180\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><rect x=\"500\" y=\"220\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"600\" y=\"237\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">App Service, aula 18</text><text x=\"600\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">Microsoft.Web/sites</text><path d=\"M437 145 L498 245\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l22-ah)\"></path><text x=\"360\" y=\"296\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">a imagem viaja sem mudar; o arquivo em volta dela é o que cada plataforma lê, e o que fica para trás</text></svg>", "caption": "Uma imagem, sete maneiras de executá-la. Mudar de uma para outra reescreve o arquivo em volta da imagem, algumas dezenas de linhas, e nunca toca na imagem."}
```

## Costuras que valem a pena

A mesma ideia vale onde quer que o Azure, de outro modo, entrasse no código ou nos arquivos em volta
dele. Cada uma destas é um padrão que o Azure fala, e cada uma deixa algo para trás:

- **A API do Kubernetes** é a costura da orquestração. O Deployment e o orçamento de interrupção da
  aula 11 valem para qualquer cluster conforme. O que não viaja é o que o AKS acrescenta: os node
  pools e as configurações de upgrade em Bicep, o controlador do Application Gateway da aula 14, os
  rótulos `azure.workload.identity` da aula 13.
- **O OpenTelemetry** é a costura da telemetria. A Microsoft documenta uma distribuição própria do
  OpenTelemetry para mandar traces, métricas e logs ao Application Insights, então um código
  instrumentado com a API do OpenTelemetry só nomeia o Azure onde o exportador é configurado. As
  aulas 8 a 13 de `azure-operations` ensinam o Azure Monitor.
- **O CloudEvents** é a costura dos eventos. O Event Grid aceita e entrega CloudEvents 1.0, a
  especificação aberta da CNCF, e a aula 20 pôs os dois esquemas em `CloudEventSchemaV1_0`; um
  handler que lê esse envelope o lê de qualquer broker que o fale.
- **O AMQP 1.0** é a costura das mensagens. É o protocolo principal do Service Bus e um padrão ISO e
  IEC. O protocolo viaja; sessões, dead-letter e a biblioteca `azure-servicebus` da aula 20 são do
  Service Bus, então ponha o cliente atrás de uma função sua, como `send_export_request(order_day)`,
  e no dia em que a fila mudar, uma função muda.
- **Infraestrutura como código** é uma costura só em parte. O Bicep declara recursos do Azure e nada
  mais; o Terraform alcança muitos provedores pelos plugins dele, mas um arquivo Terraform da loja
  nomeia recursos `azurerm`, e esses não rodam em nenhum outro lugar. A linguagem e os hábitos
  viajam, e as definições de recursos são reescritas. As aulas 4 a 6 de `azure-operations` ensinam
  os dois.

## Dapr, a costura que você instala

A aula 9 foi uma abstração deliberada. O código da loja falava a API HTTP do Dapr e um arquivo de
componente decidia se o Redis ou o Service Bus respondia, então o broker mudou sem uma linha de
código. Essa é uma costura comprada como produto, e a aula 9 mediu o preço dela no notebook: um
sidecar usando mais memória do que o programa que ele servia, um salto a mais em cada chamada e um
segundo log para ler. **E você passa a depender da API do Dapr em vez da do broker**: os caminhos
`/v1.0/`, o envelope CloudEvent, o formato das chaves no state store. O Dapr é lock-in levado para
um projeto aberto, não lock-in removido, e a aula 9 disse quando essa troca compensa.

## Quanto custa a portabilidade

**Uma costura é código, ou um processo, e os dois se pagam.** A imagem não custa quase nada, porque
uma imagem é como a loja já é construída. O preço cresce a cada recurso da plataforma que você
decide não usar diretamente. Uma equipe que embrulha o Durable Functions numa camada de workflow
própria, para poder sair um dia, escreveu um motor de workflow, e o mantém em cada dia em que não
sai.

O erro oposto é igualmente real. Recusar todo serviço gerenciado em nome da portabilidade significa
rodar o seu próprio broker, o seu próprio agendador e o seu próprio banco em máquinas virtuais, o que
custa mais todo mês do que a maioria das saídas jamais custaria. **A portabilidade vale o preço onde
sair é provável ou caro, e em nenhum outro lugar**, e a próxima seção transforma essa frase em
números.
