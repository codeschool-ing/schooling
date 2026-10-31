// __tests__/keys.test.tsx: what a key that is a position does when a row goes away.
import { fireEvent, render, screen } from "@testing-library/react-native";
import { useState } from "react";
import { Pressable, Text, View } from "react-native";

function Row({ name }: { name: string }) {
  const [open, setOpen] = useState(false); // state that belongs to this row
  return (
    <Pressable role="button" onPress={() => setOpen(true)}>
      <Text>
        {name}
        {open ? " (open)" : ""}
      </Text>
    </Pressable>
  );
}

function List({ names, byIndex }: { names: string[]; byIndex: boolean }) {
  return <View>{names.map((n, i) => <Row key={byIndex ? i : n} name={n} />)}</View>;
}

for (const byIndex of [true, false]) {
  test(`keyed by ${byIndex ? "index" : "id"}`, async () => {
    const names = ["spanish", "statistics", "guitar"];
    const view = await render(<List names={names} byIndex={byIndex} />);
    await fireEvent.press(screen.getByText("statistics"));
    await view.rerender(<List names={names.slice(1)} byIndex={byIndex} />); // spanish removed
    const rows = screen.getAllByText(/spanish|statistics|guitar/);
    console.log(`by ${byIndex ? "index" : "id"}:`, rows.map((t) => [t.props.children].flat().join("")).join(", "));
  });
}
