---
title: App Transport Security, and the http in this lesson
version: 1
---

**Every URL in this lesson starts with `http://`, and on an iPhone that is refused unless the app
says otherwise.** Apple calls the rule App Transport Security, ATS: an app's connections through
`URLSession` must use HTTPS, with a certificate the system trusts and a modern version of TLS. A
plain `http` request to a server on the internet fails before it leaves the phone. Nothing in this
section was run, because the rule lives in iOS and not in the open-source Foundation, which is also
why every request in this lesson worked on Linux without asking. It is written from Apple's
documentation for `NSAppTransportSecurity` and `NSAllowsLocalNetworking`, read on 30 October 2026.

## Why the rule exists

An unencrypted request can be read and changed by anybody between the phone and the server: the
café's Wi-Fi, a compromised router, a network that injects advertising. A study planner's sessions
are not secret, but the same connection carries the account's credentials in any real app, and an
answer that can be changed in transit is an answer the app cannot believe. **ATS makes the safe
choice the default, so that being unsafe takes a line somebody has to write and somebody else can
review.**

## The exception this course needs, and no more

The planner's server listens on `127.0.0.1` and speaks plain HTTP, which is fine on your own
machine and is exactly what ATS refuses. Apple's documentation says something precise about it:
iOS 10 to iOS 16 allowed connections to IP addresses, `.local` names and unqualified names by
default, and **iOS 17 stopped allowing IP addresses by default.** The key that allows those local
connections again, and nothing else, is `NSAllowsLocalNetworking`. In the app target's
`Info.plist`, during development:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- Info.plist (the development keys only) -->
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsLocalNetworking</key>
        <true/>
    </dict>
</dict>
</plist>
```

The simulator shares the Mac's network, so `127.0.0.1` inside the simulator is the Mac itself and
reaches the server running in a terminal there. A real iPhone is a different machine: its
`127.0.0.1` is the phone, and it would reach the server by the Mac's address on the local network
instead.

## The exception this course does not use

`NSAllowsArbitraryLoads` turns ATS off for every connection, and it is the line a search for the
error message most often suggests. **It is the wrong fix and App Review asks about it**: Apple's
documentation says an app that sets it must justify it when it is submitted. The planner's real
server would be reached over HTTPS, and the development exception above would be in an
`Info.plist` used only by the `Debug` configuration, which the target's `INFOPLIST_FILE` build setting
can name per configuration.

| key | what it allows | when it is right |
|---|---|---|
| none | HTTPS only, with ATS's checks | a production app talking to its own server |
| `NSAllowsLocalNetworking` | plain connections to local names and IP addresses | development against a server on your machine |
| `NSExceptionDomains` | a lower bar for named domains only | a third party's server you cannot change, with a reason |
| `NSAllowsArbitraryLoads` | everything | almost never, and it has to be justified to review |
