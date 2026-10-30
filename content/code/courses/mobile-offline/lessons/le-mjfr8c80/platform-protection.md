---
title: What the platform already encrypts, and the key it guards
version: 1
---

**Both platforms encrypt an app's files with a key tied to the lock screen, before the app writes a
line of code for it.** So the first question is not how to encrypt the planner's database, but when
the platform's encryption is in force and when the files are readable to anybody holding the phone.

## iOS: Data Protection classes

Every file on iOS belongs to a **protection class**, and the class says when its key is available:

| class | the file can be read |
|---|---|
| `complete` | only while the phone is unlocked; about ten seconds after it locks, the key is discarded |
| `completeUnlessOpen` | a file already open stays writable after the lock, for a download finishing |
| `completeUntilFirstUserAuthentication` | from the first unlock after the phone starts, until it is turned off; **the default for app files** |
| `none` | always, protected only by the device's own key |

The default is a compromise for apps that work in the background: after the first unlock, a sync
can read the database with the screen off. A planner whose data is sensitive and which syncs only
in the foreground can ask for `complete` instead.

## Android: file-based encryption

Android encrypts each user's files with **file-based encryption**, required on devices that ship
with Android 10 or later. An app's storage comes in two kinds:

- **Credential encrypted** (CE), the default: readable after the person unlocks the phone once
  since it started.
- **Device encrypted** (DE): readable as soon as the phone boots, before anybody unlocks it, for an
  alarm clock that must ring after a restart. An app reaches it through
  `createDeviceProtectedStorageContext()`, and a planner has no reason to.

## The key the hardware guards

For the app's own keys both platforms offer a store whose keys **cannot be copied out**: the
**Android Keystore**, backed by the phone's trusted execution environment or a separate security
chip (StrongBox), and the **iOS Keychain**, with the **Secure Enclave** for keys that never leave
the chip. The app asks the store to encrypt and decrypt; it never holds the key.

```kotlin
// Android: a 256-bit AES key generated inside the Keystore, never exported.
val spec = KeyGenParameterSpec.Builder(
        "planner-kek", KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
    .setKeySize(256)
    .build()
KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
    .apply { init(spec) }
    .generateKey()
```

```swift
// iOS: a file written in the strictest class, and a secret kept in the Keychain on this device only.
try data.write(to: url, options: .completeFileProtection)

let item: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "planner-dek",
    kSecValueData as String: dataKey,
    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
]
SecItemAdd(item as CFDictionary, nil)
```

```typescript
// React Native (Expo): expo-secure-store keeps the value in the Keychain or the Keystore.
import * as SecureStore from "expo-secure-store";

await SecureStore.setItemAsync("planner-dek", dataKeyBase64, {
  keychainAccessible: SecureStore.WHEN_UNLOCKED_THIS_DEVICE_ONLY,
});
```

*These listings are written from Android's, Apple's and Expo's documentation and were not run for
this course: there was no Android device, no Mac and no simulator.*

**`ThisDeviceOnly` matters more than it looks.** Without it, a Keychain item can travel to another
iPhone in an encrypted backup or through iCloud Keychain. A key that wraps the planner's data
should stay on the phone that made it, so a restored backup arrives encrypted with a key that did
not come along, which is the backup row of the last section's table answered.
