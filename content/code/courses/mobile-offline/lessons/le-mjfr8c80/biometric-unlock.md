---
title: Biometric unlock that releases a key, not a boolean
version: 1
---

**A fingerprint or a face check is worth something only if passing it is what unlocks the data.**
The common implementation asks the system to check the person, receives `success: true`, and then
opens a database whose key was available all along. Anything that can reach the app's code, the
malware of this lesson's first section, or a debugger on a rooted phone, flips that boolean or calls
the code after it, and the check is a curtain.

The design that holds ties the check to the **key**. The key-encryption key is created in the
Keystore or Keychain with a rule: it may be used only after a biometric check, and only for a
moment. Passing the check does not tell the app anything; it lets the hardware unwrap the data key.
No check, no key, no data, and no line of the app's code can change that.

## The three platforms

```kotlin
// Android: the key may only be used after a strong biometric, and each use needs a new one.
val spec = KeyGenParameterSpec.Builder("planner-kek",
        KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
    .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
    .setUserAuthenticationRequired(true)
    .setUserAuthenticationParameters(0, KeyProperties.AUTH_BIOMETRIC_STRONG)
    .setInvalidatedByBiometricEnrollment(true)
    .build()

// The prompt is given the cipher, and the cipher only works inside the success callback.
val cipher = Cipher.getInstance("AES/GCM/NoPadding")
cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(128, nonce))
biometricPrompt.authenticate(promptInfo, BiometricPrompt.CryptoObject(cipher))
// onAuthenticationSucceeded: result.cryptoObject!!.cipher!!.doFinal(wrappedDataKey)
```

```swift
// iOS: the Keychain item can be read only after Face ID or Touch ID, by the fingers or face
// enrolled now. Reading it shows the prompt; there is no separate check to skip.
let access = SecAccessControlCreateWithFlags(
    nil, kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly, .biometryCurrentSet, nil)!
let item: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "planner-dek",
    kSecValueData as String: dataKey,
    kSecAttrAccessControl as String: access,
]
SecItemAdd(item as CFDictionary, nil)
```

```typescript
// React Native (Expo): requireAuthentication ties the stored value to the biometric check.
import * as SecureStore from "expo-secure-store";

await SecureStore.setItemAsync("planner-dek", dataKeyBase64, { requireAuthentication: true });
const dataKey = await SecureStore.getItemAsync("planner-dek", {
  authenticationPrompt: "Unlock your planner",
});
```

*These listings are written from Android's, Apple's and Expo's documentation and were not run for
this course.* In Expo, `expo-local-authentication`'s `authenticateAsync()` returns
`{ success: true }`, which is exactly the boolean this section warns against when it is the only
thing between the person and the data. It is right for a "confirm it is you" step in front of
something the server checks again; it is wrong as the lock on the data.

## Two consequences to design for

- **Enrolling a new fingerprint invalidates the key**, by `setInvalidatedByBiometricEnrollment` on
  Android and `biometryCurrentSet` on iOS. That is deliberate: somebody who learns the passcode
  could otherwise add their own finger. The planner then cannot unwrap its data key, and falls back
  to signing in again and resyncing, as the last section's missing key did.
- **There must be another way in.** A person whose face is not recognised in the dark, or who cannot
  use biometrics at all, needs the passcode or a password. A biometric is a convenience over a
  secret, never the only door.
