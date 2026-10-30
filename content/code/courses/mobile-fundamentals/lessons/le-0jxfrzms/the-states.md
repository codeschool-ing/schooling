---
title: The states of one permission, and the two kinds of no
version: 1
---

**A runtime permission is in one of a few states, and the state decides whether asking again shows a
dialog at all.** Before anything is asked it is *not asked*. The person answers yes and it is
*granted*. They answer no, and here the platforms part: what follows a "no" is the one rule in this
lesson that differs between them, and it is the rule that decides how careful an app has to be.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l12-two-noes\" aria-label=\"The two platforms' no, compared as two rows of steps. Android: not asked, then a dialog, then no, then denied with the rationale call returning true, then a second dialog, then no, then denied for good. iOS: not asked, then a dialog, then no, then denied for good. From denied for good, on both, the only way back is the person turning the permission on in Settings.\"><defs><marker id=\"l12-two-noes-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l12-two-noes-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"14\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Android</text><text x=\"14\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">iOS</text><rect x=\"76\" y=\"32\" width=\"84\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">not asked</text><rect x=\"168\" y=\"32\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"203.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">dialog</text><path d=\"M160 50 L168 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"246\" y=\"32\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"276.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">no</text><path d=\"M238 50 L246 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"314\" y=\"32\" width=\"110\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"369.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">denied</text><text x=\"369.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">rationale: true</text><path d=\"M306 50 L314 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"432\" y=\"32\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"467.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">dialog</text><path d=\"M424 50 L432 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"510\" y=\"32\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">no</text><path d=\"M502 50 L510 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"578\" y=\"32\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"643.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">denied for good</text><path d=\"M570 50 L578 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"76\" y=\"122\" width=\"84\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"118.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">not asked</text><rect x=\"168\" y=\"122\" width=\"70\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"203.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">dialog</text><path d=\"M160 140 L168 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"246\" y=\"122\" width=\"60\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"276.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">no</text><path d=\"M238 140 L246 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"578\" y=\"122\" width=\"130\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"643.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">denied for good</text><path d=\"M306 140 L578 140\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l12-two-noes-ah-paper-dim)\"></path><rect x=\"548\" y=\"196\" width=\"156\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"626.0\" y=\"210.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">the person turns it</text><text x=\"626.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">on in Settings</text><path d=\"M626 158 L626 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-two-noes-ah-phosphor)\"></path><path d=\"M708 50 L715 50 L715 216 L704 216\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l12-two-noes-ah-phosphor)\"></path></svg>", "caption": "Android gives one more dialog after a refusal, and iOS none. After the final no, asking shows nothing, on both."}
```

## Android: the second no is final

**On Android the dialog comes back once after a refusal, and then never again.** Android's
documentation on requesting permissions says that if the person taps Deny for a permission more than
once during the app's life on that device, they no longer see the system dialog when the app asks
again: the action "implies 'don't ask again'" and "is considered a permanent denial". From then on, a
request answers *denied* at once, with no dialog for the person to see.

**Between the first no and the second, Android tells the app it is in that window.**
`shouldShowRequestPermissionRationale()` returns `true` after one refusal, which the documentation
reads as the moment to show the app's own explanation of why it wants the permission, before asking
the last time. Once the denial is permanent it returns `false` again, the same answer it gives before
anything was asked. So the app cannot tell "never asked" from "refused for good" by that call alone,
and has to remember for itself whether it has asked.

## iOS: the first no is final

**On iOS the dialog appears once, and whatever the person answers is stored.** Apple's documentation
on requesting access to protected resources says that if the person denies permission, the access
that prompted it "and any further attempts" fail. The notification call says the same in its own
words: later calls "don't prompt the person again". There is no rationale call and no second chance;
an app that wants to explain itself has to do it *before* the one dialog it will get.

| | Android | iOS |
|---|---|---|
| the first dialog | when the app first asks | when the app first asks |
| after one no | the dialog can be shown once more | no dialog again |
| a call that says "explain first" | `shouldShowRequestPermissionRationale()` | none |
| after the final no | asking answers *denied* at once | asking answers *denied* at once |
| the way back | the person turns it on in Settings | the person turns it on in Settings |

## Yes, but less: approximate and limited

**Both platforms let the person grant part of what was asked, and an app has to work with the
part.** Location is the clearest case. Android's documentation on location permissions says the
person can grant *approximate* location, which it describes as accurate to within about 3 square
kilometres, even when the app asked for precise, and that the app "should still work" with it. iOS
has the same choice, reported as reduced accuracy.

**Photos have their own partial yes.** iOS lets the person grant *limited* access to the photo
library, a selection of photos rather than all of them. Android 14 added *Selected Photos Access*,
with which, its documentation says, "users grant apps access to specific images and videos". In both
cases the app sees only what was chosen, and the right reaction is to work with those photos rather
than to ask for the rest.

**A partial yes is still a yes, and the app should not argue with it.** An app that receives
approximate location and immediately asks again for precise, with no reason the person can see, is
asking them to undo a decision they just made. The planner has no location to worry about, but the
habit is the one this whole lesson is about: take the answer, keep the app working, and ask for more
only when the person reaches something that needs it.
