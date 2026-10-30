---
title: Escolhendo uma foto
version: 1
---

**O planner ganha uma foto das suas anotações para cada curso**, na tela do curso, abaixo de *Add a
session*. Ela pode vir de dois lugares, as fotos que já estão no celular ou a câmera, e um componente
cuida dos dois. Salve-o como `src/NotesPhoto.tsx`:

```schooling-example
{"language": "tsx", "file": "src/NotesPhoto.tsx", "parts": [{"code": "// src/NotesPhoto.tsx: a photo of a course's notes, chosen from the library or taken with the camera.\nimport * as ImagePicker from \"expo-image-picker\";\nimport { useState } from \"react\";\nimport { Image, Linking, Pressable, StyleSheet, Text, View } from \"react-native\";\nimport { keepPhoto } from \"./keepPhoto\";\nimport { useTheme } from \"./theme\";\n", "note": "A biblioteca do seletor, importada inteira como `ImagePicker` para cada chamada dizer de onde vem, e o `keepPhoto`, que a seção sobre arquivos escreve."}, {"code": "const OPTIONS: ImagePicker.ImagePickerOptions = { mediaTypes: [\"images\"], quality: 0.7 };\ntype Camera = \"unasked\" | \"refused\" | \"blocked\";\n", "note": "**As mesmas opções para os dois caminhos**: só imagens, e qualidade JPEG de 0,7, de 0 a 1, que mantém legível a foto de uma página com uma fração do tamanho. O estado da câmera tem um nome para cada resposta que importa."}, {"code": "export function NotesPhoto({ course }: { course: string }) {\n  const t = useTheme();\n  const [uri, setUri] = useState<string | null>(null);\n  const [camera, setCamera] = useState<Camera>(\"unasked\");\n", "note": "Uma foto por curso, guardada em estado por enquanto: a aula 14 é onde ela sobrevive a reiniciar o app."}, {"code": "  function use(result: ImagePicker.ImagePickerResult) {\n    if (!result.canceled) setUri(keepPhoto(result.assets[0].uri, course));\n  }\n", "note": "**Os dois seletores respondem do mesmo jeito**: `canceled` e, quando ele é falso, `assets`, um por foto. Um seletor cancelado deixa tudo como estava."}, {"code": "  async function choose() {\n    use(await ImagePicker.launchImageLibraryAsync(OPTIONS)); // the system's picker: no permission\n  }\n", "note": "Escolher não pede nada, pelo motivo que a primeira seção deu: o seletor do sistema entrega só o que a pessoa escolheu."}, {"code": "  async function take() {\n    const permission = await ImagePicker.requestCameraPermissionsAsync();\n    if (!permission.granted) {\n      setCamera(permission.canAskAgain ? \"refused\" : \"blocked\");\n      return;\n    }\n    setCamera(\"unasked\");\n    use(await ImagePicker.launchCameraAsync(OPTIONS));\n  }\n", "note": "**Tirar uma foto pede antes, toda vez.** Quando a resposta é um sim ou um não definitivo, o pedido a devolve na hora, sem diálogo. Uma recusa termina aqui, com o estado dizendo de que tipo."}, {"code": "  return (\n    <View style={styles.box}>\n      <View style={styles.buttons}>\n        <Pressable role=\"button\" onPress={choose} hitSlop={8}>\n          <Text style={[styles.action, { color: t.accent }]}>Choose a photo</Text>\n        </Pressable>\n        <Pressable role=\"button\" onPress={take} hitSlop={8}>\n          <Text style={[styles.action, { color: t.accent }]}>Take a photo</Text>\n        </Pressable>\n      </View>\n      {camera === \"refused\" && (\n        <Text role=\"alert\" style={{ color: t.text }}>\n          Without the camera the planner cannot take a photo. You can choose one you already have.\n        </Text>\n      )}\n      {camera === \"blocked\" && (\n        <View>\n          <Text role=\"alert\" style={{ color: t.text }}>\n            The camera is turned off for the planner. You can turn it on in Settings.\n          </Text>\n          <Pressable role=\"button\" onPress={() => Linking.openSettings()} hitSlop={8}>\n            <Text style={[styles.action, { color: t.accent }]}>Open Settings</Text>\n          </Pressable>\n        </View>\n      )}\n      {uri && <Image source={{ uri }} alt=\"Your photo of the notes\" style={styles.photo} resizeMode=\"contain\" />}\n    </View>\n  );\n}\n", "note": "Dois botões, e uma frase para cada recusa. Cada uma é um `role=\"alert\"`, anunciado quando aparece, e diz o que a pessoa pode fazer. Só a recusa definitiva oferece os Ajustes, pelo `Linking.openSettings()`, que abre a página do próprio app lá."}, {"code": "const styles = StyleSheet.create({\n  box: { gap: 8, paddingVertical: 8 },\n  buttons: { flexDirection: \"row\", gap: 24 },\n  action: { fontSize: 16, fontWeight: \"600\" },\n  photo: { width: \"100%\", aspectRatio: 4 / 3 },\n});", "note": "A foto ocupa a largura, num quadro de 4:3, e o `contain` a mostra inteira, seja qual for o formato."}]}
```

**O `uri` de uma foto escolhida aponta para o cache do app**, uma pasta que o sistema pode esvaziar quando
o celular fica sem espaço. A foto é mostrada de onde o `keepPhoto` a puser, e a seção sobre arquivos diz
onde é. Até lá o projeto não compila, e tudo bem: nada roda antes disso.

Depois ponha o componente na tela do curso. O `src/CourseScreen.tsx` ganha um import e uma linha:

```tsx
// src/CourseScreen.tsx: one course, its sessions, the way to add one, and a photo of its notes.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import { useLayoutEffect } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";
import type { RootParams } from "./navigation";
import { NotesPhoto } from "./NotesPhoto";
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
      <NotesPhoto course={course.id} />
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

## O que o seletor devolve

Cada asset traz mais que um endereço: a `width` e a `height` em pixels, um `mimeType`, um `fileName`
quando a plataforma conhece um, e um `fileSize`. O planner usa só o endereço. As opções podem pedir mais
trabalho ao seletor, `allowsEditing: true` para uma etapa de recorte, `allowsMultipleSelection: true` para
várias fotos de uma vez, mas cada uma acrescenta uma tela que a pessoa precisa atravessar, e a foto de uma
página não precisa de nenhuma das duas.
