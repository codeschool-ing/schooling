---
title: MMKV para o que é preciso na hora, SecureStore para o que é segredo
version: 1
---

## MMKV

**O AsyncStorage responde com uma promise, então o valor chega depois do primeiro quadro.** Para um cache,
tudo bem. Para a aba em que o planner estava por último, não: o app desenharia *Courses* e pularia para
*This week* um instante depois. O **MMKV** é um armazenamento chave-valor escrito em C++ que responde de
forma síncrona, em microssegundos, então o valor está lá enquanto a primeira renderização roda:

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

O `createMMKV` abre um armazenamento por id, e `getString`, `getNumber`, `getBoolean` e `set` leem e
escrevem na hora. O preço é que o MMKV é código nativo que o Expo Go não traz, então ele precisa de um
development build. *Este arquivo foi conferido pelo compilador de TypeScript contra o `react-native-mmkv`
4.3.2 e não foi executado; o planner não instala o MMKV, porque a única leitura do AsyncStorage na
abertura é tudo de que ele precisa.*

## SecureStore

**Nem o AsyncStorage nem o MMKV são criptografados por padrão**, e o SQLite também não. Qualquer um com os
arquivos do celular, de um backup ou de um aparelho com root, consegue lê-los. Para um segredo, um token de
login ou uma chave, existe o `expo-secure-store`: no iOS ele escreve no **Keychain**, e no Android
criptografa o valor com uma chave guardada no **Keystore**, que o sistema não entrega a ninguém, nem ao
próprio app.

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

**Ele é para strings curtas, e poucas**: um valor acima de 2048 bytes pode não ser salvo, e a biblioteca
avisa quando um é escrito; cada leitura também passa pela camada de segurança do sistema. A opção mostrada
deixa o token legível só com o celular desbloqueado e impede o iOS de restaurá-lo em outro celular a partir
de um backup. *Este arquivo foi conferido pelo compilador de TypeScript contra o `expo-secure-store` 58 e
não foi executado: o servidor do planner não tem contas, então não há token a guardar.*

A regra da aula inteira cabe numa linha: **o plano no AsyncStorage, o diário no SQLite, um valor
necessário antes do primeiro quadro no MMKV, e um segredo só no SecureStore.**
