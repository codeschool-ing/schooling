---
title: Por que um map numa ScrollView deixa de funcionar
version: 1
---

**A aula 4 desenhou os cursos do planner com `map` dentro de uma `ScrollView`, e para três cursos isso está
certo.** Uma lista que cresce, sessões ao longo de um semestre, mensagens, resultados de busca, não pode ser
desenhada assim, e o motivo é um número que dá para medir.

Salve este teste como `__tests__/virtual.test.tsx`. Ele desenha mil linhas duas vezes, uma de cada jeito, e
conta quantas linhas cada um criou de fato:

```tsx
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
```

Rode-o:

```
ana@dev:~/planner$ npx jest virtual
  console.log
    ScrollView rows created: 1000

      at Object.log (__tests__/virtual.test.tsx:15:11)

  console.log
    FlatList rows created: 10

      at Object.log (__tests__/virtual.test.tsx:20:11)

PASS __tests__/virtual.test.tsx
  ✓ a ScrollView creates every row (436 ms)
  ✓ a FlatList creates the first screenful (36 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.994 s, estimated 1 s
Ran all test suites matching virtual.
```

**A ScrollView criou as mil.** Cada uma é um `Text`, então cada uma é uma view nativa, criada e posicionada
antes do primeiro quadro, e mantida na memória enquanto a tela estiver aberta, quer alguém role até ela ou
não. Num celular, isso é a demora antes de a tela aparecer, e a memória que não volta. **A FlatList criou
dez**: o bastante para encher uma tela, o padrão do `initialNumToRender` dela.

## O que é uma FlatList

A `FlatList` recebe os dados como um array e uma função que desenha um item, e decide sozinha quais itens
precisam existir. Ela renderiza os que estão perto da área visível e, conforme a pessoa rola, renderiza os
que entram na vista e desmonta os que ficaram muito para fora dela. Uma lista de dez mil sessões custa mais
ou menos o que uma de trinta custa.

As próximas seções são as três props de que toda FlatList precisa, por que a chave tem de ser um id, como a
janela de itens renderizados é dimensionada, e o que fazer quando os itens vêm em grupos.
