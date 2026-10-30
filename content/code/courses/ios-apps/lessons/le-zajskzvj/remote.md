---
title: Remote notifications, and the token that addresses one phone
version: 1
---

**A remote notification comes from a server, through Apple's Push Notification service, to one app on
one device.** The app does not keep a connection open for it; the phone does, to APNs, for every app at
once. What the planner's server needs is an address, and Apple's documentation on registering with APNs
calls it a **device token**: "unique to both the device and your app", and the server must have it
before it can deliver anything. None of this was run for the course: it needs a device, a paid
developer account, and an APNs key, and lesson 21 is where the account comes in.

## Four steps, two of them on the phone

| step | who | what happens |
|---|---|---|
| 1 | Xcode, once | the *Push Notifications* capability adds the `aps-environment` entitlement to the app |
| 2 | the app, each launch | `UIApplication.shared.registerForRemoteNotifications()` asks APNs for the token |
| 3 | the app | `application(_:didRegisterForRemoteNotificationsWithDeviceToken:)` receives it, and sends it to the planner's server |
| 4 | the server | sends the payload of section 07 to APNs with that token, signed with the team's key |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l17-push\" aria-label=\"Three columns, from left to right: the planner on the phone, Apple&#x27;s Push Notification service, and the planner&#x27;s server. Time runs downwards. First the app asks APNs to register and receives a device token. Second the app sends that token to the planner&#x27;s server, which stores it with the account. Later, when a session is added on another device, the server sends a payload with the token to APNs, and APNs delivers it to the phone, which shows it.\"><defs><marker id=\"l17-push-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l17-push-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l17-push-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"l17-push-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"15\" y=\"16\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the planner, on the phone</text><path d=\"M110 52 L110 312\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"265\" y=\"16\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">APNs</text><path d=\"M360 52 L360 312\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><rect x=\"515\" y=\"16\" width=\"190\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">the planner's server</text><path d=\"M610 52 L610 312\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"5 4\"></path><path d=\"M114 82 L356 82\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-phosphor)\"></path><text x=\"235\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">registerForRemoteNotifications()</text><path d=\"M356 118 L114 118\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-phosphor)\"></path><text x=\"235\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">device token</text><path d=\"M114 160 L606 160\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-amber)\"></path><text x=\"360\" y=\"150\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the token, sent once per launch and stored with the account</text><text x=\"610\" y=\"196\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">later: a session added elsewhere</text><path d=\"M606 236 L364 236\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-amber)\"></path><text x=\"485\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">payload + token</text><path d=\"M356 276 L114 276\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l17-push-ah-amber)\"></path><text x=\"235\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the notification</text></svg>", "caption": "The token goes from the phone to the server, again at every launch; every notification then goes from the server to APNs, and from APNs to the phone."}
```

Apple's documentation for step 2 says to register on every launch, and that the token arrives in the app
delegate, the same `AppDelegate` as section 05:

```swift
// AppDelegate.swift, the token
func application(_ application: UIApplication,
                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let token = deviceToken.map { String(format: "%02x", $0) }.joined()
    Task { await sendTokenToServer(token) }
}

func application(_ application: UIApplication,
                 didFailToRegisterForRemoteNotificationsWithError error: Error) {
    pushError = error        // shown in the reminders settings, never swallowed
}
```

**The token is data, sent as hexadecimal text.** It is not a secret in the way a password is, but it is
the address of one app on one person's phone, so the server treats it as personal data: it is stored
against the account, and removed when the account is.

The documentation is explicit on two points worth repeating. A token belongs to one app: two apps on the
same phone get different ones. And the app registers and receives its token at every launch, so it
sends the one it has just received rather than trusting the last it sent; a server holding a token that
is no longer the phone's sends to nobody, and nothing fails where anyone can see it.

## Permission, again

Registering for a token does not need the person's permission; showing something does. Apple's
documentation for `registerForRemoteNotifications()` says that without authorization from section 02,
"the system delivers all remote notifications to your app silently". So the planner asks in the same
moment as for its local reminders, and the one answer covers both.

## What the planner sends, and why so little

The planner's server sends one kind of push: a session was added on another of the student's devices.
It could instead keep the phone in step silently, with background pushes, and Apple's documentation for
those says the system treats them as low priority, does not guarantee their delivery, and may throttle
them, and asks for no more than two or three an hour. Lesson 16 is about what iOS
allows in the background, and the planner's answer there, refreshing when the app opens, holds here as
well: **a push says that something happened, and the app fetches what**.
