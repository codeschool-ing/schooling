---
title: As regras do planner vêm junto
version: 1
---

**O `src/planner.ts` entra no app nativo como está, byte por byte**, e os dados também. Copie os dois do
planner, e confira que a cópia é o mesmo arquivo:

```
ana@dev:~/planner-native$ mkdir src
ana@dev:~/planner-native$ cp ../planner/src/planner.ts ../planner/public/courses.json src/
ana@dev:~/planner-native$ cp ../planner/look.mjs .
ana@dev:~/planner-native$ cmp ../planner/src/planner.ts src/planner.ts && echo identical
identical
```

O `cmp` não imprime nada quando dois arquivos são idênticos, e é por isso que o `&& echo identical` está
ali. Uma cópia é o jeito mais simples de compartilhar um arquivo entre dois projetos. Uma equipe com
vários apps guardaria as regras num pacote próprio, num monorepo, para os dois apps importarem um arquivo
só; o ponto aqui é só que o arquivo não precisa de mudança nenhuma.

Agora troque o `App.tsx` pela tela do planner. É um componente, que a aula 8 divide em telas:

```schooling-example
{"language": "typescript", "file": "App.tsx", "parts": [{"code": "// App.tsx: the planner's screen, drawn with React Native's own components.\nimport { useState } from \"react\";\nimport { Pressable, StyleSheet, Text, View } from \"react-native\";\nimport { markDone, mondayOf, weekTotal, type Plan } from \"./src/planner\";\nimport data from \"./src/courses.json\";\n", "note": "Os componentes do React Native vêm de `react-native`, não do DOM, e as regras e os dados do planner dos dois arquivos copiados de `~/planner`. Importar JSON funciona como no Vite."}, {"code": "// The transcripts open the web build with ?today=2026-10-21, as lesson 1 does.\nconst query = typeof location === \"undefined\" ? \"\" : location.search;\nconst today = new URLSearchParams(query).get(\"today\") ?? new Date().toISOString().slice(0, 10);\n", "note": "Num celular não há barra de endereço, então `location` não existe; o teste mantém o `?today=` da aula 1 funcionando no navegador e cai na data real em qualquer outro lugar."}, {"code": "export default function App() {\n  const [plan, setPlan] = useState<Plan>(data);\n  const [open, setOpen] = useState<string | null>(null);\n  const total = weekTotal(plan, mondayOf(today));\n  return (\n    <View role=\"main\" style={styles.screen}>\n      <Text role=\"heading\" style={styles.title}>Study planner</Text>\n      <Text>This week: {total.done} of {total.planned} minutes done</Text>\n      {plan.courses.map((course) => (\n        <View key={course.id}>\n          <Pressable role=\"button\" onPress={() => setOpen(open === course.id ? null : course.id)}>\n            <Text style={styles.course}>{course.name}</Text>\n          </Pressable>\n          {open === course.id &&\n            plan.sessions.filter((s) => s.course === course.id).map((s) => (\n              <View key={s.id} style={styles.row}>\n                <Text>{s.date}, {s.minutes} min</Text>\n                {s.done ? <Text>done</Text> : (\n                  <Pressable role=\"button\" onPress={() => setPlan(markDone(plan, s.id))}>\n                    <Text style={styles.action}>Mark done</Text>\n                  </Pressable>\n                )}\n              </View>\n            ))}\n        </View>\n      ))}\n    </View>\n  );\n}\n", "note": "O componente. Dois estados, o plano e o curso aberto, e o total da semana calculado a partir deles a cada desenho pelo `weekTotal`, sem mudança. Apertar um curso o abre ou fecha; apertar **Mark done** troca o plano pelo que o `markDone` devolve. O `role` diz à tecnologia assistiva o que cada elemento é, como `<h1>` e `<button>` faziam na web."}, {"code": "const styles = StyleSheet.create({\n  screen: { flex: 1, padding: 24, gap: 8 },\n  title: { fontSize: 28, fontWeight: \"700\" },\n  course: { fontSize: 20, paddingVertical: 8 },\n  row: { flexDirection: \"row\", gap: 12, paddingLeft: 16 },\n  action: { color: \"#0a58ca\" },\n});", "note": "Os estilos são objetos JavaScript, com nomes que parecem CSS em camelCase e números sem unidade. A aula 8 é sobre o que existe e o que não existe ali."}]}
```

Confira os tipos, o que também confere que as funções do planner são chamadas do jeito que o
`planner.ts` as declara:

```
ana@dev:~/planner-native$ npx tsc --noEmit
```

**Nenhuma saída é a aprovação.** Depois exporte o app para a web, sirva a exportação como um host
estático serviria, e abra-a com o `look.mjs`, copiado do planner também:

```
ana@dev:~/planner-native$ npx expo export --platform web > /dev/null
ana@dev:~/planner-native$ ls dist
_expo
favicon.ico
index.html
metadata.json
```

```
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21'
- main:
  - heading "Study planner" [level=1]
  - text: "This week: 75 of 125 minutes done"
  - button "Spanish A2"
  - button "Statistics"
  - button "Guitar"
ana@dev:~/planner-native$ node look.mjs 'http://localhost:8082/?today=2026-10-21' --click 'Spanish A2' --click 'Mark done'
- main:
  - heading "Study planner" [level=1]
  - text: "This week: 105 of 125 minutes done"
  - button "Spanish A2"
  - text: 2026-10-19, 30 min done 2026-10-22, 30 min done
  - button "Statistics"
  - button "Guitar"
```

**A semana é a semana do planner**: 75 de 125, e depois 105 de 125 ao marcar como feita a sessão de
espanhol de 22 de outubro, os mesmos números que a aula 4 imprimiu, da mesma função. O que os desenhou é
diferente. No build web, o `react-native-web` transformou o `<Text>` em HTML; num celular, o mesmo
componente seria um rótulo nativo. As props `role` são o motivo de a árvore ainda dizer `heading` e
`button`: sem elas, um `<Pressable>` é uma caixa que recebe toques e não diz nada a um leitor de tela.

Faça o commit, no repositório que o `create-expo-app` criou:

```
ana@dev:~/planner-native$ git add . && git commit -q -m "The planner, drawn with React Native" && git log --oneline
174d42d The planner, drawn with React Native
a56282e Initial commit
```
