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
