---
title: The client secret, and why it is the wrong default
version: 1
---

The shop's order API runs in the AKS cluster of lesson 11, and from this lesson on it writes a
receipt for every order into a Blob Storage container. To do that it has to sign in to Microsoft
Entra ID, the directory behind every Azure identity, and get a token for the storage account. The
answer most teams reach for first is quick. Register an application in Entra ID and give it a
client secret. Put the application's id, the tenant's id and the secret in a Kubernetes Secret, and
hand the Secret to the pod as three environment variables. The Azure SDK finds them and signs in.
**It works on the first afternoon, and everything wrong with it happens on the days after.** This
section is about those days, seen from the side of whoever has to keep the tenant safe.

## A Secret is an envelope, not a safe

The Secret that quick answer writes looks like this. The client id and the tenant id are the
placeholders Microsoft's documentation uses, and the secret is three words that Entra ID would
refuse:

```yaml
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: orders-entra
  namespace: shop
data:
  AZURE_CLIENT_ID: MTExMTIyMjItYmJiYi0zMzMzLWNjY2MtNDQ0NGRkZGQ1NTU1
  AZURE_TENANT_ID: YWFhYWJiYmItMDAwMC1jY2NjLTExMTEtZGRkZDIyMjJlZWVl
  AZURE_CLIENT_SECRET: bm90LWEtcmVhbC1zZWNyZXQ=
```

The strings under `data` look scrambled, and that is the whole of their protection:

```
ana@laptop:~/azure$ grep CLIENT_SECRET secret.yaml
  AZURE_CLIENT_SECRET: bm90LWEtcmVhbC1zZWNyZXQ=
ana@laptop:~/azure$ grep CLIENT_SECRET secret.yaml | awk '{print $2}' | base64 -d; echo
not-a-real-secret
```

**Base64 is an encoding, and anybody can reverse it with a command every Linux machine has.**
Kubernetes keeps a Secret in etcd and hands it to the pods that mount it, and Kubernetes RBAC
decides who may read it. Neither stops the secret leaving through the people and programs that are
allowed to see it. Count where this one ends up:

- **in the repository**, if `secret.yaml` was ever committed, and then in every clone and fork;
- **in the cluster**, readable by anyone allowed to `get secrets` in the namespace `shop`, and by
  every pod that mounts it;
- **in the places a secret leaks to by accident**: a CI log that printed the environment, a
  laptop's shell history, a support ticket with a pasted error.

Each copy is as good as the original for as long as the secret lives, which raises the question of
how long that is.

## A secret with an end date

Unlike a key that lives until somebody deletes it, an Entra ID client secret has an end date. The command line says how long one lasts when nobody chooses, in the help of the two commands
that create one:

```
ana@laptop:~/azure$ az ad sp create-for-rbac --help | grep -A1 -- "--years"
    --years                             : Number of years for which the credentials will be valid.
                                          Default: 1 year.
ana@laptop:~/azure$ az ad app credential reset --help | grep -A1 -- "--end-date"
    --end-date             : Finer grain of expiry time if '--years' is insufficient, e.g.
                             '2020-12-31T11:59:59+00:00' or '2299-12-31'.
```

**A year, unless somebody chooses otherwise, and the help itself offers `2299-12-31` to whoever
wants to.** So the secret fails in one of two ways. Left at the default, it stops working on a day a
year after somebody created it, and that person may have moved team since. Microsoft's
documentation on workload identity federation names this risk in so many words: service downtime
when the credentials expire. Set far into the future instead, it becomes a password that works for
as long as anybody can imagine, in every copy listed above.

Rotating it is a small project, and it is done by a person. Add a second secret to the
application; write it into a new Kubernetes Secret; roll out every deployment that reads it; delete
the old secret from the application; and hope nothing else had a copy. The date it has to be done
by was set a year earlier, by somebody else.

## One application for every holder

Three replicas of the order API, a debugging pod somebody started last month and a developer's
laptop with the secret pasted into a file all sign in as the same application. Entra ID's sign-in
logs name that application for every one of them, so the record of who wrote a receipt cannot say
which of them it was. And the secret grants whatever the application was granted, to anybody who
holds a copy, from anywhere that can reach Entra ID.

## The other wrong answers: the node's identity, and pod-managed identity

The second answer people reach for has no secret in it at all: give the permission to the node.
Every AKS cluster has a **kubelet identity**, a managed identity of `azure-foundations` lesson 8
that AKS creates in the node resource group and attaches to the node pools' scale sets. The
kubelet uses it to pull images from the registry of lesson 10. Grant it a role on the storage
account and the order API can write receipts, asking the Instance Metadata Service at
`169.254.169.254` for a token, with nothing stored anywhere.

**So can every other pod scheduled on those nodes.** Microsoft's documentation says it in one
sentence: by default, all pods running in an AKS cluster can reach the Instance Metadata Service,
and through it the tokens of the identities the node carries. The permission is granted to a
machine, while the need belongs to one workload. AKS has a preview setting that blocks the service
for every pod not on the host network, and what its documentation tells those pods to use instead
is the subject of this lesson.

The third answer has a history, and you will still find it in older clusters and older articles.
**Microsoft Entra pod-managed identity** tried to make the node's route safe. A DaemonSet called
NMI intercepted every pod's request to the metadata service and answered only for the identities
bound to that pod, while a controller attached those identities to the node pool's scale set. It
never left preview. Microsoft's documentation, read on 30 October 2026, says the open-source
project was deprecated on 24 October 2022 and archived in September 2023, and that the AKS add-on
was supported until September 2025, to give its users time to move to Microsoft Entra Workload ID.

## What the replacement has to do

Put the failures side by side and the requirements write themselves. The credential should belong
to **one workload**, named by its Kubernetes service account, and not to an application that
anybody with a copy can be, or to a node. It should **expire on its own**, in hours rather than on
a date in a calendar. It should be **stored nowhere** a person can copy it from. And nobody should
have to **rotate** anything by hand.

**Microsoft Entra Workload ID**, called workload identity from here on, does all four. The pod
proves who it is with a token the cluster signs, and Entra ID gives it an access token because it
was told in advance whose signature to believe. The next section reads the token Kubernetes already
gives a pod; the one after it writes down the trust on the Azure side; the last one follows the
exchange between the two.

If the cluster already has secrets like `orders-entra`'s, they can be found. The command `az ad
app credential list --id <application id>` lists the metadata of an application's secrets, end
dates included. A secret that is old, used from a pod and due to expire next quarter is the first
one to replace.
