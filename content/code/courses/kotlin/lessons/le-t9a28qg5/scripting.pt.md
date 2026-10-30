---
title: Kotlin como script
version: 1
---

Nem tudo precisa de um build. Um arquivo que soma os minutos de uma semana, rodado quando preciso e
mudado quando preciso, é um script, e **um arquivo terminado em `.main.kts` é um script Kotlin que o
comando `kotlin` roda direto**: sem `main`, sem Gradle, sem jar. A entrada é o `week.txt` que a aula 14
escreveu no planejador, os minutos de uma sessão por linha, copiado para um diretório novo,
`~/kt/scripts`:

```
ana@vm:~/kt/scripts$ cp ../planner/week.txt .
ana@vm:~/kt/scripts$ cat week.txt
45
30
60
```

```kotlin
#!/usr/bin/env kotlin
// total.main.kts

import java.io.File

val path = args.firstOrNull() ?: "week.txt"
val minutes = File(path).readLines()
    .filter { it.isNotBlank() }
    .map { it.trim().toInt() }
println("${minutes.size} sessions, ${minutes.sum()} min")
```

Os comandos rodam de cima para baixo, e o `args` guarda os argumentos da linha de comando. A primeira
linha, `#!/usr/bin/env kotlin`, deixa um shell de Linux ou macOS rodar o arquivo como qualquer outro
programa, depois que ele é executável:

```
ana@vm:~/kt/scripts$ time kotlin total.main.kts
3 sessions, 135 min

real	0m6.110s
user	0m13.583s
sys	0m0.607s
ana@vm:~/kt/scripts$ chmod +x total.main.kts
ana@vm:~/kt/scripts$ time ./total.main.kts week.txt
3 sessions, 135 min

real	0m2.157s
user	0m3.564s
sys	0m0.291s
```

A primeira execução levou uns seis segundos, a maior parte compilando o script. **O script compilado fica
em cache**, em `~/.cache/main.kts.compiled.cache`, então a execução seguinte levou dois, e uma edição no
arquivo o compila de novo.

Um script também pode nomear bibliotecas do Maven Central com uma anotação no topo,
`@file:DependsOn("group:artifact:version")`, e elas são baixadas na primeira execução. É isso que torna
um arquivo `.main.kts` um substituto razoável para um script de shell que cresceu além do ponto em que
shell é agradável: os tipos do Kotlin, a biblioteca padrão dele, e qualquer biblioteca JVM, num arquivo.

Os arquivos de build do próprio Gradle são os scripts Kotlin mais conhecidos. O `build.gradle.kts` é um
script com a API do Gradle à mão, e é por isso que o da aula 18 podia começar com um `import` como
qualquer arquivo Kotlin.
