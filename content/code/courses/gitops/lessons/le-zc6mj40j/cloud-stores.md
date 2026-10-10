---
title: The clouds' secret services
version: 1
---

**Each big cloud runs a secret store as a managed service**, and in a company that runs its clusters
there, it is usually the store: nobody has to run it, unseal it or back it up, and its permissions
are the cloud's own.

| | AWS | Google Cloud | Azure |
|---|---|---|---|
| the service | Secrets Manager | Secret Manager | Key Vault |
| an entry is | a secret, with versions and labels on them | a secret, with numbered versions | a secret, with versions |
| who may read | an IAM policy on the secret or the role | an IAM binding on the secret or the project | an RBAC role on the vault or the secret |
| rotation | built in, by a function it calls | a schedule that notifies you | an expiry and a notification |
| the audit trail | CloudTrail | Cloud Audit Logs | Azure Monitor logs |

For the operator, a cloud store is one more provider in a SecretStore, and the ExternalSecret that
reads from it does not change. Here are the three, each for the `production` namespace and logging
in as the ServiceAccount `bulletin`:

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

`created (server dry run)`: the API server and the operator's webhook checked each store and would
have stored it. That proves the shape and nothing more. **No request reached AWS, Google or Azure**,
because no store was created and no ExternalSecret asked one for anything.

**None of the three has a password in it**, and that is the point of the next section: each one logs
in as the ServiceAccount, the same way the Vault store did, with an identity the cloud learned to
trust. The older way, an access key in a Secret beside the store, still works and is still found in
many clusters. It is a long-lived credential sitting in the cluster, and it is exactly what the
previous lesson set out to remove.
