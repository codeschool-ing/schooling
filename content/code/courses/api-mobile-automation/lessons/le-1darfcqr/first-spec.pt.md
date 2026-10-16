---
title: Uma primeira spec
version: 1
---

**Uma spec de Detox se lê como os testes de Espresso da lição 16 escritos em JavaScript**: achar um
elemento, agir sobre ele, esperar algo dele. `element(by.id(…))` acha, `.tap()` age, e
`expect(…).toBeVisible()` confere. O que falta é qualquer espera, pelo motivo que a seção 03 deu.

## O componente sob teste

O `App.tsx` do modelo mostra a tela de boas-vindas do React Native. Substitua-o pela lista desta
lição. Todo elemento que uma spec toca tem um `testID`. O de cada linha é montado a partir do id do
espetáculo, `show-sh-103`, para uma spec escolher uma linha pelo que ela guarda, como o `showWithId`
fazia na lição 16. Salve como `tickets-rn/App.tsx`:

```tsx
// tickets-rn/App.tsx: the list of shows, written once for Android and iOS
import { useCallback, useEffect, useState } from 'react';
import { ActivityIndicator, Button, FlatList, Pressable, StyleSheet, Text } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';

// boxoffice as the Android emulator sees it, as in Tickets (lesson 14)
const BOXOFFICE = 'http://10.0.2.2:8080';

type Show = { id: string; title: string; seats_left: number };

export default function App() {
  const [shows, setShows] = useState<Show[] | null>(null);
  const [failed, setFailed] = useState(false);
  const [chosen, setChosen] = useState<Show | null>(null);

  const load = useCallback(async () => {
    setFailed(false);
    try {
      const answer = await fetch(`${BOXOFFICE}/v1/shows`);
      const body = await answer.json();
      setShows(body.shows);
    } catch {
      setFailed(true);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  return (
    <SafeAreaProvider>
      <SafeAreaView style={styles.screen}>
        <Button testID="refresh" title="Refresh" onPress={load} />
        {failed && <Text testID="error">Could not reach the box office.</Text>}
        {shows === null && !failed && <ActivityIndicator testID="loading" />}
        <FlatList
          testID="shows"
          data={shows ?? []}
          keyExtractor={show => show.id}
          renderItem={({ item }) => (
            <Pressable testID={`show-${item.id}`} onPress={() => setChosen(item)}>
              <Text style={styles.title}>{item.title}</Text>
              <Text>{item.seats_left} seats left</Text>
            </Pressable>
          )}
        />
        {chosen && (
          <Text testID="chosen">
            {chosen.title}: {chosen.seats_left} seats left
          </Text>
        )}
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, padding: 16 },
  title: { fontSize: 18, marginTop: 12 },
});
```

Ao contrário do app, o código pôde ser conferido na máquina de gravação. O modelo vem com
TypeScript, que lê o projeto inteiro e aponta todo tipo que não encaixa. Silêncio e código de saída
0 querem dizer que ele não achou nenhum:

```
ana@laptop:~/boxoffice$ cd tickets-rn
ana@laptop:~/boxoffice/tickets-rn$ npx tsc --noEmit; echo "exit $?"
exit 0
```

## A spec

Salve como `tickets-rn/e2e/tickets.test.js`:

```js
// tickets-rn/e2e/tickets.test.js: the list, tapped from a Detox test
describe('Tickets', () => {
  beforeAll(async () => {
    await device.launchApp({ newInstance: true });
  });

  it('lists the shows boxoffice sells', async () => {
    await expect(element(by.id('show-sh-101'))).toBeVisible();
    await expect(element(by.id('show-sh-103'))).toBeVisible();
    await expect(element(by.id('error'))).not.toExist();
  });

  it('shows the seats boxoffice reports for the show tapped', async () => {
    const show = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();
    await element(by.id('show-sh-103')).tap();
    await expect(element(by.id('chosen'))).toHaveText(
      `O Pagador de Promessas: ${show.seats_left} seats left`,
    );
  });
});
```

```schooling-example
{
 "language": "js",
 "file": "tickets.test.js",
 "parts": [
  {
   "code": "  beforeAll(async () => {\n    await device.launchApp({ newInstance: true });\n  });",
   "note": "`device` é a alça do Detox sobre o emulador. O `launchApp` inicia o app, e `newInstance: true` mata antes uma cópia deixada rodando por uma spec anterior, para a lista carregar do zero."
  },
  {
   "code": "    await expect(element(by.id('show-sh-101'))).toBeVisible();\n    await expect(element(by.id('show-sh-103'))).toBeVisible();",
   "note": "A primeira linha roda no momento em que o app fica ocioso, que é depois de a requisição ao boxoffice responder e a lista ser desenhada. Nada na spec diz isso; o Detox esperou."
  },
  {
   "code": "    await expect(element(by.id('error'))).not.toExist();",
   "note": "A linha de erro só é renderizada quando a carga falhou, então numa carga boa ela nem está na árvore: `not.toExist()`, onde a faixa do Espresso da lição 16 precisava de `not(isDisplayed())`."
  },
  {
   "code": "    const show = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();",
   "note": "A spec roda no Node, no seu computador, então alcança o boxoffice em `localhost`, enquanto o app no emulador usa `10.0.2.2`. Os lugares esperados vêm do boxoffice, como na lição 15."
  },
  {
   "code": "    await element(by.id('show-sh-103')).tap();\n    await expect(element(by.id('chosen'))).toHaveText(\n      `O Pagador de Promessas: ${show.seats_left} seats left`,\n    );",
   "note": "Toque na linha, depois confira a linha de baixo. O `toHaveText` compara o texto inteiro, então a string esperada é montada do jeito que o componente a monta."
  }
 ]
}
```

## Rodando

Três terminais, a partir de `tickets-rn`, com o boxoffice rodando e o emulador iniciado:

```sh
npx react-native start
npx detox build -c android.emu.debug
npx detox test -c android.emu.debug
```

O primeiro serve o JavaScript do app ao build de debug e fica rodando. O segundo compila o app e o
APK de teste, o passo lento, refeito só quando o código nativo muda. O terceiro inicia o AVD se ele
não estiver rodando e instala os dois APKs. Depois roda as specs pelo Jest, que imprime cada teste com o
resultado.

**Essa execução não foi gravada para este curso.** Os APKs nunca foram compilados, pelo motivo que a
seção 04 deu. O que foi gravado é o terceiro comando na máquina de gravação, que não tem AVD nenhum:

```
ana@laptop:~/boxoffice/tickets-rn$ npx detox test -c android.emu.debug
01:04:51.240 detox[7489] B jest --config e2e/jest.config.js
FAIL e2e/tickets.test.js
  ● Test suite failed to run

    DetoxRuntimeError: Cannot boot Android Emulator with the name: 'Pixel_8_API_35'

    HINT: Make sure you choose one of the available emulators:

      at AVDValidator._assertAVDMatch (node_modules/detox/src/devices/allocation/drivers/android/emulator/AVDValidator.js:36:13)
      at AVDValidator.validate (node_modules/detox/src/devices/allocation/drivers/android/emulator/AVDValidator.js:18:16)
      at async EmulatorAllocDriver.allocate (node_modules/detox/src/devices/allocation/drivers/android/emulator/EmulatorAllocDriver.js:56:5)
      at async /home/ana/boxoffice/tickets-rn/node_modules/detox/src/devices/allocation/DeviceAllocator.js:44:22

Test Suites: 1 failed, 1 total
Tests:       0 total
Snapshots:   0 total
Time:        0.327 s
Ran all test suites.
01:04:52.043 detox[7489] E Command failed with exit code = 1:
jest --config e2e/jest.config.js
```

O Detox leu a configuração e pediu ao SDK do Android um emulador chamado `Pixel_8_API_35`. Ele
recusou antes de o Jest rodar um único teste, com uma lista vazia onde estariam os emuladores
disponíveis. É a mesma resposta vazia que o `emulator -list-avds` deu na lição 14. No seu computador
essa lista nomeia os AVDs que você tem. **Um nome no `.detoxrc.js` que não corresponde a nenhum deles falha
exatamente assim**, o que faz dele a primeira coisa a conferir quando o Detox não inicia.
