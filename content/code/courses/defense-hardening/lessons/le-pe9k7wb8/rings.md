---
title: Rings, a few machines first
version: 1
---

**An update goes to a few machines first, and to the rest only when the first ones are still
fine.** Each group is a **ring**. The first ring is machines whose failure is cheap and noticed
quickly: the IT team's own laptops, a test copy of the server, a workstation whose user will call the
moment something is odd. The last ring is what the firm cannot afford to lose. Microsoft calls the
same idea deployment rings for Windows updates; cloud providers call it a staged rollout; the shape
is the same.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l17-rings\" aria-label=\"Three nested rings. The innermost, ring one, holds desk and the IT team's own machines: failure is cheap and noticed quickly. The middle ring holds the ordinary workstations. The outer ring holds web, the portal, which the firm cannot afford to lose. An update moves outwards, one ring at a time, and stops if a ring reports trouble.\"><defs><marker id=\"l17-rings-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><circle cx=\"230.0\" cy=\"130.0\" r=\"115\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><circle cx=\"230.0\" cy=\"130.0\" r=\"80\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></circle><circle cx=\"230.0\" cy=\"130.0\" r=\"42\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></circle><text x=\"230.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">ring one</text><text x=\"230.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">desk</text><text x=\"230.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">workstations</text><text x=\"230.0\" y=\"34.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">web</text><path d=\"M275.0 130.0 L390.0 130.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-rings-dh-ah-paper-dim)\"></path><text x=\"420.0\" y=\"80.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">ring one</text><text x=\"420.0\" y=\"96.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">failure is cheap and noticed fast</text><text x=\"420.0\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">middle</text><text x=\"420.0\" y=\"136.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ordinary workstations</text><text x=\"420.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">outer</text><text x=\"420.0\" y=\"176.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">what the firm cannot lose</text><text x=\"420.0\" y=\"215.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">an update moves outwards, and stops on trouble</text></svg>", "caption": "Each ring is a smaller bet than the next one."}
```

In the lab there are two rings: `desk` first, `web` second. Start both on version `1.0`, from
`admin`, after pointing `web` at the repository the same way as `desk`:

```
root@web:~# mv /etc/apt/sources.list /root/sources.list.archive; echo "deb [trusted=yes] http://admin:8000 ./" > /etc/apt/sources.list.d/jatoba.list; apt-get update -q >/dev/null
ana@admin:~$ for h in desk web; do ssh $h "sudo apt-get install -y -q jatoba-health=1.0 >/dev/null 2>&1; jatoba-health"; done
jatoba-health 1.0
portal 200
jatoba-health 1.0
portal 200
```

Both machines run `1.0`, and both reach the portal: `portal 200`.

## Ring one

The update goes to `desk` alone:

```
ana@admin:~$ ssh desk "sudo apt-get install -y -q jatoba-health 2>&1 | grep -E \"^(Preparing|Unpacking|Setting)\"; jatoba-health"
Preparing to unpack .../jatoba-health_1.1_all.deb ...
Unpacking jatoba-health (1.1) over (1.0) ...
Setting up jatoba-health (1.1) ...
jatoba-health 1.1
portal 200
```

dpkg says what it did in three lines: it unpacked `1.1` over `1.0`, then set it up. The program ran
afterwards and the portal still answers. **This is the check that ring one exists for**, and in a
real rollout it is not one command: the machines in the first ring run for a day or a week, the
help desk listens, the monitoring is watched, and only then does the second ring start.

## Ring two

`desk` is fine, so `web` gets the same update, and the result is read back from both:

```
ana@admin:~$ ssh web "sudo apt-get install -y -q jatoba-health 2>&1 | grep -E \"^Setting\"; jatoba-health"
Setting up jatoba-health (1.1) ...
jatoba-health 1.1
portal 200
ana@admin:~$ for h in desk web; do printf "%s " $h; ssh $h "dpkg-query -W jatoba-health"; done
desk jatoba-health	1.1
web jatoba-health	1.1
```

`dpkg-query -W` reports what is installed, which is what a report of patch status should be built on,
not on a list of commands somebody sent. The same habit as lesson 16's verify step: the version on
the machine is the evidence.

## How long between rings

The gap is a trade, and the deadline decides it. A gap of a week catches the bad update that takes
days to show, a slow memory leak or a monthly job that breaks; it also leaves the last ring exposed
for a week longer. For a P4 finding a week is free. For a flaw on the exploited list, lesson 16's P1
gives seven days for everything, so the rings shrink to hours, and **the first ring is still worth
having**: an hour on a few machines catches the update that fails to install at all, which is most of
the bad ones.

At scale the same loop is written once and run by a tool: an Ansible playbook with `serial:` set,
lesson 3's centralised configuration doing exactly this, or the patch management of an endpoint
product. The loop in the transcript above is that idea in one line.
