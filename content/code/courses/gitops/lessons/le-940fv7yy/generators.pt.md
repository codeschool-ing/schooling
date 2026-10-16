---
title: ConfigMaps gerados, e por que o hash é o ponto
version: 1
---

**Um ConfigMap que os pods leem ao iniciar tem uma armadilha conhecida**: mude o ConfigMap, e os pods
continuam com os valores antigos até algo reiniciá-los. Nada no Kubernetes liga os dois, então a
mudança é aplicada, o cluster está sincronizado, e a aplicação roda com a configuração antiga até o
próximo rollout sem relação nenhuma.

O `configMapGenerator` fecha esse buraco. O Kustomize monta o ConfigMap a partir dos literais, dá a
ele o nome `bulletin-` mais um hash do conteúdo, e reescreve toda referência a `bulletin` no overlay
para o nome com hash. **Uma mensagem diferente é um hash diferente, um nome diferente, um template de
pod diferente**, e portanto um rollout, sem nada que alguém precise lembrar.

```
ana@laptop:~/fleet$ git switch --quiet -c staging-message
ana@laptop:~/fleet$ git diff | grep '^[-+] '
-  - MESSAGE=Staging is updated by a webhook.
+  - MESSAGE=Staging is built by Kustomize.
ana@laptop:~/fleet$ kubectl -n staging get configmaps
NAME                  DATA   AGE
bulletin-t55m2kmd94   1      13s
kube-root-ca.crt      1      2m9s
ana@laptop:~/fleet$ git commit --quiet -am "staging: built by Kustomize"
ana@laptop:~/fleet$ kubectl -n staging get configmaps
NAME                  DATA   AGE
bulletin-bgc7c2mm85   1      5s
kube-root-ca.crt      1      2m19s
ana@laptop:~/fleet$ curl -s localhost:8080
bulletin 1.1
message: Staging is built by Kustomize.
pod: bulletin-57cd9f8cc5-mdcwt
token: none
```

O pull request mudou um literal no `apps/bulletin/staging/kustomization.yaml`. O Flux aplicou um
ConfigMap novo com um sufixo novo, o Deployment apontando para ele, e os pods foram trocados; o
ConfigMap antigo foi podado na mesma passada, porque nenhum arquivo o descreve mais. A página mostra a
mensagem nova de um pod novo.

O mesmo mecanismo funciona para um `secretGenerator`, com o mesmo cuidado de todo o resto deste curso:
**os literais dele estariam no Git em texto puro**. As aulas 9 e 10 levam segredos ao cluster por
outros caminhos.
