---
title: Um container efêmero ao lado do que não tem ferramentas
version: 1
---

**Um container efêmero é um container temporário acrescentado a um pod em execução**, com uma imagem à
sua escolha. Ele compartilha a rede do pod, e com `--target` também compartilha o namespace de
processos de um container, então vê os processos dele:

```
ana@laptop:~/shop$ kubectl debug shop-774b84ff8c-q4fjf --image=busybox:1.37 --target=shop --container=dbg -- sleep 600
Targeting container "shop". If you don't see processes from this container it may be because the container runtime doesn't support this feature.
```

O pod não foi reiniciado e o container da loja não foi tocado; um container busybox foi acrescentado ao
lado, rodando `sleep` para ficar de pé e poder ser usado.

```
ana@laptop:~/shop$ kubectl exec shop-774b84ff8c-q4fjf -c dbg -- ps
PID   USER     TIME  COMMAND
    1 65532     0:00 /shop
   22 root      0:00 sleep 600
   32 root      0:00 ps
```

**O PID 1 é `/shop`, rodando como usuário 65532**: o container de depuração vê o processo da loja, que é
o que o `--target` comprou. De dentro do mesmo namespace de rede, `localhost:8080` é a própria loja:

```
ana@laptop:~/shop$ kubectl exec shop-774b84ff8c-q4fjf -c dbg -- wget -qO- localhost:8080/
shop 1.0 on shop-774b84ff8c-q4fjf
```

E `/proc/1/root` é o sistema de arquivos da própria loja, visto de fora:

```
ana@laptop:~/shop$ kubectl exec shop-774b84ff8c-q4fjf -c dbg -- ls /proc/1/root/
dev
etc
proc
product_uuid
shop
sys
var
```

`shop`, o programa, e os diretórios que o runtime monta; mais nada, como o `exec` que falhou sugeria. Ler
arquivos por `/proc/1/root` é o jeito de inspecionar o container de uma imagem scratch sem acrescentar
nada à imagem.

```
ana@laptop:~/shop$ kubectl get pod shop-774b84ff8c-q4fjf -o jsonpath='{.spec.ephemeralContainers[*].name}'; echo
dbg
```

**Um container efêmero não pode ser removido**; ele fica na spec do pod até o pod ser substituído.
Também não pode ter portas nem sondas, e os recursos dele contam no nó. Esse é o preço, e é por isso que
a alternativa da próxima seção existe.
