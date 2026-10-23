---
title: Um namespace que recusa o que um pod não declara
version: 1
---

O Kubernetes, por conta própria, roda um pod do jeito que o `docker run` roda um contêiner: com o
usuário que a imagem nomeia, as capabilities padrão do runtime e uma raiz gravável. **O Pod Security
Admission é a parte do API server que consegue recusar um pod assim**, e ele é ligado por namespace,
com um rótulo. A aula 25 de `kubernetes` comparou os três perfis, `privileged`, `baseline` e
`restricted`; o linkbox fica com o mais rígido, e a parte interessante é o que ele recusa, e onde.

### O rótulo

```
ana@vm:~/linkbox$ kubectl create namespace linkbox
namespace/linkbox created
ana@vm:~/linkbox$ kubectl label namespace linkbox pod-security.kubernetes.io/enforce=restricted
namespace/linkbox labeled
```

`enforce` é um de três modos. `enforce` recusa, `warn` deixa o objeto entrar e imprime um aviso para
quem aplicou, e `audit` escreve uma entrada no log de auditoria do cluster. Um namespace pode ter os
três em níveis diferentes, e é assim que um time leva um namespace existente para `restricted`:
primeiro avisar, ler os avisos, depois impor.

### Um pod recusado pelo que não diz

Inicie o linkbox no namespace do jeito mais rápido, como um pod avulso só com a imagem:

```
ana@vm:~/linkbox$ kubectl run probe -n linkbox --image=localhost:5000/linkbox:main
Error from server (Forbidden): pods "probe" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "probe" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "probe" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "probe" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "probe" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

**Recusado, com uma lista de quatro coisas que o pod não definiu.** Nenhuma delas está errada na
imagem: a aula 8 a fez rodar como 65532, e ela não precisa de capability nem de raiz gravável. Mas o
perfil não examina a imagem. Ele lê a especificação do pod, e um pod que não *diz* que não vai
escalar, que vai remover as capabilities, que vai rodar como não root e que vai usar o perfil seccomp
padrão é um pod que poderia fazer as quatro coisas. **O perfil restricted pede declarações, e não bom
comportamento.**

### Um Deployment aceito, e os pods dele recusados

A mesma imagem como Deployment, que é como o linkbox vai rodar de verdade:

```
ana@vm:~/linkbox$ kubectl create deployment plain -n linkbox --image=localhost:5000/linkbox:main
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "linkbox" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "linkbox" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "linkbox" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "linkbox" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
deployment.apps/plain created
ana@vm:~/linkbox$ kubectl get deployment,replicaset,pod -n linkbox
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/plain   0/1     0            0           3s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/plain-5bfc78fc94   1         0         0       3s
ana@vm:~/linkbox$ kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{.items[0].message}{"\n"}'
Error creating: pods "plain-5bfc78fc94-cgkj2" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "linkbox" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "linkbox" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "linkbox" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "linkbox" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
ana@vm:~/linkbox$ kubectl delete deployment plain -n linkbox
deployment.apps "plain" deleted from linkbox namespace
```

Este é o caso que pega as pessoas. **O `kubectl` imprimiu um aviso e criou o Deployment**, porque o
Pod Security Admission julga pods, e um Deployment não é um pod. O ReplicaSet dele depois tentou criar
o pod e foi recusado, longe dos olhos: o Deployment mostra `0/1`, não existe pod nenhum, e o motivo
está só nos eventos do namespace. Quem acompanha o `kubectl apply` num pipeline não vê falha. Um passo
de deploy que não confere nada depois do `apply` relataria sucesso para um serviço que não está
rodando.

Daí saem dois hábitos. **Esperar o rollout, e falhar se ele não terminar**, que é o que
`kubectl rollout status` faz e o que a próxima seção usa. E quando algo precisa ser recusado no
momento em que é aplicado, conferir o próprio Deployment, que é o que a regra de admissão desta aula
faz, duas seções adiante.
