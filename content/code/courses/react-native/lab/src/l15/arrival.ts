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
