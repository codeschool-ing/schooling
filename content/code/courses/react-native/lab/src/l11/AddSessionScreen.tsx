// src/AddSessionScreen.tsx: a form for one new session: two fields, their errors, and the keyboard.
import type { NativeStackScreenProps } from "@react-navigation/native-stack";
import React, { useEffect, useRef, useState } from "react";
import { Alert, KeyboardAvoidingView, Platform, Pressable, ScrollView, StyleSheet, Text, TextInput } from "react-native";
import type { RootParams } from "./navigation";
import { useAddSession } from "./planState";
import { useTheme } from "./theme";
import { validate, type Draft, type Errors } from "./validate";

type Props = NativeStackScreenProps<RootParams, "AddSession">;

export function AddSessionScreen({ route, navigation }: Props) {
  const t = useTheme();
  const add = useAddSession();
  const [draft, setDraft] = useState<Draft>({ date: "", minutes: "" });
  const [errors, setErrors] = useState<Errors>({});
  const minutesRef = useRef<React.ComponentRef<typeof TextInput>>(null);
  const saved = useRef(false);
  const dirty = draft.date !== "" || draft.minutes !== "";

  // Leaving with something typed asks first, however the person tries to leave.
  useEffect(() => {
    return navigation.addListener("beforeRemove", (e) => {
      if (!dirty || saved.current) return;
      e.preventDefault();
      Alert.alert("Discard this session?", "What you typed will be lost.", [
        { text: "Keep editing", style: "cancel" },
        { text: "Discard", style: "destructive", onPress: () => navigation.dispatch(e.data.action) },
      ]);
    });
  }, [navigation, dirty]);

  async function save() {
    const found = validate(draft);
    setErrors(found);
    if (Object.keys(found).length > 0) return;
    try {
      await add.mutateAsync({ course: route.params.course, date: draft.date, minutes: Number(draft.minutes) });
    } catch {
      return; // add.error now holds the reason, and the form shows it below the fields
    }
    saved.current = true; // what was typed is on the server: leaving loses nothing
    navigation.goBack();
  }

  const field = (key: keyof Draft) => [styles.input, { color: t.text, borderColor: errors[key] ? t.danger : t.line }];
  const error = [styles.error, { color: t.danger }];
  return (
    <KeyboardAvoidingView style={{ flex: 1 }} behavior={Platform.OS === "ios" ? "padding" : undefined}>
      <ScrollView style={{ backgroundColor: t.background }} contentContainerStyle={styles.form} keyboardShouldPersistTaps="handled">
        <Text style={[styles.label, { color: t.text }]}>
          Date
        </Text>
        <TextInput
          aria-label="Date"
          value={draft.date}
          onChangeText={(date) => setDraft({ ...draft, date })}
          placeholder="2026-10-23"
          keyboardType="numbers-and-punctuation"
          autoComplete="off"
          returnKeyType="next"
          onSubmitEditing={() => minutesRef.current?.focus()}
          style={field("date")}
        />
        {errors.date && <Text role="alert" style={error}>{errors.date}</Text>}
        <Text style={[styles.label, { color: t.text }]}>
          Minutes
        </Text>
        <TextInput
          ref={minutesRef}
          aria-label="Minutes"
          value={draft.minutes}
          onChangeText={(minutes) => setDraft({ ...draft, minutes })}
          placeholder="30"
          keyboardType="number-pad"
          returnKeyType="done"
          onSubmitEditing={save}
          style={field("minutes")}
        />
        {errors.minutes && <Text role="alert" style={error}>{errors.minutes}</Text>}
        {add.error && <Text role="alert" style={error}>The server refused it: {add.error.message}</Text>}
        <Pressable role="button" onPress={save} disabled={add.isPending} style={[styles.save, { backgroundColor: t.accent }]}>
          <Text style={[styles.saveText, { color: t.background }]}>{add.isPending ? "Saving" : "Save session"}</Text>
        </Pressable>
      </ScrollView>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  form: { padding: 24, gap: 8 },
  label: { fontSize: 15, fontWeight: "600", marginTop: 8 },
  input: { borderWidth: 1, borderRadius: 8, padding: 12, fontSize: 17 },
  error: { fontSize: 14 },
  save: { marginTop: 16, padding: 14, borderRadius: 8, alignItems: "center" },
  saveText: { fontSize: 17, fontWeight: "600" },
});
