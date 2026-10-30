---
title: Secrets go in the Keychain or the Keystore
version: 1
---

**The sandbox keeps other apps out, and that is the whole of its protection.** It does not encrypt
anything for you. A preferences file is text, exactly as readable as `prefs.json` was to `cat` two
sections ago, and it is copied to the backup with everything else. So the token that signs the
student in, which lets whoever holds it act as the student, does not belong in preferences, in a
JSON file or in the database. Both platforms keep a place built for this, and the advice in their
documentation is the same: use it.

| | where a secret goes | what the documentation, read on 30 October 2026, says it does |
|---|---|---|
| iOS | the **Keychain** | an encrypted database for small pieces of user data, such as passwords and keys |
| Android | the **Android Keystore** | holds cryptographic keys so that they are hard to extract, and the key material cannot be exported |
| React Native | a library over both, such as `expo-secure-store` | the Keychain on iOS; on Android, values encrypted with a Keystore key |

**The two native ones are not shaped alike, and the difference is worth seeing once.** The Keychain
stores the secret itself. The Android Keystore stores a *key*: the app asks it to make one, and the
key can then encrypt and decrypt inside the Keystore without its bytes ever reaching the app. The
token is encrypted with that key and the result can sit in an ordinary file, because without the key
it is noise. The fragments below are adapted from Apple's Keychain services documentation, Android's
Keystore guide and the documentation of `expo-secure-store`, and **were not compiled or run for this
course**:

```swift
let item: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: "planner-token",
    kSecValueData as String: Data(token.utf8),
]
let status = SecItemAdd(item as CFDictionary, nil) // errSecSuccess when it is stored
```

```kotlin
val spec = KeyGenParameterSpec.Builder(
    "planner-token-key",
    KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT,
).setBlockModes(KeyProperties.BLOCK_MODE_GCM)
    .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
    .build()
val generator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, "AndroidKeyStore")
generator.init(spec)
val key = generator.generateKey() // it encrypts the token; its bytes never leave the Keystore
```

```tsx
import * as SecureStore from "expo-secure-store";

await SecureStore.setItemAsync("planner-token", token);
const saved = await SecureStore.getItemAsync("planner-token");
```

## Two surprises worth knowing in advance

**A Keychain item can outlive the app.** `expo-secure-store`'s documentation warns that on iOS a
value it stored survives the app being uninstalled, and is there again if the same app is
reinstalled, and that this is not guaranteed and must not be relied on. So an app that wants a
fresh start after a reinstall has to clear what it finds, rather than assume there is nothing.

**A secret shipped inside the app is not a secret.** An API key written into the app's code or its
resources is in every copy of the app on every phone, and anyone who unpacks the app can read it.
The Keychain and the Keystore protect secrets the app *receives*, such as the student's sign-in
token. A key that must stay private stays on the server, and the app asks the server to use it.

## Where the planner's things ended up

| | the planner's | where it lives | backed up | the system may delete it |
|---|---|---|---|---|
| the student's data | `planner.db` | the app's data folder | yes | no |
| small settings | `prefs.json` | preferences | yes | no |
| a copy it can fetch again | `week.json` from lesson 14 | the cache | no | yes |
| the sign-in token | `planner-token` | the Keychain, or a file encrypted with a Keystore key | never as readable text | no |

**The rule under the table is short.** Ask whether the app could make the file again, and whether it
would hurt anyone to read it. The answers place every file the planner has. The `mobile-offline`
course goes deeper into each row: the sandbox in its lesson 1, key-value storage in its lesson 2,
databases in its lesson 3, and encryption at rest with the Keystore in its lesson 19.
