---
title: O kubelet protege o seu nó
version: 1
---

Todo kubelet vigia o seu nó para ver se algo está acabando, e informa o que vê como condições:

```
ana@laptop:~/shop$ kubectl describe node shop-worker | grep -A 7 "^Conditions"
Conditions:
  Type             Status  LastHeartbeatTime                 LastTransitionTime                Reason                       Message
  ----             ------  -----------------                 ------------------                ------                       -------
  MemoryPressure   False   Tue, 06 Oct 2026 15:06:27 -0300   Tue, 06 Oct 2026 15:06:12 -0300   KubeletHasSufficientMemory   kubelet has sufficient memory available
  DiskPressure     False   Tue, 06 Oct 2026 15:06:27 -0300   Tue, 06 Oct 2026 15:06:12 -0300   KubeletHasNoDiskPressure     kubelet has no disk pressure
  PIDPressure      False   Tue, 06 Oct 2026 15:06:27 -0300   Tue, 06 Oct 2026 15:06:12 -0300   KubeletHasSufficientPID      kubelet has sufficient PID available
  Ready            True    Tue, 06 Oct 2026 15:06:27 -0300   Tue, 06 Oct 2026 15:06:27 -0300   KubeletReady                 kubelet is posting ready status
Addresses:
```

**`MemoryPressure`, `DiskPressure` e `PIDPressure` são as três sobre as quais um kubelet age.** Quando
uma vira `True`, o kubelet despeja pods até o nó ficar seguro de novo, começando pelos pods que mais
usam acima do que pediram; essa é a ordem que as classes de qualidade de serviço da lição 19
descreveram. Um nó sob pressão também ganha um taint, para que nada novo seja alocado ali enquanto
isso.

Encher um nó inteiro para ver isso levaria minutos e atrapalharia todas as outras capturas. Um único
pod consegue mostrar o mesmo mecanismo contra o próprio limite, no recurso que as pessoas esquecem: o
disco em que um container escreve fora de qualquer volume.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: scribbler
spec:
  restartPolicy: Never
  containers:
  - name: box
    image: busybox:1.37
    command: ["sh", "-c", "dd if=/dev/zero of=/tmp/fill bs=1M count=80; sleep 3600"]
    resources:
      limits:
        ephemeral-storage: 50Mi
```

`ephemeral-storage` é o terceiro recurso que um container pode pedir e limitar, depois de CPU e
memória. Ele cobre a camada gravável do container, os logs e qualquer `emptyDir`. Este pod escreve 80
MiB em `/tmp` contra um limite de 50.

```
ana@laptop:~/shop$ kubectl apply -f scribbler.yaml
pod/scribbler created
ana@laptop:~/shop$ kubectl get pod scribbler
NAME        READY   STATUS   RESTARTS   AGE
scribbler   0/1     Error    0          30s
ana@laptop:~/shop$ kubectl get pod scribbler -o jsonpath="{.status.reason}: {.status.message}"; echo
Evicted: Pod ephemeral local storage usage exceeds the total limit of containers 50Mi. 
```

**`Evicted`, com o motivo por extenso.** O kubelet mede o uso de disco a cada poucos segundos, viu o
pod acima do limite e o removeu. Diferente de um limit de memória, que o kernel aplica no instante em
que é ultrapassado, isto é uma verificação do kubelet, e é por isso que o pod conseguiu escrever além
do limite primeiro. O pod não é reiniciado no lugar: um pod despejado está encerrado, e só um
controller como um Deployment o substituiria, com um pod novo.

| o que acaba | quem age | o que o pod vê |
|---|---|---|
| o limit de memória de um container | o kernel | `OOMKilled`, reiniciado no lugar (lição 19) |
| o limit de ephemeral-storage de um container | o kubelet | `Evicted`, pod encerrado |
| a memória ou o disco do nó | o kubelet | `Evicted`, pods acima dos requests primeiro, depois menor prioridade |
