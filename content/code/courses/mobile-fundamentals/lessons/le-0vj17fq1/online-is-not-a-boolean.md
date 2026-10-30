---
title: Online is not a yes or a no
version: 1
---

**The picture most people start with is a switch: the phone is online, or it is offline, and an
app checks which before it asks for anything.** A phone's network does not behave like that. It
changes under the app many times a day, and most of the changes leave it neither cleanly on nor
cleanly off. Five of them are worth knowing by name, because each one fails in a different way.

| what happens | what the system reports | what the app's request meets |
|---|---|---|
| the student walks out of the house, and Wi-Fi hands over to mobile data | the default network changes | a request on the old network dies halfway, with an error or with silence |
| a lift, a tunnel, the far end of a car park | often still a network, with no signal behind it | silence: nothing refuses, nothing answers |
| airplane mode | no network at all | an error at once, which is the easy case |
| a café's Wi-Fi that wants a login first | a Wi-Fi network, but not a validated one | an answer from the café's login page, not from your server |
| mobile data on a small monthly allowance | a network marked as metered | it works, and every megabyte costs the user money |

**Airplane mode is the only row where "offline" is the right word**, and it is the one that
causes the least trouble: the request fails in a millisecond and the app can say so. The rows
that hurt are the ones where a network exists. In the lift the phone still holds a connection to
the mast, the request leaves, and nothing comes back. The app is not told it failed. It is told
nothing, and waits.

**The captive portal is the strangest of the five.** The phone has joined the café's Wi-Fi, the
network is up, and every request to any address is answered, by the café's own page asking the user
to accept its terms. An app that trusts "connected" and reads the answer as its own JSON fails
somewhere unexpected, on a parse error about an HTML page.

## What the system can tell you

**Both platforms let an app ask about the network, and both answer a narrower question than it
looks.** Android's documentation on reading network state, as read on 30 October 2026, is explicit
about it. A network with the `INTERNET` capability is one that is *set up* to reach the internet,
"and not actual ability to reach public servers", and the example it gives is a captive portal. The
nearer thing is `VALIDATED`, which the system sets when a probe of its own reached the internet,
and the same page warns that a validated network can still lose its connection because of a poor
signal. iOS reports a path's `status`, and whether it is *expensive*, meaning mobile data or a
personal hotspot, or *constrained*, meaning the user turned on Low Data Mode.

The three fragments below register for changes to the network, one per platform. They are adapted
from Android's guide to network state, Apple's reference for `NWPathMonitor` and the README of the
`@react-native-community/netinfo` library, and **they were not compiled or run for this course**:

```kotlin
val cm = context.getSystemService(ConnectivityManager::class.java)
cm.registerDefaultNetworkCallback(object : ConnectivityManager.NetworkCallback() {
    override fun onAvailable(network: Network) { /* a default network exists */ }
    override fun onLost(network: Network) { /* and now it does not */ }
    override fun onCapabilitiesChanged(network: Network, caps: NetworkCapabilities) {
        val probed = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_VALIDATED)
        val free = caps.hasCapability(NetworkCapabilities.NET_CAPABILITY_NOT_METERED)
    }
})
```

```swift
let monitor = NWPathMonitor()
monitor.pathUpdateHandler = { path in
    let usable = path.status == .satisfied
    let costly = path.isExpensive      // mobile data, or a personal hotspot
    let lowData = path.isConstrained   // the user turned on Low Data Mode
}
monitor.start(queue: DispatchQueue(label: "network"))
```

```tsx
import NetInfo from "@react-native-community/netinfo";

const unsubscribe = NetInfo.addEventListener((state) => {
  const connected = state.isConnected;           // a network exists
  const reachable = state.isInternetReachable;   // null until a check has answered
  const costly = state.details?.isConnectionExpensive;
});
```

**None of the three knows anything about your server.** "The internet is reachable" means a probe
reached Google, or Apple, or whatever address the library was configured with; NetInfo's README
names `https://clients3.google.com/generate_204` as its default. Your server can be down, slow or
blocked while every one of those flags says yes.

## So what are they for

**Use the network state to decide whether to try, and to choose what to try. Never use it as the
verdict.** Three uses hold up:

- **Waiting for a network that is absent.** With no network at all, there is no point sending the
  request; an app can wait for `onAvailable`, or for the path to become satisfied, and send it then.
- **Respecting the cost.** On a metered or constrained network, the planner can refresh the week,
  which is a few hundred bytes, and leave the download of a course's videos for Wi-Fi.
- **Retrying when the network comes back.** A request that failed in the lift is worth sending
  again the moment the system reports a change, rather than on a timer.

The only test of whether your server answers is a request to your server, with a limit on how long
you wait for it. The rest of this lesson builds that request against a server that misbehaves on
purpose.
