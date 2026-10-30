---
title: Para que serve o armazenamento chave-valor
version: 1
---

**O armazenamento chave-valor serve para um punhado de configurações pequenas que o app lê ao
abrir, e para nada que cresce.** O tema, o dia em que a semana começa, se os lembretes estão
ligados, o último curso que a pessoa abriu. Cada um é um nome e um valor pequeno, e o app quer
todos antes de desenhar a primeira tela.

O erro comum é tratá-lo como um banco de dados pequeno, porque é o armazenamento mais fácil de
alcançar. Ele não é um. **O armazenamento chave-valor de toda plataforma guarda o conjunto inteiro
num arquivo, lê tudo para a memória e reescreve tudo a cada mudança.** Isso é exatamente certo para
dez configurações e exatamente errado para mil sessões, e a última seção desta aula mede a
diferença.

## As mesmas três configurações em três plataformas

*Estas listagens não foram rodadas para este curso; elas são citadas da documentação do Android,
da Apple e do Async Storage do React Native, do jeito que cada uma documenta o próprio
armazenamento.*

No Android, o **Jetpack DataStore** substitui o `SharedPreferences`, do qual a documentação do
Google agora afasta o código novo. Uma escrita é uma função suspensa e uma leitura é um `Flow`,
então nenhuma das duas trava a tela:

```kotlin
val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")
val THEME = stringPreferencesKey("theme")

suspend fun setTheme(context: Context, theme: String) {
    context.dataStore.edit { prefs -> prefs[THEME] = theme }
}

fun theme(context: Context): Flow<String> =
    context.dataStore.data.map { prefs -> prefs[THEME] ?: "light" }
```

No iOS, o **`UserDefaults`** grava a lista de propriedades que a aula 1 encontrou em
`Library/Preferences/`, e o `@AppStorage` do SwiftUI é o mesmo armazenamento com um property
wrapper em volta:

```swift
UserDefaults.standard.set("dark", forKey: "theme")
let theme = UserDefaults.standard.string(forKey: "theme") ?? "light"

struct SettingsView: View {
    @AppStorage("theme") var theme = "light"
    var body: some View { Text(theme) }
}
```

No React Native, o **Async Storage** guarda strings e responde com promises:

```typescript
import AsyncStorage from "@react-native-async-storage/async-storage";

await AsyncStorage.setItem("theme", "dark");
const theme = (await AsyncStorage.getItem("theme")) ?? "light";
```

## E o MMKV

O **MMKV** é um armazenamento chave-valor que a Tencent escreveu para o WeChat e publicou para
Android e iOS, e o `react-native-mmkv` o leva ao React Native. Ele mapeia o arquivo na memória,
então uma leitura é um acesso à memória e não uma ida ao disco, e as chamadas são síncronas. Esse é
o atrativo dele, e o motivo para mantê-lo nas mesmas configurações pequenas: ser rápido não muda o
que pertence ali.

| armazenamento | plataforma | leitura | escrita |
|---|---|---|---|
| DataStore | Android | `Flow`, fora da thread principal | `edit` suspenso |
| `SharedPreferences` | Android | síncrona, da memória | `apply()` em segundo plano, `commit()` bloqueante |
| `UserDefaults` | iOS | síncrona, da memória | o sistema salva |
| Async Storage | React Native | promise | promise |
| MMKV | as três | síncrona, memória mapeada | síncrona |

A tabela difere nas colunas que menos importam. O que os cinco têm em comum é o formato que esta
aula constrói a seguir: nomes, valores pequenos, um arquivo.
