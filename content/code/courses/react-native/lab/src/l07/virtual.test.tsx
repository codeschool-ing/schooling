// __tests__/virtual.test.tsx: a thousand rows, drawn by a ScrollView and by a FlatList.
import { render, screen } from "@testing-library/react-native";
import { FlatList, ScrollView, Text } from "react-native";

const rows = Array.from({ length: 1000 }, (_, i) => ({ id: `r${i}`, label: `Row ${i}` }));

test("a ScrollView creates every row", async () => {
  await render(
    <ScrollView>
      {rows.map((r) => (
        <Text key={r.id}>{r.label}</Text>
      ))}
    </ScrollView>,
  );
  console.log("ScrollView rows created:", screen.queryAllByText(/^Row /).length);
});

test("a FlatList creates the first screenful", async () => {
  await render(<FlatList data={rows} keyExtractor={(r) => r.id} renderItem={({ item }) => <Text>{item.label}</Text>} />);
  console.log("FlatList rows created:", screen.queryAllByText(/^Row /).length);
});
