---
title: Where the memory goes
version: 1
---

Lesson 1 found vm1's QEMU process using about 1.5 GiB for a guest given 1 GiB, and promised to find out
why. Here is the same kind of guest, with the host's view of its memory:

```
ana@host:~$ virsh dommemstat vm1 | grep -E "^(actual|rss)"
actual 1048576
rss 1713460
ana@host:~$ sudo pmap -x $(pgrep -o qemu-system) | awk "NR > 2 && \$3 > 60000"
00007fa353fff000   65672   65552   65552 rw---   [ anon ]
00007fa383e00000 1048576  446464  446464 rw---   [ anon ]
00007fa3c4000000   65532   65532   65532 rwx--   [ anon ]
00007fa3c8000000   65532   65532   65532 rwx--   [ anon ]
00007fa3cc000000   65532   65532   65532 rwx--   [ anon ]
00007fa3d0000000   65532   65532   65532 rwx--   [ anon ]
00007fa3d4000000   65532   65532   65532 rwx--   [ anon ]
00007fa3d8000000   65532   65532   65532 rwx--   [ anon ]
00007fa3dc000000   65532   65532   65532 rwx--   [ anon ]
00007fa3e0000000   65532   65532   65532 rwx--   [ anon ]
00007fa3e4000000   65532   65532   65532 rwx--   [ anon ]
00007fa3e8000000   65532   65532   65532 rwx--   [ anon ]
00007fa3ec000000   65532   65532   65532 rwx--   [ anon ]
00007fa3f0000000   65532   65532   65532 rwx--   [ anon ]
00007fa3f4000000   65532   65532   65532 rwx--   [ anon ]
00007fa3f8000000   65532   65532   65532 rwx--   [ anon ]
00007fa3fc000000   65532   63812   63812 rwx--   [ anon ]
00007fa400000000   65532   65532   65532 rwx--   [ anon ]
total kB         3400460 1713836 1691556
ana@host:~$ sudo pmap -x $(pgrep -o qemu-system) | awk "\$5 == \"rwx--\" { n++; rss += \$3 } END { print n, \"areas of translated code,\", rss, \"KiB resident\" }"
16 areas of translated code, 1046796 KiB resident
```

`actual` is the memory the guest was given, 1048576 KiB, and `rss` is what the process really
occupies, 1713460 KiB. `pmap` lists the process's memory areas, and the ones holding more than 60 MB say
where it is. The area of exactly 1048576 KiB is **the guest's memory**, and only 446464 KiB of it is
resident: the guest has touched less than half of what it was given. The other large areas are marked
`rwx`, memory that can be executed, and there are 16 of them holding 1046796 KiB between them.

That is **translated code**. Without VT-x, QEMU turns the guest's instructions into instructions for the
host's processor and keeps the result, so that it does not have to translate the same loop twice. It
sets aside up to 1 GiB for that by default, and a guest that has booted has filled it.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 170\" role=\"img\" aria-label=\"Where the QEMU process&#x27;s memory went, as one bar of 1674 mebibytes resident. 1022 MiB are translated code, in 16 executable areas, which exist only because the processor is imitated in software. 436 MiB are the guest&#x27;s own memory, the part of its 1024 MiB it has touched so far. The remaining 215 MiB are QEMU itself and its devices.\"><defs><marker id=\"mm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">the QEMU process: 1674 MiB resident</text><rect x=\"20\" y=\"36\" width=\"415.3380370117094\" height=\"34\" rx=\"0\" fill=\"var(--amber)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"435.3380370117094\" y=\"36\" width=\"177.14385740525933\" height=\"34\" rx=\"0\" fill=\"var(--phosphor)\" stroke=\"none\" stroke-width=\"0\"></rect><rect x=\"612.4818944169688\" y=\"36\" width=\"87.51810558303129\" height=\"34\" rx=\"0\" fill=\"var(--wire)\" stroke=\"none\" stroke-width=\"0\"></rect><text x=\"20\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">translated code: 1022 MiB</text><text x=\"20\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only because the processor is imitated</text><text x=\"435.3380370117094\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">guest memory touched: 436 MiB</text><text x=\"435.3380370117094\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">of the 1024 MiB the guest was given</text><text x=\"700\" y=\"96\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the rest: 215 MiB</text></svg>", "caption": "More than half of this guest’s cost is the price of imitating a processor, not the guest’s memory at all. Under KVM that part is not there, and a guest costs roughly the memory it has touched plus QEMU’s own."}
```

So on this computer, **most of what a guest costs is the price of imitating a processor**. Under KVM,
the guest's instructions run on the real processor and there is nothing to translate, and a guest
costs roughly the memory it has touched plus QEMU's own. That is lesson 2's difference again, measured
in memory this time.
