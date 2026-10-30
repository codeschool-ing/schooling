---
title: Config Connector, infraestrutura como objetos do Kubernetes
version: 1
---

**O Config Connector descreve recursos do Google Cloud como objetos do Kubernetes, e um controlador num
cluster mantém os recursos reais iguais a eles, continuamente.** As lições 5 e 6 usaram o Terraform, que
age quando uma pessoa ou uma esteira o roda e fica em silêncio entre uma vez e outra. O Config Connector
não espera: um bucket apagado à mão no console volta em minutos, porque o controlador vê que o objeto no
cluster diz que ele deve existir. **Nada nesta lição foi executado.** O Config Connector precisa de um
cluster do GKE e o Infrastructure Manager precisa de um projeto; nenhum dos dois tem emulador. Ela é
ensinada pela documentação do Google, e os arquivos abaixo foram escritos a partir dela.

O bucket de assets da loja, como objeto do Config Connector:

```yaml
# kcc/assets-bucket.yaml
apiVersion: storage.cnrm.cloud.google.com/v1beta1
kind: StorageBucket
metadata:
  name: planner-dev-shop-assets
  namespace: shop
  annotations:
    cnrm.cloud.google.com/project-id: planner-dev
  labels:
    team: shop
spec:
  location: SOUTHAMERICA-EAST1
  uniformBucketLevelAccess: true
  versioning:
    enabled: true
```

Ele é aplicado como qualquer objeto do Kubernetes, `kubectl apply -f kcc/assets-bucket.yaml`, e daí em
diante o cluster é dono do bucket. Quatro coisas decorrem disso, e cada uma é uma diferença em relação ao
Terraform:

- **Não há arquivo de estado.** O objeto no cluster é o estado desejado, e o bucket no Google é o real. A
  pergunta a que a lição 6 dedicou uma lição (onde está o estado, quem o travou) não surge; a pergunta
  passa a ser quem pode editar objetos no namespace `shop`.
- **Não há plano.** `kubectl apply` muda o objeto e o controlador age sobre ele. Uma mudança revisada é um
  pull request no YAML, e o diff é a única prévia que existe, que se lê bem para um rótulo e mal para uma
  mudança que força uma substituição.
- **O drift é corrigido, não relatado.** Uma mudança feita à mão é desfeita. É a garantia mais forte desta
  lição, e é também como a correção de emergência de alguém no console some às 3 da manhã sem uma palavra.
- **Apagar o objeto apaga o recurso**, a não ser que o objeto tenha
  `cnrm.cloud.google.com/deletion-policy: abandon`. Um namespace apagado por engano leva todo recurso
  declarado nele.

## Como quem o controlador age

O controlador age no Google Cloud como uma conta de serviço, pela Workload Identity (lição 15 de
`gcp-compute`), e essa conta precisa dos papéis para criar e mudar tudo o que o cluster declara. **Quem
pode criar objetos num namespace que o Config Connector observa pode criar recursos com as permissões
dessa conta.** O RBAC do Kubernetes no namespace é, portanto, o IAM do Google Cloud com outro nome, e é
concedido com o mesmo cuidado: uma conta de serviço por namespace, só com os papéis de que os recursos
daquele namespace precisam.

## Quando serve

O Config Connector serve a um time que já roda GKE e gerencia as aplicações com manifestos do Kubernetes:
o bucket que uma aplicação usa fica no mesmo repositório, na mesma revisão e no mesmo `kubectl` que o
`Deployment` que o usa. Serve mal a um time sem cluster, porque precisa de um rodando o tempo todo só para
guardar as descrições, e a um time cujos recursos são sobretudo redes, projetos e políticas da
organização, que vivem bem fora de qualquer cluster.
