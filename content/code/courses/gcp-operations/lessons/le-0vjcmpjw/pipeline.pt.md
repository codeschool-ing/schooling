---
title: Um delivery pipeline é uma lista ordenada de alvos
version: 1
---

**O Cloud Deploy leva um release por uma lista ordenada de ambientes, e cada ambiente é um alvo
(target).** O build da lição 1 termina com uma imagem no registro. O Cloud Deploy começa ali: pega essa
imagem, renderiza os manifestos para o primeiro alvo, faz o deploy e espera até alguém promover o
release para o alvo seguinte. Ele não constrói nada e não decide o que é bom; leva a mesma coisa
adiante, em ordem, e registra quem a moveu. **Nada nesta seção foi executado**: nenhum emulador responde
pelo Cloud Deploy, e os arquivos abaixo foram escritos a partir da documentação do Google.

A loja tem dois alvos, `dev` e `prod`, ambos serviços do Cloud Run em São Paulo, num arquivo,
`clouddeploy.yaml`, com três documentos dentro:

```yaml
# clouddeploy.yaml
apiVersion: deploy.cloud.google.com/v1
kind: DeliveryPipeline
metadata:
  name: shop-api
serialPipeline:
  stages:
    - targetId: dev
      profiles: [dev]
    - targetId: prod
      profiles: [prod]
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: dev
run:
  location: projects/planner-dev/locations/southamerica-east1
---
apiVersion: deploy.cloud.google.com/v1
kind: Target
metadata:
  name: prod
requireApproval: true
run:
  location: projects/planner-dev/locations/southamerica-east1
executionConfigs:
  - usages: [RENDER, DEPLOY]
    serviceAccount: shop-deploy@planner-dev.iam.gserviceaccount.com
```

Leia como três afirmações:

- **o pipeline** `shop-api` tem dois stages, nessa ordem; um release começa no primeiro e só chega ao
  segundo por promoção. `profiles` nomeia o perfil do Skaffold usado para renderizar cada stage, que é
  onde os dois ambientes diferem;
- **o alvo** `dev` é um lugar: aqui, o Cloud Run numa região de um projeto. Um alvo para o GKE nomeia
  um cluster;
- **o alvo** `prod` é o mesmo tipo de lugar com mais duas linhas: `requireApproval`, assunto da próxima
  seção, e a conta de serviço que renderiza e faz deploy ali. Um deploy em produção que age como uma
  conta diferente e mais estreita do que a que faz deploy em `dev` é como um erro em `dev` fica em `dev`.

O pipeline e seus alvos são registrados uma vez, e de novo sempre que o arquivo muda:

```sh
gcloud deploy apply --file=clouddeploy.yaml --region=southamerica-east1
```

## Skaffold, a parte que renderiza

O Cloud Deploy não lê manifestos do Kubernetes ou do Cloud Run sozinho. Ele os entrega ao **Skaffold**,
a ferramenta de código aberto do Google para renderizar e fazer deploy, por um arquivo do próprio
Skaffold:

```yaml
# skaffold.yaml
apiVersion: skaffold/v4beta13
kind: Config
metadata:
  name: shop-api
profiles:
  - name: dev
    manifests:
      rawYaml: [run/service-dev.yaml]
  - name: prod
    manifests:
      rawYaml: [run/service-prod.yaml]
deploy:
  cloudrun: {}
```

Cada `service-*.yaml` é um serviço do Cloud Run cuja imagem de contêiner está escrita como o nome
simples `shop-api`. Quando um release é criado, o Cloud Deploy dá ao Skaffold a imagem real para esse
nome, e o Skaffold a escreve no manifesto renderizado **como digest**. Os dois arquivos diferem no que um
ambiente deve diferir: o nome do serviço, as instâncias mínimas, a memória, as variáveis que apontam
para o banco de dados do ambiente. Não diferem na imagem, e esse é o ponto da próxima seção.
