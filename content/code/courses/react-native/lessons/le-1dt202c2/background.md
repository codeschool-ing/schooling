---
title: Location while the app is closed
version: 1
---

**Background location is the most scrutinised permission an app can ask for.** Apple's review and
Google Play's both ask what it is for, Google Play asks for a video of the feature, and both platforms
remind the person, weeks later, that the app has been using it. It is right for navigation, for a run
tracker, for a delivery driver's app. For a study planner it would be hard to defend, so the planner does
not ask; but the shape of the code is worth knowing.

The cheapest form is a **geofence**: the app gives the system a circle, and the system wakes the app when
the phone enters or leaves it. The system watches with the radio it already uses for the network, so a
geofence costs far less battery than following the GPS. A reminder when the person arrives at the place
where they study would look like this:

```ts
// src/arrival.ts: a geofence around the place the person studies, watched by the system while the app
// is closed. Defined at the top level of a module the app imports, so it exists when the system wakes it.
import * as Location from "expo-location";
import * as TaskManager from "expo-task-manager";

const TASK = "planner-arrival";

type Event = { eventType: Location.GeofencingEventType; region: Location.LocationRegion };

TaskManager.defineTask<Event>(TASK, async ({ data, error }) => {
  if (error) return; // the system could not deliver the event; there is nothing to act on
  if (data.eventType === Location.GeofencingEventType.Enter) {
    // arrived: lesson 16 shows a notification from here
  }
});

export async function watchArrival(lat: number, lng: number) {
  if (!(await Location.requestForegroundPermissionsAsync()).granted) return "refused";
  if (!(await Location.requestBackgroundPermissionsAsync()).granted) return "foreground only";
  await Location.startGeofencingAsync(TASK, [
    { identifier: "study-place", latitude: lat, longitude: lng, radius: 200, notifyOnEnter: true, notifyOnExit: false },
  ]);
  return "watching";
}
```

- **The task is defined at the top level of a module**, not inside a component. When the system wakes
  the app for a geofence event, no screen is rendered; the task has to exist as soon as the JavaScript is
  loaded, so `defineTask` runs at import.
- **Background permission is a second request**, after foreground, and on Android 11 and later it is not
  even a dialog: the system sends the person to Settings to choose *Allow all the time*. A refusal there
  still leaves foreground location working, which is why the function says so.
- **The declarations change**: `isAndroidBackgroundLocationEnabled` and `isIosBackgroundLocationEnabled`
  in the plugin's options, and a sentence for `locationAlwaysAndWhenInUsePermission`, all of which the
  planner set to `false`.

To follow the position continuously, `startLocationUpdatesAsync` replaces `startGeofencingAsync`. On
Android that runs a **foreground service**, a notification that stays on screen for as long as the app is
tracking, so the person always knows.

*This file was checked by the TypeScript compiler against `expo-location` and `expo-task-manager` 58 and
was not run: background tasks need a phone, and a geofence needs one that moves.*
