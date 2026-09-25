---
title: Changing edition without reinstalling
version: 1
---

The two computers arrived with Home after all; the shop had no Pro left. **Nothing has to be
reinstalled.** Because the editions are one system with more switched on, going up is a change of
licence:

1. *Settings > System > Activation*.
2. **Upgrade your edition of Windows**: either enter a **Pro product key**, or buy the upgrade from
   the Microsoft Store on the same screen.
3. Windows switches the features on and restarts. Files, programs and settings stay.

The licence then becomes a **digital licence** for Pro on that hardware, as in lesson 2, and a clean
reinstall later activates Pro on its own.

## Going down does not work that way

**Pro to Home is not an in-place change.** Windows has no switch to turn features off again; the way
down is a clean install of Home, with everything that means. It is one more reason to choose once and
choose Pro.

## Seeing what an installation is and can become

```sh
DISM /Online /Get-CurrentEdition            # Professional, Core (Home), Enterprise…
DISM /Online /Get-TargetEditions            # what this installation can be upgraded to
slmgr /dli                                  # the licence: edition, channel, activation state
```

**None of these were run for this lesson.** `DISM` calls Home **Core** and Pro **Professional**,
which are the internal names; you will meet them in logs and in the registry's `EditionID`. `slmgr`
also shows the **licence channel**:

| channel | how the licence came |
|---|---|
| **OEM** | with the PC, from its maker; tied to that machine |
| **Retail** | bought separately; can move to another PC, one at a time |
| **Volume** | an organisation's agreement, activated by the organisation |

An OEM licence **does not move** to a new PC. An office that throws away an old computer throws away
its Windows licence with it, which is normal and is the reason new PCs are bought with the edition
already on them.
