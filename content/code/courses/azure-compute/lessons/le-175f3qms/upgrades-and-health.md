---
title: Upgrades, health and repairs
version: 1
---

Section 02 left a question open: when the model changes, what happens to the instances already
running? The usual assumption is that they follow. **They follow only if the upgrade policy says
so**, and how safely they follow depends on whether the scale set can tell a healthy instance from a
broken one. So this section is about three things that lean on one another: the upgrade policy, the
health signal, and the repairs that the health signal drives.

## Three upgrade modes

The CLI lists them, and the one you get by saying nothing:

```
ana@laptop:~/azure$ az vmss create --help | tr -s "[:space:]" " " | grep -o "Allowed values: Automatic, Manual, Rolling. Default: [a-z]*"
Allowed values: Automatic, Manual, Rolling. Default: manual
```

- Manual, the default. Nothing happens to the existing instances when the model changes, and new
  instances use the newest model. You bring the old ones up to date yourself, when you choose.
- Automatic. The scale set updates the instances with no guarantee about their order, and
  Microsoft's documentation says it may take them all down at the same time. It recommends the mode
  for development and test, where nobody minds.
- Rolling. The update goes in batches, with settings for how large a batch is and how much ill
  health stops it. It is the mode for production, and the one the shop's file uses.

Some changes only take effect when the instance is restarted, reimaged or redeployed: a new image
reference, a new size, new SSH keys or custom data, added zones. That is the work a rolling upgrade
spreads out.

## A rolling upgrade, in numbers

The shop's `rollingUpgradePolicy` has four settings:

- `maxBatchInstancePercent: 20` is the size of a batch, and with ten instances a batch is two;
- `pauseTimeBetweenBatches: 'PT2M'` is the wait between finishing one batch and starting the next;
- `maxUnhealthyInstancePercent: 20` stops the upgrade if more than a fifth of the whole set is
  unhealthy, before it starts or while it runs;
- `maxUnhealthyUpgradedInstancePercent: 20` cancels it if more than a fifth of the instances already
  upgraded come back unhealthy.

At ten instances that is five batches of two and four pauses of two minutes between them: eight
minutes of waiting, on top of however long each batch takes to come back healthy. **The two unhealthy
limits are what make a rolling upgrade safe, and they work only if the scale set can see health.** For
a Flexible scale set that means the Application Health extension: Microsoft's upgrade policy page
says a Flexible set in Rolling mode must have it. The same documentation suggests creating the set in
Manual mode, confirming that health is being reported, and only then switching to Rolling.

Two more settings exist. `prioritizeUnhealthyInstances` upgrades the broken instances first, and
`maxSurge` creates a batch's new instances before deleting the old ones, so the count never dips while
the upgrade runs. An upgrade in progress can be watched and stopped with these commands, which need a
subscription and were not run here:

```sh
az vmss rolling-upgrade get-latest --resource-group shop --name shop-vmss
az vmss rolling-upgrade cancel --resource-group shop --name shop-vmss
```

A cancelled upgrade does not resume by itself. The next change to the model starts a new one, and so
does `az vmss update` with nothing changed, which tells the set to compare its instances with the
model again.

## Automatic OS image upgrades

A separate setting, `automaticOSUpgradePolicy.enableAutomaticOSUpgrade`, follows the image's
publisher rather than your edits. **When a new version of the image is published, the scale set
replaces each instance's OS disk with one built from it**, keeping the data disks. It works in batches
of at most 20% of the set, waits up to five minutes after each batch for its instances to be healthy,
and by default restores the previous OS disk of an instance that is not. It uses the rolling upgrade
policy's settings whatever the upgrade mode is. For a gallery image like the shop's, the upgrade
starts in a region once a new image version has been replicated there, which lesson 2 shows how to do.

For Flexible scale sets this was in preview when this lesson's documentation was read, on 2026-10-30,
and it came with conditions. The instances have to use the model's image reference, with the version
set to `latest`. An upgrade overwrites the instance's provisioning data, administrator credentials and
custom data included. And it cannot be combined with `maxSurge`. The shop's file does not turn it on.

## What the health extension reads

The shop's file installs `ApplicationHealthLinux` at version `1.0`, pointed at port 8080 and
`/healthz`. The extension runs inside each instance and asks that address locally. Here is what it
would get from the shop's image, built from lesson 7's two files and run on the laptop. The second
request asks for a path the shop does not have:

```
ana@laptop:~/azure$ docker run -d --name shop -p 8080:8080 shop:1.0
13899392e978e9c7a871e23b80475c691b7c6b38ab0467c794cc6eb3d8dacdc6
ana@laptop:~/azure$ curl -s -w " %{http_code}\n" localhost:8080/healthz
{"status": "ok"} 200
ana@laptop:~/azure$ curl -s -w " %{http_code}\n" localhost:8080/health
{"error": "no such page"} 404
```

The long hexadecimal line is the container's id, and yours will differ. **Version `1.0` reports
binary health: a 200 is healthy and anything else, a 404 or no answer at all, is unhealthy.** So a
`requestPath` of `/health` in the file would compile, and every instance would be unhealthy from its
first probe: the rolling upgrade would refuse to start and the repairs below would replace instances
that are fine. The compiler cannot see that; the second request above can.

Version `2.0` reports **rich health**, and with the shop it would be a quieter mistake. It adds an
*Initializing* state, which gives a new instance a grace period before anything acts on it, and an
*Unknown* state. But it reads the body of the answer, and wants it to say
`{"ApplicationHealthState": "Healthy"}`; a 2xx answer without that is *Unknown*, which repairs and
upgrades treat as unhealthy. The shop answers `{"status": "ok"}`, so changing `1.0` to `2.0` in the
file compiles cleanly and turns three healthy instances into three unknown ones. **Choose rich health
only for an application that writes the body it asks for.**

`numberOfProbes: 3` asks for three answers in a row before the state changes, either way, so one slow
answer does not count; `intervalInSeconds` may be 5 to 60. And a scale set has one source of health:
the extension or, in Uniform mode only, a load balancer probe, never both at once.

## Automatic instance repairs

With health visible, the scale set can act on it. **Automatic instance repairs replace an instance
that reports unhealthy**, or reimage or restart it if `repairAction` says so. `Replace` is the default:
it deletes the instance and creates a new one from the current model, so the instance id, the private
address and every disk are new. `Reimage` keeps the address and the data disks and replaces only the
OS disk, and `Restart` keeps everything.

Repairs go slowly on purpose. At most 5% of the instances are repaired at once, and a set of fewer
than 20 is repaired one instance at a time. After any change to an instance, a **grace period** holds
repairs off, so that an instance still booting is not mistaken for a broken one. Microsoft's repairs
page gives it a range of 10 to 90 minutes, with 10 as the default. The CLI's help says something else:

```
ana@laptop:~/azure$ az vmss create --help | tr -s "[:space:]" " " | grep -o "\-\-automatic-repairs-grace-period : [^.]*\."
--automatic-repairs-grace-period : The amount of time (in minutes, between 30 and 90) for which automatic repairs are suspended due to a state change on VM.
```

Two of Microsoft's sources, two lower bounds, and a laptop cannot ask the service which one it
enforces. The shop's file uses 30 minutes, which both allow.

Repairs also stop themselves. If the replacements keep coming back unhealthy, the platform sets the
repairs' service state to `Suspended`, so that a broken image does not become an endless supply of
new instances, and somebody has to set it back to `Running`. And an instance carrying either kind of
instance protection from section 02 is never repaired.
