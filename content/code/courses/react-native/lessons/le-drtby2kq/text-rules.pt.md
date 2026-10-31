---
title: A string que não está dentro de um Text
version: 1
---

**Na web, um texto pode ficar direto num `<div>`. No React Native não pode**, e o erro que diz isso é o
primeiro que todo iniciante encontra. Vale encontrá-lo de propósito, num teste, onde ele não custa nada.

## Provocando o erro

Salve isto como `__tests__/bare-string.test.tsx`. Ele renderiza uma string direto dentro de uma `View`:

```tsx
// __tests__/bare-string.test.tsx: what happens to a string outside <Text>.
import { render } from "@testing-library/react-native";
import { View } from "react-native";

test("a string straight inside a View", async () => {
  await render(<View>This week</View>);
});
```

Rode só esse arquivo; o Jest aceita um pedaço de nome de arquivo e roda os arquivos que casam:

```
ana@dev:~/planner$ npx jest bare-string 2>&1 | grep -E "Invariant|Tests:"
    Invariant Violation: Text strings must be rendered within a <Text> component. Detected attempt to render "This week" string within a <View> component.
Tests:       1 failed, 1 total
```

A mensagem cita a string e o componente em que ela foi encontrada, o que é quase todo o trabalho de
corrigi-la. Num celular, o mesmo erro enche a tela com a caixa vermelha de erro da aula 18, em
desenvolvimento. **A checagem mora só no renderizador de desenvolvimento**: o renderizador de produção do
React Native a pula, então um build de release não para com essa mensagem, e o que ele faz no lugar não é
algo em que se possa confiar. Uma `View` nativa não tem onde pôr texto. Pegue o erro no desenvolvimento,
onde ele é barulhento.

Apague o arquivo; ele estava ali para falhar:

```sh
rm __tests__/bare-string.test.tsx
```

## Onde ele se esconde

Ninguém escreve `<View>This week</View>` de propósito. O erro aparece em três formas que parecem
inocentes:

| o que você escreveu | por que é uma string numa View |
|---|---|
| `{count && <Text>{count} sessions</Text>}` | quando `count` é `0`, a expressão vale `0`, e o React renderiza esse número como texto |
| um espaço ou um `.` perdido depois de um elemento na mesma linha | o JSX mantém o texto que fica entre dois elementos numa linha |
| `{course.name}` direto numa `View` | o nome é uma string, e só um `Text` consegue guardá-la |

**A primeira é a que chega à produção**, porque funciona em todo teste em que a contagem não é zero.
Escreva `{count > 0 && …}`, que vale `false` e não `0` quando a condição falha, e o React renderiza
`false` como nada.

## O Text também é onde ficam as fontes

Uma consequência da mesma regra: uma `View` não tem fonte. `color`, `fontSize` e `fontFamily` postos numa
`View` não fazem nada ao `Text` dentro dela, porque o texto não herda através de caixas, só através de
`Text` aninhado. A aula 5 volta a isso como o CSS que aqui não existe.
