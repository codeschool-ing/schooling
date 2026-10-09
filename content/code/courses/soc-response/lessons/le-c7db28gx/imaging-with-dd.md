---
title: Imaging with dd
version: 1
---

`dd` copies bytes from one place to another, and it is on every Linux system. It is the oldest imaging tool
there is, and the format it writes, the **raw** image, is just the disk's bytes in a file: every forensic tool
reads it. Three steps: hash the source, copy, hash the copy.

```
root@soc:~/case# mkdir evidence
root@soc:~/case# sha256sum /dev/loop0
eae7ac5a6c3fdefeba94adcb9f73955babaf7ffe4f54f20cb02e0d2cee186475  /dev/loop0
root@soc:~/case# dd if=/dev/loop0 of=evidence/files-data.dd bs=4M conv=noerror,sync
8+0 records in
8+0 records out
33554432 bytes (34 MB, 32 MiB) copied, 0.126463 s, 265 MB/s
root@soc:~/case# sha256sum evidence/files-data.dd
eae7ac5a6c3fdefeba94adcb9f73955babaf7ffe4f54f20cb02e0d2cee186475  evidence/files-data.dd
```

Read the command left to right. `if=` is the input, the blocked device; `of=` is the output, the image file.
`bs=4M` copies four megabytes at a time, which is faster than `dd`'s default of 512 bytes and changes nothing in
the result. `conv=noerror,sync` matters on a damaged disk: `noerror` keeps going past a sector that cannot be
read, and `sync` pads that block with zeros so that every later byte stays at its right offset. On a healthy disk
it does nothing, and it costs nothing to have it.

`8+0 records in`, `8+0 records out`: eight full blocks of 4 MiB, the 32 MiB of the disk, and no partial ones. Then
the hash of the image, and **it is the same as the hash of the device**, character for character. Your hash is
different from this one, because your disk was made at a different moment; what matters is that your two lines
match each other.

`dd` has two well-known relatives built for this job, `dcfldd` and `dc3dd`, which hash while they copy and log
what they did. They are conveniences: the proof is still the two hashes.
