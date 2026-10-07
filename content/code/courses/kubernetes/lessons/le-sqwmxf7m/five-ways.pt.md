---
title: Cinco pods, cinco jeitos de falhar
version: 1
---

Um arquivo, cinco pods, cada um errado do seu jeito:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: typo
spec:
  containers:
  - name: shop
    image: shop:1.O
---
apiVersion: v1
kind: Pod
metadata:
  name: crashing
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: CRASH
      value: "yes"
---
apiVersion: v1
kind: Pod
metadata:
  name: greedy
spec:
  containers:
  - name: shop
    image: shop:1.0
    resources:
      requests:
        cpu: "64"
---
apiVersion: v1
kind: Pod
metadata:
  name: unconfigured
spec:
  containers:
  - name: shop
    image: shop:1.0
    env:
    - name: GREETING
      valueFrom:
        configMapKeyRef:
          name: shop-settings
          key: greeting
---
apiVersion: v1
kind: Pod
metadata:
  name: never-ready
spec:
  containers:
  - name: shop
    image: shop:1.0
    readinessProbe:
      httpGet:
        path: /ready
        port: 9090
      periodSeconds: 3
```

```
ana@laptop:~/shop$ kubectl apply -f broken.yaml
pod/typo created
pod/crashing created
pod/greedy created
pod/unconfigured created
pod/never-ready created
ana@laptop:~/shop$ kubectl get pods
NAME           READY   STATUS                       RESTARTS      AGE
crashing       0/1     Error                        3 (45s ago)   60s
greedy         0/1     Pending                      0             60s
never-ready    0/1     Running                      0             60s
typo           0/1     ErrImagePull                 0             60s
unconfigured   0/1     CreateContainerConfigError   0             60s
```

**`kubectl get pods` é a primeira olhada, e a coluna STATUS já separa os problemas em famílias.** Cada
nome diz qual parte da vida do pod falhou:

| status | o pod chegou até | olhe em seguida |
|---|---|---|
| `Pending` | ser guardado; nenhum nó o aceitou | os eventos do scheduler |
| `ErrImagePull`, `ImagePullBackOff` | um nó, que não conseguiu buscar a imagem | os eventos do pod |
| `CreateContainerConfigError` | um nó e uma imagem; o container não pôde ser configurado | a mensagem de espera |
| `Error`, `CrashLoopBackOff` | um processo rodando, que saiu | os logs do container |
| `Running` mas `0/1` pronto | um processo rodando que a sonda de readiness rejeita | os eventos da sonda |

## A imagem que não existe

`shop:1.O`, com a letra O maiúscula onde vai um zero. O nó tentou buscá-la no Docker Hub, o registry
que um nome de imagem sem host quer dizer:

```
ana@laptop:~/shop$ kubectl describe pod typo | sed -n '/^Events/,$p'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  60s                default-scheduler  Successfully assigned default/typo to shop-worker2
  Normal   Pulling    20s (x3 over 59s)  kubelet            spec.containers{shop}: Pulling image "shop:1.O"
  Warning  Failed     20s (x3 over 59s)  kubelet            spec.containers{shop}: Failed to pull image "shop:1.O": failed to pull and unpack image "docker.io/library/shop:1.O": failed to resolve reference "docker.io/library/shop:1.O": failed to do request: Head "https://registry-1.docker.io/v2/library/shop/manifests/1.O": tls: failed to verify certificate: x509: certificate signed by unknown authority
  Warning  Failed     20s (x3 over 59s)  kubelet            spec.containers{shop}: Error: ErrImagePull
  Normal   BackOff    7s (x3 over 59s)   kubelet            spec.containers{shop}: Back-off pulling image "shop:1.O"
  Warning  Failed     7s (x3 over 59s)   kubelet            spec.containers{shop}: Error: ImagePullBackOff
```

**Os eventos contam a história inteira em ordem**: alocado, baixando, falhou, espera. A mensagem de
falha cita a referência que ele tentou, `docker.io/library/shop:1.O`. Os nós da máquina em que o curso
foi gravado não alcançam registry nenhum, então o pedido falha antes de o registry conseguir responder.
Nos seus nós, que alcançam o Docker Hub, o fim da linha diz em vez disso que essa imagem não existe. De qualquer jeito a correção é a mesma, e a
referência na mensagem é onde o erro de digitação aparece.

`ImagePullBackOff` quer dizer que o kubelet está esperando cada vez mais entre as tentativas, até cinco
minutos. Ele continua tentando, porque uma imagem que falta às vezes só não foi enviada ainda.

## O processo que sai

```
ana@laptop:~/shop$ kubectl logs crashing
2026-10-06T21:28:47Z shop 1.0: CRASH is set, exiting with status 1
ana@laptop:~/shop$ kubectl get pod crashing -o jsonpath="{.status.containerStatuses[0].lastState.terminated.exitCode} {.status.containerStatuses[0].restartCount}"; echo
1 3
```

**`kubectl logs` mostra o que o processo escreveu antes de morrer**, e a loja diz o motivo ela mesma.
Código de saída 1 e três reinícios dentro do minuto: o kubelet o reinicia com pausas crescentes, que é
o que `CrashLoopBackOff` quer dizer. Quando o container atual acabou de reiniciar e ainda não escreveu
nada, `kubectl logs --previous` lê o anterior.
