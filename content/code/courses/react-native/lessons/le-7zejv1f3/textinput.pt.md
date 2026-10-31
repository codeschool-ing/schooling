---
title: TextInput, que sempre devolve uma string
version: 1
---

**O `TextInput` é o campo de texto do React Native**, um `EditText` nativo no Android e um `UITextField` no
iOS. Ele é controlado do mesmo jeito que o resto do React: a tela guarda o texto em estado, passa-o como
`value`, e o troca no `onChangeText`, que recebe o texto novo a cada tecla.

```tsx
const [minutes, setMinutes] = useState("");
<TextInput value={minutes} onChangeText={setMinutes} keyboardType="number-pad" />;
```

## Sempre uma string

**O `keyboardType="number-pad"` muda o teclado, não o valor.** O que chega ao `onChangeText` é uma string,
`"25"`, e num celular com teclado externo, ou depois de colar, pode ser `"25 min"` ou `"2.5"`. Por isso o
formulário do planner guarda os dois campos como strings num rascunho e só transforma os minutos em número na
hora de salvar, depois de conferi-los. Converter a cada tecla perde o que a pessoa digitou no momento em que
deixa de ser número, o que torna impossível corrigir um erro de digitação.

## As props que importam num celular

| prop | o que muda |
|---|---|
| `keyboardType` | que teclado aparece: `number-pad`, `email-address`, `numbers-and-punctuation`, … |
| `autoComplete` | o que o sistema pode oferecer para preencher; `off` para uma data que ele não tem como saber |
| `returnKeyType` | o rótulo da tecla de retorno: `next`, `done`, `send` |
| `onSubmitEditing` | o que apertar essa tecla faz |
| `secureTextEntry` | pontos no lugar dos caracteres, para uma senha |
| `aria-label` | o nome acessível do campo |

**Um placeholder não é um rótulo.** Ele some no momento em que a pessoa digita, costuma ser claro demais para
ler, e leitores de tela o tratam de jeitos diferentes. Cada campo do planner tem um `Text` visível acima dizendo
o que ele é, e um `aria-label` dizendo o mesmo à tecnologia assistiva, que é também como os testes o encontram:
`getByLabelText("Date")`.

## Datas, com honestidade

O campo de data recebe texto no formato `YYYY-MM-DD`, o que é desajeitado num celular. Um app de verdade usaria
um seletor de data, que em cada plataforma é um controle nativo diferente, e a biblioteca da comunidade
`@react-native-community/datetimepicker` embrulha os dois. *Ela não foi acrescentada aqui*: o seletor dela não
tem build web, e as execuções no navegador deste curso perderiam o formulário. A validação a seguir funciona do
mesmo jeito, seja o que for que preencha o campo.
