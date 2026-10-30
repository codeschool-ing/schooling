---
title: The projected token, which Kubernetes already gives a pod
version: 1
---

**Kubernetes can already prove who a pod is.** Its API server signs tokens for service accounts,
and a projected service account token volume asks the kubelet for one with the audience and the
lifetime you choose, writes it into a file in the pod and replaces it before it runs out.
Workload identity is built on that file. The pod is given a token whose audience is
`api://AzureADTokenExchange`, four environment variables that say where the token is and which
identity it is for, and nothing else from Azure. This section makes that token on kind and reads
what is in it.

The picture people often bring is that AKS hands the pod an Azure credential, or that the webhook
slips a secret into it. **Neither happens.** What the pod holds is a Kubernetes token, signed by
the cluster, which is worth nothing at Azure until Entra ID accepts it in the exchange at the end
of this lesson.

## What you write, and what the webhook adds

On an AKS cluster with workload identity turned on, you write two things. The service account
carries the annotation `azure.workload.identity/client-id`, the client id of the managed identity
the pod should become. The pod carries the label `azure.workload.identity/use: "true"`. AKS runs
a **mutating admission webhook**, a program the API server consults while a pod is being created,
and when it sees a pod with that label it adds the rest:

- **`AZURE_CLIENT_ID`**, copied from the annotation;
- **`AZURE_TENANT_ID`**, from the annotation `azure.workload.identity/tenant-id` if the service
  account has one, and the cluster's own tenant otherwise;
- **`AZURE_AUTHORITY_HOST`**, the address of Entra ID's sign-in endpoint;
- **`AZURE_FEDERATED_TOKEN_FILE`**, the path of the token;
- **a projected volume** holding a service account token for the audience
  `api://AzureADTokenExchange`, mounted at that path. It lasts 3,600 seconds unless the annotation
  `azure.workload.identity/service-account-token-expiration` asks for more, up to 86,400.

**Only a labelled pod is touched.** Microsoft's documentation calls the label required: a pod
without it is not mutated, even when its service account is annotated. And the webhook acts when
a pod is created, so changing the annotation does nothing to a pod already running until it is
restarted.

## The lab: kind, with the webhook's work done by hand

**kind runs no such webhook**, so the lab writes by hand what the webhook would add, and then reads
the token Kubernetes produces for it. That token is real, signed by the cluster's own key. The
cluster is lesson 11's shape with one worker, which is all this lesson needs. Save it as
`cluster.yaml`:

```yaml
# cluster.yaml: one control plane and one worker
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri"]
    restrict_oom_score_adj = true
kubeadmConfigPatches:
- |
  kind: KubeletConfiguration
  failCgroupV1: false
nodes:
- role: control-plane
- role: worker
```

The two patches are needed on a machine with cgroup v1, as lesson 11 explained; on cgroup v2,
which is every current distribution and Docker Desktop, they are harmless. Create the cluster and
give its nodes the shop's image from lesson 7:

```
TRANSCRIPT:create
TRANSCRIPT:load
```

Now the namespace, the service account and the pod. Save this as `orders.yaml`. Everything from
`env:` down is what the webhook would have written, and the two ids are the placeholders
Microsoft's documentation uses:

```yaml
# orders.yaml: the service account, and a pod with what the webhook would add
apiVersion: v1
kind: Namespace
metadata:
  name: shop
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: orders
  namespace: shop
  annotations:
    azure.workload.identity/client-id: 11112222-bbbb-3333-cccc-4444dddd5555
---
apiVersion: v1
kind: Pod
metadata:
  name: shop
  namespace: shop
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: orders
  containers:
  - name: shop
    image: shop:1.0
    imagePullPolicy: IfNotPresent
    env:
    - name: AZURE_CLIENT_ID
      value: 11112222-bbbb-3333-cccc-4444dddd5555
    - name: AZURE_TENANT_ID
      value: aaaabbbb-0000-cccc-1111-dddd2222eeee
    - name: AZURE_AUTHORITY_HOST
      value: https://login.microsoftonline.com/
    - name: AZURE_FEDERATED_TOKEN_FILE
      value: /var/run/secrets/azure/tokens/azure-identity-token
    volumeMounts:
    - name: azure-identity-token
      mountPath: /var/run/secrets/azure/tokens
      readOnly: true
  volumes:
  - name: azure-identity-token
    projected:
      sources:
      - serviceAccountToken:
          path: azure-identity-token
          audience: api://AzureADTokenExchange
          expirationSeconds: 3600
```

The path is the one Microsoft's documentation gives as an example, and the same documentation
warns against writing it into an application: the webhook chooses it, and it can change. A program
that needs the token reads `AZURE_FEDERATED_TOKEN_FILE` and opens whatever path it names.

```
TRANSCRIPT:apply
```

The four variables are in the container, and the last command shows who put them there: nobody.
**On kind the label and the annotation are read by nothing**; there is no webhook configuration in
the cluster at all, and on AKS that list would include the workload identity webhook.

## Reading the token

Read the token the way a program in the pod should, through the variable, and keep a copy on the
laptop:

```
TRANSCRIPT:token-cat
```

A token like this one is a JSON Web Token: three parts separated by dots, the first two
base64url-encoded JSON, the third a signature. This program prints the first two and leaves the
third alone. Save it as `~/azure/decode.py`:

```schooling-example
{"language": "python", "file": "decode.py", "parts": [{"code": "# decode.py: the header and claims of a token, WITHOUT checking its signature\nimport base64\nimport json\nimport sys\nfrom datetime import datetime, timezone\n\n\n", "note": "Standard library only, so it runs with the Python every machine in this course has. The first line says what the program does not do, which matters more than what it does."}, {"code": "def part(text):\n    return json.loads(base64.urlsafe_b64decode(text + '=' * (-len(text) % 4)))\n\n\n", "note": "**base64url, padded back.** A token drops the `=` padding that Python's decoder wants, so the function adds as many as the length needs before decoding the JSON."}, {"code": "header, claims, signature = open(sys.argv[1]).read().strip().split('.')\nprint('header:', json.dumps(part(header)))\nbody = part(claims)\nprint('claims:', json.dumps(body, indent=2))\n", "note": "The three parts. The header names the algorithm and the key that signed the token; the claims say who it is for and until when."}, {"code": "for name in ('iat', 'exp'):\n    print(name, datetime.fromtimestamp(body[name], timezone.utc).isoformat())\nprint('lifetime:', body['exp'] - body['iat'], 'seconds')\nprint('signature:', len(signature), 'characters, not checked')\n", "note": "`iat` and `exp` are seconds since 1970, printed as dates in UTC. **The signature is counted and not checked**: checking it needs the cluster's public key, and the next section shows where that is published."}]}
```

Run it on the copy:

```
TRANSCRIPT:token-decode
```

Read it against the pod that produced it. `iss` is the cluster's issuer, the name it signs as;
on kind that is `https://kubernetes.default.svc.cluster.local`, and on AKS it is a public URL of
the next section. `sub` is `system:serviceaccount:shop:orders`, the namespace and the service
account, and it is the string the trust on the Azure side will be written against. `aud` is the
audience the volume asked for. `exp` minus `iat` is the 3,600 seconds of `expirationSeconds`.
Under `kubernetes.io` the cluster says more than Entra ID will look at: the pod's name and uid,
the node it runs on, and the service account's uid, which is why a token from a deleted pod stops
being accepted by the API server even before it expires. The header carries `alg`, `RS256`, and a
`kid`, the id of the key that signed it.

**`decode.py` believed every word, and that is exactly what it must never be used for.** Anybody
can write those claims into a file; what makes this token worth something is the signature, made
with the cluster's private key, which only the cluster's public key can check. Checking it is the
job of whoever receives the token, Entra ID in this lesson, and a program that decoded its own
token and trusted the result would be trusting a note it could have written itself.

## The same pod, a second token

The pod holds another token, the one every pod is given to talk to the API server, at the path
Kubernetes always mounts it. Decode it too, and keep only the lines that differ:

```
TRANSCRIPT:api-token
```

Same issuer, same subject, same signing key, so the same cluster vouches for the same service
account in both. **What separates them is the audience**: this one is for the API server, the
first is for Entra ID, and a receiver that checks the audience refuses the other's. That is why
the trust in the next section names an audience as well as a subject.

The lifetime differs too, and for a reason that belongs to kind. Its API server extends the default
token to a year and adds `warnafter`, the moment after which it logs that an old token was used,
so that clients which never reread the file keep working. AKS's documentation says that extension
is off from Kubernetes 1.30, so on AKS this token lasts about an hour as well.

## Lifetime and rotation

A token can be made short, but not too short. Asking the API server directly for one of five
minutes, which is what the kubelet does for the volume, gets a refusal:

```
TRANSCRIPT:floor
```

**Ten minutes is the floor, and the kubelet keeps the file fresh above it.** The Kubernetes
documentation says it asks for a new token once the old one is older than 80% of its lifetime, or
older than 24 hours, and writes it over the file. For the 3,600 seconds above, that happens about
48 minutes after the token was issued; this transcript did not wait for it. What follows is a duty
for the application rather than for Kubernetes: read the file again each time a token is needed,
because a copy kept in memory expires on schedule. The Azure Identity libraries do that for you.

Leave the cluster running: the next section asks it for its keys.
