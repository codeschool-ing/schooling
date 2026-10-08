---
title: O token dentro de um pod, e as roles que já vêm prontas
version: 1
---

Um pipeline rodando fora do cluster pede um token. **Um programa rodando dentro dele recebe um**: um
pod nomeia a sua ServiceAccount, e o kubelet monta um token dessa conta em todo container.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: reader
  namespace: shop
spec:
  serviceAccountName: deployer
  automountServiceAccountToken: true
  containers:
  - name: box
    image: busybox:1.37
    command: ["sleep", "3600"]
```

`automountServiceAccountToken: true` é o padrão, escrito aqui para que o próximo parágrafo tenha para
onde apontar. Um pod que nunca fala com o API server deveria colocar `false`, porque um token que
ninguém usa continua sendo um token que alguém pode roubar.

```
ana@laptop:~/shop$ kubectl apply -f reader.yaml
pod/reader created
ana@laptop:~/shop$ kubectl -n shop exec reader -- ls /var/run/secrets/kubernetes.io/serviceaccount
ca.crt
namespace
token
```

Três arquivos: o certificado da CA para conferir o servidor, o namespace em que o pod está, e o token.
Toda biblioteca de cliente procura primeiro neste diretório, e é por isso que o código dentro de um
pod alcança a API sem configuração nenhuma. O token é um JWT, três partes em base64 separadas por
pontos, e a do meio é legível:

```
ana@laptop:~/shop$ kubectl -n shop exec reader -- sh -c "cut -d. -f2 /var/run/secrets/kubernetes.io/serviceaccount/token | base64 -d 2>/dev/null | head -c 400"; echo
{"aud":["https://kubernetes.default.svc.cluster.local"],"exp":1822844376,"iat":1791308376,"iss":"https://kubernetes.default.svc.cluster.local","jti":"f2e06ac1-2404-43b4-ab2a-c7fd513106d8","kubernetes.io":{"namespace":"shop","node":{"name":"shop-worker","uid":"21ccd822-fa5c-4c4c-8653-d88148412cf5"},"pod":{"name":"reader","uid":"bfe00e13-54ec-4a1b-97c4-f41a42cc2e4c"},"serviceaccount":{"name":"deploy
```

**O token nomeia o pod e o nó exatos para os quais foi emitido.** Apague o pod e o token deixa de ser
aceito, mesmo antes de expirar, porque o API server confere se o pod que ele nomeia ainda existe. A
audiência é o próprio endereço do API server, então outro serviço que receber este token deveria
recusá-lo.

`exp` menos `iat` dá 31.536.000 segundos, um ano, o que parece o contrário dos dez minutos da seção
anterior. O kubelet pediu cerca de uma hora e troca o arquivo antes de essa hora acabar. O API server,
por padrão, estica a validade para um ano, para que clientes antigos que leem o arquivo uma vez e
nunca mais continuem funcionando. Um pod sem permissão nenhuma não perde nada com essa extensão, e
essa é a proteção de verdade.

## As roles que vêm com o cluster

Escrever toda Role à mão não é necessário. O cluster vem com ClusterRoles feitas para serem ligadas a
pessoas:

```
ana@laptop:~/shop$ kubectl get clusterroles view edit admin cluster-admin
NAME            CREATED AT
view            2026-10-06T17:39:02Z
edit            2026-10-06T17:39:02Z
admin           2026-10-06T17:39:02Z
cluster-admin   2026-10-06T17:39:02Z
ana@laptop:~/shop$ kubectl get clusterroles --no-headers | wc -l
77
```

| ClusterRole | concede |
|---|---|
| `view` | ler a maioria dos objetos, mas não Secrets |
| `edit` | ler e escrever a maioria dos objetos, inclusive Secrets, mas não roles nem bindings |
| `admin` | quase tudo num namespace, inclusive as roles e os bindings dele |
| `cluster-admin` | tudo, em todo lugar |

Uma ClusterRole é uma Role que não está presa a um namespace, então ela também pode cobrir objetos
que não têm namespace, como nós. **Até onde ela alcança depende do binding, não da role.** Ligada com
um ClusterRoleBinding, a `edit` vale em todos os namespaces. Ligada com um RoleBinding dentro de
`shop`, a mesma `edit` vale só em `shop`. Essa segunda forma é o jeito comum de dar a uma equipe o
seu próprio namespace: um RoleBinding para `admin`, e nada no escopo do cluster. Este curso não
rodou isso.

As outras 73 das 77 são, na maior parte, para os componentes do próprio cluster, com nomes começando
por `system:`. O scheduler e os controllers têm cada um exatamente as permissões de que o trabalho deles
precisa, concedidas pelo mesmo mecanismo que as do pipeline.
