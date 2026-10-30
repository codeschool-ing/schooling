---
title: Um binding, montado à mão
version: 1
---

**Um `Binding` é duas closures e mais nada, e o jeito mais claro de acreditar nisso é escrever um.** O
SwiftUI não está no Linux, mas closures, key paths e dynamic member lookup são Swift puro, então esta
seção monta um tipo com o mesmo formato do `Binding`, chamado `Ref` para os dois não se confundirem,
e o roda. É um modelo da ideia, e não o código-fonte do SwiftUI; a documentação da Apple para o
`Binding` descreve o tipo de verdade, que carrega também uma transação para animações.

Crie um diretório, `~/bindings`, e salve isto como `binding.swift` nele:

```schooling-example
{"language": "swift", "file": "binding.swift", "parts": [{"code": "// binding.swift: what a Binding is, built by hand\n@dynamicMemberLookup\nstruct Ref<Value> {\n    let read: () -> Value\n    let write: (Value) -> Void\n\n    var value: Value {\n        get { read() }\n        nonmutating set { write(newValue) }\n    }\n", "note": "A ideia inteira em cinco linhas: duas closures, uma que lê e uma que escreve. `nonmutating set` quer dizer que definir `value` não muda o próprio `Ref`, só o que as closures alcançam. O `Binding` do SwiftUI tem o mesmo formato, com mais coisa em volta."}, {"code": "    subscript<Part>(dynamicMember path: WritableKeyPath<Value, Part>) -> Ref<Part> {\n        Ref<Part>(read: { self.value[keyPath: path] },\n                  write: { self.value[keyPath: path] = $0 })\n    }\n}\n", "note": "Estreitar. Dado um `Ref` para um valor inteiro e um key path para dentro dele, faça um `Ref` para a parte. O `@dynamicMemberLookup` deixa você escrever `ref.done` ou `ref[1]` e faz o Swift chamar isto, que é exatamente como `$session.done` funciona."}, {"code": "final class Storage<Value> {\n    var value: Value\n    init(_ value: Value) { self.value = value }\n}\n", "note": "Um substituto para onde o `@State` guarda um valor: uma caixa que vive fora das structs das views, para que uma cópia nova de uma view encontre a mesma caixa."}, {"code": "struct Session {\n    var title: String\n    var done: Bool\n}\n\nstruct DoneToggle {\n    let isOn: Ref<Bool>\n    func tap() { isOn.value.toggle() }\n}\n", "note": "Uma filha que só sabe virar um `Bool`. Como um `Toggle`, ela recebe o meio de mudar o valor, e não o valor."}, {"code": "let storage = Storage([\n    Session(title: \"SQL, joins\", done: false),\n    Session(title: \"Mobile, lifecycle\", done: false),\n])\n\nvar copy = storage.value[0].done\ncopy.toggle()\nprint(\"a copy:      copy is \\(copy), storage is \\(storage.value.map(\\.done))\")\n", "note": "Primeiro, entregue uma cópia. Virá-la muda a cópia e nada mais, que é o que passar um valor simples para uma filha faz."}, {"code": "let first = Ref(read: { storage.value[0].done }, write: { storage.value[0].done = $0 })\nDoneToggle(isOn: first).tap()\nprint(\"a binding:   storage is \\(storage.value.map(\\.done))\")\n", "note": "Depois, um binding feito do zero, do jeito que o `Binding(get:set:)` faz. O toque chega ao armazenamento."}, {"code": "let sessions = Ref(read: { storage.value }, write: { storage.value = $0 })\nDoneToggle(isOn: sessions[1].done).tap()\nprint(\"narrowed:    storage is \\(storage.value.map(\\.done))\")\n", "note": "Por último, um binding para a lista inteira, estreitado duas vezes: para o elemento 1, depois para o `done` dele. Essa linha é `$plan.sessions[1].done` com o cifrão escrito por extenso."}]}
```

Rode-o como um arquivo só, do jeito que a aula 1 seção 08 rodou o `check.swift`:

```
ana@vm:~/bindings$ swift binding.swift
a copy:      copy is true, storage is [false, false]
a binding:   storage is [true, false]
narrowed:    storage is [true, true]
```

**Três linhas, três jeitos de entregar a uma filha algo para mudar.** A cópia mudou e o armazenamento
não: `[false, false]`. O binding feito de duas closures chegou ao armazenamento e marcou a primeira
sessão: `[true, false]`. O estreitado chegou à segunda: `[true, true]`. Nada no `DoneToggle` mudou
entre os três; só o que ele recebeu.

É só isso que o `@Binding` acrescenta a uma view: uma propriedade cujo tipo é um binding, e a sintaxe
do `$` para fazer um. A parte do `@State` é a caixa `Storage`, guardada pelo SwiftUI fora da struct,
mais a chamada que roda o `body` de novo depois de uma escrita, que este modelo deixa de fora.
