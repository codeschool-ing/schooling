---
title: Grupos de tarefas, para uma quantidade que se sabe depois
version: 1
---

O planner não sabe quantos cursos uma estudante tem até ler a lista. **Um grupo de tarefas inicia uma
tarefa filha por item, sejam quantos forem**, e devolve os resultados à medida que cada um termina.
Aqui cada curso leva um tempo diferente para carregar, para que a ordem das respostas fique visível:

```schooling-example
{"language": "swift", "file": "Group.swift", "parts": [{"code": "func loadMinutes(for course: String) async -> Int {\n    try? await Task.sleep(for: .milliseconds(course.count * 50))\n    return course.count * 10\n}", "note": "O substituto da rede de novo, com um atraso que cresce com o nome: 150 milissegundos para `SQL`, 500 para `Statistics`. Atrasos diferentes tornam visível a ordem das respostas."}, {"code": "let courses = [\"Swift\", \"Kotlin\", \"Statistics\", \"SQL\"]\n\nlet total = await withTaskGroup(of: (String, Int).self) { group in", "note": "O `withTaskGroup` abre um grupo e roda a closure com ele. O `of:` diz o que cada tarefa filha devolve, aqui um curso e os minutos dele juntos, para que cada resposta diga a que curso pertence."}, {"code": "    for course in courses {\n        group.addTask {\n            (course, await loadMinutes(for: course))\n        }\n    }", "note": "**Uma tarefa filha por curso**, iniciada pelo `addTask`. O laço não espera nenhuma delas: inicia quatro tarefas e termina."}, {"code": "    var sum = 0\n    for await (course, minutes) in group {\n        print(\"\\(course): \\(minutes)\")\n        sum += minutes\n    }\n    return sum\n}", "note": "O `for await` pega os resultados **na ordem em que as tarefas terminam**, esperando sempre que nenhum está pronto. O que a closure devolve vira o valor do `withTaskGroup`."}, {"code": "print(\"week: \\(total) minutes\")"}]}
```

```
ana@vm:~/sw/l14$ swift Group.swift
SQL: 30
Swift: 50
Kotlin: 60
Statistics: 100
week: 240 minutes
```

**Os resultados voltaram na ordem em que terminaram, não na ordem em que começaram.** SQL, o nome mais
curto e por isso o atraso mais curto, veio primeiro, aos 150 milissegundos; Swift veio aos 250,
Kotlin aos 300 e Statistics por último, aos 500, embora Statistics tenha sido iniciado em terceiro.
Um grupo de tarefas é uma fila de respostas, e o `for await` as pega conforme chegam. O total não
depende da ordem, então é o mesmo 240 seja qual for o entrelaçamento das quatro cargas, e o grupo
inteiro levou o tempo do seu filho mais lento.

Essa é a primeira coisa a lembrar sobre um grupo: **código que junta resultados por posição está
errado aqui.** Se o planner precisa saber que minutos pertencem a que curso, cada filha tem de devolver
o curso junto com os minutos, como estas fazem com uma tupla, e quem chama põe cada um no seu lugar.

## As mesmas garantias do async let

Toda tarefa do grupo é uma tarefa filha. O `withTaskGroup` não retorna até todas terminarem, então um
grupo abandonado cedo, com resultados ainda não lidos, espera o resto antes de retornar, e um grupo
não consegue vazar trabalho como o `Forgotten.swift` vazou. Se a closure lança um erro, ou a tarefa que
a roda é cancelada, o grupo cancela toda filha que ainda está rodando. A aula 18 usa um grupo para
testar vários pedidos de uma vez.

Existe uma variante que lança, `withThrowingTaskGroup`, cujas filhas podem lançar erros. O
`for try await` dela relança o primeiro erro, e a essa altura o grupo já cancelou as outras filhas:
uma carga que falha para as demais, em vez de deixá-las terminar à toa.

## Escolhendo entre eles

| você tem | use |
|---|---|
| um trabalho, e precisa do resultado antes de continuar | `await` |
| um punhado fixo de trabalhos independentes | `async let` |
| tantos trabalhos quantos itens tem uma lista | um grupo de tarefas |
| trabalho iniciado de código que não é `async`, como um botão | `Task { … }` |

Os três primeiros não criam nenhuma tarefa não estruturada nova, e o compilador cuida delas para você.
O quarto é a ponte da seção 04, e o único de que você mesmo tem de cuidar.
