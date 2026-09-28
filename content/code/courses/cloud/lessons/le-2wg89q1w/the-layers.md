---
title: The layers under a running application
version: 1
---

Before anybody can say who runs what, there has to be a list of **what there is to run**. A shop's
website that answers a request is standing on nine layers, and each one has jobs that come back
every week whether anybody is looking or not.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 374\" role=\"img\" aria-label=\"The layers a running application stands on, from the building at the bottom to the data at the top. Facility: the building, power, cooling and guards. Hardware: servers, disks and the cables between them. Physical network: switches, routers and the links out. Virtualisation: one physical server cut into many virtual machines. Virtual network: the addresses, subnets and firewall rules of those machines. Operating system: kernel, packages, users and security patches. Runtime: the language, its interpreter and the web server. Application: the code and the packages it pulls in. Data: orders, customers and files, what the code stores. Beside all of them, identity and access: who may touch each layer.\"><defs><marker id=\"stk-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"24\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">layer</text><text x=\"196\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what it is</text><rect x=\"20\" y=\"328\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"343.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">facility</text><text x=\"196\" y=\"343.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the building, power, cooling, guards</text><rect x=\"20\" y=\"292\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"307.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">hardware</text><text x=\"196\" y=\"307.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">servers, disks, the cables between them</text><rect x=\"20\" y=\"256\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">physical network</text><text x=\"196\" y=\"271.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">switches, routers, the links out</text><rect x=\"20\" y=\"220\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">virtualisation</text><text x=\"196\" y=\"235.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one physical server cut into many VMs</text><rect x=\"20\" y=\"184\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"199.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">virtual network</text><text x=\"196\" y=\"199.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">addresses, subnets, firewall rules</text><rect x=\"20\" y=\"148\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">operating system</text><text x=\"196\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">kernel, packages, users, patches</text><rect x=\"20\" y=\"112\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">runtime</text><text x=\"196\" y=\"127.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the language, its interpreter, the web server</text><rect x=\"20\" y=\"76\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"91.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">application</text><text x=\"196\" y=\"91.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">the code and the packages it pulls in</text><rect x=\"20\" y=\"40\" width=\"530\" height=\"30\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">data</text><text x=\"196\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">orders, customers, files: what the code stores</text><rect x=\"566\" y=\"40\" width=\"134\" height=\"318\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"633\" y=\"181.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">identity and access</text><text x=\"633\" y=\"201.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">who may touch</text><text x=\"633\" y=\"217.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">each layer</text></svg>", "caption": "Nine layers and one column beside them. Every hosting model on this page runs the same stack; what changes between them is who runs each layer, which the rest of this lesson draws as a line."}
```

Read it from the bottom.

The **facility** is the building: the power contract, the generators for when it fails, the cooling
that carries the heat away, and the guards at the door. The hardware is the servers, the disks and
the cables between them, and its job is replacing whatever breaks, which in a building with thousands
of disks is something every day. The physical network is the switches and routers that join those
servers to each other and the links that carry traffic out to the internet.

**Virtualisation** is the software that cuts one physical server into many virtual machines, each
with its own share of processor and memory, each unable to see the others. It is the layer that makes
pooling possible, and it has patches of its own. On top of it sits the **virtual network**: the
addresses your machines have, how they are grouped into subnets, and the firewall rules that decide
what may reach them. It is a network in every sense the `networks` course taught, drawn by
configuration instead of by cables, and lesson 6 is about it.

The **operating system** is where most of the familiar work lives: installing security patches,
creating users, watching the disk fill up, reading the logs. The runtime is what your code needs
in order to run at all: the language and its interpreter, Python 3.11 for example, and the web server
in front of it. A language version reaches the end of its support on a published date, and after that
date its security fixes stop.

The **application** is the code somebody wrote for this business, together with the packages it
imports, and the data is what that code stores: the orders, the customers, the product photos.
The data is the one layer that cannot be bought again. Every other layer can be rebuilt from a
purchase or a download; last month's orders exist only where you put them.

Beside all nine, **identity and access** decides who may touch each of them: the accounts, passwords,
keys and roles, at the provider and inside your own application. It is drawn as a column rather than a
layer because it cuts across the stack. A person with the wrong access to the virtual network can
expose the database; a person with the wrong access to the application can delete the orders. Lesson 7
is about it.

## The jobs do not go away

The drawing makes one point that the rest of this lesson rests on. **Every layer has jobs, and moving
to the cloud removes none of them.** The disks still fail, the operating system still needs its
patches, the data still needs its backups. What changes is who does each job, and whether you can see
it being done.

That gives the question from the previous section a precise form. For any service you rent, you can
walk up this stack and ask of each layer: is this still mine? The next three sections do that for
IaaS, PaaS and SaaS, and the answer is always a cut at one height: **the provider runs everything
below it, and you run everything above**.
