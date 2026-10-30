// src/push.ts: this phone's address for push notifications, from Expo's push service, for the server to
// keep. Only after the person has allowed notifications: without that, a push would never be shown.
import Constants from "expo-constants";
import * as Notifications from "expo-notifications";

export async function pushAddress(): Promise<string | null> {
  if (!(await Notifications.getPermissionsAsync()).granted) return null;
  const projectId = Constants.expoConfig?.extra?.eas?.projectId; // written by `eas init`, lesson 20
  const { data } = await Notifications.getExpoPushTokenAsync({ projectId });
  return data; // "ExponentPushToken[…]"
}
