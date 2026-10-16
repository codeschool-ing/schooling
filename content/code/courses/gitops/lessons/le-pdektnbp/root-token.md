---
title: The last credential
version: 1
---

**Vault's root token can do anything in Vault, and lesson 9 has kept it in a file ever since.** It
was needed to set Vault up: the policies, the Kubernetes auth method, the secrets engines, the audit
device a section ago. A Vault in use does not need it, and a root token that exists is the one
credential every other control in this course can be bypassed with.

Revoking it is one command, and asking the token about itself afterwards shows that it is gone:

```
ana@laptop:~/fleet$ vault token revoke $VAULT_TOKEN
Success! Revoked token (if it existed)
ana@laptop:~/fleet$ vault token lookup
Error looking up token: Error making API request.

URL: GET http://127.0.0.1:8200/v1/auth/token/lookup-self
Code: 403. Errors:

* 2 errors occurred:
	* permission denied
	* invalid token
```

`Success!`, and the same token, asked about itself, is refused: `permission denied` and `invalid
token`. Every `vault` command in this terminal now needs a login.

**The day a root token is needed again, Vault makes a new one**, and it takes the unseal keys to do
it. `vault operator generate-root` starts a process in which a quorum of key holders each submit a
key, and the token it produces is meant to be used and revoked within the hour. That is a
deliberate, recorded act that needs more than one person, which is the property the token in a file
did not have.

For the rest of the work, an administrator logs in with an identity of their own and a policy that
names what they may change, and the audit log of the previous sections records them by name.

## Where the course ends

Twelve lessons ago the cluster's state was something a person typed. Now it is a repository whose
every change has an author, a reviewer, a check and a record of when it reached each environment.
Artefacts are signed, and refused when they are not. Secrets live outside Git, are read by an
identity that has a name, and are logged when read. Credentials expire on their own or are rotated
in an order that breaks nothing. And four systems keep records that answer who changed what, when
and why, without asking anybody to remember.

None of it depends on this lab. The cluster can be EKS, the Git server GitHub, the registry Harbor,
the store AWS Secrets Manager: the objects keep their names, and the questions keep their answers.
