---
title: Baking an image, or configuring at boot
version: 1
---

Every machine starts from an image: a disk with an operating system on it, copied for each new
machine. The question this lesson is about is **when the shop's software gets onto that disk**,
and there are two answers.

**Configuring at boot** starts every machine from a plain image and installs what it needs as it
comes up: a script handed to the machine at launch (on AWS, its *user data*, run by cloud-init),
or Ansible reaching in a minute later, the way lesson 18 did. People call it *frying*: the work is
done fresh, every time, on the machine that needs it.

**Baking** does that work once, before any machine exists. A build installs nginx, writes the
configuration and the page, and saves the result as a new image. Every machine is then started
from that image and has nothing left to install.

The common belief is that the two give the same result, and that baking is an optimisation for
boot time. They do not give the same result. A machine that installs nginx at boot gets the
version the archive offers **on the day it boots**. Three machines started on three different days
run what three different days offered, and nothing in any file says which:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Two ways of getting nginx onto three machines started on day 1, day 9 and day 20. Configured at boot, each machine starts from a plain image and installs nginx from the archive on the day it boots, so each can get a different version. Baked, Packer builds one image on day 0 and every machine starts as a copy of it, so all three run the same thing.\"><defs><marker id=\"bf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"110.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 0</text><text x=\"280.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 1</text><text x=\"450.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 9</text><text x=\"620.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">day 20</text><text x=\"20.0\" y=\"42.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">configure at boot</text><rect x=\"220\" y=\"55\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boot</text><text x=\"280.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">plain image</text><text x=\"280.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ day 1's apt</text><rect x=\"390\" y=\"55\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boot</text><text x=\"450.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">plain image</text><text x=\"450.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ day 9's apt</text><rect x=\"560\" y=\"55\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">boot</text><text x=\"620.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">plain image</text><text x=\"620.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">+ day 20's apt</text><text x=\"450.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">three machines, possibly three versions</text><text x=\"20.0\" y=\"152.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">bake an image, start copies</text><rect x=\"40\" y=\"165\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">packer build</text><text x=\"110.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web:1.0.1</text><rect x=\"220\" y=\"165\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"280.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">start</text><text x=\"280.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web:1.0.1</text><rect x=\"390\" y=\"165\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">start</text><text x=\"450.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web:1.0.1</text><rect x=\"560\" y=\"165\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">start</text><text x=\"620.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">shop-web:1.0.1</text><path d=\"M110 215 L110 240 L620 240\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M280 240 L280 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bf-ah-phosphor)\"></path><path d=\"M450 240 L450 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bf-ah-phosphor)\"></path><path d=\"M620 240 L620 218\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#bf-ah-phosphor)\"></path><text x=\"450.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">three machines, one image</text></svg>", "caption": "Configured at boot, every machine is built on the day it starts, from whatever the archive has that day. Baked, the building happened once, before any of them existed."}
```

Here is the difference on the laptop, with containers standing in for machines. The first command
is a fried start: plain Ubuntu, then apt. The second starts from `shop-web:1.0.1`, the image this
lesson builds in the next two sections:

```
ana@laptop:~/shop/image$ time docker run --rm ubuntu:24.04 sh -c 'apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx > /dev/null && nginx -v'
debconf: delaying package configuration, since apt-utils is not installed
nginx version: nginx/1.24.0 (Ubuntu)

real	0m9.069s
user	0m0.012s
sys	0m0.022s
```

```
ana@laptop:~/shop/image$ time docker run --rm shop-web:1.0.1 nginx -v
nginx version: nginx/1.24.0 (Ubuntu)

real	0m0.358s
user	0m0.014s
sys	0m0.023s
```

A container is not a virtual machine, and a real boot adds its own time to both. What the two
commands show is the part frying adds: the first spent its start downloading and installing, and
the second had nothing to do but run. **The installation also needs the archive to be reachable at
that moment.** A fried machine that starts while the package mirror is slow, or down, starts slow
or not at all, and the moment most machines start at once is the moment a shop is busiest.

Baking moves all of that to build time, where a failure stops a build and not a launch. It also
finishes what lesson 1 called **immutable infrastructure**: a machine started from an image is the
image, and a change means a new image and a new machine, never an edit. Nothing configures the
running machine, so there is nothing to drift.

**What baking costs** is a build for every change, and an image to keep for every version. A typo
in a page is a new image, not a one-line edit. And not everything belongs in the image:

| | in the image | at boot |
|---|---|---|
| packages and their versions | yes | |
| configuration that is the same everywhere | yes | |
| which environment this is, the database's address | | yes |
| passwords and keys | | yes, read from a secret store (lesson 12) |

The line is between what is the same on every copy and what differs per copy. An image with a
database password in it is a password in every copy of a file, readable by anyone who can start
the image.
