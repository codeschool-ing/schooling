---
title: Preferências, para as poucas configurações pequenas
version: 1
---

**Toda plataforma tem um pequeno armazenamento de chave e valor para configurações, e o erro é
transformá-lo no banco de dados do app.** Ele é feito para um punhado de valores que o app lê ao
iniciar: a aba que estava aberta, o tema que a aluna escolheu, se ela já viu a tela de boas-vindas.
Ele é lido inteiro e escrito inteiro, não tem consultas, e não é o lugar de uma lista de sessões que
cresce todo dia. O planner guarda duas coisas ali: a aba selecionada e o tema.

No Android é o **DataStore**, que a documentação do Android, lida em 30 de outubro de 2026,
recomenda no lugar das antigas `SharedPreferences`. No iOS é o **`UserDefaults`**. No React Native é
o **AsyncStorage**, uma biblioteca cujo README a descreve como armazenamento de chave e valor
persistente e sem criptografia. Salvar o tema fica assim em cada um; os trechos foram adaptados
dessas três fontes e **não foram compilados nem executados para este curso**:

```kotlin
val Context.settings: DataStore<Preferences> by preferencesDataStore(name = "settings")
val THEME = stringPreferencesKey("theme")

suspend fun saveTheme(context: Context, theme: String) {
    context.settings.edit { it[THEME] = theme }
}
```

```swift
// Read and written through UserDefaults.standard; the view redraws when it changes
@AppStorage("theme") var theme = "system"

Button("Dark") { theme = "dark" }
```

```tsx
import { createAsyncStorage } from "@react-native-async-storage/async-storage";

const settings = createAsyncStorage("settings");
await settings.setItem("theme", "dark");
```

**Os três guardam os valores num arquivo na sandbox do app, sem criptografia.** A documentação da
Apple sobre o `UserDefaults` diz isso com essas palavras, e manda guardar informação pessoal ou
sensível no Keychain; a última etapa desta aula trata disso.

## Um arquivo de preferências, escrito com segurança

O `prefs.ts` faz pelo planner o que aqueles três fazem, com um arquivo JSON. A única parte sutil é
como ele escreve. **Ele nunca sobrescreve o `prefs.json` no lugar.** Ele escreve as configurações
novas em `prefs.json.tmp`, e depois renomeia esse arquivo por cima do antigo:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l16-atomic\" aria-label=\"Dois jeitos de salvar as configurações, ao longo do tempo, com o processo morto no mesmo instante nos dois. Escrevendo prefs.json no lugar: o arquivo é esvaziado, o texto novo está pela metade quando o processo morre, e o arquivo fica com metade de cada, e não é mais lido como JSON. Escrevendo prefs.json.tmp e depois renomeando: o processo morre com o arquivo temporário pela metade, e o prefs.json ainda guarda as configurações antigas, inteiras.\"><defs><marker id=\"l16-atomic-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">escrevendo prefs.json no lugar</text><text x=\"20\" y=\"138\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">escrevendo prefs.json.tmp, depois rename</text><rect x=\"20\" y=\"36\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prefs.json</text><text x=\"125.0\" y=\"64.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">esvaziado</text><rect x=\"250\" y=\"36\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">metade do</text><text x=\"355.0\" y=\"64.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">texto novo</text><rect x=\"480\" y=\"36\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"51.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">fica pela metade:</text><text x=\"585.0\" y=\"64.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">não é mais JSON</text><rect x=\"20\" y=\"152\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"125.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prefs.json.tmp</text><text x=\"125.0\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pela metade</text><rect x=\"250\" y=\"152\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"355.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">prefs.json</text><text x=\"355.0\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">intocado</text><rect x=\"480\" y=\"152\" width=\"210\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"167.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">as configurações</text><text x=\"585.0\" y=\"180.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">antigas, inteiras</text><path d=\"M230 58 L250 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-atomic-ah-paper-dim)\"></path><path d=\"M460 58 L480 58\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-atomic-ah-paper-dim)\"></path><path d=\"M230 174 L250 174\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-atomic-ah-paper-dim)\"></path><path d=\"M460 174 L480 174\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l16-atomic-ah-paper-dim)\"></path><path d=\"M355 98 L355 128\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"355\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">✕ o processo é morto aqui</text><text x=\"360\" y=\"226\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">rename: o arquivo antigo ou o novo, nunca metade de cada</text></svg>", "caption": "Mortos no mesmo instante, o primeiro arquivo fica quebrado e o segundo guarda as configurações antigas. Um rename é o único passo que nunca fica pela metade.", "same": ["prefs.json", "prefs.json.tmp"]}
```

**Um rename dentro de uma mesma pasta é um passo único para o sistema de arquivos**: quem abre o
`prefs.json` recebe o arquivo antigo ou o novo, nunca metade de cada. Escrever no lugar tem um
instante em que o arquivo guarda parte do texto novo e nada do antigo. Um celular é exatamente a
máquina em que o processo pode ser morto nesse instante, pelo sistema recuperando memória como a
aula 4 descreveu, ou por uma bateria que acaba. Um arquivo que você mesmo escreve é
responsabilidade sua. Salve isto como `prefs.ts`:

```typescript
// prefs.ts: the planner's small settings, in a file that is never half-written
import { readFileSync, renameSync, writeFileSync } from "node:fs";

type Prefs = { tab: string; theme: string };
const FILE = "prefs.json";
const DEFAULTS: Prefs = { tab: "week", theme: "system" };

export function load(): Prefs {
  try {
    return { ...DEFAULTS, ...JSON.parse(readFileSync(FILE, "utf8")) };
  } catch {
    return DEFAULTS; // no file yet, or one that cannot be read: start from the defaults
  }
}

export function save(prefs: Prefs) {
  writeFileSync(FILE + ".tmp", JSON.stringify(prefs) + "\n");
  renameSync(FILE + ".tmp", FILE); // replaces the old file in one step
}

// `node prefs.ts` prints the settings; `node prefs.ts theme dark` changes one first.
const [key, value] = process.argv.slice(2);
if (key) save({ ...load(), [key]: value });
console.log(load());
```

**Os padrões são espalhados primeiro e o arquivo depois**, então uma configuração acrescentada numa
versão futura do app, que um arquivo antigo não menciona, ainda recebe o seu padrão em vez de
`undefined`. Rode sem arquivo, mude duas configurações, e veja o que ficou no disco:

```
ana@dev:~/planner$ node prefs.ts
{ tab: 'week', theme: 'system' }
ana@dev:~/planner$ node prefs.ts theme dark
{ tab: 'week', theme: 'dark' }
ana@dev:~/planner$ node prefs.ts tab courses
{ tab: 'courses', theme: 'dark' }
ana@dev:~/planner$ cat prefs.json
{"tab":"courses","theme":"dark"}
ana@dev:~/planner$ ls -l prefs*
-rw-r--r-- 1 ana ana  33 Oct 30 03:27 prefs.json
-rw-r--r-- 1 ana ana 867 Oct 30 03:27 prefs.ts
```

A primeira execução não achou arquivo e imprimiu os padrões. Cada mudança escreveu o objeto inteiro
de novo, porque esse é o único jeito de um arquivo ser escrito; o `prefs.json` guarda as duas
configurações em 33 bytes, e o arquivo `.tmp` sumiu, renomeado para o lugar. Esse tamanho é o
ponto: preferências continuam pequenas, e tudo o que cresce mora no banco de dados da próxima etapa.
