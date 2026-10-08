---
title: Sem shell, e um túnel no lugar
version: 1
---

Esta aula precisa de duas coisas para depurar depois do `./up.sh`: a loja, cuja imagem não tem shell, e
um pod chamado `crashing` que sai no instante em que começa, porque `CRASH` está definido.

`debug-apps.yaml`:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata: {name: shop}
spec:
  replicas: 1
  selector: {matchLabels: {app: shop}}
  template:
    metadata: {labels: {app: shop}}
    spec: {containers: [{name: shop, image: "shop:1.0"}]}
---
apiVersion: v1
kind: Pod
metadata: {name: crashing}
spec:
  containers: [{name: shop, image: "shop:1.0", env: [{name: CRASH, value: "yes"}, {name: GREETING, value: "hello"}]}]
```

```sh
kubectl apply -f debug-apps.yaml
```

O primeiro reflexo quando um pod se comporta mal é um shell dentro dele:

```
ana@laptop:~/shop$ kubectl exec shop-774b84ff8c-q4fjf -- sh -c 'echo hello'
error: Internal error occurred: Internal error occurred: error executing command in container: failed to exec in container: failed to start exec "4760325991634de719b65a77ab21417d11cd2f6944115e6fb7ded230739db94f": OCI runtime exec failed: exec failed: unable to start container process: exec: "sh": executable file not found in $PATH
```

**`"sh": executable file not found`.** A imagem da loja é feita a partir de `scratch`, com um arquivo
dentro, o programa. Não há shell, nem `ls`, nem `curl`; nada que um atacante que entrasse pudesse usar,
e nada que você possa usar também. Imagens sobre bases distroless ou scratch são comuns em produção
exatamente por isso, então o `kubectl exec` é uma ferramenta que muitas vezes não está lá quando
importa.

## `port-forward`: o pod no seu laptop

Para chamar a loja como se fosse local, sem Service, sem Ingress e sem mudar nada no cluster, o
`kubectl port-forward` abre um túnel de uma porta do laptop para uma porta de um pod, passando pelo API
server:

```
ana@laptop:~/shop$ kubectl port-forward deployment/shop 9090:8080 &
Forwarding from 127.0.0.1:9090 -> 8080
ana@laptop:~/shop$ curl -s localhost:9090/
shop 1.0 on shop-774b84ff8c-q4fjf
ana@laptop:~/shop$ curl -s localhost:9090/config
GREETING=
/etc/shop/greeting: (open /etc/shop/greeting: no such file or directory)
```

O nome do Deployment resolve para um dos pods dele, e o túnel vai só para esse pod, não pelo Service,
então este também é o jeito de falar com uma cópia em particular. O endpoint `/config` da loja mostra o
que o processo de fato recebeu: uma saudação vazia e nenhum arquivo de configuração montado, o tipo de
fato que encerra uma discussão rápido.

**O túnel só precisa da permissão `pods/portforward`**, no estilo de sub-recurso da lição 23, e nada é
exposto além do laptop que o abriu. Ele dura enquanto o comando roda. Isso o torna o jeito certo de
alcançar uma página de administração ou um banco dentro do cluster por alguns minutos, e o jeito
errado de servir qualquer coisa a qualquer outra pessoa.
