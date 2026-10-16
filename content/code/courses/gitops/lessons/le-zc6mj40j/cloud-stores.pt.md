---
title: Os serviços de segredos das nuvens
version: 1
---

**Cada grande nuvem roda um cofre de segredos como serviço gerenciado**, e numa empresa que roda os
clusters lá, em geral ele é o cofre: ninguém precisa operá-lo, destrancá-lo ou fazer backup, e as
permissões dele são as da própria nuvem.

| | AWS | Google Cloud | Azure |
|---|---|---|---|
| o serviço | Secrets Manager | Secret Manager | Key Vault |
| uma entrada é | um segredo, com versões e rótulos nelas | um segredo, com versões numeradas | um segredo, com versões |
| quem pode ler | uma política IAM no segredo ou no role | um vínculo IAM no segredo ou no projeto | um papel RBAC no cofre ou no segredo |
| rotação | embutida, por uma função que ele chama | um agendamento que avisa você | uma expiração e um aviso |
| a trilha de auditoria | CloudTrail | Cloud Audit Logs | logs do Azure Monitor |

Para o operador, um cofre de nuvem é mais um provedor num SecretStore, e o ExternalSecret que lê
dele não muda. Eis os três, cada um para o namespace `production` e entrando como a ServiceAccount
`bulletin`:

```yaml
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: aws
  namespace: production
spec:
  provider:
    aws:
      service: SecretsManager
      region: sa-east-1
      auth:
        jwt:
          serviceAccountRef:
            name: bulletin
---
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: gcp
  namespace: production
spec:
  provider:
    gcpsm:
      projectID: bulletin-production
      auth:
        workloadIdentity:
          clusterLocation: southamerica-east1
          clusterName: production
          serviceAccountRef:
            name: bulletin
---
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata:
  name: azure
  namespace: production
spec:
  provider:
    azurekv:
      authType: WorkloadIdentity
      vaultUrl: https://bulletin-production.vault.azure.net
      serviceAccountRef:
        name: bulletin
```

```
ana@laptop:~/setup$ kubectl apply --dry-run=server -f cloud-stores.yaml
secretstore.external-secrets.io/aws created (server dry run)
secretstore.external-secrets.io/gcp created (server dry run)
secretstore.external-secrets.io/azure created (server dry run)
```

`created (server dry run)`: o API server e o webhook do operador conferiram cada cofre e o teriam
guardado. Isso prova a forma e nada mais. **Nenhum pedido chegou à AWS, ao Google ou ao Azure**,
porque nenhum cofre foi criado e nenhum ExternalSecret pediu nada a um deles.

**Nenhum dos três tem senha**, e esse é o assunto da próxima seção: cada um entra como a
ServiceAccount, do mesmo jeito que o cofre do Vault, com uma identidade em que a nuvem aprendeu a
confiar. O jeito antigo, uma chave de acesso num Secret ao lado do cofre, ainda funciona e ainda
aparece em muitos clusters. É uma credencial de longa duração parada no cluster, e é exatamente o
que a aula anterior se propôs a eliminar.
