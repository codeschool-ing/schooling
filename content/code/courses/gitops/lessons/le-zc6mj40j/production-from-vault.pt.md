---
title: O token da produção, vindo do Vault
version: 1
---

O token da produção é um arquivo SOPS desde a aula 9. Ele passa para o Vault, onde a aula 9 já pôs
um valor em `secret/bulletin/production` e um role que deixa o `bulletin` da produção lê-lo. Dois
objetos em `apps/bulletin/production/vault.yaml` substituem o arquivo:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: vault
spec:
  provider:
    vault:
      server: http://vault:8200
      path: secret
      version: v2
      auth:
        kubernetes:
          mountPath: kubernetes
          role: bulletin-production
          serviceAccountRef:
            name: bulletin
---
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata:
  name: bulletin-token
spec:
  refreshInterval: 1m
  secretStoreRef:
    kind: SecretStore
    name: vault
  target:
    name: bulletin-token
  data:
  - secretKey: token
    remoteRef:
      key: bulletin/production
      property: token
```

O cofre entra **como a ServiceAccount `bulletin`**: o operador pede ao Kubernetes um token para ela
e o apresenta ao Vault, exatamente a troca que a aula 9 fez à mão. Então o operador não tem
credencial própria no Vault, e o que ele pode ler na produção é o que o role da produção permite. O
ExternalSecret escreve o campo `token` daquela entrada num Secret chamado `bulletin-token`, o nome
que o Deployment da base já monta, e o lê de novo a cada minuto.

O `validate.sh` encontra mais dois tipos cujos esquemas não são do Kubernetes, então eles entram na
lista de pulados:

```sh
sed -i 's/-skip HelmRelease,OCIRepository,SealedSecret /-skip HelmRelease,OCIRepository,SealedSecret,SecretStore,ExternalSecret /' ~/setup/validate.sh
```

Uma lista que só cresce é sinal de um jeito melhor: o `kubeconform` pode receber os esquemas de
recursos customizados, de um diretório ou de um catálogo público deles, e aí valida esses também.
Este curso mantém a lista curta o bastante para ser lida.

```
ana@laptop:~/fleet$ git switch --quiet -c production-vault
ana@laptop:~/fleet$ git rm --quiet apps/bulletin/production/token.sops.yaml && git add apps
ana@laptop:~/fleet$ git diff --cached --stat
 apps/bulletin/production/kustomization.yaml |  2 +-
 apps/bulletin/production/token.sops.yaml    | 22 -------------------
 apps/bulletin/production/vault.yaml         | 33 +++++++++++++++++++++++++++++
 3 files changed, 34 insertions(+), 23 deletions(-)
ana@laptop:~/fleet$ git commit --quiet -m "production: the token comes from Vault"
ana@laptop:~/fleet$ kubectl -n production get secretstore,externalsecret
NAME                                    AGE   STATUS   CAPABILITIES   READY
secretstore.external-secrets.io/vault   69s   Valid    ReadWrite      True

NAME                                                STORETYPE     STORE   REFRESH INTERVAL   STATUS         READY
externalsecret.external-secrets.io/bulletin-token   SecretStore   vault   1m                 SecretSynced   True
ana@laptop:~/fleet$ curl -s localhost:8081
bulletin 1.1
message: Welcome to the bulletin.
pod: bulletin-55bcbd4ddb-5swsk
token: sha256:951e14be7632
ana@laptop:~/fleet$ vault kv get -field=token secret/bulletin/production | sha256sum | cut -c1-12
951e14be7632
```

O cofre está `Valid`: o operador entrou no Vault como a ServiceAccount `bulletin` da produção. O
ExternalSecret está `SecretSynced`, e o pod mostra a impressão digital do valor que o Vault guarda,
os mesmos doze caracteres do hash do `vault kv get`. O arquivo SOPS saiu do repositório no mesmo
commit, então o token da produção não está no Git em lugar nenhum, cifrado ou não.
