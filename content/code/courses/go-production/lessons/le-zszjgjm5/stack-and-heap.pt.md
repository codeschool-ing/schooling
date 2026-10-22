---
title: Pilhas de goroutines, e o que mora nelas
version: 1
---

A lição 24 do curso `go` dividiu a memória de um programa em duas: a pilha, onde as variáveis locais
de uma chamada nascem e morrem com ela, e o heap, para onde vai um valor quando o compilador não
consegue provar que ele morre com a chamada. Ela desenhou uma pilha. Um programa Go tem tantas
quantas são as suas goroutines, e a imagem habitual de pilha, um bloco fixo reservado quando uma
thread começa, está errada para cada uma delas. **A pilha de uma goroutine começa com 2 KiB e cresce
sendo copiada, inteira, para um bloco com o dobro do tamanho.** É por isso que dez mil goroutines
custam vinte megabytes de pilha, e isso se apoia numa regra sobre ponteiros que o compilador faz
cumprir por você.

## A pilha de uma thread e a de uma goroutine

Uma thread do sistema operacional recebe sua pilha quando começa, e essa pilha nunca muda de lugar.
`ulimit -s` mostra o tamanho que esta máquina dá à thread principal, em KiB, e o código-fonte do
runtime mostra o que uma goroutine recebe:

```
ana@vm:~/mem-stacks$ ulimit -s
8192
ana@vm:~/mem-stacks$ sed -n 77,78p /usr/local/go/src/runtime/stack.go
	// The minimum size of stack used by Go code
	stackMin = 2048
```

**8.192 KiB contra 2.048 bytes, um fator de quatro mil.** A pilha de uma thread precisa ser grande,
porque nada pode aumentá-la depois: um programa que passa dela na recursão é encerrado. A de uma
goroutine pode ser pequena porque o runtime a aumenta no instante em que ela está para acabar. Quase
toda função Go começa com algumas instruções que comparam o ponteiro de pilha com o fim da pilha
atual; quando o próximo frame não caberia, o runtime aloca um bloco com o dobro do tamanho, copia a
pilha para ele e segue em frente.

Um programa em `~/mem-stacks` observa isso acontecer. Ele inicia dez mil goroutines que ficam
esperando, depois chama uma função com 100.000 níveis de profundidade, e informa a cada passo a
contagem que o próprio runtime faz da memória de pilha:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "// Command stacks watches goroutine stacks: how big they start, and how one\n// grows, moves and shrinks.\npackage main\n\nimport (\n\t\"flag\"\n\t\"fmt\"\n\t\"runtime\"\n\t\"runtime/debug\"\n\t\"runtime/metrics\"\n\t\"sync\"\n\t\"unsafe\"\n)\n",
      "note": "`runtime/metrics` é a contabilidade do próprio runtime, lida por nome. `unsafe` está aqui por uma conversão, explicada adiante; a lição 22 é sobre esse pacote."
    },
    {
      "code": "// read returns the current value of one runtime metric.\nfunc read(name string) uint64 {\n\ts := []metrics.Sample{{Name: name}}\n\tmetrics.Read(s)\n\treturn s[0].Value.Uint64()\n}\n\n// stacksKiB is the memory the runtime holds for goroutine stacks.\nfunc stacksKiB() uint64 {\n\treturn read(\"/memory/classes/heap/stacks:bytes\") >> 10\n}\n",
      "note": "**Uma métrica é lida pelo nome, e a unidade faz parte do nome.** `/memory/classes/heap/stacks:bytes` é toda a memória que o runtime separou para pilhas de goroutines, as que estão em uso e as guardadas para reaproveitar."
    },
    {
      "code": "// down calls itself n times. Each call's frame holds a 256-byte array.\nfunc down(n int) byte {\n\tvar pad [256]byte\n\tpad[n%256] = byte(n)\n\tif n == 0 {\n\t\treturn pad[0]\n\t}\n\treturn down(n-1) + pad[n%256]\n}\n",
      "note": "Recursão com um frame de tamanho conhecido. O array é local e nunca sai da chamada, então mora no frame, e cada chamada acrescenta pouco mais de 256 bytes à pilha."
    },
    {
      "code": "func main() {\n\tdepth := flag.Int(\"depth\", 100_000, \"how many calls deep to go\")\n\tlimit := flag.Int(\"max\", 0, \"the largest stack allowed, in bytes (0: the default)\")\n\tflag.Parse()\n\tif *limit > 0 {\n\t\tdebug.SetMaxStack(*limit)\n\t}\n",
      "note": "Duas flags: a profundidade, e um teto para a pilha. `debug.SetMaxStack` baixa o teto para que o estouro aconteça em um megabyte, e não no padrão."
    },
    {
      "code": "\tfmt.Printf(\"a new goroutine starts with %d bytes\\n\", read(\"/gc/stack/starting-size:bytes\"))\n\tbefore := stacksKiB()\n\tvar wg sync.WaitGroup\n\trelease := make(chan struct{})\n\tfor range 10_000 {\n\t\twg.Go(func() { <-release })\n\t}\n\tfmt.Printf(\"10,000 goroutines waiting: %d KiB of stacks more\\n\", stacksKiB()-before)\n\tclose(release)\n\twg.Wait()\n\truntime.GC()\n",
      "note": "**Dez mil goroutines que só esperam**, e a memória de pilha medida antes e depois. `wg.Go` inicia uma goroutine e a conta numa chamada só. A coleta no fim libera as pilhas das goroutines que terminaram."
    },
    {
      "code": "\tx := 1\n\tfmt.Printf(\"stacks %6d KiB, x at %#x\\n\", stacksKiB(), uintptr(unsafe.Pointer(&x)))\n\tdown(*depth)\n\tfmt.Printf(\"stacks %6d KiB, x at %#x, after %d calls\\n\", stacksKiB(), uintptr(unsafe.Pointer(&x)), *depth)\n\tfor range 3 {\n\t\truntime.GC()\n\t\tfmt.Printf(\"stacks %6d KiB, x at %#x, after a collection\\n\", stacksKiB(), uintptr(unsafe.Pointer(&x)))\n\t}\n}",
      "note": "`uintptr(unsafe.Pointer(&x))` transforma o endereço de `x` num número comum. Um número não é ponteiro, então `x` continua no frame de `main`, e imprimi-lo mostra **onde o frame está agora**. Depois vem a chamada profunda, e três coletas seguidas."
    }
  ]
}
```

Compilado e executado com os valores padrão:

```
ana@vm:~/mem-stacks$ go build -o stacks . && ./stacks
a new goroutine starts with 2048 bytes
10,000 goroutines waiting: 20000 KiB of stacks more
stacks   1280 KiB, x at 0x3d6e0e954de0
stacks  34080 KiB, x at 0x3d6e14407de0, after 100000 calls
stacks  17664 KiB, x at 0x3d6e11487de0, after a collection
stacks   9504 KiB, x at 0x3d6e123ffde0, after a collection
stacks   5408 KiB, x at 0x3d6e10887de0, after a collection
```

As duas primeiras linhas são o lado barato. **Uma goroutine nova começa com 2.048 bytes, e dez mil
goroutines esperando ocuparam 20.000 KiB**: dez mil pilhas de exatamente 2 KiB. Com threads, as
mesmas dez mil reservariam 8 MiB cada uma.

O resto é o lado caro. Depois de 100.000 chamadas de pouco mais de 256 bytes cada, a memória de pilha
foi de 1.280 KiB para 34.080 KiB: a pilha de `main` tinha sido dobrada várias vezes até guardar uns
32 MiB. **E `x`, uma variável de `main` em que ninguém mexeu, está em outro endereço.** Ela nunca foi
reatribuída e nunca escapou; o frame inteiro em que ela está foi copiado para o bloco novo, e ela foi
junto. Cada coleta depois disso a moveu de novo, porque o coletor encolhe uma pilha que usa menos de
um quarto do seu tamanho, pela metade de cada vez: 17.664, depois 9.504, depois 5.408 KiB. Pilhas de
goroutines são memória que o coletor administra, como o heap, e voltam a encolher sem ajuda nenhuma.

## Por que uma pilha pode mudar de lugar

Copiar uma pilha para outro endereço só é seguro se cada ponteiro para algo nela puder ser encontrado
e corrigido. Os ponteiros dentro da própria pilha são fáceis: o compilador registra, para cada
função, quais palavras do seu frame guardam ponteiros, e o runtime os ajusta durante a cópia. Um
ponteiro guardado no heap seria outra história. O runtime teria de vasculhar o heap inteiro atrás de
ponteiros para o bloco antigo, a cada crescimento de cada goroutine.

**Ele nunca precisa, porque nenhum valor do heap pode apontar para dentro de uma pilha.** Essa é a
primeira das duas invariantes que a análise de escape existe para manter, nas palavras do próprio
código do compilador (`cmd/compile/internal/escape/escape.go`): "pointers to stack objects cannot be
stored in the heap", ponteiros para objetos da pilha não podem ser guardados no heap. Quando um
código guardaria o endereço de uma variável local em algum lugar do heap, o compilador põe a
variável no heap, e a pilha fica só com ponteiros para fora.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Pilhas de goroutines ao lado do heap. Duas goroutines novas têm cada uma uma pilha de 2 KiB; 10.000 delas ocupam 20.000 KiB. A goroutine main, com 100.000 chamadas de profundidade, tem uma pilha de 32 MiB. Setas vão de frames nas pilhas para valores no heap compartilhado, e entre valores do heap, mas nunca do heap para dentro de uma pilha. Por isso uma pilha cheia pode ser copiada inteira para um bloco com o dobro do tamanho, corrigindo só os ponteiros que estão dentro dela.\"><defs><marker id=\"stk-ph\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"stk-am\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><text x=\"160\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pilhas de goroutines: uma cada</text><text x=\"530\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o heap: um só, compartilhado</text><rect x=\"30\" y=\"40\" width=\"90\" height=\"200\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">32 MiB</text><path d=\"M36 72 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 84 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 96 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 108 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 120 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 132 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 144 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 156 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 168 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 180 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 192 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 204 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 216 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M36 228 H114\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"75\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">main, depois de</text><text x=\"75\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">100.000 chamadas</text><rect x=\"150\" y=\"196\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2 KiB</text><path d=\"M156 224 H214\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><rect x=\"235\" y=\"196\" width=\"70\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"270\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2 KiB</text><path d=\"M241 224 H299\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"185\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">uma nova</text><text x=\"270\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">esperando</text><text x=\"228\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">10.000 delas: 20.000 KiB</text><rect x=\"360\" y=\"36\" width=\"340\" height=\"214\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><rect x=\"385\" y=\"62\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"520\" y=\"62\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"600\" y=\"128\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"385\" y=\"130\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"385\" y=\"196\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"520\" y=\"196\" width=\"80\" height=\"26\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M121 80 L382 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M121 150 L382 143\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M306 210 L382 209\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M466 75 L517 75\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M600 89 L630 125\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M466 143 L597 141\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M466 209 L517 209\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#stk-ph)\"></path><path d=\"M392 223 C 375 246, 340 246, 308 234\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 4\" marker-end=\"url(#stk-am)\"></path><path d=\"M343 236 L355 248 M355 236 L343 248\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"410\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">nunca: um valor do heap apontando para uma pilha</text><text x=\"360\" y=\"304\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Uma pilha que se esgota é copiada inteira para um bloco com o dobro do tamanho; só os ponteiros dentro dela são corrigidos.</text></svg>", "caption": "Ponteiros vão das pilhas para o heap e nunca no sentido contrário, e é isso que permite ao runtime mover uma pilha."}
```

É a mesma decisão que a lição 24 do curso `go` viu o compilador tomar com `-gcflags=-m`, vista do
outro lado. **Um valor escapa quando um ponteiro para ele pode sobreviver ao seu frame ou ser
guardado no heap**; os motivos do compilador, e como lê-los, são a lição 20. Para esta lição basta
uma consequência: o que fica numa pilha não custa nada ao coletor, e o que escapa é uma alocação que
o coletor da seção 03 terá de encontrar de novo depois.

## O teto

O crescimento não é ilimitado. O runtime se recusa a crescer uma pilha além de um máximo, e `-max`
baixa esse máximo com `debug.SetMaxStack` para que a recusa venha logo:

```
ana@vm:~/mem-stacks$ ./stacks -max 1000000 2>&1 | head -6; echo ${PIPESTATUS[0]}
a new goroutine starts with 2048 bytes
10,000 goroutines waiting: 20064 KiB of stacks more
stacks   1056 KiB, x at 0x26184975ede0
runtime: goroutine stack exceeds 1000000-byte limit
runtime: sp=0x26184ac783b0 stack=[0x26184ac78000, 0x26184acf8000]
fatal error: stack overflow
2
ana@vm:~/mem-stacks$ sed -n 160,167p /usr/local/go/src/runtime/proc.go
	// Max stack size is 1 GB on 64-bit, 250 MB on 32-bit.
	// Using decimal instead of binary GB and MB because
	// they look nicer in the stack overflow failure message.
	if goarch.PtrSize == 8 {
		maxstacksize = 1000000000
	} else {
		maxstacksize = 250000000
	}
```

**Estouro de pilha é um erro fatal, não um pânico.** Nenhum `recover` o captura, o runtime imprime a
pilha da goroutine (cortada aqui pelo `head`) e sai com status 2. O teto padrão é de 1.000.000.000
bytes numa máquina de 64 bits, escrito em decimal, como diz o comentário, para a mensagem ficar
bonita. Uma chamada que nunca para de se repetir chega lá, pedindo cem milhões de chamadas e deixando
o padrão em paz:

```
ana@vm:~/mem-stacks$ time ./stacks -depth 100000000 2>&1 | sed -n 4,6p
runtime: goroutine stack exceeds 1000000000-byte limit
runtime: sp=0x2e31a2300350 stack=[0x2e31a2300000, 0x2e31c2300000]
fatal error: stack overflow

real	0m0.863s
user	0m0.317s
sys	0m0.527s
```

Menos de um segundo, porque cada dobra copia só o que está em uso, e são umas dezenove entre 2 KiB e
um gigabyte. **O custo de uma recursão descontrolada em Go é um gigabyte de memória por um
instante**, onde os 8 MiB de uma thread teriam acabado com ela antes; um servidor que faz recursão
sobre a entrada que recebeu precisa do seu próprio limite de profundidade muito antes de qualquer
um dos dois.

Mais uma coisa no código explica por que vale imprimir a primeira linha do programa:

```
ana@vm:~/mem-stacks$ grep -n "adaptivestackstart = " /usr/local/go/src/runtime/runtime1.go
397:	debug.adaptivestackstart = 1 // set this to 0 to turn larger initial goroutine stacks off
```

O tamanho inicial não é fixo em 2 KiB. **A cada coleta o runtime mede quanta pilha as goroutines que
ele escaneou estavam usando, e passa a iniciar goroutines novas com essa média**, arredondada para
cima até uma potência de dois. Um programa cujas goroutines descem todas 20 KiB deixa de
pagar pelos mesmos poucos crescimentos em cada uma delas. `/gc/stack/starting-size:bytes` informa o
valor atual; o `~/mem-stacks` imprimiu 2.048 porque leu a métrica antes de a primeira coleta ter
medido qualquer coisa.
