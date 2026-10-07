---
title: Um volume que vive tanto quanto o pod
version: 1
---

Um volume é um diretório que os containers de um pod podem montar, declarado no pod em `volumes` e
colocado em cada container com `volumeMounts`. **O tipo de volume decide quanto tempo os dados
vivem.** O tipo mais simples, `emptyDir`, é criado vazio quando o pod chega a um nó e removido quando o
pod vai embora:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scratch
spec:
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "date > /data/started; sleep 3600"]
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    emptyDir: {}
```

O container escreve no volume a hora em que subiu. Depois o pod é apagado e criado de novo:

```
ana@laptop:~/shop$ kubectl apply -f scratch.yaml
pod/scratch created
ana@laptop:~/shop$ kubectl exec scratch -- cat /data/started
Tue Oct  6 17:55:47 UTC 2026
ana@laptop:~/shop$ kubectl delete pod scratch
pod "scratch" deleted from default namespace
ana@laptop:~/shop$ kubectl apply -f scratch.yaml
pod/scratch created
ana@laptop:~/shop$ kubectl exec scratch -- cat /data/started
Tue Oct  6 17:56:21 UTC 2026
```

**Duas horas diferentes: o segundo pod ganhou um diretório novo e vazio.** Nada do primeiro
sobreviveu, que é exatamente o que o `emptyDir` promete. Ele sobrevive, sim, a um reinício de container
dentro do mesmo pod, porque o pod, e portanto o volume, continua lá; isso o torna o lugar certo para um
cache, para arquivos que dois containers de um pod compartilham, e para o `/tmp` gravável da lição 25.

É o lugar errado para qualquer coisa que a loja não pode perder: pedidos, uploads, os arquivos de um
banco. Pods são apagados por rollouts, por despejos e por falhas de nó, como as lições 10 e 32
mostram, e os dados precisam sobreviver a todos eles. Isso exige um armazenamento que o pod não
possui, e é o que o resto desta lição monta.
