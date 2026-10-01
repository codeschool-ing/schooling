---
title: Merged, deployed, checked
version: 1
---

Merging is a push to `main`, and both hooks run:

```
ana@ctl:~$ cd net && git switch -q main && git merge -q --no-edit edge2-lan-description && git push -q origin main
remote: testing refs/heads/main at a51dbce        
remote: == yamllint        
remote: == validate        
remote: data/core1.yaml: ok        
remote: data/edge1.yaml: ok        
remote: data/edge2.yaml: ok        
remote: == offline tests        
remote: ........                                                                                     [100%]        
remote: 8 passed in 0.09s        
remote: deploying main at a51dbce        
remote: == render        
remote: data/core1.yaml -> configs/core1.conf, 34 lines        
remote: data/edge1.yaml -> configs/edge1.conf, 34 lines        
remote: data/edge2.yaml -> configs/edge2.conf, 34 lines        
remote: == apply        
remote: core1: matches        
remote: edge1: matches        
remote: edge2:        
remote: interface eth2        
remote: - description branch LAN        
remote: interface eth2        
remote: + description branch 2 LAN, floor 1        
remote: edge2: committed        
remote: == post-check        
remote: attempt 1: 6 passed in 1.28s        
```

The commit was tested again, as `main` this time, rendered, applied to the one router it changed,
and checked against the network. The result on the router, and the history on the server:

```
ana@ctl:~$ ssh netops@edge2 "show running-config" | grep "description branch"
 description branch 2 LAN, floor 1
ana@ctl:~$ git -C net.git log --oneline main
a51dbce edge2: say which floor the LAN is on
f8272ac the network as data, with its tests
```

**`main` is now what the network runs**, and its log is the list of changes the network has had,
each one tested before it was accepted. Lesson 11's backups compare the network with this
history; a difference between them is a change that did not come through the pipeline.

A failed post-check here is reported, not undone. `post-receive` cannot refuse anything, since the
commit is already on `main`, and the safe automatic response to a failure is debatable: reverting
the last commit and deploying again is right when the change broke the network, and wrong when the
network broke on its own while the change was going in. Many teams stop and call a person; the
`DEPLOY FAILED` line in `post-receive` is the hook for that, and in a real pipeline it would page
somebody or open a ticket, as lesson 7 did.

Two things in this lab are simpler than they should be. The hooks run as `ana`, with her SSH key;
a real pipeline runs as an account of its own, with a key that does nothing else, kept in the CI
system's secret store. And the deployment pushes to every router in one run; with more than a handful,
it would go in stages, one site first, its post-check, then the rest.
