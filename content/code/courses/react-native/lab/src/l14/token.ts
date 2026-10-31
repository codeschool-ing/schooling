// src/token.ts: a sign-in token, in the Keychain on iOS and encrypted with a Keystore key on Android.
import * as SecureStore from "expo-secure-store";

const KEY = "planner.token";
// iOS: readable only while the phone is unlocked, and never restored onto another phone
const OPTIONS = { keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY };

export const saveToken = (token: string) => SecureStore.setItemAsync(KEY, token, OPTIONS);
export const readToken = () => SecureStore.getItemAsync(KEY, OPTIONS);
export const forgetToken = () => SecureStore.deleteItemAsync(KEY, OPTIONS);
