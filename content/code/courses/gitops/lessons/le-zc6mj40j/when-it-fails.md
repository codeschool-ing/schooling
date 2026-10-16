---
title: When it fails
version: 1
---

**When the operator cannot read the store, the Secret keeps its last value.** It does not delete it
and it does not empty it, so the pods carry on with what they had; what stops is the next change.
That is the right default, and it means a failure here is quiet unless somebody looks.

## A path that is not the one allowed

The ExternalSecret pointed at `bulletin/prod` instead of `bulletin/production`, a typo of the kind a
pull request lets through. Patched straight into the cluster as an experiment; Flux puts the
repository's version back on its next pass:

```
ana@laptop:~/fleet$ kubectl -n production patch externalsecret bulletin-token --type merge -p '{"spec":{"data":[{"secretKey":"token","remoteRef":{"key":"bulletin/prod","property":"token"}}]}}'
externalsecret.external-secrets.io/bulletin-token patched
ana@laptop:~/fleet$ kubectl -n production get externalsecret bulletin-token
NAME             STORETYPE     STORE   REFRESH INTERVAL   STATUS              READY
bulletin-token   SecretStore   vault   1m                 SecretSyncedError   False
ana@laptop:~/fleet$ kubectl -n production get externalsecret bulletin-token -o jsonpath='{.status.conditions[0].message}'; echo
could not get secret data from provider
ana@laptop:~/fleet$ kubectl -n external-secrets logs deployment/external-secrets --since=2m | grep bulletin-token | tail -n 1 | jq -c "{msg, error}"
{"msg":"Reconciler error","error":"error processing spec.data[0] (key: bulletin/prod), err: cannot read secret data from Vault: Error making API request.\n\nURL: GET http://vault:8200/v1/secret/data/bulletin/prod\nCode: 403. Errors:\n\n* 1 error occurred:\n\t* permission denied\n\n"}
ana@laptop:~/fleet$ curl -s localhost:8081 | grep token
token: sha256:b92fc7e037ca
```

`SecretSyncedError`, and the condition's message only says the provider would not give the data.
**The reason is in the operator's log**: Vault answered `403 permission denied` for
`secret/data/bulletin/prod`, because the policy of lesson 9 names `bulletin/production` and nothing
else. The pod still prints `b92fc7e037ca`, the last value the Secret had.

## A store that is sealed

Vault restarts, and nobody unseals it:

```
ana@laptop:~/fleet$ docker restart vault
vault
ana@laptop:~/fleet$ kubectl -n production get secretstore,externalsecret
NAME                                    AGE     STATUS   CAPABILITIES   READY
secretstore.external-secrets.io/vault   3m27s   Valid    ReadWrite      True

NAME                                                STORETYPE     STORE   REFRESH INTERVAL   STATUS              READY
externalsecret.external-secrets.io/bulletin-token   SecretStore   vault   1m                 SecretSyncedError   False
ana@laptop:~/fleet$ kubectl -n external-secrets logs deployment/external-secrets --since=1m | grep bulletin-token | tail -n 1 | jq -c "{msg, error}"
{"msg":"Reconciler error","error":"error processing spec.data[0] (key: bulletin/production), err: unable to log in to auth method: unable to log in with Kubernetes auth: Error making API request.\n\nURL: PUT http://vault:8200/v1/auth/kubernetes/login\nCode: 503. Errors:\n\n* Vault is sealed"}
ana@laptop:~/fleet$ curl -s localhost:8081 | grep token
token: sha256:b92fc7e037ca
ana@laptop:~/fleet$ vault operator unseal $(jq -r '.unseal_keys_b64[0]' ~/vault-init.json) | grep '^Sealed'
Sealed                  false
```

The SecretStore still says `Valid`: it was checked when it was created and is checked again on its
own schedule, so a store that went down a minute ago can read as healthy. The ExternalSecret is the
one in error, and the operator's log has the reason: the login to Vault came back `503` and `Vault
is sealed`. The pod kept its value through all of it, and unsealing put everything back.

| what you see | where | what it means |
|---|---|---|
| `SecretSyncedError`; `403` and `permission denied` in the log | the ExternalSecret's status, the operator's log | the store answered and refused that path; with Vault's policy naming one path, a typo reads as a refusal |
| `SecretSyncedError`; `unable to log in` and `Vault is sealed` in the log | the ExternalSecret's status, the operator's log | the operator could not log in, and the rest of the line says why: here, a sealed Vault |

**Watch the status, not the pods.** An ExternalSecret that stopped syncing a week ago looks exactly
like one that is fine until the day the value has to change. Flux reports the health of the objects
it applied, so a Kustomization with `wait: true` turns an ExternalSecret that stays un-`Ready` into
a failed reconciliation once its timeout passes, and lesson 12 turns failures like that into
notifications.
