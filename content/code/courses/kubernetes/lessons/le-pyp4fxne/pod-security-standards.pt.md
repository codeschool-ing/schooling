---
title: Recusando os pods que esquecem
version: 1
---

Um security context protege os pods que o carregam. **O trabalho do cluster é recusar os que não
carregam**, e o jeito embutido é o Pod Security Admission: uma verificação dentro do API server que
compara todo pod com um de três níveis publicados, os Pod Security Standards.

| nível | o que ele recusa |
|---|---|
| `privileged` | nada |
| `baseline` | as escaladas conhecidas: containers privilegiados, a rede ou os processos do host, caminhos do host, capabilities perigosas acrescentadas |
| `restricted` | tudo o que `baseline` recusa, mais root, escalada de privilégio, qualquer capability além de `NET_BIND_SERVICE`, e a falta de perfil de seccomp |

O nível é escolhido por namespace, com um rótulo. Existem três modos, e um namespace pode carregar os
três em níveis diferentes: `enforce` recusa, `warn` deixa o pod entrar e imprime um aviso, `audit`
registra no log de auditoria.

```
ana@laptop:~/shop$ kubectl create namespace payments
namespace/payments created
ana@laptop:~/shop$ kubectl label namespace payments pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/warn=restricted
namespace/payments labeled
```

`payments` agora aplica `restricted`. O pod busybox simples da seção anterior tenta rodar lá:

```
ana@laptop:~/shop$ kubectl -n payments run plain --image=busybox:1.37 --restart=Never --command -- sleep 3600
Error from server (Forbidden): pods "plain" is forbidden: violates PodSecurity "restricted:latest": allowPrivilegeEscalation != false (container "plain" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container "plain" must set securityContext.capabilities.drop=["ALL"]), runAsNonRoot != true (pod or container "plain" must set securityContext.runAsNonRoot=true), seccompProfile (pod or container "plain" must set securityContext.seccompProfile.type to "RuntimeDefault" or "Localhost")
```

**Recusado, com todos os motivos numa mensagem só**, que se lê como uma lista de conferência dos
campos do pod endurecido. E esse pod, sem mudança a não ser o namespace, entra:

```
ana@laptop:~/shop$ sed "s/name: hardened/name: hardened\n  namespace: payments/" hardened.yaml | kubectl apply -f -
pod/hardened created
```

## Experimentando um nível antes de aplicá-lo

Rotular um namespace que já existe não mexe nos pods que já rodam nele; vale para os novos. Para
descobrir o que um nível quebraria antes de ligá-lo, pergunte ao API server com um dry run:

```
ana@laptop:~/shop$ kubectl label --dry-run=server --overwrite namespace default pod-security.kubernetes.io/enforce=baseline
namespace/default labeled (server dry run)
ana@laptop:~/shop$ kubectl label --dry-run=server --overwrite namespace default pod-security.kubernetes.io/enforce=restricted
Warning: existing pods in namespace "default" violate the new PodSecurity enforce level "restricted:latest"
Warning: plain: allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile
namespace/default labeled (server dry run)
```

`baseline` aceitaria tudo o que já está em `default`. `restricted` não aceitaria, e o aviso cita
`plain` e o motivo. **Um dry run no servidor é o jeito seguro de implantar isto**: rotule cada
namespace com `warn` primeiro, leia o que ele relata por um tempo, e só então acrescente `enforce`.

Pods não são a única porta de entrada. Com `warn` ligado, o template de pod de um Deployment também é
conferido e o aviso volta na hora. O `enforce` age só sobre pods, então a recusa dele acontece quando o
ReplicaSet tenta criá-los, e aparece como evento nele, como as recusas de cota da lição 20.
