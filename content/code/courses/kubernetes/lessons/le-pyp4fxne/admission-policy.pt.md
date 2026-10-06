---
title: Uma regra sua, na mesma porta
version: 1
---

Os Pod Security Standards respondem a uma pergunta, quanto um pod pode fazer no seu nó. Equipes têm
outras: todo Deployment precisa nomear um dono, nenhuma imagem pode vir de fora do registry da
empresa, nenhuma tag pode ser `latest`. **Uma ValidatingAdmissionPolicy é uma regra assim, escrita como
uma expressão e avaliada dentro do API server**, sem programa extra para rodar.

```yaml
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: no-latest-tag
spec:
  failurePolicy: Fail
  matchConstraints:
    resourceRules:
    - apiGroups: ["apps"]
      apiVersions: ["v1"]
      operations: ["CREATE", "UPDATE"]
      resources: ["deployments"]
  validations:
  - expression: >-
      object.spec.template.spec.containers.all(c,
        c.image.contains(':') && !c.image.endsWith(':latest'))
    message: "every image needs an explicit tag, and the tag may not be latest"
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: no-latest-tag
spec:
  policyName: no-latest-tag
  validationActions: ["Deny"]
```

A política diz o que conferir e em quais objetos: Deployments, quando criados ou atualizados. A
expressão é CEL, uma pequena linguagem de expressões que o Kubernetes usa sempre que precisa de uma
regra num manifesto: a imagem de cada container precisa conter dois-pontos e não pode terminar em
`:latest`. O binding a liga, aqui para o cluster inteiro, com a ação `Deny`.

```
ana@laptop:~/shop$ kubectl apply -f no-latest.yaml
validatingadmissionpolicy.admissionregistration.k8s.io/no-latest-tag created
validatingadmissionpolicybinding.admissionregistration.k8s.io/no-latest-tag created
ana@laptop:~/shop$ kubectl create deployment web --image=nginx:latest
error: failed to create deployment: deployments.apps "web" is forbidden: ValidatingAdmissionPolicy 'no-latest-tag' with binding 'no-latest-tag' denied request: every image needs an explicit tag, and the tag may not be latest
ana@laptop:~/shop$ kubectl create deployment web --image=nginx
error: failed to create deployment: deployments.apps "web" is forbidden: ValidatingAdmissionPolicy 'no-latest-tag' with binding 'no-latest-tag' denied request: every image needs an explicit tag, and the tag may not be latest
ana@laptop:~/shop$ kubectl create deployment web --image=nginx:1.29
deployment.apps/web created
```

`nginx:latest` é recusada, e o `nginx` puro também, que quer dizer a mesma coisa. `nginx:1.29` é
aceita. A mensagem é a da própria política, e é para isso que se escreve uma: quem é recusado lê o que
a regra quer, não um stack trace.

**A expressão tem um furo.** `registry.local:5000/shop` contém dois-pontos, por causa da porta, e
nenhuma tag, então passa. Uma regra assim precisa de um teste com cada forma de nome de imagem que a
empresa de fato usa; a captura tentou três formas e deixou passar a quarta. Uma versão mais rígida confere a parte depois da última
barra. Políticas que precisam de mais que uma expressão, ou que mudam objetos em vez de recusá-los,
são o que os admission webhooks fazem; a lição 45 é sobre estender o API server desses jeitos.

| | Pod Security Standards | ValidatingAdmissionPolicy |
|---|---|---|
| escrito por | o projeto Kubernetes | você |
| ligado por | um rótulo de namespace | um binding |
| confere | pods contra três níveis fixos | qualquer objeto, qualquer expressão |
| resposta | recusar, avisar ou auditar | recusar, avisar ou auditar |
