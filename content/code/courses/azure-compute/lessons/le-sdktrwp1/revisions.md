---
title: "Revisions: what makes a new one, and how many may run"
version: 1
---

Lesson 7 updated a container group by running the create again, and every container in it restarted
in place. The habit carries over badly. **A container app is not updated; it is given a new
revision**, an immutable snapshot of what the app runs, and the old revision stays where it was
until something deactivates it. The app is then a list of revisions, some active and most not,
and what the customers reach depends on which are active and how the traffic is shared among
them. This section is about which changes make a revision, what a revision is called, and the two
modes that decide how many may be active at once. The rules are read from Microsoft's
documentation. The compiler's view of two mistakes, and two versions of the shop running side by
side, are run on the laptop.

## What makes a new revision

Section 02 split the app's properties in two, and this is where the split pays. **A change inside `properties.template` is revision-scope, and creates a new revision. A change
inside `properties.configuration` is application-scope: it applies to every revision at once, and
creates none.**

| a change to | scope | a new revision? |
| --- | --- | --- |
| the image, an environment variable, CPU and memory | revision | yes |
| a scale rule, or the replica limits | revision | yes |
| the revision suffix | revision | yes |
| a secret's value | application | no, and revisions must restart to see it |
| the revision mode | application | no |
| ingress: on or off, the traffic split, labels | application | no |
| registry credentials, Dapr settings | application | no |

So the shop's `SHOP_VERSION` going from `1.0` to `1.1` is a new revision, although the image is the
same. Moving the traffic from 90/10 to 50/50 is not: it is a change to the app, and both revisions
carry on unchanged. The secrets row is the one that catches people. A new password for the registry
reaches the app's configuration at once, and **a revision already running keeps the value it read
when it started**, until it is restarted or replaced. Microsoft's page on secrets says to answer a
changed secret with one or the other, and, before deleting a secret, to deploy a revision that no
longer uses it and deactivate the ones that did.

## What a revision is called

Every revision gets a name, generated unless you give it a suffix. The suffix follows the same
rules as a label, section 05's: lower-case letters, digits and dashes, starting with a letter,
ending with a letter or digit, no two dashes together, at most 64 characters. Microsoft's examples
of a revision name join app and suffix with two dashes, `shop--v1-1`, and an app's own name may
not contain two dashes, so the join is never ambiguous. **A suffix you choose makes a name you can
write down before the revision exists**, which is what the traffic block in `shop-app.bicep` needs:
it names `shop--v1-1` in the same deployment that creates it. Microsoft's blue-green page suggests a
build number or a commit's short hash as the suffix.

A dot is not among the allowed characters, and `v1.1` is the obvious thing to type:

```
ana@laptop:~/azure$ sed "s/revisionSuffix: 'v1-1'/revisionSuffix: 'v1.1'/" shop-app.bicep > suffix.bicep
ana@laptop:~/azure$ bicep build suffix.bicep
ana@laptop:~/azure$ jq -r '.resources[1].properties.template.revisionSuffix' suffix.json
v1.1
ana@laptop:~/azure$ az containerapp update --name shop --resource-group shop --revision-suffix v1.1
ERROR: Please run 'az login' to setup account.
```

The compiler passes it, because a suffix is typed as text and nothing more. The CLI does not
reach the question either: without an account it stops at the login, before anything would be
checked. Only Azure would refuse `v1.1`, at the moment of deployment.

## Single and multiple

The revision mode decides how many revisions may be active at once.

**Single**, the default, keeps one. A deployment creates the new revision beside the old,
provisions it, scales it up to the old one's replica count within its own limits, and waits for
every replica to pass its startup and readiness probes. Only then does the traffic move, all of it,
and the old revision is deprovisioned. If the new revision never becomes ready, **the traffic stays
on the old one**, which is what makes an update in single mode safe without any work of yours. For
the length of the change both revisions are running, which is why section 02's subnet had to leave
room for twice the addresses.

**Multiple** keeps as many active revisions as you choose, and hands you two decisions single mode
made for you: how the traffic is shared, section 05, and when an old revision is deactivated. The
CLI's help gives the default, and the shop's file overrides it. Then the same word misspelt, in
the file and on the command line:

```
ana@laptop:~/azure$ az containerapp create --help | awk '/^    --/ {print ""} {printf "%s ", $0}' | tr -s ' ' | grep -E -- '^ --revisions-mode '
 --revisions-mode : The active revisions mode for the container app. Allowed values: multiple, single. Default: single. 
ana@laptop:~/azure$ sed "s/'Multiple'/'Multi'/" shop-app.bicep > mode.bicep
ana@laptop:~/azure$ bicep build mode.bicep
ana@laptop:~/azure$ jq -r '.resources[1].properties.configuration.activeRevisionsMode' mode.json
Multi
ana@laptop:~/azure$ az containerapp create --name shop --resource-group shop --environment shop-env --image shopregistry.azurecr.io/shop:1.0 --revisions-mode multi 2>&1 | head -n 2
ERROR: az containerapp create: 'multi' is not a valid value for '--revisions-mode'. Allowed values: single, multiple.
Did you mean 'multiple' ?
```

`activeRevisionsMode` is typed as any text, so `Multi` compiles and reaches the template as it was
written, while the CLI carries its own list and refuses the same word with a suggestion. That is
lesson 7's restart policy again: **for a value with a fixed list, the CLI checks the list and the
compiler does not**. A third mode, *Labels*, is in preview: it gives revisions names such as `dev`
or `prod` and moves traffic by name, and this course does not rely on it.

Two things only single mode has. **Session affinity**, which sends every request from one client to
the same replica by a cookie, is supported only in single mode. And Microsoft's scale page asks for
single mode when an app scales on events other than HTTP. Multiple is for an app whose traffic you
intend to steer by hand.

An inactive revision costs nothing and can be activated again, which is what a rollback is in
multiple mode: activate the old revision if it was deactivated, and move the traffic back.
Microsoft keeps up to 100 inactive revisions and purges the oldest beyond that. The commands, none
of them run in this course, are `az containerapp revision list`, with the app's name, and
`az containerapp revision activate`, `deactivate` and `restart`, each with `--revision`.

## Two revisions on the laptop

No laptop runs a revision. What a laptop can run is what two revisions are: the same app with two
fixed configurations, active at the same time, each answering for itself. The shop's image from
lesson 7, built as it showed, started twice with the one setting that differs:

```
ana@laptop:~/azure$ docker run -d --name shop-v1-0 -p 8081:8080 -e SHOP_VERSION=1.0 shop:1.0 > /dev/null
ana@laptop:~/azure$ docker run -d --name shop-v1-1 -p 8082:8080 -e SHOP_VERSION=1.1 shop:1.0 > /dev/null
ana@laptop:~/azure$ curl -s -w '\n' localhost:8081/version
{"version": "1.0", "host": "73a3292e5e3d", "up_s": 1.0}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8082/version
{"version": "1.1", "host": "db3a7e6d0ab0", "up_s": 0.6}
```

Two containers, two versions, and nothing between them. In Azure, the ingress would decide which
one each customer reaches; here, the port does. **Nothing they hold is shared**:

```
ana@laptop:~/azure$ curl -s -w '\n' -X POST localhost:8081/orders -d '{"item": "coffee", "qty": 2}'
{"item": "coffee", "qty": 2, "id": 1}
ana@laptop:~/azure$ curl -s -w '\n' localhost:8081/orders
[{"item": "coffee", "qty": 2, "id": 1}]
ana@laptop:~/azure$ curl -s -w '\n' localhost:8082/orders
[]
```

An order taken by version 1.0 is unknown to 1.1, because `ORDERS` lives in the memory of one
process. That is true of revisions in Azure, and just as true of two replicas of one revision: with
`maxReplicas: 10`, an order sent to one replica is missing from the next one's list. The shop's list
of orders is a teaching device. **Anything that must survive a second replica goes into a database
or a queue**, never into the container.

## The life of one revision

A revision reports two states. Its provisioning state is *Provisioning*, *Provisioned* or
*Provisioning failed*. Once provisioned, its running state says what it is doing. It is *Scale to
0* when idle, *Activating* while the first replica starts, then *Running*, or *Running (at max)*
once it has reached `maxReplicas`. *Degraded* means at least one replica has failed, and *Failed*
is worse: the documentation gives an exit code of 137 as a common cause. That code is 128 plus 9, a
process killed with `SIGKILL`, and in a container a frequent sender is the kernel, ending a process
that went past its memory. *Running (at max)* is the one to set an alert on, because it means the next customer is
waiting for capacity the rule is not allowed to add.
