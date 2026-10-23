---
title: Vault in a container, and why dev mode stays on your laptop
version: 1
---

**Vault is a server that keeps secrets and decides, request by request, who may read which one.**
Every request carries a Vault token; every token carries policies; a policy names paths and what may
be done to each. Secrets are stored under paths such as `secret/linkbox/signing`, and nothing can be
read without a token whose policy says so. HashiCorp publishes it, and the cloud providers' own
secret managers (AWS Secrets Manager, Google Secret Manager, Azure Key Vault) follow the same model
with their identity systems in place of Vault's tokens.

This section starts one on your machine, from the image the course pulled with the others,
`hashicorp/vault:2.1.2`.

### Starting it

With no arguments the image starts Vault's **development server**:

@@CAPTURE vault-start@@

`-p 127.0.0.1:8200:8200` publishes its port on your own machine only, and `VAULT_ADDR` tells the
command-line client inside the container where the server is. `VAULT_DEV_ROOT_TOKEN_ID` is a dev-mode
convenience that exists nowhere else: it lets you choose the root token instead of getting a random
one. The lesson chooses `dev-only-root`, a name that says what it is, for a reason lesson 6 already
gave. A random root token has the shape of a real Vault token. A transcript that carries one is
a file that secret scanners, GitHub's push protection among them, refuse as a leaked credential,
however dead the server behind it. The second command prints the warning Vault writes at start-up,
which says most of what follows.

### What dev mode gives up

**Dev mode is a server built to be thrown away, and each of its conveniences is a production
control turned off.** Reading the warning line by line:

| dev mode | what a production Vault does instead |
|---|---|
| "runs entirely in-memory" | keeps its data in persistent storage, usually Vault's integrated Raft storage across three or five servers |
| "starts unsealed with a single unseal key" | starts **sealed**: its storage is encrypted and it cannot read it until enough holders of key shares unseal it, or a cloud key service does it automatically |
| the root token printed in the log | the root token is used to configure the first policies and authentication methods, then revoked |
| the listener has no TLS | serves only over TLS, because every request carries a token |

Each of those matters for a different reason. A Vault that keeps secrets in memory loses all of them
when its container stops, which is fine for a lesson and a disaster for a CI server. A root token in
a log file is a token that can do anything, in a file that is read by whoever reads logs. And a
token sent over plain HTTP can be read by anybody between the client and the server, which on your
own machine is nobody and on a network is not.

None of the production setup is run in this course. HashiCorp's documentation describes it, and the
point here is the one sentence the warning ends with: **development mode should not be used in
production**. Everything this lesson builds on top of it, the policy, the authentication method and
the role, is configured the same way on a production Vault.

### A command-line client, lent from the container

The image carries Vault's command-line client as well as the server. A shell function lends it to
your terminal, so `vault` behaves as if it were installed:

@@CAPTURE vault-cli@@

`Sealed false` and `Storage Type inmem` are the first two lines of the warning, confirmed by the
server itself. The function runs the client inside the container, where dev mode left the root
token ready, so **every `vault` command in this lesson runs as root**. That is the operator setting
Vault up. The pipeline never uses this function: it talks to Vault over HTTP with `curl`, as a CI
job does, carrying only the token it was given. Keep the two roles apart as you read the captures.
The function lasts as long as the terminal; a new terminal needs the line again.

### The password moves in

Vault mounts a key/value store at `secret/` in dev mode. Put the CI server's signing password in it,
and check that what comes back is the file byte for byte:

@@CAPTURE kv@@

The value went from the file to Vault's command line through `$(cat …)` and was never printed. The
comparison prints `same` and nothing else, which is how to check a secret without showing it.

Two details of the output matter in the next section. The key/value store keeps **versions**:
writing the path again makes version 2 and keeps version 1, which is how a rotated secret can be
rolled back. And the path the API uses is not the path you typed. `vault kv put secret/linkbox/signing`
writes to `secret/data/linkbox/signing`, the first line of the output, because version 2 of the
store keeps data, metadata and deletions under separate prefixes. **A policy is written against the
API path**, and a policy for `secret/linkbox/signing` would grant nothing.

The password is now in two places, the file and Vault, and that is deliberate. The file is what
`ci/sign.sh` reads today. The section where the pipeline reads it from Vault, three sections on, says
what has to change on a real CI server before the file can go.
