---
title: O que você monta por conta, e em que aula
version: 1
---

**Um app React é o React mais umas seis decisões**, e este curso toma cada uma delas uma vez, na
aula em que ela importa, com o motivo por escrito. A tabela é a lista inteira. Cada pacote dela é
instalado numa versão exata na aula indicada ao lado, e cada versão é a mesma com que as
transcrições foram gravadas.

| a tarefa | o que este curso usa | aula |
|---|---|---|
| build, servidor de desenvolvimento, variáveis de ambiente | Vite, criado pelo `create-vite` | 1, e a 20 para como funciona |
| tipos | TypeScript, que o modelo do Vite já inclui | da 2 em diante, e a 19 a fundo |
| estado compartilhado pelo app | o context do próprio React, depois Zustand, comparado com Redux Toolkit e Jotai | 9 |
| formulários | React puro primeiro, depois React Hook Form e Zod | 10 |
| dados de um servidor | TanStack Query, que muita gente ainda chama de React Query | 11 |
| endereços e telas | React Router | 17 |
| renderização no servidor | Next.js | 15, 16 e 18 |
| testes | Vitest e React Testing Library | 22 |
| estilo e erros no código | Oxlint, que vem no modelo, depois ESLint, Prettier e Biome | 23 |

Três coisas sobre esta lista valem ser sabidas antes de começar.

**Ela muda.** Durante quase uma década, o jeito como a maioria das pessoas começava um projeto React
era uma ferramenta chamada Create React App, e o time do React a descontinuou em fevereiro de 2025.
Um curso que a ensinasse estaria ensinando uma estrada fechada. O Vite é uma das ferramentas de
build que a documentação do React cita hoje para um projeto feito do zero, e é a que este curso
usa; a aula 20 mostra o bastante de como ele funciona para que a próxima mudança não seja um
mistério.

**Cada linha é um mercado, não uma lei.** Para estado global há pelo menos quatro bibliotecas sérias,
e a aula 9 compara três delas. Para formulários, o React Hook Form é uma entre várias, e a aula 10
escreve um formulário sem nenhuma delas primeiro. Quando o curso escolhe uma, diz por quê, e o
motivo nunca é "este é o padrão".

**As versões são fixadas.** Uma biblioteca de React que lança uma versão major nova pode mudar a
interface, e um curso gravado com uma versão e lido com outra é um curso cujos exemplos falham por
motivos que não são seus. As duas próximas seções preparam o seu computador e fixam tudo o que esta
aula instala, e cada aula depois desta faz o mesmo com o que acrescenta.

## O que o curso pressupõe

Dois cursos vêm antes deste na trilha `frontend`, e o curso se apoia neles sem ensiná-los de novo:

- **`javascript`**, para a linguagem: módulos, arrow functions, desestruturação, promises e
  `async`/`await`, `fetch` e o event loop. A aula 1 dele também instalou o Node.js que este curso
  usa, e a próxima seção confere.
- **`git`**, porque o projeto que você cria aqui é uma pasta que você vai querer sob controle de
  versão desde o primeiro commit.

O `html-css` também vem antes na trilha, e o React escreve HTML: um componente que renderiza um
`<button>` renderiza um botão de verdade, e tudo o que aquele curso disse sobre rótulos e foco
continua valendo.

## Onde este curso fica

A trilha se bifurca depois do `ai-dev`, e você pegou o ramo de React e TypeScript. Outros três
cursos ficam ao lado deste, `angular`, `vue` e `svelte`, e cada estudante faz um dos quatro. **Eles
constroem o mesmo app**: o planejador de estudos que esta aula apresenta, com as mesmas telas e os
mesmos dados. Os cursos depois da bifurcação, `front-quality`, `front-performance`, `front-delivery`
e `front-multiplatform`, não citam nenhum dos quatro frameworks e usam uma versão em TypeScript puro
desse mesmo planejador, então o que você constrói aqui segue com você sem etapa de tradução.
