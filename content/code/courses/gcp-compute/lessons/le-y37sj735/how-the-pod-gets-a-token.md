---
title: How the pod gets a token
version: 1
---

Nothing in section 03 handed the pod a credential, and yet its client library will get one. **The
trick is the metadata server: the same address that answers on a Compute Engine machine answers
inside the pod, but on GKE it is GKE's metadata server, and it fetches tokens for the pod's
identity rather than the node's.** Knowing the sequence is what makes a failure in it readable.

## The exchange, step by step

Nothing here can run without a cluster and a Google project; the sequence is Google's documented
one.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Five columns: the container, GKE metadata server on the node, Security Token Service, IAM credentials API, and Cloud Storage. Arrows in order: 1, the container asks 169.254.169.254 for a token; 2 and 3, the metadata server sends the Kubernetes service account token to the Security Token Service and receives a federated token; 4, it exchanges that for an access token for photos-reader at the IAM credentials API; 5, the token returns to the container, which calls Cloud Storage with it.\"><defs><marker id=\"l15t-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"80\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">container</text><path d=\"M80 58 L80 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"156\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"220\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">GKE metadata server</text><path d=\"M220 58 L220 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"306\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"370\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Security Token Service</text><path d=\"M370 58 L370 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"446\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"510\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IAM credentials</text><path d=\"M510 58 L510 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><rect x=\"576\" y=\"16\" width=\"128\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"640\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Cloud Storage</text><path d=\"M640 58 L640 316\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M86 86 L214 86\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"150.0\" y=\"76\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1 token?</text><path d=\"M226 120 L364 120\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"295.0\" y=\"110\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2 KSA token</text><path d=\"M364 154 L226 154\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"295.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3 federated token</text><path d=\"M226 188 L504 188\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"365.0\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4 act as photos-reader</text><path d=\"M504 222 L226 222\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"365.0\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">access token</text><path d=\"M214 256 L86 256\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"150.0\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5 access token</text><path d=\"M86 290 L634 290\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l15t-ah)\"></path><text x=\"360.0\" y=\"280\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">read the bucket</text></svg>", "caption": "Every token in the sequence is short-lived, and none of them is stored in the pod. The binding of section 03 is what lets step 4 succeed."}
```

1. The client library inside the container asks the metadata server for an access token, exactly
   as it would on a virtual machine: an HTTP request to `169.254.169.254` with the header
   `Metadata-Flavor: Google`, the address and header lesson 7 meets on Compute Engine.
2. On a node with `GKE_METADATA`, that address is answered by **GKE's metadata server**, a pod GKE
   runs on every node. It knows which pod is asking, and so which Kubernetes service account the
   pod runs as.
3. It obtains a token for that Kubernetes service account, signed by the cluster, and exchanges it
   at **Google's Security Token Service** for a federated token belonging to the identity
   `planner-dev.svc.id.goog[shop/photos]`.
4. Because the Kubernetes service account carries the annotation, it then uses that federated token
   to ask the **IAM credentials API** for an access token for `photos-reader`. IAM allows it because
   of the `roles/iam.workloadIdentityUser` binding.
5. The access token, valid for about an hour, goes back to the client library, which sends it to
   Cloud Storage. The library asks again before it expires.

**At no step does anything long-lived exist.** There is no file to leak, and a stolen token stops
working on its own within the hour.

## Reading a failure

Each step has its own way of failing, and the error names the step if you know the sequence:

| what the pod sees | the step that failed | the usual cause |
|---|---|---|
| a token for the node's service account, not `photos-reader` | 2 | the node pool lacks `GKE_METADATA`, so the node's own metadata answered |
| `Permission ... iam.serviceAccounts.getAccessToken denied` | 4 | the `workloadIdentityUser` binding is missing, or names the wrong namespace or name |
| a token for `photos-reader`, then `403` from Storage | 5 | the service account has no role on the bucket |
| a token, but for the wrong Google service account | 4 | the annotation names another email |

The second row is the commonest, and the cause is nearly always a typo in
`[shop/photos]`: a namespace written differently in the binding and in the Deployment, which IAM
treats as two different identities without complaint.

## What the pod can no longer do

With `GKE_METADATA` on the node pool, a pod **cannot reach the node's own service account** through
the metadata server; that is the point of putting GKE's server in front. Without it, every pod on a
node could get a token for the node's identity, which on many clusters has broad scopes. So turning
Workload Identity on is also turning that path off, and it is worth doing on a cluster even before
any pod uses it.
