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
