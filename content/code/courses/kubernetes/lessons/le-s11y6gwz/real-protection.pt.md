---
title: Onde a senha realmente está, e quem pode lê-la
version: 1
---

O API server responde com base64. **Por baixo, o etcd guarda o objeto como o API server o escreveu**,
e por padrão o API server o escreve como ele é. Lendo os bytes guardados diretamente, com o cliente do
próprio etcd, e mantendo só as sequências de caracteres imprimíveis:

```
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/db --print-value-only | strings | grep -A1 password
;{"f:data":{".":{},"f:password":{},"f:user":{}},"f:type":{}}B
password
lab-only-7Hq2
```

Lá está ela, `lab-only-7Hq2`, em texto puro no banco. **Então quem tem uma cópia dos dados do etcd tem
todos os Secrets do cluster**: um backup esquecido num bucket, um disco de um plano de controle
desativado, um snapshot compartilhado para depurar outra coisa. É para esse caso que existe a
criptografia em repouso.

## Criptografia em repouso

O API server pode criptografar tipos escolhidos antes de escrevê-los, com chaves de um arquivo que ele
recebe. No plano de controle deste cluster o arquivo é assim, com a própria chave fora da
transcrição:

```
ana@laptop:~/shop$ docker exec shop-control-plane sed "s/secret: .*/secret: (32 random bytes, not shown)/" /etc/kubernetes/pki/encryption.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources: ["secrets"]
  providers:
  - secretbox:
      keys:
      - name: key1
        secret: (32 random bytes, not shown)
  - identity: {}
```

`secretbox` é um dos provedores, uma cifra autenticada com chave de 32 bytes, e a lista tem ordem:
**escritas novas usam o primeiro provedor**, e o `identity` no fim, que significa "sem criptografia",
deixa o API server ainda ler o que foi escrito antes. A flag aponta o API server para o arquivo:

```
ana@laptop:~/shop$ docker exec shop-control-plane grep encryption-provider /etc/kubernetes/manifests/kube-apiserver.yaml
    - --encryption-provider-config=/etc/kubernetes/pki/encryption.yaml
```

**Ligar a criptografia não mexe no que já está guardado.** A senha continua legível no etcd:

```
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/db --print-value-only | strings | grep -c lab-only
1
```

Todo Secret precisa ser escrito de novo para a regra nova valer, e substituir cada um por ele mesmo faz
exatamente isso:

```
ana@laptop:~/shop$ kubectl get secrets --all-namespaces -o json | kubectl replace -f - | tail -n 1
secret/bootstrap-token-abcdef replaced
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/db --print-value-only | head -c 26; echo
k8s:enc:secretbox:v1:key1:
ana@laptop:~/shop$ kubectl -n kube-system exec etcd-shop-control-plane -- etcdctl --endpoints=https://127.0.0.1:2379 --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key get /registry/secrets/default/db --print-value-only | strings | grep -c lab-only
0
ana@laptop:~/shop$ kubectl get secret db -o jsonpath="{.data.password}" | base64 -d; echo
lab-only-7Hq2
```

**Agora o valor guardado começa com `k8s:enc:secretbox:v1:key1:`** (qual provedor, qual chave) e a
senha não aparece em lugar nenhum dele. Pela API nada mudou: o `kubectl` continua devolvendo a senha,
porque o API server descriptografa na saída. A criptografia em repouso protege uma cópia dos dados. Não
protege contra quem pode perguntar ao API server.

Num cluster gerenciado o provedor roda o etcd, e a criptografia em repouso é uma configuração, em geral
com a chave guardada no serviço de chaves do provedor em vez de num arquivo no plano de controle.

## Quem pode ler um Secret

```
ana@laptop:~/shop$ kubectl auth can-i get secrets --as=system:serviceaccount:default:default
no
ana@laptop:~/shop$ kubectl auth can-i get secrets
yes
```

**Esta é a proteção que importa todos os dias.** Os pods do namespace `default` rodam como a service
account `default`, e ela não pode ler Secrets; o usuário da própria Ana, administradora do cluster,
pode. A lição 23 escreve essas regras. Para um valor que não deve viver no cluster de jeito nenhum, um
cofre externo como o Vault ou o gerenciador de segredos de uma nuvem o guarda, e um controlador ou um
driver CSI (lição 27) o entrega ao pod quando ele sobe.

| o que preocupa | o que protege |
|---|---|
| alguém lê o objeto pela API | RBAC: quem pode fazer `get` em Secrets (lição 23) |
| uma cópia dos dados do etcd vaza | criptografia em repouso |
| o valor vaza de dentro do pod | um arquivo em `tmpfs` em vez de uma variável, e uma imagem pequena |
| o valor está no git | nunca o ponha lá; guarde-o num cofre e entregue-o na execução |
