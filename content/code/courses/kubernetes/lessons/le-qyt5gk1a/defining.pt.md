---
title: Ensinando um tipo novo ao API server
version: 1
---

Antes de qualquer definição, o API server nunca ouviu falar de um Backup:

```
ana@laptop:~/shop$ kubectl get backups
error: the server doesn't have a resource type "backups"
```

**Uma CustomResourceDefinition é ela mesma um objeto comum**, criado com `kubectl apply`, e o que ela
descreve é um tipo novo de objeto. A equipe da loja quer declarar os backups do banco do jeito que
declara todo o resto, então o tipo é `Backup`:

```schooling-example
{"language": "yaml", "file": "backup-crd.yaml", "parts": [{"code": "apiVersion: apiextensions.k8s.io/v1\nkind: CustomResourceDefinition\nmetadata:\n  name: backups.shop.example.test\n", "note": "**O nome é o plural e o grupo**, `backups.shop.example.test`. Um grupo sob um domínio seu impede que os seus tipos colidam com os de outras pessoas."}, {"code": "spec:\n  group: shop.example.test\n  names:\n    kind: Backup\n    plural: backups\n    singular: backup\n    shortNames: [\"bk\"]\n  scope: Namespaced\n", "note": "Como o tipo novo se escreve: `Backup` nos manifestos, `backups` e `backup` na linha de comando, `bk` para abreviar. `Namespaced` põe cada Backup num namespace, como um Deployment."}, {"code": "  versions:\n  - name: v1\n    served: true\n    storage: true\n", "note": "Uma versão, `v1`, servida pela API e usada para armazenar. Uma `v2` depois seria acrescentada ao lado, nunca no lugar."}, {"code": "    schema:\n      openAPIV3Schema:\n        type: object\n        required: [\"spec\"]\n        properties:\n          spec:\n            type: object\n            required: [\"database\", \"schedule\"]\n            properties:\n              database:\n                type: string\n              schedule:\n                type: string\n              keep:\n                type: integer\n                minimum: 1\n                maximum: 30\n                default: 7\n          status:\n            type: object\n            properties:\n              lastRun:\n                type: string\n", "note": "**O schema é a validação.** `database` e `schedule` são obrigatórios; `keep` precisa ser um inteiro de 1 a 30 e o padrão é 7. Qualquer campo não listado é desconhecido. `status` ganha um schema próprio."}, {"code": "    subresources:\n      status: {}\n", "note": "`subresources.status` torna `status` uma parte separada do objeto, escrita por outra rota que não a do `spec`."}, {"code": "    additionalPrinterColumns:\n    - name: Database\n      type: string\n      jsonPath: .spec.database\n    - name: Schedule\n      type: string\n      jsonPath: .spec.schedule\n    - name: Keep\n      type: integer\n      jsonPath: .spec.keep\n    - name: Last run\n      type: string\n      jsonPath: .status.lastRun\n", "note": "As colunas que o `kubectl get` imprime, cada uma um caminho dentro do objeto."}]}
```

```
ana@laptop:~/shop$ kubectl apply -f backup-crd.yaml
customresourcedefinition.apiextensions.k8s.io/backups.shop.example.test created
ana@laptop:~/shop$ kubectl api-resources --api-group=shop.example.test
NAME      SHORTNAMES   APIVERSION             NAMESPACED   KIND
backups   bk           shop.example.test/v1   true         Backup
```

O API server agora serve `backups` no grupo `shop.example.test`, versão `v1`. **Nada foi compilado,
reiniciado ou instalado além desse único objeto.** O tipo novo é guardado no etcd como qualquer outro,
tem a sua própria URL na API, e funciona com `kubectl get`, `describe`, `delete`, `-o yaml`, regras de
RBAC e `watch`, tudo de graça, porque o API server trata essas coisas do mesmo jeito para todo tipo.

É assim que a maior parte do ecossistema Kubernetes estende o cluster. A Gateway API da lição 16 é um
conjunto de CRDs; também são os certificados do cert-manager, as aplicações do Argo CD, as regras de
alerta do Prometheus e o VerticalPodAutoscaler da lição 34. Listá-los em qualquer cluster de verdade
mostra o quanto dele é feito assim:

```
kubectl get crds
```

O cluster de laboratório desta lição só tem o que acabou de ser criado, então esse comando não foi
capturado aqui.
