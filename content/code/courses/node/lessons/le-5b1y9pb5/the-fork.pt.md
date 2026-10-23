---
title: Onde este curso fica
version: 1
---

**A trilha de back-end se bifurca uma vez, na linguagem do servidor, e se junta de novo logo
depois.** Quatro caminhos saem do mesmo ponto e chegam ao mesmo curso:

| caminho | cursos | horas |
|---|---|---|
| **JavaScript / Node.js** | `javascript`, depois `node` | 140 |
| Python | `python`, depois `python-back` | 150 |
| Java | `java`, `java-functional`, depois `java-back` | 230 |
| Go | `go`, `go-concurrency`, `go-back`, depois `go-production` | 290 |

Você está na primeira linha, e este é o segundo curso dela. Qualquer que seja a linha escolhida, o
curso seguinte é o `sql-databases`, e tudo depois dele — `apis`, `servers-cache`, `testing-cicd`,
`docker`, `architecture`, `scale` — é escrito para quem consegue construir um servidor em **uma**
das quatro linguagens. **Esses cursos não citam nenhuma delas.** Os exemplos são escritos para que
cada ideia possa ser levada para a linguagem que você conhece, e é isso que este curso precisa
deixar você capaz de fazer.

## O que este curso pressupõe

Dois cursos antes dele, e nada mais:

- **`javascript`**, a linguagem em si, sem a página. Este curso usa a sintaxe, os módulos, as
  promises e o `async`/`await`, e o event loop de lá, e aponta para a aula em que cada coisa foi
  ensinada em vez de ensinar de novo. As aulas 1 a 10, 13 a 17, 19 e 21 daquele curso são as que
  mais importam aqui; as aulas 11, 12, 18 e 22 eram sobre o navegador e não são usadas.
- **`git`**, porque um projeto de servidor é um repositório desde o primeiro arquivo, e a aula 9
  mantém um segredo fora de um.

## O que ele deixa você capaz de fazer

Até a aula 10 você terá escrito um serviço pequeno, um encurtador de links, três vezes: uma só com
o módulo HTTP do próprio Node, uma com Express, e depois crescendo no lugar. No fim ele guarda os dados em um arquivo, lê as configurações do ambiente e roda um processo por processador. Ele é pequeno de
propósito. Cada linha dele aparece em uma aula, e tudo o que ele faz é algo que os cursos depois
deste dão por garantido.

As onze aulas vêm nesta ordem:

| aula | o que ela acrescenta |
|---|---|
| 1 | por que uma linguagem, a sua máquina, um primeiro servidor |
| 2 | o runtime: V8, as fases do event loop, o pool de threads |
| 3 | módulos: CommonJS, ES modules, e como o Node encontra um arquivo |
| 4 | um projeto: `package.json`, scripts, dependências, o test runner |
| 5 | um servidor HTTP e roteamento sem instalar nada |
| 6 | Express: rotas, middleware e erros |
| 7 | a requisição e a resposta em detalhe |
| 8 | arquivos, buffers e streams |
| 9 | configuração e o ambiente |
| 10 | processos, workers e modo cluster |
| 11 | o mesmo servidor em Python, Go, Java, PHP e C# |
