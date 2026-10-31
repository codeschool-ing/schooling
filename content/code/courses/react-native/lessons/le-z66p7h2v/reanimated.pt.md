---
title: "Reanimated: worklets na thread de UI"
version: 1
---

**O driver nativo tem um limite: só roda animações que lhe foram descritas de antemão.** Um timing, uma
mola, uma sequência, tudo fixado quando começa. Ele não consegue seguir um dedo, porque não se sabe de
antemão para onde o dedo vai, e não consegue calcular um valor a partir de outros dois a cada quadro.
Para isso o próprio código precisa rodar na thread de UI, e é o que o **Reanimated** faz.

O Reanimated se apoia em duas ideias:

- **Um shared value** é um número (ou um objeto) que as duas threads leem e escrevem. O JavaScript o
  define, e a thread de UI vê a mudança sem renderização.
- **Um worklet** é uma função JavaScript pequena que o plugin de Babel do Reanimated copia para um
  segundo runtime JavaScript que vive na thread de UI. Ela roda lá a cada quadro. Pode ler shared
  values e chamar outros worklets, mas não funções comuns do resto do app, que vivem na outra thread.

Desde o Reanimated 4 a maquinaria dos worklets é um pacote à parte, o `react-native-worklets`, instalado
ao lado dele. A biblioteca de gestos da próxima seção usa os dois:

```
ana@dev:~/planner$ npx expo install react-native-reanimated react-native-worklets react-native-gesture-handler
Unable to fetch compatibility data from React Native Directory. Skipping check.
Dependency validation is unreliable in offline-mode
› Installing 3 SDK 58.0.0 compatible native modules using npm
> npm install

added 18 packages, and audited 1112 packages in 9s

15 vulnerabilities (12 low, 3 high)

To address issues that do not require attention, run:
  npm audit fix

To address all issues (including breaking changes), run:
  npm audit fix --force

Run `npm audit` for details.
```

O `npx expo install` escolhe as versões com que o SDK 58 foi testado, em vez da mais nova de cada uma, e
as escreve no `package.json`. As duas bibliotecas têm código nativo, então um development build precisa
ser reconstruído para carregá-las, como a aula 3 disse de toda biblioteca com código nativo; o Expo Go já
as tem.

## A barra da semana, escrita para o Reanimated

A versão da barra com `Animated` funciona e fica. Aqui está a mesma barra em Reanimated, para comparar os
dois jeitos de dizer a mesma coisa. Ela não faz parte do planner:

```schooling-example
{"language": "tsx", "file": "src/WeekBarReanimated.tsx", "parts": [{"code": "// src/WeekBarReanimated.tsx: the week bar again, with the animation written for Reanimated.\nimport { useEffect, useState } from \"react\";\nimport { StyleSheet, View } from \"react-native\";\nimport Animated, {\n  Easing,\n  ReduceMotion,\n  useAnimatedStyle,\n  useSharedValue,\n  withTiming,\n} from \"react-native-reanimated\";\nimport { useTheme } from \"./theme\";\n\ntype Props = { done: number; planned: number };\n", "note": "Os imports são o vocabulário todo: um valor que as duas threads leem, um estilo calculado a partir dele e uma animação que o move."}, {"code": "export function WeekBar({ done, planned }: Props) {\n  const t = useTheme();\n  const share = planned > 0 ? done / planned : 0;\n  const scale = useSharedValue(share);\n  const [width, setWidth] = useState(0);", "note": "O `useSharedValue` toma o lugar de `useRef(new Animated.Value(...))`. É criado uma vez, como o ref, e mora onde a thread de UI consegue lê-lo."}, {"code": "  useEffect(() => {\n    scale.value = withTiming(share, {\n      duration: 300,\n      easing: Easing.out(Easing.cubic),\n      reduceMotion: ReduceMotion.System,\n    });\n  }, [share, scale]);", "note": "Atribuir uma animação a `.value` a inicia. `ReduceMotion.System` segue sozinho a configuração do celular, e a pergunta que a versão com `Animated` fazia à mão some."}, {"code": "  const grown = useAnimatedStyle(() => ({\n    transform: [{ translateX: -width / 2 }, { scaleX: scale.value }, { translateX: width / 2 }],\n  }));", "note": "Esta função é um **worklet**: o plugin de Babel do Reanimated a copia para a thread de UI, que a roda a cada quadro e define a transformação sem perguntar ao JavaScript. O `width` é copiado junto a cada renderização do componente."}, {"code": "  return (\n    <View\n      accessible\n      role=\"progressbar\"\n      aria-label=\"Minutes done this week\"\n      aria-valuemin={0}\n      aria-valuemax={planned}\n      aria-valuenow={done}\n      onLayout={(e) => setWidth(e.nativeEvent.layout.width)}\n      style={[styles.track, { backgroundColor: t.track }]}\n    >\n      <Animated.View style={[styles.done, { width, backgroundColor: t.accent }, grown]} />\n    </View>\n  );\n}\n\nconst styles = StyleSheet.create({\n  track: { height: 12, borderRadius: 6, overflow: \"hidden\" },\n  done: { height: 12 },\n});", "note": "O resto é o mesmo componente: a mesma trilha, os mesmos valores acessíveis. Só o estilo animado mudou de mãos."}]}
```

*Esta versão foi conferida pelo compilador de TypeScript contra o Reanimated 4.7.1 e não foi executada,
nem no Jest, nem num navegador, nem num celular.* Ao lado da de `Animated`, ela diz o mesmo com menos
palavras, e a troca é esta: **para uma animação conhecida de antemão, o driver nativo basta**, e o
Reanimated se justifica quando a animação precisa responder a algo que está acontecendo, como um dedo.

## Onde os worklets mordem

Um worklet é copiado, não chamado, e isso tem consequências que aparecem na primeira vez que você escreve
um:

- **Uma função que ele chama também precisa ser um worklet.** Uma função comum do seu módulo não está na
  thread de UI, e chamá-la lá derruba o app. Marque-a com a diretiva `"worklet"` na primeira linha.
- **Voltar ao JavaScript é explícito.** De dentro de um worklet, `scheduleOnRN(f)` pede à thread do
  JavaScript que rode `f` quando puder; é assim que um gesto termina numa atualização de estado ou numa
  requisição.
- **O que ele captura é uma cópia.** Uma variável do componente é copiada quando o worklet é criado, então
  mudá-la depois do lado do JavaScript não chega à cópia até a próxima renderização criar outra.
