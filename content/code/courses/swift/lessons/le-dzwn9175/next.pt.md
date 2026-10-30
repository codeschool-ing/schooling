---
title: O que o ios-apps leva deste curso
version: 1
---

O `ios-apps` constrói o planner de estudos como app de iPhone, em vinte e duas lições, com SwiftUI e
SwiftData. Ele pressupõe este curso e nada mais. **Ele não ensina a linguagem de novo**, então a
tabela abaixo é a lista honesta do que ele vai esperar que você leia sem parar.

| no `ios-apps` | apoia-se em | aqui |
|---|---|---|
| lição 3, views como valores, e um body que roda de novo | structs, semântica de valor e propriedades computadas | lições 5 e 6 |
| lição 5, modificadores, em que a ordem importa | métodos que devolvem um valor novo em vez de mudar um | lições 3 e 5 |
| lição 6, `@State` e `@Binding` | property wrappers e a projeção `$` | lição 16 |
| lições 2 e 4, o app e o layout em stacks | result builders, e `some View` como tipo opaco | lições 16 e 9 |
| lição 7, `@Observable` e o environment | classes, referências e uma macro vista de fora | lições 5 e 16 |
| lição 8, listas, `ForEach` e identidade | `Identifiable`, `Hashable` e protocolos com implementações padrão | lições 8 e 9 |
| lição 12, `URLSession` com `async`/`await` | funções `async`, `Codable` e erros | lições 12, 13 e 14 |
| lição 13, modelos do SwiftData | classes, macros e opcionais | lições 2, 5 e 16 |
| lição 14, o repositório entre a rede e o armazenamento | protocolos como pontos de troca, genéricos | lições 9 e 10 |
| toda tela, toda lição | o `@MainActor` e a verificação de `Sendable` | lição 15 |
| lição 20, testes unitários e de interface | XCTest e Swift Testing | lição 18 |

## O modelo do planner já está escrito

O planner do `ios-apps` é o planner deste curso: cursos, sessões de estudo com data e duração,
marcadas como feitas, e o total da semana contra uma meta. **A camada de modelo que você construiu
aqui, as structs, os enums, as conformidades a `Codable` e os testes, é a parte que passa como
código**, porque nada dela importa coisa alguma da Apple. O que o `ios-apps` acrescenta são as telas,
o armazenamento no aparelho e o trabalho de levar um app até um celular.

## Se você não tem um Mac

O caminho pela trilha `mobile` tem três opções, e esta é a que precisa do hardware da Apple em
seguida. Tudo o que você aprendeu aqui continua seu: Swift num servidor, como a seção 04 construiu, é
um trabalho por si só, e a linguagem é a mesma que um desenvolvedor iOS escreve. Se o próximo passo
tiver de ser um Mac, pode ser um alugado por hora, como a seção 06 disse, pelas semanas que levar.
