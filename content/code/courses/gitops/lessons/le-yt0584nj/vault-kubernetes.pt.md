---
title: O Vault reconhece o cluster
version: 1
---

**Um programa que pede um segredo ao Vault precisa provar quem é, e um token para provar seria mais
um segredo a entregar.** O Kubernetes já dá uma identidade a cada pod: a ServiceAccount dele, e um
token assinado que diz isso, montado no pod. O **método de autenticação Kubernetes** do Vault aceita
esse token como login. Ele pergunta ao API server do cluster se o token é genuíno e a qual
ServiceAccount pertence, e, se um **role** no Vault liga essa ServiceAccount a uma política, devolve
um token do Vault com essa política e vida curta.

São três coisas, e as duas primeiras moram no repositório:

- uma ServiceAccount `vault-auth` que o Vault usa para perguntar ao API server sobre tokens, que é o
  que o role `system:auth-delegator` permite;
- uma ServiceAccount `bulletin` na produção, a identidade que vai pedir o token da produção;
- no Vault, o método, uma política e um role.

Este é o `infrastructure/vault-auth/vault-auth.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: vault-auth
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: vault-auth
  namespace: vault-auth
---
apiVersion: v1
kind: Secret
metadata:
  name: vault-auth
  namespace: vault-auth
  annotations:
    kubernetes.io/service-account.name: vault-auth
type: kubernetes.io/service-account-token
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: vault-auth-tokenreview
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: system:auth-delegator
subjects:
- kind: ServiceAccount
  name: vault-auth
  namespace: vault-auth
```

O Secret do tipo `service-account-token` pede ao Kubernetes um token de longa duração para o
`vault-auth`, que o Vault guarda para fazer as conferências. E este é o
`apps/bulletin/production/serviceaccount.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bulletin
```

O Flux aplica o `infrastructure/vault-auth` por meio do `clusters/lab/vault-auth.yaml`, que é o
`sealed-secrets.yaml` com `vault-auth` no lugar de `sealed-secrets`, e o kustomization da produção
lista o `serviceaccount.yaml`. Um pull request leva tudo:

```
ana@laptop:~/fleet$ git switch --quiet -c vault-auth
ana@laptop:~/fleet$ git add infrastructure apps clusters && git status --short
M  apps/bulletin/production/kustomization.yaml
A  apps/bulletin/production/serviceaccount.yaml
A  clusters/lab/vault-auth.yaml
A  infrastructure/vault-auth/vault-auth.yaml
ana@laptop:~/fleet$ git commit --quiet -m "vault: an identity to check tokens with, and one for production"
ana@laptop:~/fleet$ kubectl -n vault-auth get serviceaccount,secret
NAME                        AGE
serviceaccount/default      58s
serviceaccount/vault-auth   58s

NAME                TYPE                                  DATA   AGE
secret/vault-auth   kubernetes.io/service-account-token   3      58s
ana@laptop:~/fleet$ kubectl -n production get serviceaccount bulletin
NAME       AGE
bulletin   0s
```

O `vault-auth` e o Secret dele existem, o Secret guardando o token que o Kubernetes fez para ele, e
a produção tem a ServiceAccount `bulletin`.

## O lado do Vault

O método recebe onde está o API server, como confiar no certificado dele e com qual token perguntar.
O endereço é `gitops-control-plane:6443`, o nome do control plane na rede `kind` que o Vault
compartilha:

```
ana@laptop:~$ vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
ana@laptop:~$ kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ~/vault/cluster-ca.crt
ana@laptop:~$ vault write auth/kubernetes/config kubernetes_host=https://gitops-control-plane:6443 kubernetes_ca_cert=@$HOME/vault/cluster-ca.crt token_reviewer_jwt=$(kubectl -n vault-auth get secret vault-auth -o jsonpath='{.data.token}' | base64 -d)
Success! Data written to: auth/kubernetes/config
```

Uma **política** diz quais caminhos um token pode tocar e como. Esta pode ler o token da produção e
mais nada. Um **role** diz quem recebe a política: a ServiceAccount `bulletin`, no namespace
`production`, por dez minutos de cada vez. Este é o `~/vault/bulletin-production.hcl`:

```hcl
path "secret/data/bulletin/production" {
  capabilities = ["read"]
}
```

O `data/` no caminho é como a versão 2 do motor chave-valor nomeia o valor atual de uma entrada: o
que a linha de comando chama de `secret/bulletin/production` é `secret/data/bulletin/production`
para uma política.

```
ana@laptop:~$ vault policy write bulletin-production ~/vault/bulletin-production.hcl
Success! Uploaded policy: bulletin-production
ana@laptop:~$ vault write auth/kubernetes/role/bulletin-production bound_service_account_names=bulletin bound_service_account_namespaces=production policies=bulletin-production ttl=10m
WARNING! The following warnings were returned from Vault:

  * Role bulletin-production does not have an audience configured. While
  audiences are not required, consider specifying one if your use case would
  benefit from additional JWT claim verification.
```

## Entrando como um pod entraria

Um pod leria o token do arquivo que o Kubernetes monta; o `kubectl create token` faz o mesmo tipo de
token de fora, o que mostra a troca sem escrever um programa:

```
ana@laptop:~$ POD_TOKEN=$(kubectl -n production create token bulletin)
ana@laptop:~$ vault write -format=json auth/kubernetes/login role=bulletin-production jwt=$POD_TOKEN | jq '.auth | {policies, lease_duration, metadata}'
{
  "policies": [
    "bulletin-production",
    "default"
  ],
  "lease_duration": 600,
  "metadata": {
    "role": "bulletin-production",
    "service_account_name": "bulletin",
    "service_account_namespace": "production",
    "service_account_secret_name": "",
    "service_account_uid": "bd5612af-f883-40bc-972f-92ea7bdbcb4b"
  }
}
```

Um token do Vault com a política `bulletin-production` (e a `default`, que todo token recebe),
vivendo 600 segundos, e metadados nomeando exatamente qual ServiceAccount em qual namespace entrou:
a linha que a aula 12 vai achar no log de auditoria do Vault. O aviso sobre audiência é o Vault
sugerindo mais uma conferência no token, que um role para um cluster de verdade deve definir.

```
ana@laptop:~$ BULLETIN=$(vault write -field=token auth/kubernetes/login role=bulletin-production jwt=$POD_TOKEN)
ana@laptop:~$ VAULT_TOKEN=$BULLETIN vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12
94054ba47262
ana@laptop:~$ VAULT_TOKEN=$BULLETIN vault kv get secret/bulletin/staging
Error reading secret/data/bulletin/staging: Error making API request.

URL: GET http://127.0.0.1:8200/v1/secret/data/bulletin/staging
Code: 403. Errors:

* 1 error occurred:
	* permission denied
```

O token lê o valor da produção, a mesma impressão digital de antes, e é recusado no do staging com
`403 permission denied`: a política nomeia um caminho, e é só isso que ela abre.

**Nada nesta troca é um segredo que alguém precisou entregar.** O token da ServiceAccount é emitido
pelo Kubernetes e expira em uma hora; o token do Vault vive dez minutos; a política é a única coisa
que diz o que ele pode ler, e é um caminho só. A aula 10 põe no cluster um operador que faz este
login periodicamente e mantém um Secret atualizado a partir do Vault.
