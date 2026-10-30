---
title: O que a plataforma já cifra, e a chave que ela guarda
version: 1
---

**As duas plataformas cifram os arquivos de um app com uma chave ligada à tela de bloqueio, antes
de o app escrever uma linha de código para isso.** Então a primeira pergunta não é como cifrar o
banco do planner, e sim quando a criptografia da plataforma está valendo e quando os arquivos ficam
legíveis para qualquer um que segure o celular.

## iOS: classes de Proteção de Dados

Todo arquivo no iOS pertence a uma **classe de proteção**, e a classe diz quando a chave dele está
disponível:

| classe | o arquivo pode ser lido |
|---|---|
| `complete` | só com o celular desbloqueado; uns dez segundos depois do bloqueio, a chave é descartada |
| `completeUnlessOpen` | um arquivo já aberto continua gravável depois do bloqueio, para um download terminar |
| `completeUntilFirstUserAuthentication` | do primeiro desbloqueio depois de o celular ligar até ele ser desligado; **o padrão para os arquivos de um app** |
| `none` | sempre, protegido só pela chave do próprio aparelho |

O padrão é um meio-termo para apps que trabalham em segundo plano: depois do primeiro desbloqueio,
uma sincronização consegue ler o banco com a tela apagada. Um planner cujo dado é sensível e que só
sincroniza em primeiro plano pode pedir `complete` em vez disso.

## Android: criptografia baseada em arquivo

O Android cifra os arquivos de cada usuário com **criptografia baseada em arquivo**, obrigatória
nos aparelhos que saem de fábrica com Android 10 ou mais novo. O armazenamento de um app vem em dois
tipos:

- **Cifrado por credencial** (CE), o padrão: legível depois de a pessoa desbloquear o celular uma
  vez desde que ele ligou.
- **Cifrado pelo aparelho** (DE): legível assim que o celular inicia, antes de alguém desbloquear,
  para um despertador que precisa tocar depois de uma reinicialização. Um app o alcança por
  `createDeviceProtectedStorageContext()`, e um planner não tem motivo para isso.

## A chave que o hardware guarda

Para as chaves do próprio app, as duas plataformas oferecem um cofre cujas chaves **não podem ser
copiadas para fora**: o **Android Keystore**, apoiado no ambiente de execução confiável do celular
ou num chip de segurança separado (StrongBox), e o **Keychain** do iOS, com o **Secure Enclave**
para chaves que nunca saem do chip. O app pede ao cofre para cifrar e decifrar; ele nunca segura a
chave.

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

*Estas listagens foram escritas a partir da documentação do Android, da Apple e do Expo e não foram
rodadas para este curso: não havia aparelho Android, Mac nem simulador.*

**O `ThisDeviceOnly` importa mais do que parece.** Sem ele, um item do Keychain pode viajar para
outro iPhone num backup cifrado ou pelo Keychain do iCloud. Uma chave que embrulha o dado do
planner deve ficar no celular que a criou, então um backup restaurado chega cifrado com uma chave
que não veio junto, que é a linha do backup na tabela da seção anterior respondida.
