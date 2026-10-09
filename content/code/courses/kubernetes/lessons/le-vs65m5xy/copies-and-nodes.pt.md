---
title: Uma cópia para desmontar, e uma olhada no nó
version: 1
---

Um pod que quebra ao subir já se foi antes de alguém conseguir acoplar algo a ele. **`kubectl debug
--copy-to` cria um pod novo a partir da spec do quebrado, com mudanças**, e deixa o original em paz:

```
ana@laptop:~/shop$ kubectl get pod crashing
NAME       READY   STATUS   RESTARTS     AGE
crashing   0/1     Error    1 (8s ago)   9s
ana@laptop:~/shop$ kubectl debug crashing --copy-to=crashing-debug --container=shop --image=busybox:1.37 -- sleep 600
ana@laptop:~/shop$ kubectl exec crashing-debug -c shop -- env | grep -E "CRASH|GREETING"
GREETING=hello
CRASH=yes
ana@laptop:~/shop$ kubectl get pods
NAME                    READY   STATUS    RESTARTS     AGE
crashing                0/1     Error     1 (8s ago)   9s
crashing-debug          1/1     Running   0            0s
shop-774b84ff8c-q4fjf   1/1     Running   0            9s
```

A cópia, `crashing-debug`, manteve o ambiente do original, as variáveis e todo o resto da spec, mas o
container chamado `shop` agora roda busybox com `sleep`, então fica de pé. Dentro dela, a causa está à
vista: `CRASH=yes`. Mudar a imagem e o comando de uma cópia, e não do original, é o ponto: o pod
quebrado fica como evidência, e a cópia é apagada quando você termina.

A cópia é um pod separado e sem dono, então nenhum Service a seleciona a não ser que os rótulos dela
digam isso, e nenhum Deployment a substitui; ela não faz parte da aplicação. O `--copy-to` também pode
manter a imagem original e mudar só o comando, ou acrescentar um container de depuração com
`--share-processes`.

## O próprio nó

Alguns problemas estão no nó, não num pod: as configurações do kubelet, um disco cheio, um
certificado. **`kubectl debug node/NOME` sobe um pod nesse nó com o sistema de arquivos do nó montado
em `/host`**:

```
ana@laptop:~/shop$ kubectl debug node/shop-worker --image=busybox:1.37 -- sleep 600
Creating debugging pod node-debugger-shop-worker-k5g5t with container debugger on node shop-worker.
ana@laptop:~/shop$ kubectl exec node-debugger-shop-worker-k5g5t -- ls /host/etc/kubernetes
kubelet.conf
manifests
pki
ana@laptop:~/shop$ kubectl exec node-debugger-shop-worker-k5g5t -- sh -c 'cat /host/var/lib/kubelet/config.yaml | grep -E "^(cgroupDriver|serverTLSBootstrap|failCgroupV1):"'
cgroupDriver: systemd
failCgroupV1: false
serverTLSBootstrap: true
```

O arquivo de configuração do kubelet, lido do laptop sem SSH: `failCgroupV1: false` e
`serverTLSBootstrap: true` são duas configurações que o `cluster.yaml` acrescentou na aula 1, e aqui estão elas no nó. Esse
pod roda com acesso aos arquivos do nó, então é tão poderoso quanto um login na máquina, e o RBAC
deveria tratar o direito de criá-lo desse jeito.

| ferramenta | muda o pod em execução? | precisa na imagem | certa para |
|---|---|---|---|
| `kubectl exec` | não | um shell e ferramentas | imagens que os têm |
| `kubectl port-forward` | não | nada | chamar um pod a partir do laptop |
| `kubectl debug --target` | acrescenta um container efêmero | nada | inspecionar um pod rodando sem ferramentas |
| `kubectl debug --copy-to` | não, faz uma cópia | nada | pods que quebram ao subir |
| `kubectl debug node/…` | não, acrescenta um pod no nó | nada | os arquivos e configurações do próprio nó |

O que foi subido para depurar é apagado depois. Um pod de depuração esquecido com o sistema de arquivos
de um nó montado é exatamente o tipo de coisa que um atacante espera encontrar.
