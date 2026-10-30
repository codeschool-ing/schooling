---
title: The path a request takes
version: 1
---

**The portal, the Azure CLI, Azure PowerShell, Bicep, Terraform and every SDK are clients. None of them
creates anything. Each one turns what you asked for into HTTP requests to one address,
`https://management.azure.com/`, and that address is Azure Resource Manager.** Lesson 1 found it in
`az cloud show`. This lesson follows a request to it, as far as a lab without an account can, and
reads the rest from Microsoft's documentation.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l25-path\" aria-label=\"The path of a request. On the left, the clients: the portal, the Azure CLI, Azure PowerShell, Bicep and Terraform. Step 1: the client gets a token from Microsoft Entra ID at login.microsoftonline.com. Step 2: it sends the request with the token to Resource Manager at management.azure.com. Step 3: Resource Manager checks the token, the role, the policies, the locks and the request limit. Step 4: it hands the request to the resource provider, such as Microsoft.Network, which does the work.\"><defs><marker id=\"l25-path-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l25-path-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l25-path-af-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"10.0\" y=\"30.0\" width=\"150.0\" height=\"260.0\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"20.0\" y=\"40.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">portal</text><rect x=\"20.0\" y=\"84.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"100.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">az</text><rect x=\"20.0\" y=\"128.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Az PowerShell</text><rect x=\"20.0\" y=\"172.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Bicep</text><rect x=\"20.0\" y=\"216.0\" width=\"130.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"85.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Terraform</text><text x=\"85.0\" y=\"272.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the clients</text><rect x=\"230.0\" y=\"20.0\" width=\"200.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Microsoft Entra ID</text><text x=\"330.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">login.microsoftonline.com</text><path d=\"M161.0 56.0 L229.0 50.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-path-af-ah-phosphor)\"></path><text x=\"190.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><rect x=\"230.0\" y=\"130.0\" width=\"200.0\" height=\"150.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Resource Manager</text><text x=\"330.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">management.azure.com</text><text x=\"330.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">token valid?</text><text x=\"330.0\" y=\"208.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">role allows it?</text><text x=\"330.0\" y=\"226.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">policy allows it?</text><text x=\"330.0\" y=\"244.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">no lock?</text><text x=\"330.0\" y=\"262.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">under the limit?</text><path d=\"M161.0 166.0 L229.0 190.0\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-path-af-ah-amber)\"></path><text x=\"190.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2</text><text x=\"442.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3</text><rect x=\"520.0\" y=\"160.0\" width=\"180.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"184.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">resource provider</text><text x=\"610.0\" y=\"206.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Microsoft.Network</text><text x=\"610.0\" y=\"224.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">does the work</text><path d=\"M431.0 230.0 L519.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l25-path-af-ah-paper-dim)\"></path><text x=\"475.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">4</text><text x=\"475.0\" y=\"306.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">steps 2 to 4 are the same whichever client sent the request</text></svg>", "caption": "Five clients, one token issuer, one API. Whatever is refused is refused in the middle."}
```

Four steps, always in this order:

1. **The client gets a token from Microsoft Entra ID.** It signs in at `login.microsoftonline.com`, for
   a particular tenant, and asks for a token whose audience is Resource Manager: the *scope*
   `https://management.azure.com/.default`. The token is a signed statement of who the caller is, and
   Microsoft's documentation gives it a lifetime between 60 and 90 minutes.
2. **The client sends the request to Resource Manager** with the token in the `Authorization` header,
   the resource's id as the path, and an `api-version` in the query string.
3. **Resource Manager checks it.** Is the token valid and meant for it? Does the caller hold a role
   that allows this action at this scope, which is lesson 9? Does any Azure Policy forbid it, which is
   lesson 4? Is there a lock on the resource? Is the subscription over its request limit, which the last
   section of this lesson covers?
4. **Resource Manager hands the request to the resource provider** that owns the type,
   `Microsoft.Network` for a virtual network, which does the work and answers.

**Every door shares steps 2 to 4.** A permission refused, a policy that denies, a throttled request:
each is the same answer whichever client sent it, because the client is not the one deciding.

## Step 1, against the real Entra ID

The first step is the one the lab can take for real, because the sign-in endpoint answers anybody.
This is the request a program makes to sign in as an application, the way lesson 7's service
principals do. Here it is sent with a tenant and an application that do not exist:

```sh
mkdir -p ~/azure/arm && cd ~/azure/arm
```

```
ana@laptop:~/azure/arm$ curl -sS -X POST https://login.microsoftonline.com/aaaabbbb-0000-cccc-1111-dddd2222eeee/oauth2/v2.0/token -d grant_type=client_credentials -d client_id=00001111-aaaa-2222-bbbb-3333cccc4444 -d client_secret=not-a-secret -d scope=https://management.azure.com/.default | jq '{error, error_codes, first: (.error_description | split(". ")[0])}'
{
  "error": "invalid_request",
  "error_codes": [
    90002
  ],
  "first": "AADSTS90002: Tenant 'aaaabbbb-0000-cccc-1111-dddd2222eeee' not found"
}
```

**That refusal came from Microsoft Entra ID itself**: `AADSTS90002` is its code for a tenant it does
not know. The request has exactly the shape a working one has. The tenant in the address, the
application's id and secret, and the scope that asks for a token for Resource Manager. With a real
tenant and a real application the answer is a JSON document holding an `access_token`. `jq` kept the
first sentence of the description, because the rest carries an id and a time that change on every
call.

## Steps 2 to 4, as far as the CLI gets

`--debug` shows the Azure CLI working through a command. Filtered to the lines that matter:

```
ana@laptop:~/azure/arm$ az group list --debug 2>&1 | grep -E 'Command table|client_type=|ERROR: cli'
DEBUG: cli.azure.cli.core: Command table: group list
DEBUG: cli.azure.cli.core.commands.client_factory: Getting management service client client_type=ResourceManagementClient
ERROR: cli.azure.cli.core.azclierror: Please run 'az login' to setup account.
```

The CLI found the command, then built a `ResourceManagementClient`, the client for Resource Manager's
`Microsoft.Resources` provider, and only then went looking for a token to give it, found no sign-in,
and stopped. **With an account, the next lines of the same output are the HTTP request itself**:
`GET https://management.azure.com/subscriptions/<id>/resourcegroups?api-version=...`, its headers with
the token removed, and the response.

A request sent straight to Resource Manager without a token is answered with **401**, and a header
named `WWW-Authenticate` that says which authority to get a token from. **That was not run here**: the
machine the lessons were recorded on is not allowed to reach `management.azure.com`, and nothing in
this course sends a request there.
