// src/NotesPhoto.tsx: a photo of a course's notes, chosen from the library or taken with the camera.
import * as ImagePicker from "expo-image-picker";
import { useState } from "react";
import { Image, Linking, Pressable, StyleSheet, Text, View } from "react-native";
import { keepPhoto } from "./keepPhoto";
import { shrink } from "./shrink";
import { useTheme } from "./theme";

const OPTIONS: ImagePicker.ImagePickerOptions = { mediaTypes: ["images"], quality: 0.7 };
type Camera = "unasked" | "refused" | "blocked";

export function NotesPhoto({ course }: { course: string }) {
  const t = useTheme();
  const [uri, setUri] = useState<string | null>(null);
  const [camera, setCamera] = useState<Camera>("unasked");

  async function use(result: ImagePicker.ImagePickerResult) {
    if (result.canceled) return;
    const { uri, width, height } = result.assets[0];
    setUri(keepPhoto(await shrink(uri, width, height), course));
  }

  async function choose() {
    use(await ImagePicker.launchImageLibraryAsync(OPTIONS)); // the system's picker: no permission
  }

  async function take() {
    const permission = await ImagePicker.requestCameraPermissionsAsync();
    if (!permission.granted) {
      setCamera(permission.canAskAgain ? "refused" : "blocked");
      return;
    }
    setCamera("unasked");
    use(await ImagePicker.launchCameraAsync(OPTIONS));
  }

  return (
    <View style={styles.box}>
      <View style={styles.buttons}>
        <Pressable role="button" onPress={choose} hitSlop={8}>
          <Text style={[styles.action, { color: t.accent }]}>Choose a photo</Text>
        </Pressable>
        <Pressable role="button" onPress={take} hitSlop={8}>
          <Text style={[styles.action, { color: t.accent }]}>Take a photo</Text>
        </Pressable>
      </View>
      {camera === "refused" && (
        <Text role="alert" style={{ color: t.text }}>
          Without the camera the planner cannot take a photo. You can choose one you already have.
        </Text>
      )}
      {camera === "blocked" && (
        <View>
          <Text role="alert" style={{ color: t.text }}>
            The camera is turned off for the planner. You can turn it on in Settings.
          </Text>
          <Pressable role="button" onPress={() => Linking.openSettings()} hitSlop={8}>
            <Text style={[styles.action, { color: t.accent }]}>Open Settings</Text>
          </Pressable>
        </View>
      )}
      {uri && <Image source={{ uri }} aria-label="Your photo of the notes" style={styles.photo} resizeMode="contain" />}
    </View>
  );
}

const styles = StyleSheet.create({
  box: { gap: 8, paddingVertical: 8 },
  buttons: { flexDirection: "row", gap: 24 },
  action: { fontSize: 16, fontWeight: "600" },
  photo: { width: "100%", aspectRatio: 4 / 3 },
});
