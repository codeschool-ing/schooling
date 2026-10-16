---
title: A first spec
version: 1
---

**A Detox spec reads like the Espresso tests of lesson 16 written in JavaScript**: find an element,
act on it, expect something of it. `element(by.id(…))` finds, `.tap()` acts, and
`expect(…).toBeVisible()` checks. What is missing is any waiting, for the reason section 03 gave.

## The component under test

The template's `App.tsx` shows React Native's welcome screen. Replace it with the list of this
lesson. Every element a spec touches has a `testID`. Each row's is built from the show's id,
`show-sh-103`, so a spec picks a row by what it holds, as `showWithId` did in lesson 16.
Save it as `tickets-rn/App.tsx`:

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

Unlike the app, the code could be checked on the recording machine. The template comes with
TypeScript, which reads the whole project and reports every type that does not fit. Silence and
exit code 0 mean it found none:

```
ana@laptop:~/boxoffice$ cd tickets-rn
ana@laptop:~/boxoffice/tickets-rn$ npx tsc --noEmit; echo "exit $?"
exit 0
```

## The spec

Save it as `tickets-rn/e2e/tickets.test.js`:

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
   "note": "`device` is Detox's handle on the emulator. `launchApp` starts the app, and `newInstance: true` kills a copy left running by an earlier spec first, so the list loads fresh."
  },
  {
   "code": "    await expect(element(by.id('show-sh-101'))).toBeVisible();\n    await expect(element(by.id('show-sh-103'))).toBeVisible();",
   "note": "The first line runs the moment the app is idle, which is after the request to boxoffice has answered and the list has been drawn. Nothing in the spec says so; Detox waited."
  },
  {
   "code": "    await expect(element(by.id('error'))).not.toExist();",
   "note": "The error line is only rendered when the load failed, so on a good load it is not in the tree at all: `not.toExist()`, where Espresso's banner of lesson 16 needed `not(isDisplayed())`."
  },
  {
   "code": "    const show = await (await fetch('http://localhost:8080/v1/shows/sh-103')).json();",
   "note": "The spec runs in Node on your computer, so it reaches boxoffice at `localhost`, while the app on the emulator uses `10.0.2.2`. The expected seats come from boxoffice, as in lesson 15."
  },
  {
   "code": "    await element(by.id('show-sh-103')).tap();\n    await expect(element(by.id('chosen'))).toHaveText(\n      `O Pagador de Promessas: ${show.seats_left} seats left`,\n    );",
   "note": "Tap the row, then check the line at the bottom. `toHaveText` compares the whole text, so the expected string is built the way the component builds it."
  }
 ]
}
```

## Running it

Three terminals, from `tickets-rn`, with boxoffice running and the emulator started:

```sh
npx react-native start
npx detox build -c android.emu.debug
npx detox test -c android.emu.debug
```

The first serves the app's JavaScript to the debug build and stays running. The second builds the
app and the test APK, the slow step, done again only when native code changes. The third boots the
AVD if it is not running and installs both APKs. Then it runs the specs through Jest, which prints
each test with its result.

**That run was not recorded for this course.** The APKs were never built, for the reason section
04 gave. What was recorded is the third command on the recording machine, which has no AVD at all:

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

Detox read the configuration and asked the Android SDK for an emulator called `Pixel_8_API_35`. It
refused before Jest ran a single test, with an empty list where the available emulators would be.
That is the same empty answer `emulator -list-avds` gave in lesson 14. On your computer that list
names the AVDs you have. **A name in `.detoxrc.js` that matches none of them fails exactly like
this**, which makes it the first thing to check when Detox will not start.
