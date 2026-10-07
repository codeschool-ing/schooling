---
title: Desvio, e voltar com o git
version: 1
---

Alguém, com pressa durante um incidente, escala a loja à mão:

```
ana@laptop:~/shop/platform$ kubectl scale deployment shop --replicas=5
deployment.apps/shop scaled
ana@laptop:~/shop/platform$ kubectl diff -k shop | grep -E "^[-+] "
-  generation: 3
+  generation: 4
-  replicas: 5
+  replicas: 2
```

**O cluster e o repositório agora discordam, e o `diff` diz exatamente como**: cinco réplicas rodando,
duas no git. Isso é desvio (drift), e é como clusters ficam impossíveis de refazer: toda correção
manual que nunca foi escrita é uma diferença que a próxima reconstrução desfaz em silêncio. Aplicar o
repositório põe o cluster de volta:

```
ana@laptop:~/shop/platform$ kubectl apply -k shop
deployment.apps/shop configured
ana@laptop:~/shop/platform$ kubectl get deployment shop
NAME   READY   UP-TO-DATE   AVAILABLE   AGE
shop   2/2     2            2           13s
```

Uma ferramenta de GitOps faz isso sozinha, o que é a força dela e também o motivo de equipes desligarem
a correção automática para alguns campos. Um autoscaler, o da lição 33, também muda `replicas`, e uma
ferramenta que brigasse com ele a cada poucos minutos desfaria a escala. A correção comum é deixar
`replicas` fora do manifesto de todo Deployment que um autoscaler gerencia.

## Voltar é um commit

A 1.1 se mostra ruim. O caminho de volta é o mesmo de ida, pelo git:

```
ana@laptop:~/shop/platform$ git revert --no-edit HEAD >/dev/null && git log --oneline
ad5e381 Revert "shop 1.1"
be6246c shop 1.1
efea582 shop 1.0, two copies
ana@laptop:~/shop/platform$ kubectl apply -k shop
deployment.apps/shop configured
ana@laptop:~/shop/platform$ kubectl get deployment shop -o jsonpath="{.spec.template.spec.containers[0].image}"; echo
shop:1.0
```

`git revert` cria um commit novo que desfaz o antigo, o cluster acompanha, e o histórico agora mostra o
lançamento, o problema e a reversão, em ordem. Compare com o `kubectl rollout undo` da lição 35: ele é
mais rápido numa emergência, mas deixa o repositório dizendo 1.1 enquanto o cluster roda 1.0, o que é
desvio de novo, esperando o próximo apply trazer a versão ruim de volta.
