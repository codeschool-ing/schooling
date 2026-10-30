---
title: Choosing a photo
version: 1
---

**The planner gets a photo of your notes for each course**, on the course's screen under *Add a
session*. It can come from two places, the photos already on the phone or the camera, and one component
handles both. Save it as `src/NotesPhoto.tsx`:

```schooling-example
{"language": "tsx", "file": "src/NotesPhoto.tsx", "parts": [{"code": "// src/NotesPhoto.tsx: a photo of a course's notes, chosen from the library or taken with the camera.\nimport * as ImagePicker from \"expo-image-picker\";\nimport { useState } from \"react\";\nimport { Image, Linking, Pressable, StyleSheet, Text, View } from \"react-native\";\nimport { keepPhoto } from \"./keepPhoto\";\nimport { useTheme } from \"./theme\";\n", "note": "The picker library, imported whole as `ImagePicker` so every call says where it comes from, and `keepPhoto`, which the section on files writes."}, {"code": "const OPTIONS: ImagePicker.ImagePickerOptions = { mediaTypes: [\"images\"], quality: 0.7 };\ntype Camera = \"unasked\" | \"refused\" | \"blocked\";\n", "note": "**The same options for both ways in**: images only, and a JPEG quality of 0.7, from 0 to 1, which keeps a photo of a page legible at a fraction of the size. The camera's state has a name for each answer that matters."}, {"code": "export function NotesPhoto({ course }: { course: string }) {\n  const t = useTheme();\n  const [uri, setUri] = useState<string | null>(null);\n  const [camera, setCamera] = useState<Camera>(\"unasked\");\n", "note": "One photo per course, kept in state for now: lesson 14 is where it survives a restart."}, {"code": "  function use(result: ImagePicker.ImagePickerResult) {\n    if (!result.canceled) setUri(keepPhoto(result.assets[0].uri, course));\n  }\n", "note": "**Both pickers answer the same way**: `canceled`, and when it is false, `assets`, one per photo. A cancelled picker leaves everything as it was."}, {"code": "  async function choose() {\n    use(await ImagePicker.launchImageLibraryAsync(OPTIONS)); // the system's picker: no permission\n  }\n", "note": "Choosing asks for nothing, for the reason the first section gave: the system's picker hands over only what the person picked."}, {"code": "  async function take() {\n    const permission = await ImagePicker.requestCameraPermissionsAsync();\n    if (!permission.granted) {\n      setCamera(permission.canAskAgain ? \"refused\" : \"blocked\");\n      return;\n    }\n    setCamera(\"unasked\");\n    use(await ImagePicker.launchCameraAsync(OPTIONS));\n  }\n", "note": "**Taking a photo asks first, every time.** Once the answer is a yes or a final no, the request returns it at once, with no dialog. A refusal ends here, with the state saying which kind."}, {"code": "  return (\n    <View style={styles.box}>\n      <View style={styles.buttons}>\n        <Pressable role=\"button\" onPress={choose} hitSlop={8}>\n          <Text style={[styles.action, { color: t.accent }]}>Choose a photo</Text>\n        </Pressable>\n        <Pressable role=\"button\" onPress={take} hitSlop={8}>\n          <Text style={[styles.action, { color: t.accent }]}>Take a photo</Text>\n        </Pressable>\n      </View>\n      {camera === \"refused\" && (\n        <Text role=\"alert\" style={{ color: t.text }}>\n          Without the camera the planner cannot take a photo. You can choose one you already have.\n        </Text>\n      )}\n      {camera === \"blocked\" && (\n        <View>\n          <Text role=\"alert\" style={{ color: t.text }}>\n            The camera is turned off for the planner. You can turn it on in Settings.\n          </Text>\n          <Pressable role=\"button\" onPress={() => Linking.openSettings()} hitSlop={8}>\n            <Text style={[styles.action, { color: t.accent }]}>Open Settings</Text>\n          </Pressable>\n        </View>\n      )}\n      {uri && <Image source={{ uri }} alt=\"Your photo of the notes\" style={styles.photo} resizeMode=\"contain\" />}\n    </View>\n  );\n}\n", "note": "Two buttons, and a sentence for each refusal. Each is a `role=\"alert\"`, announced when it appears, and says what the person can do. Only the final refusal offers Settings, through `Linking.openSettings()`, which opens the app's own page there."}, {"code": "const styles = StyleSheet.create({\n  box: { gap: 8, paddingVertical: 8 },\n  buttons: { flexDirection: \"row\", gap: 24 },\n  action: { fontSize: 16, fontWeight: \"600\" },\n  photo: { width: \"100%\", aspectRatio: 4 / 3 },\n});", "note": "The photo fills the width, in a 4:3 frame, and `contain` shows all of it whatever its shape."}]}
```

**A picked photo's `uri` points into the app's cache**, a folder the system is allowed to empty when the
phone runs short of space. The photo is shown from wherever `keepPhoto` puts it, and the section on files
says where that is. Until then the project does not compile, which is fine: nothing runs before then.

Then put the component on the course's screen. `src/CourseScreen.tsx` gains one import and one line:

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

## What the picker gives back

Each asset carries more than an address: its `width` and `height` in pixels, a `mimeType`, a `fileName`
when the platform knows one, and a `fileSize`. The planner uses only the address. The options can ask for
more work from the picker, `allowsEditing: true` for a cropping step, `allowsMultipleSelection: true` for
several photos at once, but each adds a screen the person has to get through, and a photo of a page needs
neither.
