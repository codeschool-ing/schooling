---
title: MMKV for what is needed at once, SecureStore for what is secret
version: 1
---

## MMKV

**AsyncStorage answers with a promise, so its value arrives after the first frame.** For a cache that is
fine. For the tab the planner was last on, it is not: the app would draw *Courses*, then jump to *This
week* a moment later. **MMKV** is a key-value store written in C++ that answers synchronously, in
microseconds, so the value is there while the first render runs:

```ts
// src/lastTab.ts: the tab the planner was last on, read synchronously, before the first frame.
import { createMMKV } from "react-native-mmkv";

const storage = createMMKV({ id: "planner" });

export function lastTab(): "Courses" | "Week" {
  return storage.getString("tab") === "Week" ? "Week" : "Courses";
}

export function rememberTab(tab: "Courses" | "Week") {
  storage.set("tab", tab);
}
```

`createMMKV` opens a store by id, and `getString`, `getNumber`, `getBoolean` and `set` read and write
immediately. The price is that MMKV is native code that Expo Go does not contain, so it needs a
development build. *This file was checked by the
TypeScript compiler against `react-native-mmkv` 4.3.2 and was not run; the planner does not install
MMKV, because AsyncStorage's one read at launch is all it needs.*

## SecureStore

**Neither AsyncStorage nor MMKV is encrypted by default**, and neither is SQLite. Anybody with the
phone's files, from a backup or a rooted device, can read them. For a secret, a sign-in token or a key,
there is `expo-secure-store`: on iOS it writes to the **Keychain**, and on Android it encrypts the value
with a key kept in the **Keystore**, which the system will not hand to anybody, the app included.

```ts
// src/token.ts: a sign-in token, in the Keychain on iOS and encrypted with a Keystore key on Android.
import * as SecureStore from "expo-secure-store";

const KEY = "planner.token";
// iOS: readable only while the phone is unlocked, and never restored onto another phone
const OPTIONS = { keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY };

export const saveToken = (token: string) => SecureStore.setItemAsync(KEY, token, OPTIONS);
export const readToken = () => SecureStore.getItemAsync(KEY, OPTIONS);
export const forgetToken = () => SecureStore.deleteItemAsync(KEY, OPTIONS);
```

**It is for short strings and few of them**: a value over 2048 bytes may fail to save, and the library
warns when one is written; each read also goes through the system's security layer. The option shown keeps the token
readable only while the phone is unlocked and stops iOS from restoring it onto another phone from a
backup. *This file was checked by the TypeScript compiler against `expo-secure-store` 58 and was not run:
the planner's server has no accounts, so there is no token to keep.*

The rule of the whole lesson fits on one line: **the plan in AsyncStorage, the journal in SQLite, a value
needed before the first frame in MMKV, and a secret only ever in SecureStore.**
