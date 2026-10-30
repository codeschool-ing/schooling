---
title: "The exchange: a token in, an access token out"
version: 1
---

Everything so far was preparation for one request. **The Azure SDK in the pod reads the token
file, sends the token to Entra ID's token endpoint as a client assertion, and Entra ID answers
with an access token for the managed identity, for the one resource the request named.** The SDK
attaches that access token to every call to Blob Storage, and asks for a new one before it runs
out, reading the file again each time. No secret is stored anywhere, and the token that started it
lasts an hour.

**This section is read, not practised.** Nothing on a laptop plays Entra ID, and the issuer of the
lab's kind cluster cannot be reached from outside it, so no exchange was attempted in this course
and nothing below shows output. What it shows comes from Microsoft's documentation, read on 30
October 2026.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"A sequence in five steps between four parties: the pod, Microsoft Entra ID, the cluster's issuer and Blob Storage. 1, the pod sends Entra ID its projected token as a client assertion, with the managed identity's client id and the scope it wants. 2, Entra ID fetches the issuer's discovery document and its public keys. 3, Entra ID checks the signature, then the issuer, subject and audience against the federated credential, and the expiry. 4, Entra ID returns an access token with its lifetime in seconds. 5, the pod writes the receipt to Blob Storage with that token as a bearer token. A note says none of this was run in this course: there is no tenant, and kind's issuer cannot be reached from outside the laptop.\"><defs><marker id=\"wi-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"wi-ah-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90 62 L90 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M310 62 L310 188\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M310 234 L310 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M520 62 L520 190\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M660 62 L660 200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M660 244 L660 320\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"15\" y=\"14\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"90.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the pod</text><text x=\"90.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">SDK and token file</text><rect x=\"235\" y=\"14\" width=\"150\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"310.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Microsoft Entra ID</text><text x=\"310.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the token endpoint</text><rect x=\"440\" y=\"14\" width=\"160\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"520.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the cluster's issuer</text><text x=\"520.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">discovery and keys</text><rect x=\"612\" y=\"14\" width=\"96\" height=\"48\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"660.0\" y=\"31\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">Blob Storage</text><text x=\"660.0\" y=\"49\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the receipts</text><text x=\"200\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 · the token as client_assertion, and a scope</text><path d=\"M92 98 L306 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah)\"></path><text x=\"415\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">2 · fetch the issuer's keys</text><path d=\"M312 134 L516 134\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah-dim)\"></path><text x=\"415\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the keys, as a JWKS</text><path d=\"M518 170 L314 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah-dim)\"></path><rect x=\"170\" y=\"188\" width=\"280\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"310\" y=\"204\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 · the signature first, then iss, sub</text><text x=\"310\" y=\"220\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">and aud against the credential, and exp</text><text x=\"200\" y=\"252\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">4 · an access token, and expires_in</text><path d=\"M308 264 L94 264\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah)\"></path><text x=\"375\" y=\"290\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">5 · write the receipt, Authorization: Bearer</text><path d=\"M92 302 L656 302\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#wi-ah)\"></path><rect x=\"458\" y=\"200\" width=\"248\" height=\"44\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"582\" y=\"215\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">not run in this course:</text><text x=\"582\" y=\"231\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">no tenant, and kind's issuer is private</text></svg>", "caption": "The exchange at the heart of workload identity. The pod proves who it is with a token its cluster signed, and Entra ID believes it only after checking that signature against keys it fetched from the cluster's issuer, then the three strings of the federated credential. None of it runs on a laptop."}
```

## The request

The exchange is OAuth 2.0's client credentials grant, the one an application with a secret uses,
with the secret replaced by the cluster's token. Written as `curl` from a shell in the pod, with
the four variables the webhook set, it is this. It was not run in this course: it needs a tenant
and an issuer Entra ID can reach.

```sh
curl -s "${AZURE_AUTHORITY_HOST}${AZURE_TENANT_ID}/oauth2/v2.0/token" \
  -d grant_type=client_credentials \
  -d client_id="$AZURE_CLIENT_ID" \
  -d client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer \
  --data-urlencode client_assertion@"$AZURE_FEDERATED_TOKEN_FILE" \
  --data-urlencode scope=https://storage.azure.com/.default
```

Read it field by field. `client_id` names the managed identity, `shop-orders`, by the client id the
annotation carried. `client_assertion` is the projected token itself, the file's contents as they
are, and `client_assertion_type` says it is a JWT. `scope` is the resource the access token will be
for, Blob Storage here, written in the form `<resource>/.default`. **The scope has to be written
that way**: Microsoft's documentation warns that a bare resource address such as
`https://storage.azure.com/` can fail, because workload identity uses Entra ID's v2 token
endpoint rather than the managed identity flow of the metadata service, which took one.

A successful answer is JSON with three fields, in Entra ID's documentation: `token_type`, which is
`Bearer`; `expires_in`, the access token's lifetime in seconds; and `access_token`. The pod then
sends that access token in an `Authorization: Bearer` header with every request to the storage
account.

## What Entra ID checks before it answers

It answers only when every one of these holds, in this order of dependence:

- **the signature**, checked with a public key from the key set that the issuer in the token's `iss`
  publishes, chosen by the `kid` in its header. Until that is done, no claim can be believed;
- **a federated credential on the identity** whose issuer, subject and audience are the token's
  `iss`, `sub` and `aud`, compared case-sensitively and in full;
- **the token's lifetime**: a token past its `exp` is refused.

Two of the failures have a documented wording, and neither was produced here. Entra ID's page on
propagation gives `AADSTS70021: No matching federated identity record found for presented
assertion` for a request made before a new credential has reached every server, and the words
describe any token that matches no record. AKS's page gives `AADSTS700212` for a token whose
audience is not the credential's, sent by a pod that used a token meant for something else.

**Notice what Entra ID never asks for: a secret of the pod's.** It does not need one, because it
believes the cluster's signature and was told in advance, by the federated credential, which
service account of which cluster may be `shop-orders`.

## What the SDK does for you

Nobody writes the request above in the order API. The Azure Identity library does it, in each of the
languages AKS's documentation lists with a minimum version; for Python it is
`azure-identity` 1.13.0. The application asks for a credential and hands it to a client:

```python
from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient

blobs = BlobServiceClient('https://shopreceipts.blob.core.windows.net',
                          credential=DefaultAzureCredential())
blobs.get_container_client('receipts').upload_blob('order-1.json', b'{"id": 1}')
```

That fragment was not run either: the shop's image is the standard library alone, and the receipts
are this lesson's example. `DefaultAzureCredential` tries a fixed list of credentials in order and
uses the first that has what it needs. For Python, Microsoft's documentation gives the start of
the list as **environment, then workload identity, then managed identity**, followed by the tools
on a developer's machine.

**The order is a trap during a migration.** The environment credential is the one the last
section's quick answer used: it looks for `AZURE_CLIENT_ID`, `AZURE_TENANT_ID` and
`AZURE_CLIENT_SECRET`. A pod that still mounts the old Secret beside the new token signs in with
the secret, every time, and the token sits unused while everything appears to work. Taking the
Secret out of the pod is part of the move, and so is deleting the secret from the application
afterwards. Code that should only ever use the token can say so with `WorkloadIdentityCredential`,
which reads the four variables and nothing else.

## What the access token may do

The access token carries the managed identity and nothing more, so what the order API can do is
whatever roles `shop-orders` holds. Lesson 9 of `azure-foundations` taught Azure RBAC; for the
receipts the role is `Storage Blob Data Contributor`, on the one container. Not run in this course:

```sh
az role assignment create \
  --assignee-object-id "$ORDERS_PRINCIPAL_ID" \
  --assignee-principal-type ServicePrincipal \
  --role "Storage Blob Data Contributor" \
  --scope "/subscriptions/$SUBSCRIPTION/resourceGroups/shop/providers/Microsoft.Storage/storageAccounts/shopreceipts/blobServices/default/containers/receipts"
```

`ORDERS_PRINCIPAL_ID` is the identity's principal id, which `az identity show` returns beside its
client id. Microsoft's documentation warns that a role assignment can take up to 10 minutes to take
effect, so a pod that gets an access token and is then refused by the storage account has usually
been set up correctly and too recently.

## Three answers, side by side

| | a client secret in a Secret | the kubelet identity | workload identity |
| --- | --- | --- | --- |
| what is stored | the secret, in every copy | nothing | nothing |
| expires | on its end date, a year by default | managed by Azure | the token in an hour, the access token on its own schedule |
| who can use it | anyone holding a copy | every pod on the node | one service account in one cluster |
| what a person rotates | the secret, by a date | nothing | nothing; the signing keys on demand |
| set up in | Entra ID and Kubernetes | one role | an identity, a credential, a role, an annotation and a label |

The last row is the honest cost. Workload identity takes five things to set up where the secret
took two, and in exchange there is nothing left to leak, nothing to remember on a date, and an
identity that belongs to the order API alone. The next lesson moves from who the pod is to how
requests reach it.
