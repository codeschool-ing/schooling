// src/place.ts: where the phone is, asked only when the person has turned it on, and rounded to about a
// kilometre before anything keeps it.
import AsyncStorage from "@react-native-async-storage/async-storage";
import * as Location from "expo-location";

export type Place = { lat: number; lng: number };
const KEY = "note-place";

// Two decimal places: about 1.1 km north to south, and less east to west away from the equator.
export function rounded(lat: number, lng: number): Place {
  return { lat: Math.round(lat * 100) / 100, lng: Math.round(lng * 100) / 100 };
}

export async function notingPlace() {
  return (await AsyncStorage.getItem(KEY)) === "on";
}

// Turning it on is the moment to ask. A refusal leaves it off, and the caller is told which.
export async function setNotingPlace(on: boolean): Promise<"on" | "off" | "refused"> {
  if (on && !(await Location.requestForegroundPermissionsAsync()).granted) return "refused";
  await AsyncStorage.setItem(KEY, on ? "on" : "off");
  return on ? "on" : "off";
}

export async function currentPlace(): Promise<Place | null> {
  if (!(await notingPlace())) return null;
  const { coords } = await Location.getCurrentPositionAsync({ accuracy: Location.Accuracy.Low });
  return rounded(coords.latitude, coords.longitude);
}
