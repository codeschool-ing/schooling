---
title: Linked clones
version: 1
---

A machine made from a template does not need a full copy. It can be a thin layer on the template, the
same overlay the lab has used since lesson 1, and that is called a **linked clone**:

```
ana@host:~$ cd /var/lib/libvirt/images && for n in web1 web2; do sudo qemu-img create -q -f qcow2 -b template.qcow2 -F qcow2 $n.qcow2 8G; done && ls -lsh template.qcow2 web1.qcow2 web2.qcow2
 37M -r--r--r-- 1 root root  37M Sep 25 20:52 template.qcow2
196K -rw-r--r-- 1 root root 193K Sep 25 20:52 web1.qcow2
196K -rw-r--r-- 1 root root 193K Sep 25 20:52 web2.qcow2
ana@host:~$ sudo qemu-img info --backing-chain /var/lib/libvirt/images/web1.qcow2 | grep "^image:"
image: /var/lib/libvirt/images/web1.qcow2
image: /var/lib/libvirt/images/template.qcow2
image: /var/lib/libvirt/images/lab-base.qcow2
ana@host:~$ for n in web1 web2; do sudo virt-install --name $n --virt-type qemu --memory 1024 --vcpus 2 --import --disk /var/lib/libvirt/images/$n.qcow2,bus=virtio --disk /var/lib/libvirt/images/$n-seed.img,bus=virtio,format=raw --os-variant ubuntu24.04 --network network=default --graphics none --noautoconsole >/dev/null 2>&1; done; virsh list
 Id   Name   State
----------------------
 12   web1   running
 13   web2   running
```

Two clones, 196K each, on a template of 37M. `--backing-chain` shows three levels: `web1.qcow2`
reads from `template.qcow2`, which reads from `lab-base.qcow2`. Each clone got its own cloud-init disk
with its own name, and both were started.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 220\" role=\"img\" aria-label=\"A template with linked clones. At the bottom, lab-base.qcow2, the lab&#x27;s base, read-only. On it, template.qcow2, 37M, which was vm1, sealed and made read-only. On the template, two linked clones, web1.qcow2 and web2.qcow2, 196K each when new.\"><defs><marker id=\"tt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"16\" width=\"260\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"74\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">web1.qcow2   196K</text><text x=\"74\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a linked clone</text><path d=\"M190 68 L360 94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tt-ah)\"></path><rect x=\"400\" y=\"16\" width=\"260\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"414\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">web2.qcow2   196K</text><text x=\"414\" y=\"54\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a linked clone</text><path d=\"M530 68 L360 94\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tt-ah)\"></path><rect x=\"200\" y=\"96\" width=\"320\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\" xml:space=\"preserve\">template.qcow2   37M</text><text x=\"214\" y=\"134\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">vm1, sealed and read-only</text><path d=\"M360 148 L360 164\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tt-ah)\"></path><rect x=\"200\" y=\"166\" width=\"320\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">lab-base.qcow2</text><text x=\"214\" y=\"202\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">the lab’s base, read-only</text></svg>", "caption": "Each linked clone is a thin layer on the template, which is itself a layer on the base. Nothing is copied, so a clone is made in a moment; and nothing below a clone may ever change or move."}
```

The price of the thin layer is a dependency. **Nothing under a linked clone may change**: a template
that is updated, moved or deleted breaks every clone made from it, which is why this one is
read-only. And every read the clone has not written itself goes down the chain, so a linked clone on a
slow shared disk is a little slower than a full one.
