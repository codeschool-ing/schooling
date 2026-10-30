---
title: O desempacotamento forçado, e a quebra que ele promete
version: 1
---

A quarta resposta não é resposta para o caso `nil`. **O `!` depois de um opcional diz: há um valor
aqui dentro, e se eu estiver errado, pare o programa.** Ele lhe dá o valor simples e devolve a
quebra.

```swift
// Bang.swift
let good = Int("45")!
print(good + 1)
let bad = Int("forty")!
print(bad + 1)
```

```
ana@vm:~/sw/l02$ swiftc Bang.swift -o bang
ana@vm:~/sw/l02$ ./bang 2>&1 | head -5
bang/Bang.swift:4: Fatal error: Unexpectedly found nil while unwrapping an Optional value

*** Signal 4: Backtracing from 0x7f53791731ef... done ***

*** Program crashed: Illegal instruction at 0x00007f53791731ef ***
ana@vm:~/sw/l02$ script -qc ./bang /dev/null | tr -d '\r' | head -2
46
bang/Bang.swift:4: Fatal error: Unexpectedly found nil while unwrapping an Optional value
```

O desempacotamento da linha 4 encontrou `nil`, e o programa parou com um **erro fatal** antes do
último `print`. A primeira linha é a que se lê: onde, `bang/Bang.swift:4`, que é o módulo, o arquivo
e a linha, e por quê, `Unexpectedly found nil while unwrapping an Optional value`. O `head -5` guarda
essa linha e o começo do relatório da quebra; o relatório completo segue por umas cinquenta linhas.

**Falta uma linha nessa saída, e isso é uma lição por si.** O `print(good + 1)` rodou, e o `46` nunca
apareceu. Quando a saída vai para um pipe em vez de direto para um terminal, o programa junta o que
imprime num buffer e o escreve em pedaços grandes, e uma quebra encerra o processo antes de o buffer
ser escrito. O último comando roda o `./bang` através do `script`, que o faz acreditar que está
imprimindo num terminal, e o `tr` tira os retornos de carro que um terminal acrescenta: agora o `46`
está lá, acima do erro. **Saída que falta antes de uma quebra não prova que a linha não rodou.**

É o mesmo tipo de parada do estouro da lição 1, e pelo mesmo motivo. Um programa que seguisse em
frente teria um `bad` sem número dentro, e toda linha depois estaria adivinhando.

## Quando o ! é honesto

O `!` não é proibido. É uma afirmação, e algumas afirmações são verdadeiras por construção:

- um valor que o próprio programa acabou de montar, `URL(string: "https://swift.org")!`, em que o
  texto é fixo e correto;
- um teste, em que uma quebra com número de linha é exatamente a falha que você quer (lição 18);
- um programa curto que você vai jogar fora.

**O que ele nunca serve é para entrada**: qualquer coisa que uma estudante digitou, um arquivo lido, a
resposta de um servidor. É ali que `nil` é normal, e uma quebra ali é uma quebra na frente de alguém. O
mesmo vale para um `!` acrescentado porque o compilador reclamou: o segundo erro da seção 02 ofereceu o
`!` como jeito de fazer a mensagem sumir, e esse é o pior motivo para escrever um.

## O opcional desempacotado implicitamente

Você vai encontrar mais uma grafia em código antigo da Apple: um tipo escrito `String!` em vez de
`String?`. É um opcional que se desempacota sozinho toda vez que é usado, com uma quebra se for `nil`
naquele momento. Existe para valores atribuídos logo depois que um objeto é criado e antes que alguém
os leia, que é como o UIKit liga os controles de uma tela ao código. O `ios-apps` o encontra nesse
papel. Nos seus próprios tipos, escreva `?` e desempacote de propósito.
