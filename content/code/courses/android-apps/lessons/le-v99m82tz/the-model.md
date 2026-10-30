---
title: Three kinds of permission, and the one that asks
version: 1
---

**Most permissions an app holds were never asked for.** Lesson 18 found four in the merged manifest,
`WAKE_LOCK`, `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED` and `FOREGROUND_SERVICE`, and the student
saw none of them: they are *normal* permissions, granted at install because what they protect is not
private. Android sorts permissions into three groups by what is at stake, and only one of them
involves the student at run time.

| kind | what it protects | how it is granted | examples |
|---|---|---|---|
| **normal** | nothing private | at install, by declaring it | `INTERNET`, `WAKE_LOCK` |
| **runtime**, which Google's documentation also calls *dangerous* | the student's data or the phone's sensors | by the student, in a dialog, while the app runs | `POST_NOTIFICATIONS`, `CAMERA`, `ACCESS_FINE_LOCATION` |
| **special** | something powerful enough to need a settings screen | by the student, on a dedicated page in Settings | exact alarms, drawing over other apps |

This lesson is about the middle row. The planner needs one runtime permission,
`POST_NOTIFICATIONS`, for lesson 19's reminders, and the same pattern serves the camera or the
location; `mobile-fundamentals` lesson 12 discusses which of those an app should ask for at all.

## A runtime permission has a history

The dialog is the system's, and the system remembers what the student said. **From Android 11, two
refusals of the same permission are final**: after the second, a request is answered with a refusal
at once, without showing the dialog, and only the app's page in Settings can change it. That is
what the figure follows:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l20-twice\" aria-label=\"The life of a runtime permission on Android 11 and later. Never asked: the app may show the system dialog. If the student allows, it is granted. If the student denies once, Android reports that the app should explain, and the app may show the dialog a second time. If the student denies again, the system stops showing the dialog: the app's request is refused at once, and only the app's settings screen, where the student can allow it, can change the answer.\"><defs><marker id=\"l20-twice-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l20-twice-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l20-twice-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"16\" y=\"30\" width=\"120\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"76.0\" y=\"53\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">never asked</text><rect x=\"236\" y=\"30\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"311.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">denied once</text><text x=\"311.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">explain, then ask</text><rect x=\"486\" y=\"30\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"561.0\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">denied twice</text><text x=\"561.0\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no more dialogs</text><rect x=\"236\" y=\"170\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"311.0\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">granted</text><rect x=\"486\" y=\"170\" width=\"150\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"561.0\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">the app's settings screen</text><path d=\"M136 53 L234 53\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-twice-ah-amber)\"></path><text x=\"185\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">deny</text><path d=\"M386 53 L484 53\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-twice-ah-amber)\"></path><text x=\"435\" y=\"44\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">deny</text><path d=\"M76 76 L76 193 L234 193\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-twice-ah-phosphor)\"></path><text x=\"84\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">allow</text><path d=\"M311 76 L311 168\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l20-twice-ah-phosphor)\"></path><text x=\"318\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">allow</text><path d=\"M561 76 L561 168\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l20-twice-ah-wire)\"></path><text x=\"568\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">only way back</text><path d=\"M486 205 L388 205\" stroke=\"var(--wire)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#l20-twice-ah-wire)\"></path><text x=\"437\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">allowed there</text></svg>", "caption": "Two refusals end the conversation: after the second, the request is answered with a no before any dialog appears, and only the settings screen can change it."}
```

Between the first refusal and the second, Android tells the app something useful.
`shouldShowRequestPermissionRationale` returns `true`, which means: the student said no once, and an
explanation before asking again is appropriate. It returns `false` before the first request and
**also** after the second refusal, which makes the two states hard to tell apart; section 04 is the
code that does it, and section 06 tests the whole path.

## When to ask

**Ask when the student does something that needs the permission, not when the app starts.** A
dialog on the first screen asks for notifications before the student knows what the app would
notify about, and a refusal there costs one of the two chances. The planner asks when the student
taps "Turn on reminders", on a card that has already said what a reminder is. Google's documentation
gives the same advice, and the Android 13 notification permission is the clearest case: an app
targeting 33 or later decides that moment for itself, as lesson 19 section 05 described.

The order the rest of the lesson builds, then: the request itself, in section 03; a pure function
that turns Android's answers into what the card should offer, in section 04; the card in its three
states, in section 05; and a test that walks the whole path, refusal, explanation, second refusal,
settings, in section 06.
