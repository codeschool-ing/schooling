---
title: Uma linguagem na página, quatro na trilha
version: 1
---

**Todo programa deste curso é Python, e essa é uma decisão tomada por você, então aqui vai o
raciocínio.** A trilha que traz você até aqui, `software-architecture`, continua a `backend`, e a
`backend` deixa escolher a linguagem do servidor: JavaScript com Node.js, Python, Java ou Go. Então
você chega com uma de quatro, e um curso sobre projeto precisa mostrar projetos em código que alguém
consiga rodar.

Havia três caminhos. Quatro versões de cada exemplo seriam quatro vezes a leitura e enterrariam o
projeto debaixo da sintaxe. Pseudocódigo não roda em lugar nenhum, e um padrão que não roda é um
padrão em que você precisa acreditar sem ver. Sobrou uma linguagem só, escolhida pelo pouco que ela
atrapalha. O Python ganha nisso por dois motivos: uma classe com dois métodos tem umas dez linhas, e
o interpretador já vem instalado na maioria das máquinas Linux e está a um download de distância nas
outras.

**O que você aprende aqui não é Python.** Uma strategy, um agregado, uma projeção ou um ator são a
mesma ideia nas quatro linguagens. Onde as quatro de fato diferem, a lição diz isso numa tabela como
a de baixo, e esta seção é o dicionário para todo o resto.

## O Python de que você precisa, e o nome que ele tem na sua

É preciso muito pouco Python para ler este curso: classes, funções, listas e dicionários, e as
poucas construções desta tabela. Se você veio pela `backend` com outra linguagem, leia a linha na sua
coluna na primeira vez que uma construção aparecer.

| neste curso (Python) | JavaScript / TypeScript | Java | Go |
|---|---|---|---|
| `class Loan:` com `__init__` | `class Loan { constructor() {} }` | `class Loan { Loan() {} }` | `type Loan struct {}` mais uma função `NewLoan` |
| `self` | `this` | `this` | o receptor, `func (l *Loan)` |
| `_due`, um sublinhado na frente | `#due`, um campo privado | `private` | um nome com inicial minúscula |
| `class Channel(Protocol)` | `interface Channel` (TypeScript) | `interface Channel` | `type Channel interface` |
| `@dataclass(frozen=True)` | `Object.freeze` num objeto simples | `record` | uma struct passada por valor |
| uma função passada como argumento | o mesmo | um lambda ou uma referência de método | um valor `func` |
| `raise ValueError(...)` | `throw new Error(...)` | `throw new IllegalArgumentException(...)` | `return ..., errors.New(...)` |
| `threading`, `queue`, `asyncio` | `async`/`await`, worker threads | threads, `ExecutorService`, virtual threads | goroutines e canais |

A última linha é a que mais pesa nas lições 16 a 18, onde as quatro linguagens mais diferem. Essas
lições dizem, ao lado de cada programa em Python, o que a sua linguagem oferece.

## Como estudar

Cada lição constrói programas pequenos num diretório próprio, dentro de `~/patterns` na sua máquina.
Os programas aparecem inteiros, então você pode copiar cada um, rodá-lo e ver a saída que a lição
mostra. Digitá-los você mesmo é mais lento e ensina mais, e é um bom hábito com qualquer exemplo que
você queira guardar.

Se quiser ir além, reescreva o programa de uma lição na sua linguagem depois que ele rodar em Python.
Nada confere esse trabalho, mas o lugar onde a tradução briga com você costuma ser o lugar onde a sua
linguagem tem uma resposta melhor que o padrão, e a lição 6 tem uma seção exatamente sobre isso.
