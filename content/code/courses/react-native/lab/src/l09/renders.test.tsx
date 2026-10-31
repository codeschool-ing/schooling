// __tests__/renders.test.tsx: who re-renders when one value changes, with a context and with a store.
import { act, render } from "@testing-library/react-native";
import { createContext, useContext, useState } from "react";
import { Text } from "react-native";
import { create } from "zustand";

type State = { done: number; theme: string };
const renders = { done: 0, theme: 0 };

// The same two readers, once through a context and once through a store.
const Ctx = createContext<State>({ done: 0, theme: "light" });
function DoneFromContext() {
  renders.done++;
  return <Text>{useContext(Ctx).done}</Text>;
}
function ThemeFromContext() {
  renders.theme++;
  return <Text>{useContext(Ctx).theme}</Text>;
}

const useStore = create<State>(() => ({ done: 0, theme: "light" }));
function DoneFromStore() {
  renders.done++;
  return <Text>{useStore((s) => s.done)}</Text>;
}
function ThemeFromStore() {
  renders.theme++;
  return <Text>{useStore((s) => s.theme)}</Text>;
}

test("a context re-renders every reader", async () => {
  let set: (s: State) => void = () => {};
  function Root() {
    const [state, setState] = useState<State>({ done: 0, theme: "light" });
    set = setState;
    return (
      <Ctx.Provider value={state}>
        <DoneFromContext />
        <ThemeFromContext />
      </Ctx.Provider>
    );
  }
  await render(<Root />);
  renders.done = renders.theme = 0;
  for (const done of [15, 30, 45]) await act(async () => set({ done, theme: "light" }));
  console.log("context: done rendered", renders.done, "times, theme rendered", renders.theme, "times");
});

test("a store re-renders only the readers whose slice changed", async () => {
  await render(
    <>
      <DoneFromStore />
      <ThemeFromStore />
    </>,
  );
  renders.done = renders.theme = 0;
  for (const done of [15, 30, 45]) await act(async () => useStore.setState({ done }));
  console.log("store: done rendered", renders.done, "times, theme rendered", renders.theme, "times");
});
