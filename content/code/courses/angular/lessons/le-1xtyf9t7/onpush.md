---
title: OnPush, checking only what asks to be checked
version: 1
---

**`ChangeDetectionStrategy.OnPush` tells Angular to skip a component during the walk unless the
component has been marked as needing it.** Under zone.js it was the way to stop checking everything
after everything, and in large applications it was the difference between a page that kept up and one
that stuttered. The previous section's middle line shows its rule biting: the timer set `count` to 1,
zone.js triggered a walk, and Angular skipped `TickOnPush`, because nothing had marked it.

What marks an OnPush component, so that the next walk visits it:

| what happened | example |
|---|---|
| **a signal its template reads changed** | `TickSignal`'s `count.set(1)`, which is why its line said 1 |
| **an event fired in its template** | a `(click)` on one of its buttons |
| **an input changed to a new value** | lesson 8: the parent passes a new object, not the same one changed |
| **somebody marked it by hand** | `inject(ChangeDetectorRef).markForCheck()`, the escape hatch older code is full of |

A plain field changed by a timer is none of these, so the OnPush component never knew. The fix older
code used was the last row: inject the `ChangeDetectorRef` and call `markForCheck()` after changing
the field. The fix today is the first row: put the value in a signal, and the signal does the marking.

**OnPush is also why lesson 6 insisted on new values.** An input that receives the same array, changed
in place, has not changed by OnPush's rule, exactly as a signal holding it has not, and for the same
reason: the comparison is of identity.

OnPush is not a default in Angular 21. `ng generate component` writes components without it, and they
are checked on every walk. The last section of this lesson changes that for the planner.
