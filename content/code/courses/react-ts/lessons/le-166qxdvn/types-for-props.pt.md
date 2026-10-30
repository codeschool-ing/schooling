---
title: O que um tipo de props promete
version: 1
---

**O tipo das props de um componente é um contrato conferido em todo lugar onde o componente é usado.**
Todo componente deste curso teve um, desde a aula 2: o `WeekNav` recebe um `monday` que é string e um
`onChange` que recebe uma. Quebre cada metade do contrato de propósito, com `sed`, e pergunte ao
compilador:

```
ana@dev:~/planner$ sed -i 's/<WeekNav monday={monday}/<WeekNav monday={19}/' src/WeekScreen.tsx && npx tsc -b
src/WeekScreen.tsx(16,16): error TS2322: Type 'number' is not assignable to type 'string'.
ana@dev:~/planner$ sed -i 's/<WeekNav monday={19}/<WeekNav monday={monday}/' src/WeekScreen.tsx && sed -i 's/<WeekNav monday={monday} onChange={setMonday} \/>/<WeekNav monday={monday} \/>/' src/WeekScreen.tsx && npx tsc -b
src/WeekScreen.tsx(9,18): error TS6133: 'setMonday' is declared but its value is never read.
src/WeekScreen.tsx(16,8): error TS2741: Property 'onChange' is missing in type '{ monday: string; }' but required in type 'WeekNavProps'.
ana@dev:~/planner$ sed -i 's/<WeekNav monday={monday} \/>/<WeekNav monday={monday} onChange={setMonday} \/>/' src/WeekScreen.tsx && npx tsc -b && echo no errors
no errors
```

- **Um número onde se prometeu uma string** é o TS2322, na linha e coluna exatas da prop.
- **Uma prop deixada de fora** é o TS2741, que nomeia a prop que falta e o tipo que a pediu. O compilador
  também notou que o `setMonday` ficou sem uso, que é o mesmo erro visto do outro lado.

Os dois teriam rodado num navegador, e os dois estariam errados lá: uma semana cuja segunda-feira é o
número 19, ou botões de semana que não fazem nada quando apertados. O terceiro comando devolveu a linha.

Os tipos do próprio React cobrem o que um tipo de props costuma precisar. Os que este curso usou, e mais
dois que uma biblioteca de componentes usa o tempo todo:

| tipo | para | usado em |
|---|---|---|
| `ReactNode` | qualquer coisa que o React desenha: texto, elementos, `null`, listas deles | o `title` do `Card`, aula 2 |
| `ComponentProps<'input'>` | toda prop que um elemento HTML aceita, `ref` inclusive | `Field`, aula 14 |
| `(value: string) => void` | um callback, tipado pelo que recebe | o `onChange` do `WeekNav` |
| `ChangeEvent<HTMLInputElement>` | o evento que o handler `onChange` de um input recebe | um handler escrito fora do JSX |
| `Dispatch<SetStateAction<T>>` | o setter que o `useState<T>` devolve, passado como prop | um filho que muda o estado do pai |

Dois hábitos deixam o contrato mais útil. **Dê ao tipo o nome do componente**, `WeekNavProps`, para a
mensagem de erro apontar para um lugar óbvio. E **tipe o que a prop significa, não o que por acaso é
passado**: `monday: string` deixa passar `'banana'`, que nenhum compilador pega, mas `onChange: (monday:
string) => void` diz exatamente o que o pai precisa aceitar, e é aí que acontece a maioria dos erros entre
componentes.
