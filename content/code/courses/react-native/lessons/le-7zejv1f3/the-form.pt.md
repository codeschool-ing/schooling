---
title: A tela do formulário
version: 1
---

**A tela nova é empilhada a partir de um curso, com o id do curso como único parâmetro**, como a tela Course na
aula 8. Salve-a como `src/AddSessionScreen.tsx`:

```schooling-example
{"language": "tsx", "file": "src/AddSessionScreen.tsx", "parts": [{"code": "// src/AddSessionScreen.tsx: a form for one new session: two fields, their errors, and the keyboard.\nimport type { NativeStackScreenProps } from \"@react-navigation/native-stack\";\nimport React, { useEffect, useRef, useState } from \"react\";\nimport { Alert, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput } from \"react-native\";\nimport type { RootParams } from \"./navigation\";\nimport { useAddSession } from \"./planState\";\nimport { useTheme } from \"./theme\";\nimport { validate, type Draft, type Errors } from \"./validate\";\n", "note": "O formulário usa os componentes do próprio React Native, a mutation de acrescentar da seção do servidor, o tema e o validador."}, {"code": "type Props = NativeStackScreenProps<RootParams, \"AddSession\">;\n", "note": "Uma tela de pilha cujo parâmetro é o id do curso, como declara o `RootParams`."}, {"code": "export function AddSessionScreen({ route, navigation }: Props) {\n  const t = useTheme();\n  const add = useAddSession();\n  const [draft, setDraft] = useState<Draft>({ date: \"\", minutes: \"\" });\n  const [errors, setErrors] = useState<Errors>({});\n  const minutesRef = useRef<React.ComponentRef<typeof TextInput>>(null);\n  const saved = useRef(false);\n  const dirty = draft.date !== \"\" || draft.minutes !== \"\";\n", "note": "**O rascunho são duas strings**, nunca números, para um valor pela metade ficar como foi digitado. `errors` guarda as frases do último salvamento que falhou. O `minutesRef` deixa a tecla de retorno do campo de data seguir adiante; `saved` e `dirty` decidem se sair precisa perguntar."}, {"code": "  // Leaving with something typed asks first, however the person tries to leave.\n  useEffect(() => {\n    return navigation.addListener(\"beforeRemove\", (e) => {\n      if (!dirty || saved.current) return;\n      e.preventDefault();\n      Alert.alert(\"Discard this session?\", \"What you typed will be lost.\", [\n        { text: \"Keep editing\", style: \"cancel\" },\n        { text: \"Discard\", style: \"destructive\", onPress: () => navigation.dispatch(e.data.action) },\n      ]);\n    });\n  }, [navigation, dirty]);\n", "note": "A proteção de saída da seção sobre sair: quando há algo digitado e não salvo, interrompe a navegação e pergunta."}, {"code": "  async function save() {\n    const found = validate(draft);\n    setErrors(found);\n    if (Object.keys(found).length > 0) return;\n    try {\n      await add.mutateAsync({ course: route.params.course, date: draft.date, minutes: Number(draft.minutes) });\n    } catch {\n      return; // add.error now holds the reason, and the form shows it below the fields\n    }\n    saved.current = true; // what was typed is on the server: leaving loses nothing\n    navigation.goBack();\n  }\n", "note": "**Salvar valida antes** e para na primeira recusa, com as frases na tela. Uma recusa do servidor é capturada e fica em `add.error`, que o formulário mostra; só um sucesso volta."}, {"code": "  const field = (key: keyof Draft) => [styles.input, { color: t.text, borderColor: errors[key] ? t.danger : t.line }];\n  const error = [styles.error, { color: t.danger }];\n  return (\n    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === \"ios\" ? \"padding\" : undefined}>\n      <ScrollView style={{ backgroundColor: t.background }} contentContainerStyle={styles.form} keyboardShouldPersistTaps=\"handled\">\n        <Text style={[styles.label, { color: t.text }]}>\n          Date\n        </Text>\n        <TextInput\n          aria-label=\"Date\"\n          value={draft.date}\n          onChangeText={(date) => setDraft({ ...draft, date })}\n          placeholder=\"2026-10-23\"\n          keyboardType=\"numbers-and-punctuation\"\n          autoComplete=\"off\"\n          returnKeyType=\"next\"\n          onSubmitEditing={() => minutesRef.current?.focus()}\n          style={field(\"date\")}\n        />\n        {errors.date && <Text role=\"alert\" style={error}>{errors.date}</Text>}\n        <Text style={[styles.label, { color: t.text }]}>\n          Minutes\n        </Text>\n        <TextInput\n          ref={minutesRef}\n          aria-label=\"Minutes\"\n          value={draft.minutes}\n          onChangeText={(minutes) => setDraft({ ...draft, minutes })}\n          placeholder=\"30\"\n          keyboardType=\"number-pad\"\n          returnKeyType=\"done\"\n          onSubmitEditing={save}\n          style={field(\"minutes\")}\n        />\n        {errors.minutes && <Text role=\"alert\" style={error}>{errors.minutes}</Text>}\n        {add.error && <Text role=\"alert\" style={error}>The server refused it: {add.error.message}</Text>}\n        <Pressable role=\"button\" onPress={save} disabled={add.isPending} style={[styles.save, { backgroundColor: t.accent }]}>\n          <Text style={[styles.saveText, { color: t.background }]}>{add.isPending ? \"Saving\" : \"Save session\"}</Text>\n        </Pressable>\n      </ScrollView>\n    </KeyboardAvoidingView>\n  );\n}\n", "note": "Os campos. Cada um tem um rótulo visível e um `aria-label`, o teclado de que o conteúdo precisa, e uma tecla de retorno que segue adiante ou salva. Todo erro é um `role=\"alert\"`, anunciado quando aparece. A view sobe para o teclado no iOS; a scroll view deixa um toque chegar ao *Save* com ele aberto."}, {"code": "const styles = StyleSheet.create({\n  form: { padding: 24, gap: 8 },\n  label: { fontSize: 15, fontWeight: \"600\", marginTop: 8 },\n  input: { borderWidth: 1, borderRadius: 8, padding: 12, fontSize: 17 },\n  error: { fontSize: 14 },\n  save: { marginTop: 16, padding: 14, borderRadius: 8, alignItems: \"center\" },\n  saveText: { fontSize: 17, fontWeight: \"600\" },\n});", "note": "Só tamanhos e espaços; toda cor vem do tema."}]}
```

## Os três arquivos em volta

O formulário precisa de uma cor para erros, nas duas paletas, então o tema ganha `danger`. Sobre os próprios
fundos, o vermelho da paleta clara chega a 5,4 para 1 e o da escura a 7,5 para 1. O botão *Save* escreve a cor
de fundo sobre o destaque, 6,0 para 1 no claro e 6,8 no escuro. Troque o `src/theme.ts`:

```typescript
// src/theme.ts: the planner's colours, one set for each colour scheme.
import { useColorScheme } from "react-native";

const light = {
  background: "#ffffff",
  text: "#1f2328",
  muted: "#57606a",
  line: "#d0d7de",
  pressed: "#eef2f6",
  track: "#e6ebf0",
  accent: "#2f6f4e",
  danger: "#cf222e",
};
const dark: typeof light = {
  background: "#0d1117",
  text: "#e6edf3",
  muted: "#9198a1",
  line: "#3d444d",
  pressed: "#161b22",
  track: "#21262d",
  accent: "#57ab7a",
  danger: "#ff7b72",
};
export type Theme = typeof light;

export function useTheme(): Theme {
  return useColorScheme() === "dark" ? dark : light;
}
```

Os navegadores ganham a tela e o endereço dela, `course/:course/add`. Troque o `src/navigation.tsx`:

```tsx
// src/navigation.tsx: the planner's screens, how they nest, and the addresses that reach them.
import { createBottomTabNavigator } from "@react-navigation/bottom-tabs";
import type { LinkingOptions, NavigatorScreenParams } from "@react-navigation/native";
import { createNativeStackNavigator } from "@react-navigation/native-stack";
import { AddSessionScreen } from "./AddSessionScreen";
import { CourseScreen } from "./CourseScreen";
import { PlanScreen } from "./PlanScreen";
import { WeekScreen } from "./WeekScreen";

export type TabParams = { Courses: undefined; Week: undefined };
export type RootParams = {
  Tabs: NavigatorScreenParams<TabParams>;
  Course: { id: string };
  AddSession: { course: string };
};

const Tab = createBottomTabNavigator<TabParams>();
const Stack = createNativeStackNavigator<RootParams>();

function Tabs() {
  return (
    <Tab.Navigator screenOptions={{ tabBarIcon: () => null }}>
      <Tab.Screen name="Courses" component={PlanScreen} options={{ headerShown: false }} />
      <Tab.Screen name="Week" component={WeekScreen} options={{ title: "This week" }} />
    </Tab.Navigator>
  );
}

export function RootNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Tabs" component={Tabs} options={{ headerShown: false, title: "Courses" }} />
      <Stack.Screen name="Course" component={CourseScreen} options={{ title: "Course" }} />
      <Stack.Screen name="AddSession" component={AddSessionScreen} options={{ title: "New session" }} />
    </Stack.Navigator>
  );
}

export const linking: LinkingOptions<RootParams> = {
  prefixes: ["planner://"],
  config: {
    screens: {
      Tabs: { screens: { Courses: "", Week: "week" } },
      Course: "course/:id",
      AddSession: "course/:course/add",
    },
  },
};
```

E a tela do curso ganha um botão que abre o formulário. Troque o `src/CourseScreen.tsx`:

```tsx
// src/CourseScreen.tsx: one course, its sessions, and the way to add one.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useLayoutEffect } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { RootParams } from "./navigation";
import { usePlan } from "./planState";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";

export function CourseScreen({ route, navigation }: NativeStackScreenProps<RootParams, "Course">) {
  const { plan, dispatch } = usePlan();
  const t = useTheme();
  const course = plan.courses.find((c) => c.id === route.params.id);
  useLayoutEffect(() => {
    navigation.setOptions({ title: course?.name ?? "Not found" });
  }, [navigation, course]);
  if (!course) {
    return (
      <View style={[styles.screen, { backgroundColor: t.background }]}>
        <Text style={[styles.missing, { color: t.text }]}>There is no course called {route.params.id}.</Text>
      </View>
    );
  }
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <Pressable role="button" onPress={() => navigation.navigate("AddSession", { course: course.id })} style={styles.add}>
        <Text style={[styles.addText, { color: t.accent }]}>Add a session</Text>
      </Pressable>
      <SessionList
        sessions={plan.sessions.filter((s) => s.course === course.id)}
        onDone={(id) => dispatch({ type: "done", id })}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  screen: { flex: 1, paddingHorizontal: 24 },
  missing: { marginTop: 24, fontSize: 17 },
  add: { paddingVertical: 12 },
  addText: { fontSize: 16, fontWeight: "600" },
});
```

## Erros que um leitor de tela ouve

**Um erro que aparece em silêncio é invisível para quem não consegue vê-lo aparecer.** Cada mensagem tem
`role="alert"`, que faz o VoiceOver e o TalkBack anunciá-la no momento em que é desenhada, sem a pessoa
precisar procurá-la. O campo com o erro também muda a borda para `danger`, então o engano é marcado duas vezes,
em cor e em palavras, e as palavras são aquilo em que confia uma pessoa que não distingue vermelho de cinza.

O botão *Save* diz *Saving* enquanto a requisição está em curso e fica desativado nesse meio-tempo, para um
segundo toque não enviar a sessão duas vezes.
