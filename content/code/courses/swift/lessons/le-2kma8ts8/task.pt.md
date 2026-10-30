---
title: Task, onde o trabalho assíncrono começa
version: 1
---

A seção 03 terminou numa pergunta: `report()` não é `async`, e precisa da resposta de algo que é.
**Uma `Task` é a ponte.** `Task { … }` inicia a closure como um trabalho assíncrono separado e retorna
na hora, devolvendo um valor que representa esse trabalho:

```swift
// Tasks.swift
func loadMinutes(for course: String) async -> [Int] {
    try? await Task.sleep(for: .milliseconds(200))
    return [45, 30, 60]
}

func startLoading() -> Task<Int, Never> {
    Task {
        let minutes = await loadMinutes(for: "Swift")
        print("the task finished")
        return minutes.reduce(0, +)
    }
}

let task = startLoading()
print("startLoading returned")
let total = await task.value
print("total: \(total)")
```

```
ana@vm:~/sw/l14$ swift Tasks.swift
startLoading returned
the task finished
total: 135
```

O `startLoading` é uma função comum, sem `async` na assinatura, e iniciou trabalho assíncrono mesmo
assim. Ela retornou antes de a tarefa fazer qualquer coisa, então "startLoading returned" veio
primeiro. **`Task<Int, Never>` é o tipo da tarefa**: ela produz um `Int`, e o `Never` diz que ela não
pode falhar. O `await task.value` espera a tarefa e dá o resultado dela, então o nível de cima esperou
200 milissegundos ali e imprimiu o total por último.

Um app inicia a maior parte do trabalho assíncrono assim, a partir de código que não é assíncrono: o
tratador de um toque num botão é uma função comum, e o pedido que ele envia vive numa `Task`. O
`ios-apps` escreve esses tratadores; o mecanismo é este.

## Uma tarefa que ninguém espera

A tarefa continua rodando depois que `startLoading` retorna, e nada nela espera pelo programa. Uma
tarefa iniciada e nunca aguardada vive exatamente tanto quanto o processo que a contém:

```swift
// Forgotten.swift
Task {
    try? await Task.sleep(for: .milliseconds(200))
    print("saved")
}
print("done")
```

```
ana@vm:~/sw/l14$ swift Forgotten.swift
done
```

**"saved" nunca apareceu.** O nível de cima imprimiu "done", chegou ao fim, e o processo saiu com a
tarefa ainda dormindo. Nada avisou, porque do ponto de vista do Swift nada deu errado. Num app, que
roda até a pessoa fechá-lo, a mesma tarefa terminaria; num script, numa ferramenta de linha de comando
ou num teste, é um trabalho que silenciosamente não aconteceu. Guarde o valor da `Task` e faça `await`
nele quando o trabalho importa, ou faça `await` diretamente no trabalho.

## Não estruturada, e por que a palavra importa

Uma tarefa feita com `Task { … }` é **não estruturada**: ela não está presa à função que a criou. A
função retorna, e a tarefa segue sozinha, que é o que a ponte precisa e também o que fez "saved"
sumir. O outro tipo de tarefa do Swift é a **tarefa filha**, criada dentro de uma função `async` e
garantida de terminar antes que essa função retorne. As seções 05 e 06 criam tarefas filhas, e essa
garantia é o que deixa o compilador cancelá-las e esperá-las por você.

Existe também `Task.detached { … }`, que inicia uma tarefa que não herda nada do código que a criou.
Você raramente vai precisar dela, e a lição 15 mostra a única coisa que uma `Task` comum herda e que
faz a diferença: o ator em que ela foi iniciada.
