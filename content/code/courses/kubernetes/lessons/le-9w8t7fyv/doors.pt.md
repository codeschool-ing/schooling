---
title: As outras portas do API server
version: 1
---

Um segundo scheduler é um jeito de pôr código seu nas decisões de um cluster. Há mais três, e eles
diferem em onde o seu código roda e no que acontece quando ele está fora do ar.

| Porta | O seu código é | Perguntado quando | Se estiver fora do ar |
| --- | --- | --- | --- |
| Extender do scheduler | um serviço HTTP | depois do filtro e da pontuação, para cada pod do perfil | o campo `ignorable` dele decide: falhar o pod ou seguir |
| Webhook de admissão | um serviço HTTPS | em toda escrita que a configuração casa | o `failurePolicy` decide: recusar a escrita ou deixar passar |
| ValidatingAdmissionPolicy | uma expressão dentro do API server | em toda escrita que o binding casa | ela não tem como estar fora do ar |
| API agregada | um API server inteiro atrás de um Service | em toda requisição ao grupo de API dela | esse grupo responde com erro |

**O extender é a porta antiga.** Ele é anterior ao framework de plugins, custa uma ida e volta HTTP por
pod, e trabalho novo escreve um plugin ou um perfil. Vale reconhecê-lo numa configuração que outra pessoa
escreveu.

**Um webhook de admissão fica no caminho de toda escrita que ele casa**, e isso é o poder e o risco dele.
Um mutante pode acrescentar um sidecar a todo pod, que é como várias service meshes injetam o seu; um
validador pode recusar o que a política da lição 25 não consegue expressar. Com `failurePolicy: Fail`, um
webhook fora do ar recusa as escritas que casa, e se ele casar os pods do próprio Deployment, não dá para
reiniciá-lo. **Limite-o com um seletor e mantenha-o fora do `kube-system`.** A ValidatingAdmissionPolicy
da lição 25 faz as verificações comuns dentro do API server, sem nada para manter rodando, e é a primeira
coisa a buscar.

**Uma API agregada é uma porta para recursos inteiros novos.** A lição 21 viu uma: o `metrics.k8s.io` é
servido pelo metrics-server, e o API server só repassa para ele. Os CRDs da lição 43 são o outro jeito de
acrescentar um recurso, guardado no etcd pelo próprio API server; a agregação é para a API rara que não
pode viver no etcd, como uma que calcula as respostas.

Um cluster novo não tem nenhuma dessas:

```
ana@laptop:~/shop$ kubectl get apiservices | grep -v Local
NAME                              SERVICE   AVAILABLE   AGE
ana@laptop:~/shop$ kubectl get validatingwebhookconfigurations,mutatingwebhookconfigurations
No resources found
ana@laptop:~/shop$ kubectl get validatingadmissionpolicies
No resources found
```

A lista de `apiservices` sem `Local` é só o cabeçalho: todo grupo de API é servido pelo próprio API
server. Nenhum webhook e nenhuma política. **Cada linha que aparecer aqui depois é código que roda na
escrita de alguém**, então esses três comandos valem a pena num cluster que você herda.
