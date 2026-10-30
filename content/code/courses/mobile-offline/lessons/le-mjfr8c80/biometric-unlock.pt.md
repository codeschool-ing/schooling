---
title: Desbloqueio por biometria que libera uma chave, não um booleano
version: 1
---

**Uma digital ou um reconhecimento facial só vale alguma coisa se passar por ele for o que
desbloqueia o dado.** A implementação comum pede ao sistema para conferir a pessoa, recebe
`success: true` e então abre um banco cuja chave estava disponível o tempo todo. Qualquer coisa que
alcance o código do app, o malware da primeira seção desta aula ou um depurador num celular com root,
vira esse booleano ou chama o código que vem depois dele, e a conferência é uma cortina.

O desenho que se sustenta amarra a conferência à **chave**. A chave de cifrar chaves é criada no
Keystore ou no Keychain com uma regra: ela só pode ser usada depois de uma conferência biométrica, e
só por um instante. Passar na conferência não conta nada ao app; ela deixa o hardware desembrulhar a
chave de dados. Sem conferência, sem chave, sem dado, e nenhuma linha do código do app muda isso.

## As três plataformas

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

*Estas listagens foram escritas a partir da documentação do Android, da Apple e do Expo e não foram
rodadas para este curso.* No Expo, o `authenticateAsync()` do `expo-local-authentication` devolve
`{ success: true }`, que é exatamente o booleano contra o qual esta seção avisa quando ele é a única
coisa entre a pessoa e o dado. Ele serve para um passo de "confirme que é você" diante de algo que o
servidor confere de novo; ele não serve como tranca do dado.

## Duas consequências para desenhar

- **Cadastrar uma digital nova invalida a chave**, por `setInvalidatedByBiometricEnrollment` no
  Android e `biometryCurrentSet` no iOS. Isso é de propósito: alguém que descobre a senha do
  aparelho poderia, de outro modo, cadastrar o próprio dedo. O planner então não consegue
  desembrulhar a chave de dados, e recorre a entrar de novo e ressincronizar, como fez a chave
  ausente da seção anterior.
- **Precisa existir outra porta.** Uma pessoa cujo rosto não é reconhecido no escuro, ou que não pode
  usar biometria, precisa da senha do aparelho ou de uma senha. A biometria é uma comodidade por cima
  de um segredo, nunca a única porta.
