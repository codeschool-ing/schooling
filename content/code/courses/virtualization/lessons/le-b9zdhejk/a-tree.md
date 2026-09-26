---
title: Several of them
version: 1
---

Snapshots can be taken one after another, and they form a tree, each the child of the one that was
current when it was taken:

```
ana@host:~$ virsh snapshot-create-as vm1 configured >/dev/null && virsh snapshot-create-as vm1 tested >/dev/null && virsh snapshot-list vm1 --tree
clean
  |
  +- configured
      |
      +- tested
        

ana@host:~$ virsh snapshot-delete vm1 tested && virsh snapshot-list vm1 --tree
Domain snapshot tested deleted

clean
  |
  +- configured
    
```

`configured` was taken after `clean` and `tested` after `configured`, and `--tree` draws the line
between them. Any of them can be reverted to, and taking a new one after reverting to an older one
starts a new branch beside the old line. Deleting `tested` removed only that state; the others are
untouched.

The tree is where labs get untidy. **Keep few, name them for what they protect, and delete the ones
whose change has been judged**: once the update has run for a week without trouble, the snapshot from
before it is only taking space, and in the next section, slowing the disk.
