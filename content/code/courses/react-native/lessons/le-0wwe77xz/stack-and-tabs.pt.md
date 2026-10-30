---
title: Uma pilha, com abas dentro
version: 1
---

**Os navegadores são declarados num arquivo só, com cada tela, cada parâmetro e cada endereço.** Salve isto
como `src/navigation.tsx`:

```schooling-example
{"language": "tsx", "file": "src/navigation.tsx", "parts": [{"code": "// src/navigation.tsx: the planner's screens, how they nest, and the addresses that reach them.\nimport { createBottomTabNavigator } from \"@react-navigation/bottom-tabs\";\nimport type { LinkingOptions, NavigatorScreenParams } from \"@react-navigation/native\";\nimport { createNativeStackNavigator } from \"@react-navigation/native-stack\";\nimport { CourseScreen } from \"./CourseScreen\";\nimport { PlanScreen } from \"./PlanScreen\";\nimport { WeekScreen } from \"./WeekScreen\";\n", "note": "As duas fábricas de navegadores e as três telas. `LinkingOptions` e `NavigatorScreenParams` são só tipos."}, {"code": "export type TabParams = { Courses: undefined; Week: undefined };\nexport type RootParams = { Tabs: NavigatorScreenParams<TabParams>; Course: { id: string } };\n", "note": "**Toda rota e seus parâmetros, num lugar só.** As abas não recebem nenhum; a tela Course recebe o `id` do curso; a rota `Tabs` da pilha carrega o estado das próprias abas."}, {"code": "const Tab = createBottomTabNavigator<TabParams>();\nconst Stack = createNativeStackNavigator<RootParams>();\n", "note": "Os navegadores, tipados com esses parâmetros, para o `navigate` ser conferido."}, {"code": "function Tabs() {\n  return (\n    <Tab.Navigator screenOptions={{ tabBarIcon: () => null }}>\n      <Tab.Screen name=\"Courses\" component={PlanScreen} options={{ headerShown: false }} />\n      <Tab.Screen name=\"Week\" component={WeekScreen} options={{ title: \"This week\" }} />\n    </Tab.Navigator>\n  );\n}\n", "note": "As abas. A lista desenha o próprio título, então a aba dela não mostra cabeçalho; a aba da semana tem título. Ainda sem ícones, de propósito."}, {"code": "export function RootNavigator() {\n  return (\n    <Stack.Navigator>\n      <Stack.Screen name=\"Tabs\" component={Tabs} options={{ headerShown: false, title: \"Courses\" }} />\n      <Stack.Screen name=\"Course\" component={CourseScreen} options={{ title: \"Course\" }} />\n    </Stack.Navigator>\n  );\n}\n", "note": "A pilha raiz: as abas primeiro, a tela do curso acima delas. O `title` em `Tabs` é o que diz o botão de voltar de uma tela empilhada."}, {"code": "export const linking: LinkingOptions<RootParams> = {\n  prefixes: [\"planner://\"],\n  config: {\n    screens: {\n      Tabs: { screens: { Courses: \"\", Week: \"week\" } },\n      Course: \"course/:id\",\n    },\n  },\n};", "note": "O endereço de cada tela, lido na seção sobre endereços."}]}
```

O `NavigatorScreenParams` diz que a rota `Tabs` carrega o estado das próprias abas, que é como o TypeScript
acompanha uma navegação da pilha para dentro de uma aba. O objeto `linking` no fim é o assunto da seção sobre
endereços.

## As telas

A lista de cursos vira a aba *Courses*. Ela não recebe mais o plano como prop: uma tela num navegador é
renderizada pelo navegador, que lhe passa `navigation` e `route` e mais nada. **Então, nesta aula, as telas
leem o arquivo de dados diretamente.** A aula 9 leva o plano para um estado que toda tela compartilha, que é o
que permite marcar uma sessão como feita numa tela e mudar o total em outra. Troque o `src/PlanScreen.tsx`
por:

```tsx
// src/PlanScreen.tsx: the Courses tab: the week, and every course, which opens its own screen.
import type { BottomTabScreenProps } from "@react-navigation/bottom-tabs";
import type { CompositeScreenProps } from "@react-navigation/native";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { CourseRow } from "./CourseRow";
import data from "./courses.json";
import type { RootParams, TabParams } from "./navigation";
import { mondayOf, weekTotal, type Plan } from "./planner";
import { savedWhere } from "./savedWhere";
import { useTheme } from "./theme";
import { today } from "./today";
import { WeekBar } from "./WeekBar";

const plan: Plan = data;
type Props = CompositeScreenProps<BottomTabScreenProps<TabParams, "Courses">, NativeStackScreenProps<RootParams>>;

export function PlanScreen({ navigation }: Props) {
  const t = useTheme();
  const insets = useSafeAreaInsets();
  const total = weekTotal(plan, mondayOf(today()));
  const header = (
    <View>
      <View testID="header" style={styles.header}>
        <Image source={require("../assets/icon.png")} style={styles.icon} aria-hidden />
        <Text role="heading" style={[styles.title, { color: t.text }]}>
          Study planner
        </Text>
      </View>
      <Text style={[styles.total, { color: t.muted }]}>
        This week: {total.done} of {total.planned} minutes done
      </Text>
      <WeekBar done={total.done} planned={total.planned} />
    </View>
  );
  const footer = (
    <View>
      <Text style={[styles.footer, { color: t.muted }]}>{savedWhere}</Text>
    </View>
  );
  return (
    <FlatList
      data={plan.courses}
      keyExtractor={(c) => c.id}
      renderItem={({ item }) => (
        <CourseRow
          course={item}
          sessions={plan.sessions.filter((s) => s.course === item.id).length}
          onOpen={(id) => navigation.navigate("Course", { id })}
        />
      )}
      ListHeaderComponent={header}
      ListHeaderComponentStyle={styles.listTop}
      ListFooterComponent={footer}
      style={{ backgroundColor: t.background }}
      contentContainerStyle={[styles.content, { paddingTop: insets.top + 24, paddingBottom: insets.bottom + 24 }]}
    />
  );
}

const styles = StyleSheet.create({
  content: { paddingHorizontal: 24 },
  header: { flexDirection: "row", alignItems: "center", gap: 12 },
  icon: { width: 40, height: 40 },
  title: { fontSize: 24, fontWeight: "700" },
  total: { marginVertical: 12, fontSize: 15 },
  listTop: { marginBottom: 16 },
  footer: { marginTop: 24, fontSize: 13 },
});
```

A linha de status da aula 4 se foi: apertar um curso agora **navega** até ele. O tipo `Props` combina as props
de tela da aba com as da pilha, para que `navigation.navigate("Course", …)`, uma rota da pilha chamada de
dentro de uma aba, também seja conferido pelo TypeScript.

A aba *This week* são as sessões da semana, na `SessionList` da aula 7. Salve-a como `src/WeekScreen.tsx`:

```tsx
// src/WeekScreen.tsx: every session of this week, whatever its course.
import { StyleSheet, View } from "react-native";
import data from "./courses.json";
import { mondayOf, type Plan } from "./planner";
import { SessionList } from "./SessionList";
import { useTheme } from "./theme";
import { today } from "./today";

const plan: Plan = data;

export function WeekScreen() {
  const t = useTheme();
  const monday = mondayOf(today());
  const week = plan.sessions.filter((s) => mondayOf(s.date) === monday);
  return (
    <View style={[styles.screen, { backgroundColor: t.background }]}>
      <SessionList sessions={week} />
    </View>
  );
}

const styles = StyleSheet.create({ screen: { flex: 1, paddingHorizontal: 24 } });
```

## A raiz

O `App.tsx` põe um `NavigationContainer` em volta dos navegadores. Ele guarda o estado de navegação do app
inteiro, liga-o à ação de voltar da plataforma e, na web, à barra de endereço. Troque-o por:

```tsx
// App.tsx: the planner's root: safe areas, then navigation with its addresses.
import { NavigationContainer } from "@react-navigation/native";
import { StatusBar } from "expo-status-bar";
import { initialWindowMetrics, SafeAreaProvider } from "react-native-safe-area-context";
import { linking, RootNavigator } from "./src/navigation";

export default function App() {
  return (
    <SafeAreaProvider initialMetrics={initialWindowMetrics}>
      <NavigationContainer linking={linking}>
        <RootNavigator />
      </NavigationContainer>
      <StatusBar style="auto" />
    </SafeAreaProvider>
  );
}
```

As abas não têm ícones. O `tabBarIcon: () => null` no `navigation.tsx` diz isso de propósito; a primeira
gravação desta aula desenhou um caractere provisório que o navegador não conseguia mostrar, porque nenhuma
fonte de ícones estava instalada. Um app acrescentaria o `@expo/vector-icons` e daria a cada aba uma figura
com o rótulo ao lado, nunca no lugar dele.
