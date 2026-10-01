---
title: A branch is a proposal
version: 1
---

A change somebody wants to make goes on a branch of its own. edge2's LAN gets its floor in the
description:

```
ana@ctl:~$ cd net && git switch -qc edge2-lan-description && sed -i 's/description: branch LAN/description: branch 2 LAN, floor 1/' data/edge2.yaml && git commit -qam 'edge2: say which floor the LAN is on' && git push -q origin edge2-lan-description
remote: testing refs/heads/edge2-lan-description at a51dbce        
remote: == yamllint        
remote: == validate        
remote: data/core1.yaml: ok        
remote: data/edge1.yaml: ok        
remote: data/edge2.yaml: ok        
remote: == offline tests        
remote: ........                                                                                     [100%]        
remote: 8 passed in 0.10s        
```

**Tested and accepted, and not deployed.** `post-receive` deploys `main` only, so the branch sits on
the server as a proposal that has passed its tests. In a hosted service this is the moment a merge
request or pull request opens: another person reads the diff, which is a line of YAML rather than a
router configuration, and the test result is next to it.

The review is the part a pipeline cannot do. Tests know that the data is well formed and that both
ends of a link agree; they do not know whether edge2's LAN really is on the first floor, or whether
this was the week to change it. **A pipeline makes review cheaper, by taking the mechanical
questions away from it**, and leaves the questions only a person can answer.

When the branch is approved, it is merged into `main`.
