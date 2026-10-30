---
title: Pressable, e um toque que sabe que está sendo segurado
version: 1
---

**Tudo o que uma pessoa pode apertar é um `Pressable`.** Ele embrulha outros componentes e informa os
toques neles: `onPress` quando um toque termina, `onLongPress` para um toque segurado, e `onPressIn` e
`onPressOut` nas bordas. O que ele não faz é parecer qualquer coisa. A aparência de um botão, e o que ele
faz enquanto um dedo está nele, ficam por sua conta.

## A linha de curso do planner

Cada curso da lista é uma linha que você aperta para abri-lo. Salve isto como `src/CourseRow.tsx`:

```tsx
// src/CourseRow.tsx: one course in the list, as a button that says what it holds.
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { Course } from "./planner";

type Props = { course: Course; sessions: number; onOpen: (id: string) => void };

export function CourseRow({ course, sessions, onOpen }: Props) {
  return (
    <Pressable
      role="button"
      accessibilityHint={`Opens ${course.name}`}
      onPress={() => onOpen(course.id)}
      hitSlop={8}
      style={({ pressed }) => [styles.row, pressed && styles.pressed]}
    >
      <View>
        <Text style={styles.name}>{course.name}</Text>
        <Text style={styles.count}>
          {sessions} {sessions === 1 ? "session" : "sessions"} planned
        </Text>
      </View>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  row: { paddingVertical: 12, paddingHorizontal: 16, borderBottomWidth: 1, borderColor: "#d0d7de" },
  pressed: { backgroundColor: "#eef2f6" },
  name: { fontSize: 17, fontWeight: "600" },
  count: { fontSize: 14, color: "#57606a" },
});
```

O `style` recebe uma **função** aqui, chamada com `{ pressed }`, para que a linha mude enquanto o dedo está
abaixado: ela devolve o estilo base e, quando apertada, o de apertado por cima. Um array de estilos é
aplicado da esquerda para a direita e um `false` nele é ignorado, e é por isso que `pressed &&
styles.pressed` funciona. O `hitSlop={8}` deixa a área de toque oito pontos maior que a linha em cada
lado, o que não custa nada visualmente e poupa muitos toques perdidos num alvo pequeno.

## Dizendo o que ele é

Um `Pressable` sem papel é, para um leitor de tela, um grupo de texto. **O `role="button"` é o que faz o
TalkBack e o VoiceOver o anunciarem como botão**, e é o que o `getByRole("button")` encontra num teste. O
nome acessível dele é o texto dele, juntado: *Spanish A2 2 sessions planned*. O `accessibilityHint`
acrescenta o que apertá-lo vai fazer, lido depois de uma pausa.

As props mais antigas do React Native para as mesmas coisas, `accessibilityRole` e `accessibilityLabel`,
continuam funcionando e enchem a maior parte da documentação que você vai ler. O `role` e as props `aria-`
são a grafia mais nova, a mesma da web, e este curso as usa.

## Lembrando o que foi apertado

O `CourseRow` informa um toque ao pai pelo `onOpen` e não guarda nada. O pai precisa lembrar qual curso está
aberto de uma renderização para a seguinte, e uma variável comum não consegue, porque a função do
componente roda desde o começo a cada renderização. A resposta do React é o **estado**:

```tsx
const [open, setOpen] = useState<string | null>(null);
```

O `useState` devolve o valor atual e uma função que o troca. Chamar `setOpen("guitar")` guarda o valor novo
e **pede ao React que renderize o componente de novo**, e desta vez `open` vale `"guitar"`. Passar o próprio
`setOpen` como `onOpen` é toda a ligação de que a linha precisa. A aula 9 é sobre estado por inteiro; esta é
a única linha dele que a primeira tela usa.
