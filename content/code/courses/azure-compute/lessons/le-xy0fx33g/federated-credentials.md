---
title: The issuer, and a federated credential that trusts it
version: 1
---

The token of the last section is signed by the cluster, and Entra ID has never heard of the
cluster. **A federated identity credential is the record that introduces them: three strings on a
user-assigned managed identity, saying that a token from this issuer, with this subject and this
audience, may act as this identity.** There is no secret in it and no certificate. Entra ID compares
the three strings with the token's `iss`, `sub` and `aud`, but only after checking the token's
signature against keys it fetches from the issuer itself, which is why the cluster has to publish
them.

Two pictures are wrong here, and both are common. The credential is not a login the cluster makes:
nothing on the Azure side ever reaches into the cluster, and the cluster never signs in to
anything. And the credential does not live on the cluster. It is a child of the managed identity,
so one identity can trust several clusters, and deleting a cluster leaves its credentials behind on
the identities until somebody removes them.

## The issuer a cluster publishes

Every Kubernetes cluster signs its service account tokens, so every cluster has an issuer. What
AKS adds is a public one. With the **OIDC issuer** turned on, AKS serves two documents at an
address on the internet, and those are what Entra ID reads:

- `/.well-known/openid-configuration`, the discovery document, which names the issuer and says
  where its keys are;
- `/openid/v1/jwks`, the key set: the public halves of the keys the cluster signs with.

Microsoft's documentation, read on 30 October 2026, gives the address as
`https://{region}.oic.prod-aks.azure.com/{tenant_id}/{uuid}/`, a region, the tenant and a GUID
generated for each cluster that never changes; for the shop's cluster the region is `brazilsouth`.
On AKS Standard, a cluster created on Kubernetes 1.34 or later has the issuer on from the start, and
an older or existing one needs it turned on, which restarts the API server for a moment. **Once on,
it cannot be turned off.** The keys behind it rotate with `az aks oidc-issuer rotate-signing-keys`,
and both the old key and the new one stay valid for 24 hours afterwards, long enough for every
pod's token to be replaced by one signed with the new key.

The command line names the two switches a cluster needs, and the query that reads the address
back. Its help is real text from this version; the query needs a subscription and was refused:

```
ana@laptop:~/azure$ az aks create --help | grep -e "--enable-oidc-issuer" -e "--enable-workload-identity "
    --enable-oidc-issuer                                          : Enable OIDC issuer.
    --enable-workload-identity                                    : Enable workload identity addon.
ana@laptop:~/azure$ az aks show --resource-group shop --name shop-aks --query oidcIssuerProfile.issuerUrl --output tsv
ERROR: Please run 'az login' to setup account.
```

kind's API server serves the same two documents, through the same paths, and `kubectl` can read
them with `--raw`. Ask the cluster from the last section:

```
ana@laptop:~/azure$ kubectl get --raw /.well-known/openid-configuration | jq
{
  "issuer": "https://kubernetes.default.svc.cluster.local",
  "jwks_uri": "https://172.19.0.3:6443/openid/v1/jwks",
  "response_types_supported": [
    "id_token"
  ],
  "subject_types_supported": [
    "public"
  ],
  "id_token_signing_alg_values_supported": [
    "RS256"
  ]
}
ana@laptop:~/azure$ kubectl get --raw /openid/v1/jwks | jq '.keys[] | {kid, kty, alg, use}'
{
  "kid": "XRBr3pJmOiPXL-AaUkREEj_6qffoEunMXctRB_Mk3xs",
  "kty": "RSA",
  "alg": "RS256",
  "use": "sig"
}
```

The `kid` in the key set is the `kid` in the header of the token decoded in the last section:
**that is how a receiver knows which public key checks a given token**, and why a rotation can
publish two keys at once. The discovery document is the same shape as the example in AKS's
documentation, field for field. What differs is where it can be read from. kind's issuer is
`https://kubernetes.default.svc.cluster.local`, a name that only resolves inside a cluster, and its
key set sits at a private Docker address on your laptop. **Entra ID could not fetch these keys, so
it could not believe a token from this cluster even with a real tenant behind it**, which is one
more reason this course does not attempt the exchange.

## The identity, and its credential

The identity is a **user-assigned managed identity**, the kind `azure-foundations` lesson 8 created
as a resource of its own, here called `shop-orders`. Federated credentials can be added to one of
those or to an application registration, and not to a system-assigned identity, which lives and
dies with one resource. The declaration below is the whole of the Azure side: a cut-down
version of lesson 11's cluster, keeping only what this lesson adds to it, and the identity with its
credential. Save it as `~/azure/identity.bicep`, the notes left out:

```schooling-example
{"language": "bicep", "file": "identity.bicep", "parts": [{"code": "// identity.bicep\nparam location string = 'brazilsouth'\n\nresource aks 'Microsoft.ContainerService/managedClusters@2026-01-01' = {\n  name: 'shop-aks'\n  location: location\n  identity: {\n    type: 'SystemAssigned'\n  }\n  properties: {\n    dnsPrefix: 'shop'\n    agentPoolProfiles: [\n      {\n        name: 'system'\n        mode: 'System'\n        count: 3\n        vmSize: 'Standard_D4s_v5'\n      }\n    ]\n", "note": "**Lesson 11's cluster, cut down** to the properties it cannot do without. Its node pools, tier and upgrade settings are that lesson's; this one adds the two blocks below."}, {"code": "    oidcIssuerProfile: {\n      enabled: true\n    }\n    securityProfile: {\n      workloadIdentity: {\n        enabled: true\n      }\n    }\n  }\n}\n\n", "note": "**The two switches.** `oidcIssuerProfile` publishes the issuer and its keys; `workloadIdentity` installs the webhook that mutates labelled pods. The second is useless without the first, and nothing in the file says so."}, {"code": "resource orders 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {\n  name: 'shop-orders'\n  location: location\n}\n\n", "note": "The identity the order API becomes. It is a resource of its own, so it outlives any one cluster, and its client id is what the service account's annotation names."}, {"code": "resource trust 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2024-11-30' = {\n  parent: orders\n  name: 'shop-aks-orders'\n  properties: {\n    issuer: aks.properties.oidcIssuerProfile.issuerURL\n", "note": "**The credential is a child of the identity**, not of the cluster. `issuer` is read from the cluster rather than typed: the comparison is exact, so a missing trailing slash in a pasted URL is a credential that matches no token."}, {"code": "    subject: 'system:serviceaccount:shop:orders'\n", "note": "The token's `sub`: the namespace `shop` and the service account `orders`. **One credential trusts one service account in one cluster**, and nothing else that cluster signs."}, {"code": "    audiences: [\n      'api://AzureADTokenExchange'\n    ]\n  }\n}\n\noutput clientId string = orders.properties.clientId\n", "note": "The audience the projected volume asked for. The output is the client id that goes into the annotation, which Azure generates when it creates the identity."}]}
```

Compile it, and read the credential back out of the template:

```
ana@laptop:~/azure$ bicep build identity.bicep
ana@laptop:~/azure$ jq '.resources[] | select(.type | endswith("federatedIdentityCredentials")) | .properties' identity.json
{
  "issuer": "[reference(resourceId('Microsoft.ContainerService/managedClusters', 'shop-aks'), '2026-01-01').oidcIssuerProfile.issuerURL]",
  "subject": "system:serviceaccount:shop:orders",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
```

It compiles with no warnings, and the issuer in the template is still an expression, resolved by
Resource Manager from the cluster when it deploys. Two steps remain on the Azure side, and neither
is in the file. The identity needs a role on the storage account, which `azure-foundations` lesson
9 taught and the next section shows as a command. And `shop-orders`'s client id goes into the
service account's annotation, where `orders.yaml` already has the placeholder.

## What the compiler catches, and what it cannot

Make three slips at once: `audience` for `audiences`, an extra `s` in the subject, and the issuer
switched off.

```
ana@laptop:~/azure$ sed -e 's/audiences:/audience:/' -e 's/serviceaccount:shop/serviceaccounts:shop/' -e '/oidcIssuerProfile/,/}/s/enabled: true/enabled: false/' identity.bicep > slips.bicep
ana@laptop:~/azure$ bicep build slips.bicep
/home/ana/azure/slips.bicep(39,3) : Warning BCP035: The specified "object" declaration is missing the following required properties: "audiences". If this is a resource type definition inaccuracy, report it using https://aka.ms/bicep-type-issues. [https://aka.ms/bicep/core-diagnostics#BCP035]
/home/ana/azure/slips.bicep(42,5) : Warning BCP089: The property "audience" is not allowed on objects of type "FederatedIdentityCredentialProperties". Did you mean "audiences"? [https://aka.ms/bicep/core-diagnostics#BCP089]
```

**One slip out of three was found.** The misspelt property is refused with the right name
suggested, and its absence reported as a missing required property. The other two compile without
a word, because to the compiler they are a string and a boolean of the right type.
`system:serviceaccounts:shop:orders` is a subject no token will ever carry, so Entra ID would find no
credential to match, the state the words of
`AADSTS70021: No matching federated identity record found for presented assertion` describe. The issuer
switched off leaves the webhook on with nothing for Entra ID to fetch keys from. Neither mistake
shows until a pod asks for a token, which is the strongest argument for reading `issuer`
from the cluster, as the file does, and checking `subject` against a decoded token, as the last
section did.

## The command line, and the limits

`az identity federated-credential create` writes the same record without Bicep. Its help says
what each property is compared with:

```
ana@laptop:~/azure$ az identity federated-credential create --help | sed -n '/^Properties Arguments/,/^$/p'
Properties Arguments
    --audiences                                                  : The aud value in the token sent
                                                                   to Azure for getting the user-
                                                                   assigned managed identity token.
                                                                   The value configured in the
                                                                   federated credential and the one
                                                                   in the incoming token must
                                                                   exactly match for Azure to issue
                                                                   the access token.  Support
                                                                   shorthand-syntax, json-file and
                                                                   yaml-file. Try "??" to show more.
                                                                   Default:
                                                                   ['api://AzureADTokenExchange'].
    --issuer                                                     : The openId connect metadata URL
                                                                   of the issuer of the identity
                                                                   provider that Azure AD would use
                                                                   in the token exchange protocol
                                                                   for validating tokens before
                                                                   issuing a token as the user-
                                                                   assigned managed identity.
    --subject                                                    : The sub value in the token sent
                                                                   to Azure AD for getting the user-
                                                                   assigned managed identity token.
                                                                   The value configured in the
                                                                   federated credential and the one
                                                                   in the incoming token must
                                                                   exactly match for Azure AD to
                                                                   issue the access token. Either
                                                                   'subject' or
                                                                   'claimsMatchingExpression' must
                                                                   be defined, but not both.
```

Three phrases in it decide behaviour. The audience **defaults** to `api://AzureADTokenExchange`, the
value Microsoft's documentation recommends and warns against changing. Subject and audience must
**exactly match** the token, so `system:serviceaccount:shop:*` is a subject containing an asterisk,
matched by no token, and not a pattern. And the subject's last sentence names the one alternative:
`claimsMatchingExpression`, which the same help lists among its preview arguments and which tests
the token's claims with an expression instead of one fixed string. A credential has one or the
other, never both.

For the shop, the command is this. It was not run in this course: it needs a subscription.

```sh
az identity federated-credential create \
  --name shop-aks-orders \
  --identity-name shop-orders \
  --resource-group shop \
  --issuer "$AKS_OIDC_ISSUER" \
  --subject system:serviceaccount:shop:orders \
  --audiences api://AzureADTokenExchange
```

`AKS_OIDC_ISSUER` holds the address read with the `az aks show` query above.

Microsoft's documentation, read on 30 October 2026, sets the limits that shape how these are laid
out:

- **20 federated credentials per managed identity.** Each is one service account in one cluster,
  so an identity used by the order API in four clusters spends four, and a team that replaces
  clusters at every upgrade spends one per cluster it has not yet cleaned up.
- **It takes a moment to propagate.** AKS's page says a few seconds, Entra ID's says a request made
  several minutes later can still fail with `AADSTS70021` while the directory's cache catches up,
  and both recommend a short wait and retries.
- **Not two at once on one identity.** Creating several credentials under the same identity
  concurrently fails with HTTP 409, so a template that declares more than one makes each depend on
  the one before. Credentials under different identities can be created in parallel.

The first limit is the one that grows with the platform. AKS has an answer for it called
identity bindings, which let many clusters share one credential through a proxy AKS runs; the
documentation treats it as its own subject, and this course leaves it there.
