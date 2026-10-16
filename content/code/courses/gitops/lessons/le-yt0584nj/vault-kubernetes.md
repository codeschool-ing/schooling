---
title: Vault recognises the cluster
version: 1
---

**A program asking Vault for a secret has to prove who it is, and a token to prove it with would be
one more secret to deliver.** Kubernetes already gives every pod an identity: its ServiceAccount,
and a signed token that says so, mounted into the pod. Vault's **Kubernetes auth method** accepts
that token as a login. It asks the cluster's API server whether the token is genuine and which
ServiceAccount it belongs to, and if a **role** in Vault maps that ServiceAccount to a policy, it
hands back a Vault token with that policy and a short life.

Three things are needed, and the first two live in the repository:

- a ServiceAccount `vault-auth` that Vault uses to ask the API server about tokens, which is what the
  `system:auth-delegator` role allows;
- a ServiceAccount `bulletin` in production, the identity that will ask for production's token;
- in Vault, the method, a policy and a role.

This is `infrastructure/vault-auth/vault-auth.yaml`:

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

The Secret of type `service-account-token` asks Kubernetes for a long-lived token for `vault-auth`,
which Vault keeps to make its checks. And this is `apps/bulletin/production/serviceaccount.yaml`:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: bulletin
```

Flux applies `infrastructure/vault-auth` through `clusters/lab/vault-auth.yaml`, which is
`sealed-secrets.yaml` with `vault-auth` in place of `sealed-secrets`, and production's kustomization
lists `serviceaccount.yaml`. One pull request carries all of it:

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

`vault-auth` and its Secret exist, the Secret holding the token Kubernetes made for it, and
production has its `bulletin` ServiceAccount.

## The Vault side

The method is told where the API server is, how to trust its certificate and which token to ask
with. The address is `gitops-control-plane:6443`, the control plane's name on the `kind` network
that Vault shares:

```
ana@laptop:~$ vault auth enable kubernetes
Success! Enabled kubernetes auth method at: kubernetes/
ana@laptop:~$ kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ~/vault/cluster-ca.crt
ana@laptop:~$ vault write auth/kubernetes/config kubernetes_host=https://gitops-control-plane:6443 kubernetes_ca_cert=@$HOME/vault/cluster-ca.crt token_reviewer_jwt=$(kubectl -n vault-auth get secret vault-auth -o jsonpath='{.data.token}' | base64 -d)
Success! Data written to: auth/kubernetes/config
```

A **policy** says which paths a token may touch and how. This one may read production's token and
nothing else. A **role** says who gets the policy: the ServiceAccount `bulletin`, in the namespace
`production`, for ten minutes at a time. This is `~/vault/bulletin-production.hcl`:

```hcl
path "secret/data/bulletin/production" {
  capabilities = ["read"]
}
```

The `data/` in the path is how version 2 of the key-value engine names the current value of an
entry: what the command line calls `secret/bulletin/production` is `secret/data/bulletin/production`
to a policy.

```
ana@laptop:~$ vault policy write bulletin-production ~/vault/bulletin-production.hcl
Success! Uploaded policy: bulletin-production
ana@laptop:~$ vault write auth/kubernetes/role/bulletin-production bound_service_account_names=bulletin bound_service_account_namespaces=production policies=bulletin-production ttl=10m
WARNING! The following warnings were returned from Vault:

  * Role bulletin-production does not have an audience configured. While
  audiences are not required, consider specifying one if your use case would
  benefit from additional JWT claim verification.
```

## Logging in as a pod would

A pod would read its token from the file Kubernetes mounts; `kubectl create token` makes the same
kind of token from outside, which shows the exchange without writing a program:

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

A Vault token with the policy `bulletin-production` (and `default`, which every token gets), living
600 seconds, and metadata naming exactly which ServiceAccount in which namespace logged in: the line
lesson 12 will find in Vault's audit log. The warning about an audience is Vault suggesting one more
check on the token, which a role for a real cluster should set.

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

The token reads production's value, the same fingerprint as before, and is refused staging's with
`403 permission denied`: the policy names one path, and that is all it opens.

**Nothing in this exchange is a secret somebody had to deliver.** The ServiceAccount token is minted
by Kubernetes and expires within the hour; the Vault token lives ten minutes; the policy is the only
thing that says what it can read, and it is one path. Lesson 10 puts an operator in the cluster that
does this login on a schedule and keeps a Secret up to date from Vault.
