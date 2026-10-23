---
title: Regras de admissão próprias, na porta do Deployment
version: 1
---

O Pod Security Admission responde a uma pergunta, quanto um pod pode fazer no nó. O time do linkbox
tem mais duas, ambas de aulas anteriores: **uma imagem tem de vir do registry para onde o pipeline
envia, porque só essas imagens passaram pelo scan da aula 8; e um contêiner tem de declarar limite de
memória, porque a aula 9 mostrou o que um sem limite faz com os vizinhos.** Nenhuma das duas está em
algum perfil do Pod Security. Uma ValidatingAdmissionPolicy é uma regra assim, escrita como expressão
em CEL e avaliada dentro do API server, sem programa nenhum para instalar. A aula 25 de `kubernetes`
escreveu uma que recusava a tag `latest`; esta codifica as garantias do próprio pipeline.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" data-fig=\"sp-l10-admission\" aria-label=\"O que acontece com um Deployment no caminho para dentro do cluster, e com os pods feitos a partir dele. O kubectl apply manda o Deployment ao API server, que autentica e autoriza o pedido e depois roda a admissão: a ValidatingAdmissionPolicy confere a imagem e o limite de memória do Deployment, e só então ele é gravado. O controlador do ReplicaSet então cria os pods, e cada pod passa por uma admissão própria: o LimitRange preenche padrões, e o Pod Security Admission e a ResourceQuota podem recusá-lo. Um Deployment recusado recebe um erro no kubectl; um pod recusado só aparece como evento.\"><defs><marker id=\"sp-l10-admission-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l10-admission-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"30\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"75.0\" y=\"55.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">kubectl apply</text><rect x=\"160\" y=\"30\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"235.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">API server</text><text x=\"235.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">quem pede, e se pode</text><rect x=\"335\" y=\"30\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ValidatingAdmissionPolicy</text><text x=\"450.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">o Deployment: registry, limite de memória</text><rect x=\"590\" y=\"30\" width=\"115\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"647.5\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">gravado</text><text x=\"647.5\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">etcd</text><path d=\"M135 55 L158 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M310 55 L333 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M565 55 L588 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M450 80 L450 112\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l10-admission-ah-amber)\"></path><text x=\"450\" y=\"124\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">recusado: erro no kubectl</text><path d=\"M647 80 L647 168\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><rect x=\"560\" y=\"170\" width=\"145\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"632.5\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">ReplicaSet</text><text x=\"632.5\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">cria cada pod</text><rect x=\"390\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"465.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">LimitRange</text><text x=\"465.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">padrões, máximo</text><rect x=\"210\" y=\"170\" width=\"160\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"290.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">Pod Security Admission</text><text x=\"290.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">perfil restricted</text><rect x=\"40\" y=\"170\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"115.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">ResourceQuota</text><text x=\"115.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper-dim)\">total do namespace</text><path d=\"M560 195 L542 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M390 195 L372 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M210 195 L192 195\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l10-admission-ah-paper-dim)\"></path><path d=\"M290 220 L290 252\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l10-admission-ah-amber)\"></path><path d=\"M115 220 L115 252\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l10-admission-ah-amber)\"></path><text x=\"205\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">recusado: evento, nenhum pod</text></svg>", "caption": "Duas portas. A do Deployment é onde o kubectl ouve o não; a dos pods recusa depois, e só os eventos contam.", "same": ["API server", "ValidatingAdmissionPolicy", "ReplicaSet", "Pod Security Admission", "LimitRange", "ResourceQuota"]}
```

### A política

Salve como `k8s/admission.yaml`:

```yaml
# Two rules the cluster itself enforces on every Deployment in the linkbox
# namespace, whoever applies it and however: images come from this
# project's registry, and every container declares a memory limit.
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicy
metadata:
  name: linkbox-deployments
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
        c.image.startsWith('localhost:5000/'))
      message: images come from the registry at localhost:5000 and nowhere else
    - expression: >-
        object.spec.template.spec.containers.all(c,
        has(c.resources.limits) && 'memory' in c.resources.limits)
      message: every container declares a memory limit
---
apiVersion: admissionregistration.k8s.io/v1
kind: ValidatingAdmissionPolicyBinding
metadata:
  name: linkbox-deployments
spec:
  policyName: linkbox-deployments
  validationActions: ["Deny"]
  matchResources:
    namespaceSelector:
      matchLabels:
        kubernetes.io/metadata.name: linkbox
```

A política diz o que conferir e em que objetos: Deployments, quando criados ou atualizados. Cada
`validation` é uma expressão CEL que precisa ser verdadeira, com a mensagem que a pessoa recusada lê.
O binding liga a política, com a ação `Deny`, nos namespaces que o seletor dele pega: aqui o que se
chama `linkbox`, pelo rótulo que o Kubernetes põe em todo namespace.

**`failurePolicy: Fail` decide o que acontece quando a própria política não consegue ser avaliada**,
um erro de expressão num objeto de formato inesperado, por exemplo. `Fail` recusa o objeto; `Ignore`
deixa entrar. Uma garantia que caduca sempre que a checagem dá erro é o scanner que não rodou da aula
7, então ela falha fechada.

### Aplique e teste

```
ana@vm:~/linkbox$ kubectl apply -f k8s/admission.yaml
validatingadmissionpolicy.admissionregistration.k8s.io/linkbox-deployments created
validatingadmissionpolicybinding.admissionregistration.k8s.io/linkbox-deployments created
```

Uma imagem de qualquer outro lugar, aqui do Docker Hub:

```
ana@vm:~/linkbox$ kubectl create deployment other -n linkbox --image=python:3.13-slim
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "python" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "python" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "python" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "python" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
error: failed to create deployment: deployments.apps "other" is forbidden: ValidatingAdmissionPolicy 'linkbox-deployments' with binding 'linkbox-deployments' denied request: images come from the registry at localhost:5000 and nowhere else
```

A imagem do próprio linkbox, mas criada do jeito rápido, sem recurso nenhum:

```
ana@vm:~/linkbox$ kubectl create deployment nolimit -n linkbox --image=localhost:5000/linkbox:main
Warning: would violate PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "linkbox" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "linkbox" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "linkbox" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "linkbox" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
error: failed to create deployment: deployments.apps "nolimit" is forbidden: ValidatingAdmissionPolicy 'linkbox-deployments' with binding 'linkbox-deployments' denied request: every container declares a memory limit
```

**As duas recusadas no momento do `kubectl create`, com a frase da própria política.** O `Warning`
acima de cada erro é o Pod Security Admission, que olha o template do pod enquanto o Deployment passa
e diz que os pods dele seriam recusados; ele avisa e não impede nada, exatamente como no namespace
restricted duas seções atrás, onde um Deployment entrou e os pods dele foram recusados longe dos
olhos. A linha `error` é a política. Ela pega Deployments, então quem aplica um ouve a recusa
diretamente. O segundo caso também mostra como as regras se combinam: a imagem passou na primeira
regra, e a mensagem é a da segunda.

O manifesto do próprio linkbox, aplicado de novo, passa nas duas:

```
ana@vm:~/linkbox$ kubectl apply -f k8s/linkbox.yaml
namespace/linkbox unchanged
deployment.apps/linkbox unchanged
service/linkbox unchanged
```

E fora do namespace que o binding seleciona, nada muda:

```
ana@vm:~/linkbox$ kubectl create deployment other -n default --image=python:3.13-slim --dry-run=server
deployment.apps/other created (server dry run)
```

**`--dry-run=server` manda o objeto pela admissão sem gravá-lo**, então é o jeito honesto de
perguntar "isso seria aceito?". O namespace `default` aceita uma imagem do Docker Hub, porque o
binding nomeia só `linkbox`. Isso é uma escolha, e um cluster que abriga mais de um time costuma
ligar regras assim de forma mais ampla, com exceções para os namespaces do sistema.

### O que as regras não dizem

**`startsWith('localhost:5000/')` confere um nome, e um nome não é uma identidade.** Qualquer coisa
enviada a esse registry com qualquer nome passa, tenha o pipeline construído ou não, e a tag `main` se
move a cada push. A aula 14 fecha essa lacuna de verdade, assinando a imagem no pipeline e conferindo
a assinatura na admissão; até lá a regra diz "do nosso registry", o que é mais estreito que "de
qualquer lugar" e mais largo que "construída por nós".

E nenhuma regra de admissão vê o que a imagem faz depois que roda. A admissão lê o manifesto: os
campos, os nomes, os números. Ela não tem como saber que uma biblioteca dentro da imagem abre uma
conexão que não deveria, ou que um processo escreve onde não deveria; quem limita isso, em execução,
é o sistema de arquivos somente leitura e o conjunto vazio de capabilities. Vigiar o que os
contêineres de fato fazem, com um detector de runtime como o Falco, é a camada seguinte, descrita na
documentação do Falco e não executada neste curso.
