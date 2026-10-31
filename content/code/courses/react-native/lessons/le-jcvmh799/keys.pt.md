---
title: Chaves, e a linha que herda o estado da vizinha
version: 1
---

**Uma chave diz ao React qual elemento é qual de uma renderização para a seguinte.** Quando a lista muda, o
React casa os elementos novos com os antigos pela chave: mesma chave, mesmo componente, e o estado vem junto.
Erre a chave, e o estado vai para a linha que agora tem aquela chave.

## Uma chave que é uma posição

A chave errada mais comum é o índice, `key={i}`, porque ele está sempre ali e cala o aviso sobre chaves
faltando. Este teste mostra quanto isso custa. Cada linha guarda um pedaço de estado próprio, se foi aberta;
o teste abre *statistics*, depois remove *spanish*, a primeira linha, e imprime as linhas. Salve-o como
`__tests__/keys.test.tsx`:

```tsx
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
```

```
ana@dev:~/planner$ npx jest keys
  console.log
    by index: statistics, guitar (open)

      at Object.log (__tests__/keys.test.tsx:29:13)

  console.log
    by id: statistics (open), guitar

      at Object.log (__tests__/keys.test.tsx:29:13)

PASS __tests__/keys.test.tsx
  ✓ keyed by index (137 ms)
  ✓ keyed by id (8 ms)

Test Suites: 1 passed, 1 total
Tests:       2 passed, 2 total
Snapshots:   0 total
Time:        0.646 s, estimated 1 s
Ran all test suites matching keys.
```

**Com chave por índice, *guitar* agora está aberta, e ninguém a abriu.** Antes da remoção, *statistics* tinha
a chave 1 e *guitar* a chave 2. Depois, *statistics* tem a chave 0 e *guitar* a 1, então o React deu o estado
da chave 1, *open*, para *guitar*, e *statistics*, agora sob a chave 0, assumiu o estado fechado de *spanish*.
Com chave pelo id, cada linha mantém o seu.

Neste teste o estado é uma palavra. Num app, é uma anotação digitada pela metade, uma caixa marcada, um vídeo
tocando ou uma posição de rolagem, e ele aparece no item errado sem erro em lugar nenhum.

## A chave é o id

**Use o id estável do item**, o que os dados já carregam, que no planner é o `id` de cada curso e de cada
sessão. Uma FlatList o pede pelo `keyExtractor`; um `map` o recebe como `key`. Duas regras para escolher:

- **Ele não pode mudar** enquanto o item existir. Um nome não é chave: renomeie o curso e o React acha que é
  outro.
- **Ele precisa ser único na lista.** Dois itens com uma chave são um item só, até onde o React consegue
  saber.

É a mesma regra que os próprios dados do planner seguem: as sessões apontam para o curso pelo `id`, nunca
pelo nome, então renomear *Spanish A2* não muda nada do que se liga a ele. Uma chave é uma ligação entre duas
renderizações.

## Quando os dados não têm id

Dê um a eles, quando forem criados, e guarde-o. O `addSession` do `src/planner.ts` faz exatamente isso, com
`s` e um número. Um índice só é aceitável numa lista que nunca muda de ordem e nunca perde um item no meio, o
que é mais raro do que parece e não é uma propriedade que alguém confira.
