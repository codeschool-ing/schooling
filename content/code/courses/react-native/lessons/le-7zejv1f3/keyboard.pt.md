---
title: O teclado que cobre o campo
version: 1
---

**Quando um campo de texto recebe o foco, o teclado do sistema sobe por cima da metade de baixo da tela**, e o
que estava ali, o próximo campo, o botão *Save*, agora fica por baixo dele. Nenhuma das plataformas tira o seu
conteúdo do caminho sozinha do mesmo jeito, e cada prop de teclado do formulário é uma resposta a uma parte
disso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" data-fig=\"l11-keyboard\" aria-label=\"Duas telas de celular com o teclado aberto. À esquerda, sem KeyboardAvoidingView, o teclado cobre o campo de minutos e o botão Save. À direita, com ele no iOS, um padding igual à altura do teclado empurra o formulário para cima, e o campo em foco e o Save continuam visíveis acima do teclado.\"><text x=\"170\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">sem</text><text x=\"510\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">com KeyboardAvoidingView</text><rect x=\"70\" y=\"30\" width=\"200\" height=\"300\" rx=\"14\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"90\" y=\"140\" width=\"160\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"100\" y=\"153.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Date</text><rect x=\"72\" y=\"180\" width=\"196\" height=\"146\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"170\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">teclado</text><text x=\"170\" y=\"260\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--amber)\">escondidos sob o teclado</text><rect x=\"410\" y=\"30\" width=\"200\" height=\"300\" rx=\"14\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><rect x=\"430\" y=\"50\" width=\"160\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"440\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Date</text><rect x=\"430\" y=\"90\" width=\"160\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"440\" y=\"103.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Minutes</text><rect x=\"430\" y=\"130\" width=\"160\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"510.0\" y=\"143.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">Save session</text><rect x=\"412\" y=\"180\" width=\"196\" height=\"146\" rx=\"6\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"510\" y=\"254\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">teclado</text></svg>", "caption": "O teclado ocupa metade da tela; o formulário precisa sair do caminho dele, e cada plataforma faz isso de um jeito.", "same": ["Date", "Minutes", "Save session"]}
```

## KeyboardAvoidingView

O `KeyboardAvoidingView` ajusta o conteúdo quando o teclado aparece. O `behavior` dele precisa mudar por
plataforma, e é por isso que o formulário o escreve com um ternário:

| plataforma | `behavior` | por quê |
|---|---|---|
| iOS | `"padding"` | acrescenta um padding igual à altura do teclado, empurrando o conteúdo para cima |
| Android | nenhum | o Android redimensiona a janela do app sozinho, por padrão em projetos Expo |

Dentro dele, o formulário é uma `ScrollView`, para que uma tela alta demais para o que sobra acima do teclado
ainda possa rolar até o último campo. *Como isso fica com o teclado aberto não foi rodado para este curso*: o
build web não tem teclado na tela para empurrar nada, e não havia celular. É ensinado a partir da documentação
do React Native para o `KeyboardAvoidingView`, e é a parte de um formulário que mais vale experimentar num
aparelho de verdade.

## Toques com o teclado aberto

O `keyboardShouldPersistTaps="handled"` na `ScrollView`, como disse a aula 4. Sem ele, o primeiro toque em
*Save* com o teclado aberto só fecha o teclado, e a pessoa precisa tocar de novo; com ele, um toque em algo que
o trata, um botão, vai para essa coisa.

## Passando de um campo para outro

A tecla de retorno do campo de data tem o rótulo *next* (`returnKeyType="next"`), e apertá-la chama o
`onSubmitEditing`, que dá o foco ao campo de minutos por uma ref:

```tsx
onSubmitEditing={() => minutesRef.current?.focus()}
```

A tecla do campo de minutos diz *done*, e apertá-la salva. Uma pessoa consegue preencher o formulário sem nunca
levar o dedo à tela acima do teclado, que é como formulários em celulares devem parecer.

## O teclado certo para cada campo

`keyboardType="numbers-and-punctuation"` para a data, porque ela precisa de dígitos e hífens; `number-pad` para
os minutos, que só precisam de dígitos. No iOS, o `number-pad` não tem tecla de retorno, então o campo de
minutos não pode ser enviado pelo teclado ali: o botão *Save* é o caminho, e ele está sempre alcançável porque
a view subiu. É uma diferença de plataforma exatamente do tipo da aula 6, encontrada lendo a documentação do
`keyboardType` e não adivinhando.
