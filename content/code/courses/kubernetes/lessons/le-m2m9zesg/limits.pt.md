---
title: Um limit é um teto, e os dois recursos batem nele de jeitos diferentes
version: 1
---

Um request decide para onde um pod vai. **Um limit decide o que acontece com ele depois que está lá**:
o kubelet o entrega ao kernel do Linux como uma configuração de cgroup, e o kernel o aplica a cada
fatia de tempo de CPU e a cada alocação. CPU e memória são aplicadas de jeitos opostos, porque são
tipos opostos de recurso.

## CPU: desacelerada, nunca morta

Duas cópias da loja, iguais a não ser por uma linha: `capped` tem um limit de CPU de 100m, e `free`
não tem nenhum.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: capped
  labels:
    app: capped
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: 100m
        memory: 64Mi
      limits:
        cpu: 100m
        memory: 64Mi
---
apiVersion: v1
kind: Pod
metadata:
  name: free
  labels:
    app: free
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: 100m
```

O endpoint `/work` da loja gira pelo número de milissegundos que recebe e informa quantas voltas
conseguiu dar. O pod `probe` chama cada cópia no endereço do pod, consultado antes:

```
ana@laptop:~/shop$ kubectl apply -f cpu.yaml
pod/capped created
pod/free created
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- '10.244.2.6:8080/work?ms=1000'
worked 1000ms, 14556734 loops, on free
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- '10.244.1.5:8080/work?ms=1000'
worked 1000ms, 1470592 loops, on capped
```

**O mesmo segundo de relógio rendeu a `free` 14.556.734 voltas e a `capped` 1.470.592, cerca de um
décimo.** É exatamente isso que um limit de 100m quer dizer: a cada período de 100 milissegundos, o
kernel deixa o container rodar por 10 milissegundos e depois o faz esperar. O request não desacelerou
`free` em nada; um request é um piso, e `free` podia usar o que o nó tivesse sobrando.

CPU pode ser tirada e devolvida um milissegundo depois, então o kernel estrangula e nada quebra além do
tempo. Uma requisição que leva cem milissegundos sem estrangulamento leva cerca de um segundo sob este
limit, e é por isso que um limit de CPU baixo demais aparece como latência, nunca como erro.

## Memória: morto

Memória não pode ser pausada e devolvida. Um processo que guarda memória acima do limit só consegue
perdê-la morrendo.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hungry
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        memory: 64Mi
      limits:
        memory: 64Mi
```

O endpoint `/eat` da loja aloca o número de megabytes que recebe e os guarda:

```
ana@laptop:~/shop$ kubectl apply -f hungry.yaml
pod/hungry created
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- '10.244.1.6:8080/eat?mb=30'
holding 30 MiB on hungry
```

30 MiB, mais o que a própria loja usa, cabem em 64. Mais sessenta não cabem:

```
ana@laptop:~/shop$ kubectl exec probe -- wget -qO- -T 5 '10.244.1.6:8080/eat?mb=60'
wget: error getting response
command terminated with exit code 1
ana@laptop:~/shop$ kubectl get pod hungry
NAME     READY   STATUS    RESTARTS     AGE
hungry   1/1     Running   1 (5s ago)   6s
ana@laptop:~/shop$ kubectl get pod hungry -o jsonpath="{.status.containerStatuses[0].lastState.terminated}"; echo
{"containerID":"containerd://35cede72e8e5dded14a9b57c45e511a6f227bb42fd28fe7aac248a036968ceb0","exitCode":137,"finishedAt":"2026-10-06T17:48:38Z","reason":"OOMKilled","startedAt":"2026-10-06T17:48:38Z"}
```

**A requisição não teve resposta, porque o processo que responderia foi morto no meio do caminho.** O
pod continua `Running`, com um reinício cinco segundos atrás: o kubelet subiu o container de novo, como
diz `restartPolicy: Always`. O estado do container anterior é a evidência: `OOMKilled`, código de
saída 137, que é 128 mais 9, o número do sinal SIGKILL. O OOM killer do kernel não pede com educação,
então nada no log da própria loja fala disso.

| | CPU | memória |
|---|---|---|
| acima do request | permitido, quando o nó tem sobra | permitido, quando o nó tem sobra |
| no limit | estrangulada: o container espera | o container é morto (`OOMKilled`) |
| o que você vê | respostas mais lentas | reinícios, código de saída 137 |
