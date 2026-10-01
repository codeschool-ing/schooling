---
title: One shop, three ways, one Tuesday
version: 1
---

The models are easiest to tell apart by watching the same business live on each. Take **Barro**, a
small shop selling handmade ceramics online: three people, a catalogue of two hundred pieces, a few
dozen orders a day. It could be hosted three ways.

- On IaaS, it is one virtual machine running Ubuntu 24.04, with a web server, the shop's own
  Python application, and a PostgreSQL database, all installed by whoever set it up.
- On PaaS, the same Python code is pushed to a platform, which runs it, and a managed PostgreSQL
  database sits beside it.
- On SaaS, there is no code. Barro rents a hosted shop service and fills it with products, a theme,
  payment settings and three staff accounts.

To the customers the three look the same: a page with pots on it and a button that takes their money.
The difference only shows when something has to be done.

## Tuesday morning

A critical security fix is published for the TLS library that the operating system ships, the code
that encrypts every HTTPS connection to the shop.

**On IaaS, this is Barro's job, and only Barro's.** Nobody at the provider will log in to their
machine. Somebody at Barro has to learn that the fix exists and install it: `sudo apt update` and
`sudo apt upgrade` on Ubuntu, not run here, because there is no machine in this course. Then they
restart every program that had the old library loaded, and check that the shop still answers. If nobody does,
**nothing breaks**. The shop keeps selling, the pages keep loading, and every connection is encrypted
by a library with a published hole in it, for as long as it takes somebody to notice. The first
person to notice may not work at Barro.

**On PaaS, the platform owns the operating system and its libraries**, so the fix is theirs to apply.
How it reaches Barro's running shop depends on the platform: some apply it underneath the running
application, others build the fixed library into the application's image the next time Barro deploys.
Which of the two Barro's platform does is written in its documentation, and knowing it before the
Tuesday is Barro's part. On the second kind, a shop nobody has changed for a month is running last
month's library.

**On SaaS, it is invisible.** The provider patches its servers, and Barro may read about it on a
status page or not at all.

## Tuesday afternoon

The same day, a fix is published for the web framework Barro's Python code imports. This one sits in
the application row, and the picture changes. On IaaS it is Barro's job. **On PaaS it is still Barro's
job**, because the platform patches the runtime and not the packages the code lists: somebody updates
the version, runs the tests and deploys. On SaaS there is no Barro code, so it is the provider's.

## Every other day

Two more jobs complete the picture, and they are the ones that do not move.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Four jobs the shop has on one Tuesday, and who does each under IaaS, PaaS and SaaS. A security fix for the operating system: under IaaS you update, restart and check; under PaaS the platform does it, at your next deploy on some platforms; under SaaS the provider does it. A fix for a package the shop's code imports: you update, test and deploy under IaaS and under PaaS; the provider does it under SaaS. A member of staff leaves: you remove their access under all three. Backups and a copy you can leave with: under IaaS you schedule and test them; under PaaS you switch them on and check them; under SaaS you export the orders. Jobs that are yours are highlighted.\"><defs><marker id=\"shop-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"269.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">IaaS</text><text x=\"449.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">PaaS</text><text x=\"629.0\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" fill=\"var(--paper)\" font-weight=\"600\">SaaS</text><text x=\"20\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">a security fix for</text><text x=\"20\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">the operating system</text><rect x=\"184\" y=\"40\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: update, restart,</text><text x=\"194\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">check the shop answers</text><rect x=\"364\" y=\"40\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"55.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the platform; on some,</text><text x=\"374\" y=\"71.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">at your next deploy</text><rect x=\"544\" y=\"40\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the provider</text><text x=\"20\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">a fix for a package</text><text x=\"20\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">the code imports</text><rect x=\"184\" y=\"94\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: update, test,</text><text x=\"194\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">deploy</text><rect x=\"364\" y=\"94\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"109.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: update, test,</text><text x=\"374\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">deploy</text><rect x=\"544\" y=\"94\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"117.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the provider</text><text x=\"20\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">a member of staff</text><text x=\"20\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">leaves</text><rect x=\"184\" y=\"148\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: remove their keys</text><text x=\"194\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">and their logins</text><rect x=\"364\" y=\"148\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: remove their</text><text x=\"374\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">platform and shop logins</text><rect x=\"544\" y=\"148\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"163.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: remove their</text><text x=\"554\" y=\"179.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">user in the shop admin</text><text x=\"20\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">backups, and a copy</text><text x=\"20\" y=\"233.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\" font-weight=\"600\">you can leave with</text><rect x=\"184\" y=\"202\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: schedule them,</text><text x=\"194\" y=\"233.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">test a restore</text><rect x=\"364\" y=\"202\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"374\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: switch them on,</text><text x=\"374\" y=\"233.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">check they run</text><rect x=\"544\" y=\"202\" width=\"170\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"554\" y=\"217.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">you: export the</text><text x=\"554\" y=\"233.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">orders and customers</text></svg>", "caption": "The same shop on the same Tuesday. The first job moves across the line as the model changes; the last two never do. A shop on SaaS still has a member of staff whose login somebody has to remove.", "same": ["IaaS", "PaaS", "SaaS"]}
```

When one of the three people leaves, removing their access is Barro's job on every model: their SSH
key on the machine, their login on the platform, their user in the shop's admin. And on every model
Barro needs a copy of its orders it can leave with. On IaaS that means scheduling backups and testing a
restore; on PaaS switching the managed database's backups on and checking they run; on SaaS knowing
where the export button is and what the file it produces contains.

Read down the columns and the SaaS one has the fewest jobs marked as Barro's, which is the argument
for it. Read across the rows and the bottom two are Barro's everywhere, which is the argument against
believing that any model leaves you nothing to do.
