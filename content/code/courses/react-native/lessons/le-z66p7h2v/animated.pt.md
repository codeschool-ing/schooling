---
title: Animated, e o driver nativo
version: 1
---

**O `Animated` é a biblioteca de animação que vem com o React Native.** Um `Animated.Value` guarda um
número; o `Animated.timing` o leva a um número novo ao longo de uma duração, com uma curva de easing; um
`Animated.View` o lê no estilo. Com `useNativeDriver: true`, a animação inteira é descrita ao lado nativo
uma vez, e a thread de UI roda cada quadro.

A barra da semana do planner cresce quando uma sessão é feita. Troque o `src/WeekBar.tsx` por esta
versão:

```tsx
// src/WeekBar.tsx: the week's minutes as a bar that grows when a session is done.
// The animation is a transform, so the native driver runs it on the UI thread.
import { useEffect, useRef, useState } from "react";
import { AccessibilityInfo, Animated, Easing, StyleSheet, View } from "react-native";
import { useTheme } from "./theme";

type Props = { done: number; planned: number };

export function WeekBar({ done, planned }: Props) {
  const t = useTheme();
  const share = planned > 0 ? done / planned : 0;
  const scale = useRef(new Animated.Value(share)).current;
  const [width, setWidth] = useState(0);
  useEffect(() => {
    let stopped = false;
    AccessibilityInfo.isReduceMotionEnabled().then((reduce) => {
      if (stopped) return;
      Animated.timing(scale, {
        toValue: share,
        duration: reduce ? 0 : 300,
        easing: Easing.out(Easing.cubic),
        useNativeDriver: true,
      }).start();
    });
    return () => {
      stopped = true;
    };
  }, [share, scale]);
  return (
    <View
      testID="week-bar"
      accessible
      role="progressbar"
      aria-label="Minutes done this week"
      aria-valuemin={0}
      aria-valuemax={planned}
      aria-valuenow={done}
      onLayout={(e) => setWidth(e.nativeEvent.layout.width)}
      style={[styles.track, { backgroundColor: t.track }]}
    >
      <Animated.View
        testID="week-done"
        style={[
          styles.done,
          { width, backgroundColor: t.accent },
          // grow from the left edge: move left by half the width, scale, move back
          { transform: [{ translateX: -width / 2 }, { scaleX: scale }, { translateX: width / 2 }] },
        ]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  track: { height: 12, borderRadius: 6, overflow: "hidden" },
  done: { height: 12 },
});
```

**A barra é desenhada na largura toda e escalada.** Um `scaleX` de 0,6 a 0,76 a faz parecer com 60 e
depois 76 por cento da largura, sem layout. Uma escala encolhe na direção do centro, então a
transformação move a view para a esquerda em metade da largura, escala, e a move de volta, o que prende
a borda esquerda. A largura vem do `onLayout`, o tamanho da trilha depois que o Yoga a calculou.

O `useRef(new Animated.Value(share)).current` cria o valor uma vez, na primeira renderização, e o guarda:
um valor criado a cada renderização recomeçaria do início toda vez. O efeito inicia uma animação sempre
que a fração muda, e a regra da aula 9 sobre efeitos vale aqui também: a limpeza marca o efeito como
parado, para que uma resposta atrasada sobre movimento reduzido não inicie uma animação numa barra que já
mudou.

## Testado onde um teste enxerga

O substituto do Jest para o módulo nativo de animação não roda os quadros, então o teste confere o que é
verdade seja o que for que a animação faça: o valor que um leitor de tela ouve. Troque o
`__tests__/WeekBar.test.tsx`:

```tsx
// __tests__/WeekBar.test.tsx: the bar's value, which is what a screen reader hears.
// How it moves is measured in the browser, where the animation really runs.
import { render, screen } from "@testing-library/react-native";
import { WeekBar } from "../src/WeekBar";

test("the bar says its value, before and after a session is done", async () => {
  const view = await render(<WeekBar done={75} planned={125} />);
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ min: 0, max: 125, now: 75 });
  await view.rerender(<WeekBar done={95} planned={125} />);
  expect(screen.getByRole("progressbar")).toHaveAccessibilityValue({ now: 95 });
});
```

```
ana@dev:~/planner$ npx tsc --noEmit
ana@dev:~/planner$ npx jest WeekBar --forceExit
PASS __tests__/WeekBar.test.tsx
  ✓ the bar says its value, before and after a session is done (194 ms)

Test Suites: 1 passed, 1 total
Tests:       1 passed, 1 total
Snapshots:   0 total
Time:        0.787 s, estimated 1 s
Ran all test suites matching WeekBar.
Force exiting Jest: Have you considered using `--detectOpenHandles` to detect async operations that kept running after all tests finished?
```

Como a barra se move é trabalho da próxima seção, num navegador onde a animação roda de verdade.
