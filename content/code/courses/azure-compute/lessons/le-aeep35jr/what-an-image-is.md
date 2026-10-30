---
title: What an image is, on Azure
version: 1
---

An image is easy to picture as a file: a disk somebody uploaded, which a new machine boots from,
the way a laptop boots from an ISO. **On Azure, nothing boots from an image.** An image is the
source a new machine's operating system disk is copied from. When a virtual machine is created,
Azure makes a new managed disk out of the image, and the machine boots from that disk, which is its
own from then on. The image stays where it was and can be copied again for the next machine.
Lesson 3 is about managed disks; this lesson is about what they are copied from.

The machine's declaration names its image in one place, `storageProfile.imageReference`, and that
field takes three kinds of source:

```schooling-figure
{"svg": "<svg id=\"fig-image-sources\" viewBox=\"0 0 720 316\" role=\"img\" aria-label=\"Three kinds of image source on the left: a Marketplace image named by four names, Canonical:ubuntu-24_04-lts:server:latest; a managed image, one resource in one region; and a gallery image version, shopgallery/shop-web/1.0.0. Each can be named in the VM's imageReference. At creation Azure copies the one named into a new managed disk, the OS disk, and the VM boots from that disk.\"><defs><marker id=\"img-src-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"16\" y=\"14\" width=\"688\" height=\"288\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 4\"></rect><text x=\"30\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">brazilsouth, the region</text><rect x=\"30\" y=\"52\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"180\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">Marketplace image</text><text x=\"180\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Canonical:ubuntu-24_04-lts:server:latest</text><text x=\"180\" y=\"107\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">four names, published by Canonical</text><line x1=\"330\" y1=\"87\" x2=\"384\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><rect x=\"30\" y=\"136\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"180\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">Managed image</text><text x=\"180\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Microsoft.Compute/images</text><text x=\"180\" y=\"191\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">one resource, one region, generalised only</text><line x1=\"330\" y1=\"171\" x2=\"384\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><rect x=\"30\" y=\"220\" width=\"300\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"180\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">Gallery image version</text><text x=\"180\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">shopgallery/shop-web/1.0.0</text><text x=\"180\" y=\"275\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">versioned, replicated, shareable</text><line x1=\"330\" y1=\"255\" x2=\"384\" y2=\"160\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><rect x=\"386\" y=\"124\" width=\"140\" height=\"72\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"456\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11.5\" fill=\"var(--phosphor)\" font-weight=\"600\">imageReference</text><text x=\"456\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">names exactly one</text><line x1=\"526\" y1=\"160\" x2=\"552\" y2=\"104\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><text x=\"456\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">copied at creation</text><rect x=\"554\" y=\"52\" width=\"136\" height=\"74\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"622\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">OS disk</text><text x=\"622\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a managed disk,</text><text x=\"622\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">copied from the image</text><line x1=\"622\" y1=\"126\" x2=\"622\" y2=\"194\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#img-src-ah)\"></line><rect x=\"554\" y=\"196\" width=\"136\" height=\"60\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"622\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">the VM</text><text x=\"622\" y=\"238\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">boots from its own disk</text></svg>", "caption": "An image is never booted from. It is the source a new OS disk is copied from, and imageReference says which of three kinds of source it is."}
```

- a **Marketplace image**, published by somebody else and named by four names, which the next
  section takes apart: `Canonical:ubuntu-24_04-lts:server:latest` is Ubuntu 24.04 from Canonical;
- a **managed image**, a single resource in your subscription, made from a machine of your own;
- a **gallery image version**, one numbered version of an image you keep in an Azure Compute
  Gallery, which the last section of this lesson builds.

The CLI's help for `az vm create` says the same in its own words, and it is the first thing worth
reading without a subscription:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-image : [^.]*\.[^.]*\."
--image : The name of the operating system image as a URN alias, URN, custom image name or ID, custom image version ID, or VHD blob URI. In addition, it also supports shared gallery image.
```

An alias is a short name the CLI translates into four names, and the next section shows that
translation is less fixed than it looks. A VHD blob URI is a disk file in a storage account, the
oldest way of all and the one this course does not use.

## What an image says about the machine

An image is more than its bytes. It also states what kind of machine it can become, and three of
those statements decide whether a creation succeeds at all.

**The generation.** Azure runs two kinds of virtual hardware, and an image is built for one of
them. A *generation 1* machine starts from BIOS firmware and sees its disks through an IDE
controller; a *generation 2* machine starts from UEFI firmware and sees them through SCSI. The
operating system inside the image was installed for one or the other, so a generation 1 image does
not boot as generation 2. Generation 2 also allows an OS disk larger than 2 TB, and it is the only
kind Trusted Launch, below, protects. Publishers name the two in the SKU, which is the third of the
four names: for Ubuntu 22.04 Canonical publishes `22_04-lts` for generation 1 and `22_04-lts-gen2`
for generation 2, and for 24.04 the plain `server` is generation 2 and `server-gen1` is the old
kind. Sizes have a say as well. Microsoft's documentation lists the A-family and the Dv2 and Dv3
series among the sizes that cannot run generation 2 at all, and a few large sizes, such as the
Mv2-series, that run nothing else.

**The architecture.** An image is built for `x64` or for `Arm64`, and it runs only on a size with
that processor. Lesson 1 read the `p` in a size's name as the Arm processor; a `Standard_D2ps_v6`
needs an Arm64 image, and Canonical publishes one for 24.04 as the SKU `server-arm64`.

**The security type.** The CLI accepts three values for it:

```
ana@laptop:~/azure$ az vm create --help | tr -s "[:space:]" " " | grep -o "\-\-security-type : [^.]*\. Allowed values: [A-Za-z, ]*"
--security-type : Specify the security type of the virtual machine. Allowed values: ConfidentialVM, Standard, TrustedLaunch
```

`Standard` is a machine with no extra protection of its boot. `TrustedLaunch` adds two things to a
generation 2 machine. **Secure Boot** refuses to start a boot loader, kernel or driver that is not
signed by a trusted publisher. A **virtual TPM** is a private vault for keys, and it keeps a record
of each stage of the boot that can be checked from outside. Microsoft's documentation says Trusted
Launch adds nothing to the price of the machine. `ConfidentialVM` goes further and encrypts the
machine's memory, on sizes built for it.

## The default depends on who is asking

**The CLI and the portal create a generation 2 machine with
Trusted Launch unless told otherwise. A template does not, unless it is new enough or says so.**
Microsoft's documentation describes the two behaviours side by side. A declaration that uses the
virtual machine API version `2024-07-01`, as this lesson's does, and leaves out the security
profile gets a `Standard` machine. From API version `2025-11-01` the same omission gets Trusted
Launch, provided the image, the disk and the size all support it, and quietly gets `Standard` when
one of them does not.

So the same machine, created once with `az vm create` and once from a Bicep file, can come out with
two different boots, and nothing fails to tell you. The rule this course follows is the one lesson 1
set for warnings, applied to defaults: **a property that changes what the machine is gets written
down**, whichever value the tool would have chosen. The next section's declaration writes the
security type and both of its switches.

One consequence reaches as far as the last section. **Trusted Launch does not support managed
images.** A machine built from a managed image is a `Standard` machine, and Microsoft's answer for
an image of your own that keeps Secure Boot is the Compute Gallery. That is one of three reasons,
by the end of this lesson, that the gallery is where your own images belong.

## Reading it without a subscription

Everything above that can be checked on a laptop has been: the three kinds of source and the three
security types are what the CLI's help says, and the help text is generated from the same
definitions the CLI builds its requests from. What cannot be checked here is which images a region
actually offers, and the next section meets that refusal.
