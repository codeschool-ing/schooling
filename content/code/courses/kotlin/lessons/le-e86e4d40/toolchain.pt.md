---
title: O toolchain e o bytecode que ele mira
version: 1
---

O `kotlin { jvmToolchain(21) }` está em todo script de build desde a lição 14. **Ele diz qual JDK compila
e roda o projeto, e para qual versão do Java é o bytecode.** O Gradle procura um JDK 21 na máquina e o
usa, seja qual for o JDK que iniciou o Gradle; sem um, o build para com a mensagem que a lição 14
provocou de propósito.

A versão é escrita em todo arquivo `.class` que o compilador produz, como um número que a JVM confere
antes de carregar um. O `javap`, o leitor de arquivos de classe do JDK, o mostra:

```
ana@vm:~/kt/planner$ javap -v build/classes/kotlin/main/HelloKt.class | grep major
  major version: 65
```

**A versão de arquivo de classe 65 é o Java 21.** Cada versão do Java soma um: 61 é o Java 17, 55 é o
Java 11. Uma JVM recusa um arquivo de classe mais novo que ela, com `UnsupportedClassVersionError`,
então o número do toolchain também é o Java mais velho em que um usuário consegue rodar o programa.

| o build diz | a máquina precisa | o programa roda em |
|---|---|---|
| `jvmToolchain(21)` | de um JDK 21 para construir | Java 21 ou mais novo |
| `jvmToolchain(17)` | de um JDK 17 para construir | Java 17 ou mais novo |

**Escolha a versão que o programa vai encontrar, não a mais nova disponível.** O `android-apps` vai
definir esse número a partir do que o Android suporta, não do que o notebook tem, e essa é a pergunta a
fazer sobre qualquer alvo: onde esse bytecode roda?
