// src/SwipeRow.web.tsx: on the web the row does not swipe. A mouse has the button beside it, and the
// swipe's two libraries were nearly half the web bundle (lesson 19 measured it).
import type { ReactNode } from "react";

export function SwipeRow({ children }: { onDone: () => void; children: ReactNode }) {
  return children;
}
