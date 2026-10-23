---
title: What the pipeline holds, and for how long
version: 1
---

A secret's danger is two numbers multiplied: **how many people and processes can read it, and how
long it keeps working**. `testing-cicd` lesson 9 covered the first half from the CI service's side:
where a job gets a secret, why masking in logs is a courtesy rather than a control, and why a job
should hold only what it needs. This lesson works on both numbers at once, on linkbox's own
pipeline, and ends with a pipeline that holds no credential at all.

### What linkbox's pipeline holds today

Two stages handle something secret. A search of the stage scripts finds both:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ grep -n -e password -e LINKBOX_TOKEN ci/*.sh
ci/dast.sh:15:  -e LINKBOX_TOKEN="$(head -c 18 /dev/urandom | base64)" "linkbox:${CI_COMMIT:-dev}" >/dev/null
ci/sign.sh:3:# The key and its password belong to the CI server, in ~/ci/keys, and never
ci/sign.sh:12:COSIGN_PASSWORD=$(cat "$keys/password")
ana@vm:~/linkbox$ ls -l ~/ci/keys
total 16
-rw------- 1 ana ana 653 Oct 23 09:43 cosign.key
-rw-r--r-- 1 ana ana 178 Oct 23 09:43 cosign.pub
-rw------- 1 ana ana 104 Oct 23 09:43 offline.json
-rw------- 1 ana ana  33 Oct 23 09:43 password
```

They are opposites, and the difference is the subject of this lesson.

**The staging token in `ci/dast.sh` is short-lived by construction.** Lesson 4 made the scan start a
staging copy of the service, and lesson 6 made the service refuse to start without `LINKBOX_TOKEN`.
`dast.sh` answers that with 18 random bytes from `/dev/urandom`, made at the moment the container
starts. Nobody ever writes it down, and it stops meaning anything when the staging container is
removed at the end of the scan. If a log printed it, the reader would hold the key to a service that
no longer exists.

**The signing key's password in `~/ci/keys/password` is the other kind.** Lesson 14 made it with
`openssl rand` when the CI server got its cosign key, and `ci/sign.sh` reads it on every run. It is
33 bytes on the CI server's disk, it has worked since the day it was made, and it will keep working
until somebody makes a new key pair, which nothing in the course has a reason to do.

### Who can read it

The listing says the file belongs to `ana` and only she may read it. That sounds narrow until you
remember who `ana` is on this machine. Lesson 16 named it: the CI server's hook runs as `ana`, and
it runs the pipeline of **every branch that is pushed**, from that branch's own copy of `ci/`. A
branch whose `sign.sh` printed the password instead of passing it to cosign would put it in that
run's log, and nothing in the pipeline would object, because the pipeline that would object is the
one the branch just changed.

So the honest answers about this password are: every run of every branch can read it, and it works
indefinitely. A hosted CI service is the same shape. A secret stored in a repository's settings is
handed to whichever workflows the settings allow, and it stays valid until somebody rotates it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"sp-l17-lifetimes\" aria-label=\"Four credentials of linkbox's pipeline on one time line. The signing key's password in ~/ci/keys works from the day it was made until somebody changes it, and every run of every branch can read it. The staging token in dast.sh lives for one staging run. A Vault token and an identity token each live five minutes and belong to one run.\"><defs><marker id=\"sp-l17-lifetimes-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"170\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">how long it works</text><text x=\"600\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">who can read it</text><rect x=\"110\" y=\"34\" width=\"120\" height=\"196\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 3\"></rect><text x=\"170\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one run</text><text x=\"16\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">the key's password</text><rect x=\"130\" y=\"50\" width=\"310\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><path d=\"M440 62 L482 62\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#sp-l17-lifetimes-ah-amber)\"></path><text x=\"285\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">from lesson 14 until somebody changes it</text><rect x=\"515\" y=\"48\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">every run, every branch</text><text x=\"16\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">staging token</text><rect x=\"130\" y=\"96\" width=\"86\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"224\" y=\"108\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one staging run</text><rect x=\"515\" y=\"94\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">that run</text><text x=\"16\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Vault token</text><rect x=\"130\" y=\"142\" width=\"40\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 minutes</text><rect x=\"515\" y=\"140\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">that run</text><text x=\"16\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">identity token</text><rect x=\"130\" y=\"188\" width=\"40\" height=\"24\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"178\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 minutes</text><rect x=\"515\" y=\"186\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"610.0\" y=\"200.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">that run, for Vault only</text></svg>", "caption": "The password is the only one with no end. Everything this lesson builds is about giving it one, and about narrowing the column on the right."}
```

### Three questions, and the answers a file gives

**Minimal scope is three narrowings, and a secret in a file answers all three with "everything".**

| question | the password in `~/ci/keys` | where this lesson ends |
|---|---|---|
| what may be done | everything the key can do, by anybody holding the file | read one path in Vault, nothing else |
| who may do it | any run of any branch | a run of `main` of `ana/linkbox` |
| for how long | until somebody changes it | five minutes, then the token is dead |

The order of the lesson follows the table. Vault, a server whose whole job is keeping secrets, takes
the password off the CI server's disk. A Vault policy narrows **what**, and a Vault token's time to
live narrows **how long**. Both are built in a container on your machine in the next two sections.

That leaves a problem, and it is the one most teams stop at. Something has to give the pipeline its
Vault token. If the answer is "a token stored in the CI server's configuration", the secret has
moved one step and is still long-lived: lose that token and whoever has it reads every secret its
policy allows. This is sometimes called **the secret zero problem**: every secrets manager needs the
first secret that unlocks it.

### The way out of secret zero

The answer is not a better place to keep the first secret. It is to stop needing one. **The CI
server already knows which repository and which branch a run is building**, because it started the
run. If it signs that statement, and Vault trusts the CI server's signature, the run can prove who
it is without holding anything durable: it presents a token minted for it a moment ago, which
expires minutes later, and Vault decides from what the token says.

This is **federated identity**, and it is how GitHub Actions, GitLab CI and the other hosted services
reach clouds and vaults without stored keys. `testing-cicd` lesson 9 showed the exchange from the
outside. Here you build both ends: a CI that mints the tokens, and a Vault that checks them and
refuses the ones it should.

None of this replaces what lesson 6 taught. A secret that leaks still has to be revoked, and the
password above is still the one lesson 14 made. What changes is how far a leak can reach, and for
how long.
