---
title: When the layout breaks something
version: 1
---

A layout fails in its references: one file pointing at another by path or by name. Each of these was
produced on purpose, with a test Kustomization applied by hand and deleted afterwards.

## A path that moved

A Kustomization still pointing at the old `./staging`, after the move to `apps/bulletin/staging`:

```
ana@laptop:~/setup$ flux get kustomizations probe-path
NAME      	REVISION	SUSPENDED	READY	MESSAGE                                                                                           
probe-path	        	False    	False	kustomization path not found: stat /tmp/kustomization-21424086/staging: no such file or directory	
```

`kustomization path not found`, with the full path inside the artifact. Flux does nothing with a
path it cannot find, and the objects it applied before stay as they are; the Kustomization stays not
ready until the path is fixed in Git.

## A dependency that does not exist

A `dependsOn` naming a Kustomization that is not there, a typo or one that was renamed:

```
ana@laptop:~/setup$ flux get kustomizations probe-depends
NAME         	REVISION	SUSPENDED	READY	MESSAGE                                                                                                  
probe-depends	        	False    	False	dependency 'flux-system/stagin' not found: kustomizations.kustomize.toolkit.fluxcd.io "stagin" not found	
```

The Kustomization waits, and says what for. A renamed Kustomization is the usual cause, which is why
a rename in `clusters/` gets a search for the old name across the directory before it is merged.
