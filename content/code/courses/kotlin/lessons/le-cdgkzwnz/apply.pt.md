---
title: apply, para configurar um objeto
version: 1
---

O `apply` torna o objeto o receptor do bloco e devolve o objeto. **Ele serve para configurar algo e
então entregá-lo adiante**: criar, ajustar num bloco em que os membros dispensam prefixo, e receber de
volta no fim.

```kotlin
// Apply.kt
fun main() {
    val report = StringBuilder().apply {
        append("Week 44\n")
        append("Kotlin   105 min\n")
        append("Android   30 min")
    }
    println(report)
    println(report.length)

    val goals = mutableMapOf<String, Int>().apply {
        put("Kotlin", 300)
        put("Android", 240)
    }
    println(goals)
}
```

```
ana@vm:~/kt/l06$ kotlinc Apply.kt -include-runtime -d apply.jar && java -jar apply.jar
Week 44
Kotlin   105 min
Android   30 min
41
{Kotlin=300, Android=240}
```

`StringBuilder` é uma classe Java que junta texto barato, e `append` é um método dela. Dentro do
bloco, o `append` é chamado no builder sem nomeá-lo, porque o builder é `this`. O valor da expressão
inteira é o builder, então `report` o guarda, e o mapa é montado do mesmo jeito.

## A forma que ele substitui

Sem `apply`, o mesmo código nomeia o objeto em toda linha:

```kotlin
val report = StringBuilder()
report.append("Week 44\n")
report.append("Kotlin   105 min\n")
report.append("Android   30 min")
```

São quatro instruções sobre um objeto, e nada impede uma quinta linha de aparecer no meio fazendo
outra coisa. **O `apply` transforma a configuração numa expressão**, que se lê como "o builder,
configurado assim", e ela fica onde cabe uma expressão: um argumento, um valor de retorno, o valor
inicial de uma propriedade.

## O que o `apply` não deve conter

O valor do bloco é jogado fora, porque o `apply` devolve o objeto. **Um cálculo cujo resultado você
quer pertence ao `run`**, e um bloco que faz algo no mundo, registrar ou salvar, pertence ao `also`.
Um `apply` com um `println` dentro funciona, e faz quem lê depois se perguntar se imprimir faz parte da
configuração.

O `android-apps` encontra `apply` o tempo todo. Montar um `Intent`, uma notificação ou um `Bundle` tem
exatamente essa forma: criar um objeto, ajustar cinco coisas nele, passá-lo adiante.
