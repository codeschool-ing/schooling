---
title: Blocos init, e a ordem em que um objeto é montado
version: 1
---

Um construtor primário não tem corpo próprio. **Código que precisa rodar quando um objeto é montado
vai num bloco `init`**, e uma classe pode ter vários. Eles rodam junto com os inicializadores de
propriedade, na ordem em que aparecem na classe, de cima para baixo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l07-init\" aria-label=\"A construção de Planner(&quot;Ana&quot;) como uma linha do tempo da esquerda para a direita. Primeiro o parâmetro owner do construtor é atribuído. Depois, na ordem em que aparecem na classe: a propriedade greeting, o primeiro bloco init, a propriedade sessions, o segundo bloco init. Então o objeto é entregue a quem chamou. Uma nota diz que um bloco só usa o que está à esquerda dele.\"><defs><marker id=\"l07-init-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l07-init-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l07-init-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"80\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">owner = \"Ana\"</text><text x=\"80\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">construtor</text><rect x=\"160\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"220\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">val greeting</text><text x=\"220\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">propriedade</text><path d=\"M140 98 L160 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-amber)\"></path><rect x=\"290\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">init { … }</text><text x=\"350\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">bloco</text><path d=\"M280 98 L290 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-amber)\"></path><rect x=\"420\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"480\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">val sessions</text><text x=\"480\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">propriedade</text><path d=\"M410 98 L420 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-amber)\"></path><rect x=\"550\" y=\"70\" width=\"120\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"610\" y=\"92\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">init { … }</text><text x=\"610\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">bloco</text><path d=\"M540 98 L550 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-amber)\"></path><text x=\"220\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">1.</text><text x=\"350\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">2.</text><text x=\"480\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">3.</text><text x=\"610\" y=\"55\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">4.</text><path d=\"M670 98 L700 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-phosphor)\"></path><text x=\"600\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">então o objeto é devolvido</text><path d=\"M30 190 L690 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l07-init-ah-paper-dim)\"></path><text x=\"360\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ordem no arquivo = ordem de execução</text><text x=\"360\" y=\"230\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">um bloco só usa o que está à esquerda dele</text></svg>", "caption": "Os parâmetros do construtor primeiro, depois cada inicializador de propriedade e bloco init na ordem em que estão escritos."}
```

```kotlin
// Order.kt
class Planner(val owner: String) {
    val greeting = "planner of $owner".also { println("1. property: $it") }

    init {
        println("2. init: owner is $owner")
    }

    val sessions = mutableListOf<Int>().also { println("3. property: sessions") }

    init {
        println("4. init: ${sessions.size} sessions")
    }
}

fun main() {
    Planner("Ana")
}
```

```
ana@vm:~/kt/l07$ kotlinc Order.kt -include-runtime -d order.jar && java -jar order.jar
1. property: planner of Ana
2. init: owner is Ana
3. property: sessions
4. init: 0 sessions
```

Os parâmetros do construtor são atribuídos primeiro, e é por isso que todo bloco consegue usar
`owner`. Depois disso, **a ordem na tela é a ordem no arquivo**. Isso é simples, e tem uma armadilha:
um bloco só usa o que está acima dele.

```kotlin
// TooEarly.kt
class Planner(val owner: String) {
    init {
        println("${sessions.size} sessions")
    }

    val sessions = mutableListOf<Int>()
}

fun main() {
    Planner("Ana")
}
```

```
ana@vm:~/kt/l07$ kotlinc TooEarly.kt -include-runtime -d tooearly.jar
TooEarly.kt:4:20: error: variable 'sessions' must be initialized.
        println("${sessions.size} sessions")
                   ^^^^^^^^
```

`sessions` está declarado abaixo do `init`, então naquele momento ainda não recebeu valor, e o
compilador recusa. **Declare as propriedades primeiro e os blocos `init` depois delas**, e a
armadilha não aparece.

## Verificando o que entrou

O bloco `init` mais comum verifica os argumentos, para um objeto que existe ser um objeto que faz
sentido:

```kotlin
// Checked.kt
class Session(val course: String, val minutes: Int) {
    init {
        require(course.isNotBlank()) { "a session needs a course" }
        require(minutes in 1..600) { "minutes out of range: $minutes" }
    }
}

fun main() {
    println(Session("Kotlin", 45).minutes)
    Session("Kotlin", 0)
}
```

```
ana@vm:~/kt/l07$ kotlinc Checked.kt -include-runtime -d checked.jar && java -jar checked.jar
45
Exception in thread "main" java.lang.IllegalArgumentException: minutes out of range: 0
	at Session.<init>(Checked.kt:5)
	at CheckedKt.main(Checked.kt:11)
	at CheckedKt.main(Checked.kt)
```

O `require` lança `IllegalArgumentException` com a mensagem da lambda dele. **Uma sessão inválida
agora nem chega a ser montada**, então nenhum código que recebe uma `Session` precisa perguntar se os
minutos dela fazem sentido. É a mesma troca que a lição 2 fez com o `null`: uma verificação onde o
valor é criado, em vez de uma dúvida em todo lugar onde ele é usado.
