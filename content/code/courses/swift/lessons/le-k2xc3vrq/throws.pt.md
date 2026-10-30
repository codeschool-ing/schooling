---
title: Erros que fazem parte do tipo de uma função
version: 1
---

A aula 2 usou um opcional para um valor que pode faltar: `Int("forty")` é `nil`, e é tudo o que ele
diz. **Quando quem chama precisa saber por que algo falhou, um `nil` não basta**, e a resposta do
Swift é um erro: um valor que descreve a falha, lançado pela função que a encontrou e pego por quem
puder lidar com ela.

Um erro é qualquer tipo que conforma ao protocolo `Error`, e um enum é a escolha comum, porque cada
caso nomeia um jeito de falhar e pode carregar o que quem chama precisa saber (aula 7). Uma função
que pode falhar diz isso com **`throws`** entre os parâmetros e o tipo de retorno, e falha com
**`throw`**:

```swift
// Throws.swift
enum PlannerError: Error {
    case notANumber(String)
    case tooLong(minutes: Int)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else {
        throw PlannerError.notANumber(text)
    }
    guard minutes <= 240 else {
        throw PlannerError.tooLong(minutes: minutes)
    }
    return minutes
}

let minutes = parseMinutes("45")
print(minutes)
```

```
ana@vm:~/sw/l12$ swiftc Throws.swift -o throws
Throws.swift:17:15: error: call can throw but is not marked with 'try'
15 | }
16 | 
17 | let minutes = parseMinutes("45")
   |               |- error: call can throw but is not marked with 'try'
   |               |- note: did you mean to use 'try'?
   |               |- note: did you mean to handle error as optional value?
   |               `- note: did you mean to disable error propagation?
18 | print(minutes)
19 | 
```

**O compilador recusa a chamada, não a função.** A `parseMinutes` está certa. O que é recusado é
chamá-la como se ela não pudesse falhar: uma função marcada com `throws` só pode ser chamada com
`try` na frente, e as três notas são os três jeitos de escrever isso, que as seções 03 e 04 cobrem. A
regra põe na página todo lugar de onde um erro pode vir, onde quem lê o vê, em vez de só na
declaração da função, três arquivos adiante.

## O que o `try` faz com o erro

O `try` sozinho não trata nada. **Ele repassa o erro**: se a chamada lança, a função que contém o
`try` para ali e lança o mesmo erro para quem a chamou. Isso só é permitido dentro de uma função que
também é marcada com `throws`, ou no nível de cima de um programa, onde não sobra ninguém que chame:

```swift
// Uncaught.swift
enum PlannerError: Error {
    case notANumber(String)
}

func parseMinutes(_ text: String) throws -> Int {
    guard let minutes = Int(text) else { throw PlannerError.notANumber(text) }
    return minutes
}

print(try parseMinutes("45"))
print(try parseMinutes("forty"))
print("never printed")
```

```
ana@vm:~/sw/l12$ swiftc Uncaught.swift -o uncaught
ana@vm:~/sw/l12$ SWIFT_BACKTRACE=enable=no ./uncaught
45
Swift/ErrorType.swift:254: Fatal error: Error raised at top level: uncaught.PlannerError.notANumber("forty")
Current stack trace:
0    libswiftCore.so                    0x00007fc381f62cd0 swift_reportError + 33
1    libswiftCore.so                    0x00007fc382319190 _swift_stdlib_reportFatalErrorInFile + 109
2    libswiftCore.so                    0x00007fc381f734e1 <unavailable> + 1520865
3    libswiftCore.so                    0x00007fc382109e90 _assertionFailure(_:_:file:line:flags:) + 299
4    libswiftCore.so                    0x00007fc382169600 swift_errorInMain + 766
5    uncaught                           0x0000563e71a7ecb3 <unavailable> + 7347
6    libc.so.6                          0x00007fc381a2a1ca <unavailable> + 172490
7    libc.so.6                          0x00007fc381a2a200 __libc_start_main + 139
8    uncaught                           0x0000563e71a7e155 <unavailable> + 4437
```

A primeira chamada imprimiu 45. A segunda lançou, nada a pegou, e o erro chegou ao topo do programa,
onde o Swift para o processo com **`Error raised at top level`** e o próprio erro:
`uncaught.PlannerError.notANumber("forty")`, o módulo, o tipo, o caso e o valor que ele carregava. O
`never printed` não foi impresso. O `SWIFT_BACKTRACE=enable=no` mantém o relatório de quebra no stack
trace curto, como na aula 11.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 256\" role=\"img\" data-fig=\"l12-propagation\" aria-label=\"Um diagrama de chamadas empilhadas de baixo para cima. Embaixo, parseMinutes lança PlannerError.notANumber. Acima dela, uma função marcada com throws que a chama com try repassa o erro. O caminho 1, à esquerda, termina num bloco do com catch, onde o erro é tratado. O caminho 2, à direita, chega ao nível de cima sem catch, e o programa para com um erro fatal.\"><defs><marker id=\"l12-propagation-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l12-propagation-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker><marker id=\"l12-propagation-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"200\" y=\"196\" width=\"320\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"211\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">parseMinutes(\"forty\")</text><text x=\"360\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">lança PlannerError.notANumber</text><rect x=\"200\" y=\"112\" width=\"320\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"127\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">func total(…) throws</text><text x=\"360\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">marcada com try, numa função que lança: repassa</text><path d=\"M360 194 L360 158\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-propagation-ah-amber)\"></path><rect x=\"30\" y=\"24\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"180\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">caminho 1</text><text x=\"180\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">do { try … } catch: tratado aqui</text><rect x=\"390\" y=\"24\" width=\"300\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\" stroke-dasharray=\"5 3\"></rect><text x=\"540\" y=\"39\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">caminho 2</text><text x=\"540\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">ninguém pega: erro fatal no nível de cima</text><path d=\"M330 110 L210 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l12-propagation-ah-phosphor)\"></path><path d=\"M390 110 L510 70\" stroke=\"var(--amber)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l12-propagation-ah-amber)\"></path></svg>", "caption": "Um erro sobe pelas chamadas, do throw até o primeiro do/catch que o trata, passando por toda função marcada com throws. Se chegar antes ao topo do programa, o programa para."}
```

**Um erro lançado não é uma quebra.** É um valor comum subindo pelas chamadas, e só encerra o
programa quando nada no caminho o pega. A seção 02 é sobre pegá-lo.
