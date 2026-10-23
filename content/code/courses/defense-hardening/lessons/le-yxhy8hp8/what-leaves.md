---
title: The ways data leaves
version: 1
---

**Data loss prevention is about the data, not the machine.** Every other lesson of this course
protects a computer from somebody outside it. DLP starts from the opposite fact: most of the
people who can take Jatobá's client list out of the firm are allowed to read it, and most of the
times it leaves, nobody meant any harm. An accountant mails a spreadsheet to their own address to
finish it at home. An intern uploads a file to a converter site. A laptop with a folder that syncs
to a personal cloud account goes to a repair shop.

The common picture is a tool that stops thieves. A DLP tool mostly stops **mistakes**, and the
deliberate case is the harder one: somebody determined to take a file out can photograph the
screen. That does not make DLP pointless; it makes it a control whose numbers are honest about
what it catches.

## Three states

DLP borrows a distinction worth keeping, because each state is protected in a different place:

| state | where the data is | where it is watched |
|---|---|---|
| **at rest** | in a file, a database, a backup | a scan of the disks: where is the personal data, and should it be there |
| **in motion** | crossing a network: mail, an upload, a sync | at the edge of the network, or on the endpoint before it is encrypted |
| **in use** | open in a program: copied, printed, pasted, put on a USB stick | only on the endpoint, by an agent that sees the action |

## The channels

From a workstation like `desk`, data leaves by a short list of doors:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l09-channels\" aria-label=\"The workstation desk in the middle with five ways data leaves it. Mail goes through the firm's mail gateway, which can read attachments. Web uploads cross the network encrypted. A sync folder uploads in the background, also encrypted. A USB stick and a printer are actions on the machine itself. Only the endpoint sees all five while the file is still readable.\"><defs><marker id=\"l09-channels-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"270.0\" y=\"110.0\" width=\"180.0\" height=\"80.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">desk</text><text x=\"360.0\" y=\"165.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">the file is readable here</text><rect x=\"25.0\" y=\"28.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"110.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mail</text><text x=\"110.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">gateway reads attachments</text><rect x=\"525.0\" y=\"28.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"610.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">web upload</text><text x=\"610.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">encrypted on the wire</text><rect x=\"525.0\" y=\"228.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"610.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sync folder</text><text x=\"610.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">encrypted on the wire</text><rect x=\"25.0\" y=\"228.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"110.0\" y=\"243.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">USB stick</text><text x=\"110.0\" y=\"260.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">on the machine itself</text><rect x=\"275.0\" y=\"246.0\" width=\"170.0\" height=\"44.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.3\"></rect><text x=\"360.0\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">printer</text><text x=\"360.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">on the machine itself</text><path d=\"M270.0 125.0 L195.0 65.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path><path d=\"M450.0 125.0 L525.0 65.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path><path d=\"M450.0 175.0 L525.0 235.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path><path d=\"M270.0 175.0 L195.0 235.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path><path d=\"M360.0 190.0 L360.0 246.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-channels-dh-ah-paper-dim)\"></path></svg>", "caption": "Five doors. A network device reads one of them; the endpoint is in front of all five."}
```

Each door has a different control. Mail goes through a gateway the firm runs, which can read
attachments. Web uploads go through the network, but almost all of them are encrypted, so a
network device reads nothing unless it decrypts the traffic, which is TLS inspection, a decision
with costs and privacy questions of its own. Removable media and printing happen on the machine
itself, and lesson 5 is about closing the first. Sync clients look
like ordinary encrypted web traffic from outside, and are only visible on the endpoint.

**So the endpoint is where most of DLP has to live.** It is the only place where the file is still
readable at the moment it is about to leave, whatever door it takes. This lesson builds both
halves on `desk`: a content check that knows what personal data looks like, and a network rule
that knows where data may go.

Start the lab with the machines this lesson uses:

```sh
sudo bash hostlab.sh up desk web trap
```

`desk` is the workstation, `web` the firm's own portal, and `trap` plays the outside world: a
place a file could be uploaded to that is not the firm's.
