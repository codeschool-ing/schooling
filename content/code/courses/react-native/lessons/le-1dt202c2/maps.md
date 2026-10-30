---
title: Maps
version: 1
---

**A map is a native view**, drawn by Google Maps on Android and Apple Maps on iOS, and in React Native it
comes from `react-native-maps`. `MapView` is the map; `Marker`, `Polyline`, `Polygon` and `Circle` go
inside it. A map of the journal's places would look like this:

```tsx
// src/PlacesMap.tsx: the journal's places as pins on a map, beside the text that says the same thing.
import MapView, { Marker } from "react-native-maps";

type Place = { lat: number; lng: number; sessions: number };

export function PlacesMap({ places }: { places: Place[] }) {
  if (places.length === 0) return null;
  const [first] = places;
  return (
    <MapView
      style={{ height: 240 }}
      initialRegion={{ latitude: first.lat, longitude: first.lng, latitudeDelta: 0.1, longitudeDelta: 0.1 }}
      accessibilityElementsHidden // the list above says it in words; a map read aloud says nothing useful
      importantForAccessibility="no-hide-descendants"
    >
      {places.map((p) => (
        <Marker key={`${p.lat},${p.lng}`} coordinate={{ latitude: p.lat, longitude: p.lng }} title={`${p.sessions} sessions`} />
      ))}
    </MapView>
  );
}
```

`initialRegion` is where the map opens: a centre and how many degrees of latitude and longitude fit on
screen. Each `Marker` is a pin, and `title` is what a tap on it shows.

**Three things a map costs, before it draws anything:**

- **On Android it needs a Google Maps API key**, from a Google Cloud project with the Maps SDK for Android
  turned on, written into `app.json` under `android.config.googleMaps.apiKey`. The key goes into the app,
  where anybody can read it, so it is restricted in Google's console to the app's package name and
  signing certificate. On iOS, Apple Maps needs no key.
- **It does not run on the web.** `react-native-maps` has no web version, so a web build needs a
  different component or a platform file, as in lesson 13.
- **A screen reader cannot read a map.** The component above hides itself from accessibility, because the
  line above it, *Studied at …*, already says the same thing in words. A map is a picture of
  information, and the information has to be somewhere else as well.

*This file was checked by the TypeScript compiler against `react-native-maps` 1.29.11, the version SDK 58
expects, and was not run: the planner does not install it, because a map with a key needs a Google Cloud
project this course does not have, and the planner's two or three places read well as a line of text.*
