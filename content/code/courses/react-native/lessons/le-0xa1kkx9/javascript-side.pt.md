---
title: O lado JavaScript
version: 1
---

O tipo do módulo num celular diz o que o lado nativo promete. Salve o
`modules/week-start/src/WeekStartModule.ts`:

```ts
// modules/week-start/src/WeekStartModule.ts: the native module, as JavaScript sees it on a phone.
import { NativeModule, requireNativeModule } from "expo";

declare class WeekStartModule extends NativeModule {
  /** The first day of the week in the phone's calendar: 0 is Sunday, 1 Monday, as Date.getDay() counts. */
  firstWeekday(): number;
}

export default requireNativeModule<WeekStartModule>("WeekStart");
```

**O `requireNativeModule("WeekStart")` acha o módulo nativo pelo nome que o `Name` lhe deu**, e lança um
erro se não houver nenhum: um development build feito antes de o módulo existir, ou o Expo Go, que só traz
os módulos com que foi construído. O `declare class` é o tipo do módulo, escrito à mão. É uma promessa que o
compilador de TypeScript não consegue conferir contra o Kotlin, então o comentário diz exatamente o que o
número quer dizer.

Na web não há Kotlin nem Swift; a mesma pergunta vai ao `Intl` do navegador. Salve o
`modules/week-start/src/WeekStartModule.web.ts`:

```ts
// modules/week-start/src/WeekStartModule.web.ts: the same answer in a browser, from Intl.
import { NativeModule, registerWebModule } from "expo";

type WeekInfo = { firstDay: number }; // 1 is Monday … 7 is Sunday
type WithWeekInfo = Intl.Locale & { getWeekInfo?: () => WeekInfo; weekInfo?: WeekInfo };

class WeekStartModule extends NativeModule {
  firstWeekday() {
    const locale = new Intl.Locale(navigator.language) as WithWeekInfo;
    const info = locale.getWeekInfo?.() ?? locale.weekInfo;
    return info ? info.firstDay % 7 : 1; // a browser that cannot say gets Monday, the planner's own week
  }
}

export default registerWebModule(WeekStartModule, "WeekStart");
```

O `Intl.Locale` consegue descrever a semana de um locale, como `getWeekInfo()` nos navegadores mais novos e
`weekInfo` nos mais antigos, e conta segunda como 1 e domingo como 7, então o `% 7` transforma 7 em 0. Um
navegador sem nenhum dos dois recebe segunda, que é a semana do próprio planner. E os nomes dos dias,
compartilhados por todas as plataformas, vão no `modules/week-start/src/WeekStart.types.ts`:

```ts
// modules/week-start/src/WeekStart.types.ts: the names of the days, in the order firstWeekday counts them.
export const DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"] as const;
```

## Na tela

O planner não muda as semanas dele: os totais, a tela da semana e o diário contam todos a partir de
segunda, e mudar tudo isso é uma decisão de produto. O que ele pode fazer é dizer o que o celular acha, no pé
da aba *Courses*. No `src/PlanScreen.tsx`:

```tsx
// src/PlanScreen.tsx: the Courses tab, drawn from the shared plan, with the reminders switch and what the
// phone's calendar says about the week at its foot.
import type { BottomTabScreenProps } from "@react-navigation/bottom-tabs";
import type { CompositeScreenProps } from "@react-navigation/native";
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { FlatList, Image, StyleSheet, Text, View } from "react-native";
import { useSafeAreaInsets } from "react-native-safe-area-context";
import WeekStart, { DAYS } from "../modules/week-start";
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
      <Text style={[styles.footer, { color: t.muted }]}>
        Your phone's calendar starts the week on {DAYS[WeekStart.firstWeekday()]}; the planner's weeks start on Monday.
      </Text>
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

A função é síncrona, então o texto está certo na primeira renderização, sem efeito e sem estado de
carregamento. É por isso que o `firstWeekday` é uma `Function` e não uma `AsyncFunction`.
