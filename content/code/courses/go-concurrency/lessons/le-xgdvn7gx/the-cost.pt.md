---
title: Quanto custa uma goroutine
version: 1
---

Uma goroutine não é uma thread do sistema operacional, e a diferença é de tamanho. **Uma thread
reserva megabytes de pilha quando é criada; uma goroutine começa com poucos kilobytes e só cresce
se precisar.** É por isso que um servidor Go consegue manter uma goroutine por conexão, dezenas de
milhares delas, onde um servidor feito com threads precisa reaproveitá-las num pool.

A afirmação merece uma medida. Este programa inicia cem mil goroutines que esperam todas no mesmo
canal, informa quanto custaram e depois as libera, salvo como `many.go`:

```schooling-example
{"language": "go", "file": "many.go", "parts": [{"code": "// Command many starts a hundred thousand goroutines that all wait on one channel.\npackage main\n\nimport (\n\t\"fmt\"\n\t\"runtime\"\n\t\"sync\"\n\t\"time\"\n)\n\n", "note": "Só a biblioteca padrão. `runtime` é onde o programa pergunta sobre as próprias goroutines e a própria memória."}, {"code": "func stack() uint64 {\n\tvar m runtime.MemStats\n\truntime.ReadMemStats(&m)\n\treturn m.StackInuse\n}\n\n", "note": "**`StackInuse` é a memória que o runtime mantém como pilhas de goroutines**, em bytes. Lê-la antes e depois de as goroutines começarem dá o que elas acrescentaram."}, {"code": "func main() {\n\tconst n = 100_000\n\tbefore := stack()\n\tstart := time.Now()\n\n\trelease := make(chan struct{})\n\tvar wg sync.WaitGroup\n\tfor range n {\n\t\twg.Go(func() { <-release })\n\t}\n\telapsed := time.Since(start)\n\n", "note": "Cada goroutine faz uma coisa só: espera receber de `release`. Nada é enviado nele, então todas continuam vivas até ele ser fechado. A lição 3 explica canais; aqui um deles é só uma porteira."}, {"code": "\tfmt.Println(\"goroutines:\", runtime.NumGoroutine())\n\tfmt.Println(\"started in:\", elapsed.Round(time.Millisecond))\n\tfmt.Println(\"stack memory:\", (stack()-before)/1024/1024, \"MiB\")\n\tfmt.Println(\"per goroutine:\", (stack()-before)/n, \"bytes\")\n\n", "note": "`runtime.NumGoroutine` conta toda goroutine viva naquele momento, `main` incluída."}, {"code": "\tclose(release)\n\twg.Wait()\n\tfmt.Println(\"after they return:\", runtime.NumGoroutine())\n}\n", "note": "Fechar o canal libera de uma vez todos os receptores que esperam. Quando `wg.Wait` retorna, as cem mil terminaram, e a contagem volta a cair."}]}
```

```
ana@vm:~/goroutines$ go build -o many many.go
ana@vm:~/goroutines$ ./many
goroutines: 100001
started in: 424ms
stack memory: 195 MiB
per goroutine: 2048 bytes
after they return: 1
ana@vm:~/goroutines$ ulimit -s
8192
```

Cem mil goroutines começaram em 424 milissegundos, uns quatro microssegundos cada, e as pilhas delas
ocuparam 195 MiB juntas: **2048 bytes cada uma, dois kilobytes**. É desse tamanho que a pilha de uma
goroutine começa. Se uma chamada de função precisar de mais, o runtime copia a pilha para uma maior
e segue em frente, e pode encolhê-la de novo depois; ninguém declara tamanho nenhum.

`ulimit -s` imprime a pilha que o sistema dá a cada thread nova, em kilobytes: 8192, ou seja, 8 MiB
por thread. A maior parte disso é espaço de endereçamento reservado, e não memória em uso, mas é
reservado de antemão, e criar uma thread é uma chamada de sistema toda vez. **Uma goroutine nasce
umas quatro mil vezes menor**, e iniciar uma nunca sai do processo.

A contagem também merece um olhar. `NumGoroutine` disse 100001: as cem mil, mais `main`. Depois do
`close`, disse 1. **Uma goroutine que retorna desaparece, com pilha e tudo**, e uma goroutine que
nunca retorna não desaparece, que é o assunto da lição 6: uma goroutine presa para sempre num canal
que ninguém vai fechar custa esses dois kilobytes e tudo a que ela se refere, enquanto o programa
rodar.

Barato não é de graça. Cada uma dessas goroutines não fazia nada; uma de verdade segura buffers,
conexões e os dados em que está trabalhando, e é isso que enche a memória. O ponto da medida é o
piso: **a goroutine em si nunca é o motivo para não iniciar uma**.
