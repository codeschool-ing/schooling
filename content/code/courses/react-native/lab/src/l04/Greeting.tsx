// src/Greeting.tsx: a component is a function that returns what to draw.
import { Text } from "react-native";

type Props = { name: string; minutes: number };

export function Greeting({ name, minutes }: Props) {
  const unit = minutes === 1 ? "minute" : "minutes";
  return (
    <Text>
      {name}, you have {minutes} {unit} planned today.
    </Text>
  );
}
