// src/ErrorBoundary.tsx: when a screen throws while rendering, show a way out instead of a blank app,
// and say what happened where a developer will see it.
import { Component, type ErrorInfo, type ReactNode } from "react";
import { Pressable, StyleSheet, Text, View } from "react-native";

type State = { error: Error | null };

// A class, because only a class component can catch an error thrown by its children while they render.
export class ErrorBoundary extends Component<{ children: ReactNode }, State> {
  state: State = { error: null };

  static getDerivedStateFromError(error: Error): State {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    // In a release build this is where a crash reporter would be told; here, the log is enough.
    console.error("render failed:", error.message, "\n", error.stack, info.componentStack);
  }

  render() {
    if (!this.state.error) return this.props.children;
    return (
      <View style={styles.screen}>
        <Text role="alert" style={styles.text}>
          Something went wrong on this screen. Your sessions are safe.
        </Text>
        <Pressable role="button" onPress={() => this.setState({ error: null })} hitSlop={8}>
          <Text style={styles.action}>Try again</Text>
        </Pressable>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  screen: { flex: 1, justifyContent: "center", padding: 24, gap: 12 },
  text: { fontSize: 17 },
  action: { fontSize: 16, fontWeight: "600" },
});
