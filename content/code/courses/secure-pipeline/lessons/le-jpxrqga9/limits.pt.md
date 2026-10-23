---
title: Limits, LimitRange e ResourceQuota
version: 1
---

A regra de admissão obriga todo Deployment do linkbox a declarar limite de memória. **Qual pode ser
o limite, e quanto o namespace pode usar no total, são decisões do cluster e não da aplicação**, e o
Kubernetes tem um objeto para cada uma. A aula 19 de `kubernetes` mostrou o que um limite faz com um
pod que passa dele; esta seção é sobre quem define os números e o que acontece nas bordas.

### Dois objetos, de quem cuida do cluster

Um LimitRange define padrões e limites para cada contêiner de um namespace: o limit que um contêiner
recebe se não declarar nenhum, e o maior que ele pode declarar. Uma ResourceQuota põe teto no
namespace inteiro: quantos pods, quanta memória pedida e limitada somando todos. Nenhum dos dois
pertence ao repositório do linkbox. Numa empresa eles são escritos pelo time que cuida do cluster, por
namespace, e o time da aplicação trabalha dentro deles. Neste laboratório você é os dois, então o
arquivo fica no seu diretório pessoal e não em `k8s/`. Salve como `~/quota.yaml`:

```yaml
# What the linkbox namespace may use, set by whoever runs the cluster rather
# than by the application's repository. The LimitRange fills in a memory
# limit for a container that declares none and refuses one above 256Mi; the
# ResourceQuota caps the namespace as a whole.
apiVersion: v1
kind: LimitRange
metadata:
  name: linkbox
  namespace: linkbox
spec:
  limits:
    - type: Container
      default:
        memory: 128Mi
      defaultRequest:
        memory: 64Mi
      max:
        memory: 256Mi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: linkbox
  namespace: linkbox
spec:
  hard:
    pods: "4"
    requests.memory: 512Mi
    limits.memory: 512Mi
```

```
ana@vm:~/linkbox$ kubectl apply -f ~/quota.yaml
limitrange/linkbox created
resourcequota/linkbox created
ana@vm:~/linkbox$ kubectl describe resourcequota linkbox -n linkbox
Name:            linkbox
Namespace:       linkbox
Resource         Used   Hard
--------         ----   ----
limits.memory    128Mi  512Mi
pods             1      4
requests.memory  64Mi   512Mi
```

**A cota já conta o pod do linkbox**: um de quatro pods, e 64Mi de requests e 128Mi de limits de
512Mi cada, exatamente o que o Deployment declara.

### A cota na borda

Peça cinco réplicas, onde a cota permite quatro pods:

```
ana@vm:~/linkbox$ kubectl scale deployment linkbox -n linkbox --replicas=5
deployment.apps/linkbox scaled
ana@vm:~/linkbox$ kubectl get deployment linkbox -n linkbox
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
linkbox   4/5     4            4           17s
ana@vm:~/linkbox$ kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{range .items[*]}{.message}{"\n"}{end}' | grep -m 1 'exceeded quota'
Error creating: pods "linkbox-56f7558485-d4kbh" is forbidden: exceeded quota: linkbox, requested: limits.memory=128Mi,pods=1, used: limits.memory=512Mi,pods=4, limited: limits.memory=512Mi,pods=4
ana@vm:~/linkbox$ kubectl scale deployment linkbox -n linkbox --replicas=1
deployment.apps/linkbox scaled
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" data-fig=\"sp-l10-quota\" aria-label=\"A cota do namespace linkbox contra cinco réplicas do linkbox. A cota permite 4 pods e 512Mi de limites de memória. Cada pod declara um limite de 128Mi, então quatro pods usam a cota inteira, 4 de 4 pods e 512Mi de 512Mi, e o quinto é recusado.\"><defs></defs><rect x=\"15\" y=\"30\" width=\"520\" height=\"100\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"30\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">cota: 4 pods, 512Mi de limites</text><rect x=\"30\" y=\"62\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"86.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 1</text><text x=\"86.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><rect x=\"155\" y=\"62\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"211.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 2</text><text x=\"211.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><rect x=\"280\" y=\"62\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"336.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 3</text><text x=\"336.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><rect x=\"405\" y=\"62\" width=\"112\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"461.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 4</text><text x=\"461.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><rect x=\"565\" y=\"62\" width=\"140\" height=\"52\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pod 5</text><text x=\"635.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">128Mi</text><text x=\"635\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">recusado: cota excedida</text></svg>", "caption": "Quatro pods de 128Mi enchem o namespace exatamente. O quinto cabe ao ReplicaSet criar e à cota recusar."}
```

**O `kubectl scale` deu certo, e quatro pods rodam.** Como o Pod Security Admission, uma ResourceQuota
julga pods, então o Deployment aceitou o número e o ReplicaSet dele teve o quinto pod recusado, com
uma mensagem que nomeia a cota e o que foi pedido contra o que sobrava. O Deployment fica em quatro
prontos de cinco até a cota ou o número mudar, e nada quebra para os quatro que rodam. É esse o
propósito: o escalonamento descontrolado de um namespace, ou um erro num manifesto, para no orçamento
do namespace em vez de no do cluster.

### O LimitRange na borda

Agora uma mudança que a regra de admissão aceita, porque o Deployment declara limite, mas que o
LimitRange recusa, porque o limite passa do máximo:

```
ana@vm:~/linkbox$ kubectl set resources deployment linkbox -n linkbox --limits=memory=512Mi
deployment.apps/linkbox resource requirements updated
ana@vm:~/linkbox$ kubectl get pods -n linkbox
NAME                       READY   STATUS    RESTARTS   AGE
linkbox-56f7558485-jsxj4   1/1     Running   0          20s
ana@vm:~/linkbox$ kubectl get events -n linkbox --field-selector reason=FailedCreate -o jsonpath='{range .items[*]}{.message}{"\n"}{end}' | grep -m 1 'maximum memory'
Error creating: pods "linkbox-5bc4f6895f-5pvfh" is forbidden: maximum memory usage per Container is 256Mi, but limit is 512Mi
ana@vm:~/linkbox$ kubectl rollout undo deployment linkbox -n linkbox
Warning: resource deployments/linkbox was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation, which may cause unexpected behavior on future 'kubectl apply' operations. Consider using 'kubectl apply' with your previous configuration file instead.
deployment.apps/linkbox rolled back
ana@vm:~/linkbox$ kubectl rollout status deployment/linkbox -n linkbox --timeout=120s
deployment "linkbox" successfully rolled out
```

O Deployment foi atualizado, e o pod novo dele foi recusado com a mensagem do próprio LimitRange: no
máximo 256Mi por contêiner, e foram pedidos 512Mi. O pod antigo continuou rodando, porque um rollout
só remove pods velhos quando os novos ficam prontos, e o `kubectl rollout undo` levou o Deployment de
volta à versão anterior. **Uma mudança ruim foi barrada sem queda**, que é o que um rollout com uma
checagem na porta do pod oferece, desde que alguém leia o status do rollout e não o do `apply`. O
aviso no undo é o `kubectl` apontando a correção mais limpa: o arquivo é a fonte, então no trabalho de
verdade a mudança é corrigida em `k8s/linkbox.yaml` e aplicada de novo.

### Três checagens sobre um número

| checagem | o que ela vê | onde recusa |
|---|---|---|
| a política de admissão | o Deployment: existe limite de memória? | no `kubectl apply`, na hora |
| o LimitRange | cada contêiner: o limite está dentro dos limites? preenche um se faltar | no pod, como evento |
| a ResourceQuota | o namespace: este pod cabe no que sobra? | no pod, como evento |

As três se sobrepõem de propósito. A política pega o Deployment que esqueceu, no momento em que alguém
pode corrigir; o LimitRange pega um pod feito por qualquer coisa que a política não pega, um Job ou um
pod avulso, e preenche um padrão em vez de recusar; a cota pega o total, que nenhum manifesto sozinho
enxerga. **A aula 19 acrescenta uma quarta, no pipeline**: a mesma regra conferida contra `k8s/` antes
de qualquer coisa chegar a um cluster, para a recusa aparecer num log de build e não na hora do deploy.

### Faça o commit

```
ana@vm:~/linkbox$ git add k8s
ana@vm:~/linkbox$ git commit -q -m "linkbox on Kubernetes, held to the restricted profile, and two admission rules"
9:45AM INF 0 commits scanned.
9:45AM INF scanned ~2980 bytes (2.98 KB) in 332ms
9:45AM INF no leaks found
```

O `ci/stages` não muda nesta aula. Os manifestos estão no repositório, revisados com o código, e a aula
19 é onde o pipeline começa a conferi-los.
