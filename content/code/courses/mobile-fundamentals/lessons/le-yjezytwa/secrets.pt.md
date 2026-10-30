---
title: Segredos vão para o Keychain ou o Keystore
version: 1
---

**A sandbox mantém os outros apps do lado de fora, e essa é toda a proteção que ela dá.** Ela não
criptografa nada por você. Um arquivo de preferências é texto, tão legível quanto o `prefs.json` foi
para o `cat` duas etapas atrás, e ele é copiado para o backup junto com todo o resto. Então o token
que mantém a aluna conectada, que deixa quem o tiver agir como ela, não pertence às preferências, a
um arquivo JSON nem ao banco de dados. As duas plataformas têm um lugar feito para isso, e o
conselho da documentação delas é o mesmo: use-o.

| | onde vai um segredo | o que a documentação, lida em 30 de outubro de 2026, diz que ele faz |
|---|---|---|
| iOS | o **Keychain** | um banco de dados criptografado para pequenos dados do usuário, como senhas e chaves |
| Android | o **Android Keystore** | guarda chaves criptográficas de modo que sejam difíceis de extrair, e o material da chave não pode ser exportado |
| React Native | uma biblioteca sobre os dois, como o `expo-secure-store` | o Keychain no iOS; no Android, valores criptografados com uma chave do Keystore |

**Os dois nativos não têm o mesmo formato, e vale ver a diferença uma vez.** O Keychain guarda o
próprio segredo. O Android Keystore guarda uma *chave*: o app pede que ele crie uma, e a chave então
criptografa e descriptografa dentro do Keystore sem que os bytes dela cheguem ao app. O token é
criptografado com essa chave e o resultado pode ficar num arquivo comum, porque sem a chave ele é
ruído. Os trechos abaixo foram adaptados da documentação de Keychain services da Apple, do guia do
Keystore do Android e da documentação do `expo-secure-store`, e **não foram compilados nem
executados para este curso**:

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

## Duas surpresas que vale conhecer antes

**Um item do Keychain pode sobreviver ao app.** A documentação do `expo-secure-store` avisa que, no
iOS, um valor guardado por ela sobrevive à desinstalação do app, e está lá de novo se o mesmo app
for reinstalado, e que isso não é garantido e não deve ser usado como premissa. Então um app que quer
começar do zero depois de uma reinstalação precisa limpar o que encontrar, em vez de supor que não há
nada.

**Um segredo que vai dentro do app não é segredo.** Uma chave de API escrita no código do app ou nos
recursos dele está em toda cópia do app em todo celular, e qualquer pessoa que desempacote o app
consegue lê-la. O Keychain e o Keystore protegem segredos que o app *recebe*, como o token de login
da aluna. Uma chave que precisa ficar privada fica no servidor, e o app pede ao servidor que a use.

## Onde as coisas do planner foram parar

| | o do planner | onde mora | com backup | o sistema pode apagar |
|---|---|---|---|---|
| os dados da aluna | `planner.db` | a pasta de dados do app | sim | não |
| configurações pequenas | `prefs.json` | preferências | sim | não |
| uma cópia que dá para buscar de novo | `week.json` da aula 14 | o cache | não | sim |
| o token de login | `planner-token` | o Keychain, ou um arquivo criptografado com uma chave do Keystore | nunca como texto legível | não |

**A regra por baixo da tabela é curta.** Pergunte se o app conseguiria fazer o arquivo de novo, e se
lê-lo faria mal a alguém. As respostas põem no lugar cada arquivo que o planner tem. O curso
`mobile-offline` vai mais fundo em cada linha: a sandbox na aula 1, armazenamento de chave e valor na
aula 2, bancos de dados na aula 3, e criptografia em repouso com o Keystore na aula 19.
