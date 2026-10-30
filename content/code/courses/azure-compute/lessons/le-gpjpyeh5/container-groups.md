---
title: "The container group, which is what Azure runs"
version: 1
---

The name suggests Azure runs one container for you, and the commands seem to agree: `az container
create` takes an image and a size. **What it creates is a container group: one or more containers
scheduled together on one host, sharing a lifecycle, a local network and a set of volumes.** The
group is the resource Azure names, bills, starts, stops and deletes. A group holding one container
is the common case, and it is still a group, so every setting in this lesson belongs either to the
group or to one of its containers, and it matters which.

If you took the `kubernetes` course, you have met the idea under another name. Microsoft's
documentation compares a container group to a pod, and the comparison holds: several processes
that live and die as one unit, on one machine, talking over `localhost`. What Container Instances
does not give you is the rest of Kubernetes. There is no cluster around the group, no controller
keeping a number of copies, and no service in front of them. That absence is the subject of
section 05.

## What the containers in a group share

Four things, and each one has a consequence you will meet in this lesson.

**The host.** The containers of a group are placed on the same machine, which is Microsoft's, and
you never see it. Microsoft's documentation says a container in Container Instances is as isolated
as it would be in a virtual machine, so a stranger's group on the same hardware is kept as far from
yours as another virtual machine would be.

**The lifecycle.** The group starts and stops as a whole. Restarting it restarts every container in
it, and so does updating it: you cannot restart or update one container of a multi-container group
on its own. Billing follows the group too. Microsoft's pricing FAQ says the meter runs from the
moment the first image starts downloading until the group is stopped, and keeps running while any
container in the group is still running.

**The local network.** Containers in a group reach each other on `localhost`, on any port, whether
or not that port is opened to the outside. The next section shows the same arrangement with Docker
on your laptop.

**The volumes.** A group declares volumes, and each container mounts the ones it names, at a path
of its own choosing. Four kinds exist. An Azure Files share, which lesson 3 introduced, outlives
the group. A secret hands the containers sensitive values as read-only files, kept in memory and
never written to disk. An empty directory is scratch space the containers share: it survives a
container crashing and is gone when the group stops. And the fourth is a cloned Git repository.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 334\" role=\"img\" aria-label=\"A container group named shop, drawn as one dashed boundary: one host and one lifecycle. Above it, one public IP address and one DNS label, shop-sp.brazilsouth.azurecontainer.io, port 8080, reaching the shop container. Inside, two containers: shop, running python app.py on port 8080 and requesting 1 CPU and 1.5 GB, and a sidecar that calls /healthz every minute and requests 0.5 CPU and 0.5 GB. The two reach each other on localhost. Along the bottom, a volume, an Azure Files share, mounted in the containers that name it. Azure allocates the group the sum of the requests, 1.5 CPU and 2 GB.\"><rect x=\"32\" y=\"12\" width=\"290\" height=\"46\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">one public IP address and one DNS label</text><text x=\"177\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">shop-sp.brazilsouth.azurecontainer.io</text><rect x=\"12\" y=\"78\" width=\"696\" height=\"228\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"694\" y=\"94\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">container group shop: one host, one lifecycle</text><line x1=\"177\" y1=\"58\" x2=\"177\" y2=\"110\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></line><path d=\"M171 102 L177 112 L183 102 Z\" fill=\"var(--amber)\"></path><text x=\"188\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">port 8080, opened on both</text><rect x=\"32\" y=\"112\" width=\"290\" height=\"104\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"177\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">shop</text><text x=\"177\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">python app.py  :8080</text><text x=\"177\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">requests 1 CPU, 1.5 GB</text><rect x=\"398\" y=\"112\" width=\"290\" height=\"104\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"543\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">sidecar</text><text x=\"543\" y=\"158\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">calls /healthz every minute</text><text x=\"543\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">requests 0.5 CPU, 0.5 GB</text><line x1=\"322\" y1=\"172\" x2=\"398\" y2=\"172\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.5\"></line><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">localhost</text><rect x=\"32\" y=\"240\" width=\"656\" height=\"44\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360\" y=\"262\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">volume: an Azure Files share, mounted in the containers that name it</text><line x1=\"177\" y1=\"216\" x2=\"177\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></line><line x1=\"543\" y1=\"216\" x2=\"543\" y2=\"240\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></line><text x=\"708\" y=\"322\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">Azure allocates the group the sum: 1.5 CPU and 2 GB</text></svg>", "caption": "What a container group shares. Its containers sit on one host, start and stop together, reach each other on localhost and mount the same volumes; the outside world sees one address. The group is sized by adding up what its containers request."}
```

The resources add up the same way. **A group is allocated the sum of what its containers
request**, so a group whose two containers request 1 CPU and 0.5 CPU is a group of 1.5 CPU, and
it is billed as one. Section 04 is about those requests.

Two limits on the shape are worth knowing before you design around it. Multi-container groups run
**Linux containers only**: a Windows group holds exactly one container. And a group holds at most
60 containers and 20 volumes, which are hard limits that no support request raises.

## The sidecar

A second container in a group is usually there to help the first, and the pattern has a name: a
**sidecar**. Microsoft's examples are the ordinary ones. A container that pulls the latest content
from source control beside the one that serves it. A logging container that collects what the
application writes and sends it to long-term storage. A monitoring container that calls the
application every so often and raises an alert when it stops answering.

For the shop, the last of those is the one that makes sense today: a small container beside
`shop` that asks `http://localhost:8080/healthz` once a minute. It needs no address of its own and
no port opened to anybody, because it reaches the shop where the shop listens. **The price is
that the two are one unit**: if the sidecar is updated, the shop restarts with it. Lesson 9 comes
back to sidecars when Dapr runs as one beside the shop.

## How the group is reached

A group is reachable in one of two ways, and **it is one or the other**.

**A public address.** The group gets an IP address on the internet and, if you ask, a DNS label.
The label `shop-sp` in São Paulo becomes the name
`shop-sp.brazilsouth.azurecontainer.io`, which is the *label*, then the *region*, then
`azurecontainer.io`. A port has to be opened twice to be reachable: on the group's address, and on
the container that listens on it. A public address carries at most five ports.

**The address is not yours to keep.** Microsoft's documentation says the IP address of a group can
change when the group restarts, and advises against writing it down anywhere. The DNS label is
the stable half, and it is what anything outside should call. A fixed public address is possible
only by putting something that has one in front, such as an Application Gateway, which
`azure-foundations` lesson 22 introduced.

**A private address, in a virtual network.** The group is deployed into a subnet of one of your
virtual networks, from `azure-foundations` lesson 16, and is reachable from the network and from
whatever is connected to it, including an office through a VPN. Three rules come with it. The
subnet must be **delegated** to Container Instances and then holds container groups and nothing
else. A group in a virtual network has **no public address and no DNS label** at all. And it
reaches the internet only through a **NAT gateway**, which Microsoft's documentation calls the only
supported way out. Microsoft also asks for a subnet of at least `/24`, because smaller ones fill
up: addresses taken by deleted groups are not handed back fast enough to be reused.

The command line knows the first two rules and refuses before it asks Azure anything. Here are two
attempts to put the shop in a virtual network and give it a public face at the same time:

```
ana@laptop:~/azure$ az container create --resource-group shop --name shop --image shopregistry.azurecr.io/shop:1.0 --ports 8080 --vnet shop-vnet --subnet aci --dns-name-label shop-sp
ERROR: Can not use "--subnet" or "--vnet" with "--dns-name-label".
ana@laptop:~/azure$ az container create --resource-group shop --name shop --image shopregistry.azurecr.io/shop:1.0 --ports 8080 --vnet shop-vnet --subnet aci --ip-address Public
ERROR: Can not use "--subnet" or "--vnet" with IP address type "Public".
```

Both refusals come from the CLI's own checks of its arguments, which is why they appear without a
subscription. The first refuses the DNS label and the second the public address type: a group in a
subnet is private, whichever way you try to say otherwise.

**Which to choose follows from who calls the shop.** Its customers are on the internet, so the
order API wants a public address, and section 05 asks whether Container Instances is the right
place for it at all. A job that reads the shop's database and writes a report has no callers, and
belongs in the network next to the database, with a private address and a route out through the
NAT gateway.
