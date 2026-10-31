---
title: A chave, e a ordem de duas chamadas
version: 1
---

Os lembretes ficam desligados até a pessoa ligá-los, no pé da aba *Courses*. Salve o
`src/RemindersSwitch.tsx`:

```tsx
// src/RemindersSwitch.tsx: the switch for session reminders, and the effect that keeps them in step
// with the plan while it is on.
import { useEffect, useState } from "react";
import { Platform, StyleSheet, Switch, Text, View } from "react-native";
import { usePlan } from "./planState";
import { remindersOn, scheduleReminders, setReminders } from "./reminders";
import { useTheme } from "./theme";

export function RemindersSwitch() {
  const { plan } = usePlan();
  const t = useTheme();
  const [on, setOn] = useState(false);
  const [refused, setRefused] = useState(false);
  useEffect(() => {
    remindersOn().then(setOn);
  }, []);
  useEffect(() => {
    if (on) scheduleReminders(plan);
  }, [on, plan]);
  // A browser's notifications are another system, which expo-notifications does not schedule.
  if (Platform.OS === "web") return null;
  async function change(want: boolean) {
    const result = await setReminders(want);
    setOn(result === "on");
    setRefused(result === "refused");
  }
  return (
    <View style={styles.box}>
      <View style={styles.row}>
        <Text style={[styles.label, { color: t.text }]}>Remind me on the day</Text>
        <Switch value={on} onValueChange={change} aria-label="Remind me on the day" />
      </View>
      {refused && (
        <Text role="alert" style={{ color: t.text }}>
          Notifications are off for the planner, so it cannot remind you. You can turn them on in Settings.
        </Text>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  box: { marginTop: 16, gap: 4 },
  row: { flexDirection: "row", alignItems: "center", justifyContent: "space-between" },
  label: { fontSize: 16 },
});
```

**O segundo efeito é o que mantém os lembretes verdadeiros.** Sempre que o plano muda, uma sessão feita,
acrescentada ou movida, e a chave está ligada, todos os lembretes são trocados. Marcar a sessão de guitar
como feita cancela o lembrete dela no mesmo segundo, que é a diferença entre um lembrete e uma cobrança.

**No Android 13 em diante, a ordem dentro do `setReminders` decide se a pessoa é perguntada.** O sistema
só mostra o diálogo de notificações a um app que tem pelo menos um **canal**, então o
`setNotificationChannelAsync` vem antes do `requestPermissionsAsync`. Pergunte antes e nenhum diálogo
aparece, e ninguém consegue saber por quê olhando a tela. Um canal também é o que a pessoa vê nas
configurações de notificação do app, uma chave por canal, então o nome dele, *Study reminders*, é escrito
para ela.

Na web a chave nem é desenhada: um navegador tem notificações próprias, que o `expo-notifications` não
agenda, e uma chave que não faz nada é pior que nenhuma. Depois a chave vai para o rodapé do
`src/PlanScreen.tsx`:

```tsx
// src/PlanScreen.tsx: the Courses tab, drawn from the shared plan, with the reminders switch at its foot.
import type { BottomTabScreenProps } from "@react-navigation/bottom-tabs";
import type { CompositeScreenProps } from "@react-navigation/native";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import { CourseRow } from "./CourseRow";
import type { RootParams, TabParams } from "./navigation";
import { usePlan } from "./planState";
import { RemindersSwitch } from "./RemindersSwitch";
import { mondayOf, weekTotal } from "./planner";
import { savedWhere } from "./savedWhere";
import { useTheme } from "./theme";
import { today } from "./today";
import { WeekBar } from "./WeekBar";

type Props = CompositeScreenProps<BottomTabScreenProps<TabParams, "Courses">, NativeStackScreenProps<RootParams>>;

export function PlanScreen({ navigation }: Props) {
  const { plan } = usePlan();
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
      <RemindersSwitch />
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
