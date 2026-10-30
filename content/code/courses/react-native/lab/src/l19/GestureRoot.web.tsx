// src/GestureRoot.web.tsx: on the web there are no gestures to root, so a plain view, and neither
// Gesture Handler nor the Reanimated it brings with it is in the web bundle.
export { View as GestureRoot } from "react-native";
