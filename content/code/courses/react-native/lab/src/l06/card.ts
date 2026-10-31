// src/card.ts: a raised card, which each platform draws its own way.
import { Platform, type ViewStyle } from "react-native";

export const card: ViewStyle = {
  borderRadius: 12,
  padding: 16,
  ...Platform.select<ViewStyle>({
    ios: { shadowColor: "#000", shadowOpacity: 0.12, shadowRadius: 8, shadowOffset: { width: 0, height: 2 } },
    android: { elevation: 3 },
    default: { boxShadow: "0 2px 8px rgba(0, 0, 0, 0.12)" },
  }),
};
