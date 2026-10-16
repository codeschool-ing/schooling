---
title: Quem mexeu por último num campo
version: 1
---

**Todo objeto lembra qual cliente definiu cada um dos seus campos.** Desde o server-side apply, o
API server mantém `managedFields` em todo objeto: uma lista de *managers*, cada um com os campos que
definiu e o horário em que fez isso pela última vez. O Flux aplica como `kustomize-controller`;
`kubectl scale` é `kubectl`; um autoscaler tem o próprio nome. Sem nenhum log de auditoria
configurado, um objeto consegue dizer quem o mudou por último, campo a campo.

Uma mudança à mão, do tipo que a aula 1 chamou de drift, feita pouco antes da próxima passada do
Flux:

```
ana@laptop:~/fleet$ kubectl -n staging scale deployment bulletin --replicas=5
deployment.apps/bulletin scaled
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin -o json --show-managed-fields | jq -c '.metadata.managedFields[] | {manager, operation, time, replicas: (.fieldsV1."f:spec"."f:replicas" != null)}'
{"manager":"kustomize-controller","operation":"Apply","time":"2026-10-16T04:40:00Z","replicas":false}
{"manager":"kubectl","operation":"Update","time":null,"replicas":true}
{"manager":"kube-controller-manager","operation":"Update","time":"2026-10-16T04:53:57Z","replicas":false}
ana@laptop:~/fleet$ flux reconcile kustomization staging >/dev/null
► annotating Kustomization staging in flux-system namespace
✔ Kustomization annotated
◎ waiting for Kustomization reconciliation
✔ applied revision main@sha1:42c811e7415a8d67d9632a5889e32afd2f4083cd
ana@laptop:~/fleet$ kubectl -n staging get deployment bulletin -o json --show-managed-fields | jq -c '.metadata.managedFields[] | {manager, operation, time, replicas: (.fieldsV1."f:spec"."f:replicas" != null)}'
{"manager":"kustomize-controller","operation":"Apply","time":"2026-10-16T04:53:57Z","replicas":true}
{"manager":"kube-controller-manager","operation":"Update","time":"2026-10-16T04:53:57Z","replicas":false}
```

Antes da passada do Flux, o `kubectl` é dono de `spec.replicas`, com um `Update`. Depois dela, a
entrada do `kubectl` sumiu e o `kustomize-controller` voltou a ser dono do campo, com um `Apply` e
um horário novo: o Flux retomou o campo, e o objeto agora diz isso.

É uma evidência mais fraca que um log de auditoria, e vale conhecê-la justamente por isso. Ela
nomeia um cliente, não uma pessoa: todo usuário de `kubectl` é `kubectl`. Guarda o último a escrever
cada campo e esquece os anteriores. E faz parte do objeto, então some quando o objeto é apagado e é
reescrita quando o Flux retoma o campo. **Ela responde "algo além do Flux mexeu nisto?"** depressa e
em qualquer cluster, e para "quem, e exatamente quando" a seção seguinte liga o registro feito para
isso.
