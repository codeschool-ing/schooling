---
title: O que um container pode fazer por padrão, e como tirar isso dele
version: 1
---

Comece por um pod em que ninguém pensou:

```
ana@laptop:~/shop$ kubectl run plain --image=busybox:1.37 --restart=Never --command -- sleep 3600
pod/plain created
ana@laptop:~/shop$ kubectl exec plain -- id
uid=0(root) gid=0(root) groups=0(root),10(wheel)
ana@laptop:~/shop$ kubectl exec plain -- sh -c "grep Cap /proc/1/status"
CapInh:	0000000000000000
CapPrm:	00000000a80425fb
CapEff:	00000000a80425fb
CapBnd:	00000000a80425fb
CapAmb:	0000000000000000
ana@laptop:~/shop$ kubectl exec plain -- sh -c "touch /etc/written-by-the-pod && echo written"
written
```

**Root, com catorze capabilities, e um sistema de arquivos gravável.** O conjunto de capabilities é
uma máscara de bits: `a80425fb` é a lista padrão do runtime de containers, que inclui mudar o dono de
arquivos, ocupar portas baixas e mandar pacotes de rede crus. Nenhuma delas faz um container escapar
sozinha. Cada uma é algo que um atacante que entre no processo pode usar, e a loja não precisa de
nenhuma.

Root dentro de um container não é root no nó, porque os namespaces do kernel e as capabilities que
faltam ficam no meio. Mas está a um bug de kernel de importar, e tirá-lo custa quase nada.

## Levantando os muros

O `securityContext` define isso por pod e por container:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hardened
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 10001
    runAsGroup: 10001
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop: ["ALL"]
    volumeMounts:
    - name: tmp
      mountPath: /tmp
  volumes:
  - name: tmp
    emptyDir: {}
```

| campo | o que faz |
|---|---|
| `runAsUser`, `runAsGroup` | os ids de usuário e de grupo do processo |
| `runAsNonRoot: true` | recusa subir o container se ele fosse rodar como usuário 0 |
| `seccompProfile: RuntimeDefault` | a lista de chamadas de sistema permitidas do runtime; as outras são recusadas |
| `allowPrivilegeEscalation: false` | nenhum binário set-uid pode dar ao processo mais do que ele começou tendo |
| `readOnlyRootFilesystem: true` | os arquivos da imagem não podem ser mudados |
| `capabilities.drop: ["ALL"]` | nenhuma capability |

O `emptyDir` montado em `/tmp` dá ao programa um lugar gravável, porque muitos programas precisam
escrever em algum lugar, e um diretório de rascunho que some com o pod é o lugar seguro para isso.

```
ana@laptop:~/shop$ kubectl apply -f hardened.yaml
pod/hardened created
ana@laptop:~/shop$ kubectl exec hardened -- id
uid=10001 gid=10001 groups=10001
ana@laptop:~/shop$ kubectl exec hardened -- sh -c "grep Cap /proc/1/status"
CapInh:	0000000000000000
CapPrm:	0000000000000000
CapEff:	0000000000000000
CapBnd:	0000000000000000
CapAmb:	0000000000000000
ana@laptop:~/shop$ kubectl exec hardened -- sh -c "touch /etc/written-by-the-pod"
touch: /etc/written-by-the-pod: Read-only file system
command terminated with exit code 1
ana@laptop:~/shop$ kubectl exec hardened -- sh -c "touch /tmp/scratch && echo /tmp is writable"
/tmp is writable
```

Usuário 10001, todos os conjuntos de capabilities vazios, `/etc` somente leitura e `/tmp` gravável. A
mesma imagem busybox, fazendo o mesmo `sleep`, sem nada sobrando para ser mal usado.

## Uma imagem que insiste em root

`runAsNonRoot` sem um `runAsUser` confia que a imagem nomeie um usuário que não seja root. Quando ela
não nomeia, o kubelet se recusa a subir o container:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: web
spec:
  securityContext:
    runAsNonRoot: true
  containers:
  - name: nginx
    image: nginx:1.29
```

```
ana@laptop:~/shop$ kubectl apply -f root-image.yaml
pod/web created
ana@laptop:~/shop$ kubectl get pod web
NAME   READY   STATUS                       RESTARTS   AGE
web    0/1     CreateContainerConfigError   0          9s
ana@laptop:~/shop$ kubectl get pod web -o jsonpath="{.status.containerStatuses[0].state.waiting.message}"; echo
container has runAsNonRoot and image will run as root (pod: "web_default(5ba43b42-957c-4319-8337-f87a9abf8510)", container: nginx)
```

**`CreateContainerConfigError`, e o motivo na mensagem de espera.** A imagem oficial do nginx sobe
como root, então isto é um defeito da combinação, não de uma das metades. As correções são uma imagem
feita para rodar como outro usuário (o nginx publica uma variante sem privilégios), ou um `runAsUser`
mais os diretórios em que o programa escreve. A imagem da loja que este curso usa é feita para rodar
como usuário 65532, então todo pod da loja nele poderia ter levado `runAsNonRoot: true`.
